REM <#
@echo off
copy UpdateArcMechanics.cmd UpdateArcMechanics.ps1 >NUL
PowerShell.exe -ExecutionPolicy Unrestricted -NoProfile -Command "&{Set-Alias REM Write-Host; .\UpdateArcMechanics.ps1}"
del UpdateArcMechanics.ps1
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

$mechanicsD3 = 'http://martionlabs.com/wp-content/uploads/d3d9_arcdps_mechanics.dll'
$mechanicsMD5 = 'http://martionlabs.com/wp-content/uploads/d3d9_arcdps_mechanics.dll.md5sum'


# ======================== Downloads mechanics plugin ========================================================

function DownloadArcMechanics
{
	Write-Verbose 'Downloading ArcMechanics'
    $mechanicsD3Response = Invoke-WebRequest -Uri $mechanicsD3
    Set-Content -Path "$($GW2Path)\bin64\d3d9_arcdps_mechanics.dll" -Encoding Byte -Value $mechanicsD3Response.Content
    Write-Verbose 'Completed ArcMechanics install'
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

CheckMechanicsUpdates
Write-Verbose 'Starting GuildWars 2...'
Start-Process -FilePath "$($GW2Path)\$($gw).exe"