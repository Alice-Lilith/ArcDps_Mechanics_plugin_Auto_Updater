REM <#
@echo off
copy UpdateAll.cmd UpdateAll.ps1 >NUL
PowerShell.exe -ExecutionPolicy Unrestricted -NoProfile -Command "&{Set-Alias REM Write-Host; .\UpdateAll.ps1}"
del UpdateAll.ps1
exit
REM #>


# Lines starting with a '#' are comments for readability and will not be executed
# This is based off of the code from https://gist.github.com/OneFaced/764f9c5c7bef1c49a31d928c223bcb24
# It checks for updates to arc dps and also the mechanics plugin at the uri below
# comments included for readability

# ======================== Guild Wars 2 Path (Change if needed) ========================================================

$GW2Path = "$env:ProgramFiles\Guild Wars 2\"
$gw = 'Gw2-64'

# ======================== Links to files needed ========================================================

$arcMD5 = 'https://www.deltaconnected.com/arcdps/x64/d3d9.dll.md5sum'
$arcD3 = 'https://www.deltaconnected.com/arcdps/x64/d3d9.dll'
$buildTemplates = 'https://www.deltaconnected.com/arcdps/x64/buildtemplates/d3d9_arcdps_buildtemplates.dll'
$mechanicsD3 = 'http://martionlabs.com/wp-content/uploads/d3d9_arcdps_mechanics.dll'
$mechanicsMD5 = 'http://martionlabs.com/wp-content/uploads/d3d9_arcdps_mechanics.dll.md5sum'

# ======================== Downloads main arc dps ========================================================

function DownloadArcDps
{
	Write-Verbose 'Downloading ArcDps'
    $arcD3Response = Invoke-WebRequest -Uri $arcD3
    Set-Content -Path "$($GW2Path)\bin64\d3d9.dll" -Encoding Byte -Value $arcD3Response.Content
    $btResponse = Invoke-WebRequest -Uri $buildTemplates
    Set-Content -Path "$($GW2Path)\bin64\d3d9_arcdps_buildtemplates.dll" -Encoding Byte -Value $btResponse.Content
    Write-Verbose 'Completed ArcDps install'
}

# ======================== Downloads mechanics plugin ========================================================

function DownloadArcMechanics
{
	Write-Verbose 'Downloading ArcMechanics'
    $mechanicsD3Response = Invoke-WebRequest -Uri $mechanicsD3
    Set-Content -Path "$($GW2Path)\bin64\d3d9_arcdps_mechanics.dll" -Encoding Byte -Value $mechanicsD3Response.Content
    Write-Verbose 'Completed ArcMechanics install'
}


# ======================== Checks main arc file for updates ========================================================

function CheckArcUpdates
{
    if((Get-Process $gw -ErrorAction 0).Count -gt 0)
    {
        Exit
    }
	
	# checks if the file exists in the directory
    $arcD3Exists = Test-Path "$($GW2Path)\bin64\d3d9.dll"
	
	# if it does exist, check if the version is the most recent
    if($arcD3Exists)
    {
		# gets the hash of the version in the GW2 directory
        $currentArcD3 = Get-FileHash "$($GW2Path)\bin64\d3d9.dll" -Algorithm MD5
		
		# attempts to get a response from the MD5
		try
		{
			$arcMD5Response = Invoke-WebRequest -Uri $arcMD5
		}
		
		# exits if it cant download the MD5
        catch 
		{
		    Write-Verbose 'Failed to download Arc Dps MD5 sum'
            Exit
		}

		# if we get a response, check if the hash matches the one we currently have, if they dont match, it is out of date
        if(!$currentArcD3.Hash.Equals(($arcMD5Response.ToString().Split(" ",[System.StringSplitOptions]::RemoveEmptyEntries)[0]), 
			[System.StringComparison]::InvariantCultureIgnoreCase))
        {
            Write-Verbose 'Arc Dps is out of date'
			
			# copying the current arc dps to a old.bak file for backup
            Copy-Item "$($GW2Path)\bin64\d3d9.dll" -Destination "$($GW2Path)\bin64\d3d9_old.bak" -Force
			
			# makes an attempt to copy the build templates file as well
            try
            {
                Copy-Item "$($GW2Path)\bin64\d3d9_arcdps_buildtemplates.dll" -Destination "$($GW2Path)\bin64\d3d9_arcdps_buildtemplates_old.bak" -Force
            }
            catch {}
			
			# calls the function to download the newest version
            DownloadArcDps
        }
		# The hashes match, you currently have the most recent version
        else
        {
            Write-Verbose 'Arc Dps is up to date'
        }
    }
	# the file does not exist in the directory, downloading a new copy now
    else
    {
        DownloadArcDps
    }
}


# ======================== Checks mechanics plugin for updates ========================================================

function CheckMechanicsUpdates
{
    if((Get-Process $gw -ErrorAction 0).Count -gt 0)
    {
        Exit
    }
	
	# checks if the file exists in the directory
    $mechanicsD3Exists = Test-Path "$($GW2Path)\bin64\d3d9_arcdps_mechanics.dll"
	
	# if it does exist, check if the version is the most recent
    if($mechanicsD3Exists)
    {
		# gets the hash of the version in the GW2 directory
        $currentMechanicsD3 = Get-FileHash "$($GW2Path)\bin64\d3d9_arcdps_mechanics.dll" -Algorithm MD5
		
		# attempts to get a response from the MD5
		try
		{
			$mechanicsMD5Response = Invoke-WebRequest -Uri $mechanicsMD5
		}
		
		# exits if it cant download the MD5
        catch 
		{
		    Write-Verbose 'Failed to download Arc Mechanics MD5 sum'
            Exit
		}

		# if we get a response, check if the hash matches the one we currently have, if they dont match, it is out of date
        if(!$currentMechanicsD3.Hash.Equals(($mechanicsMD5Response.ToString().Split(" ",[System.StringSplitOptions]::RemoveEmptyEntries)[0]), 
			[System.StringComparison]::InvariantCultureIgnoreCase))
        {
            Write-Verbose 'Arc Mechanics is out of date'
			
			# copying the current arc Mechanics to a old.bak file for backup
            Copy-Item "$($GW2Path)\bin64\d3d9_arcdps_mechanics.dll" -Destination "$($GW2Path)\bin64\d3d9_arcdps_mechanics_old.bak" -Force
			
			# calls the function to download the newest version
			DownloadArcMechanics
        }
		# The hashes match, you currently have the most recent version
        else
        {
            Write-Verbose 'Arc Mechanics is up to date'
        }
    }
	# the file does not exist in the directory, downloading a new copy now
    else
    {
        DownloadArcMechanics
    }
}

# ======================== Function Calls and launches GW2 ========================================================

CheckArcUpdates
CheckMechanicsUpdates
Write-Verbose 'Launching Guild Wars 2'
Start-Process -FilePath "$($GW2Path)\$($gw).exe"