#Region CheckAdmin
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-Host "You didn't run this script as an Administrator. This script will self elevate to run as an Administrator and continue.  3"
    Start-Sleep 1
	Clear-Host
    Write-Host "You didn't run this script as an Administrator. This script will self elevate to run as an Administrator and continue.  2"
    Start-Sleep 1
	Clear-Host
    Write-Host "You didn't run this script as an Administrator. This script will self elevate to run as an Administrator and continue.  1"
	Start-Sleep 1
    Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`" -WhitelistApps {1}" -f $PSCommandPath, ($WhitelistApps -join ',')) -Verb RunAs
    Exit
}
#EndRegion CheckAdmin

Write-Host -ForegroundColor Green "Welcome to OSDCloud ImmyBot Environment Hydration Pack`n`n"

#Region CheckInstallADK
if (!((Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -match "Windows Assessment and Deployment Kit*"}).Displayname).count) {
	
	Write-Host -ForegroundColor Blue @"
The Windows ADK was not detected, preparing to download and install it now.
1. May 2024
2. Sept 2023
Which version would you like to install (You will need to install Insider's edition manually)
"@ -nonewline;[ValidateSet("1","2")]$ADKanswer = Read-Host " "
	
	switch ($ADKanswer) {
		'1' { $ADKURL = "https://download.microsoft.com/download/5/8/6/5866fc30-973c-40c6-ab3f-2edb2fc3f727/ADK/adksetup.exe" }
		'2' { $ADKURL = "https://download.microsoft.com/download/6/1/f/61fcd094-9641-439c-adb5-6e9fe2760856/adk/adksetup.exe" }
	}
	$ADKFile = "$($env:windir)\TEMP\adksetup.exe"
	$ADKInstallFile = Invoke-WebRequest -Uri "$ADKURL" -Passthru -Outfile "$ADKFile"
	
	$Process = Start-Process $ADKInstallFile -ArgumentList "/quiet /norestart /features OptionId.DeploymentTools" -Passthru -Wait
	if ($Process.ExitCode -eq 0){
		Write-Host -Foreground Yellow "Windows ADK successfully installed."
	} else {
		Write-Host -Foreground Red "Windows ADK was not installed, aborting..."
		Break
	}
} else {
	Write-Host -ForegroundColor DarkGreen "Windows ADK is detected, continuing..."
}

if (!((Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -match "Windows Assessment and Deployment Kit Windows Preinstallation Environment*"}).Displayname).count) {
	Write-Host -ForegroundColor Blue @"
	The Windows ADK WinPE Plugin was not detected, preparing to download and install it now.
1. May 2024
2. Sept 2023
The version should match your ADK installation (You will need to install Insider's edition manually)
"@ -nonewline;[ValidateSet("1","2")]$ADKWinPEanswer = Read-Host " "

	switch ($ADKWinPEanswer) {
		'1' { $ADKWinPEURL = "https://download.microsoft.com/download/d/f/0/df0273fb-4587-4cc5-a98c-7d2359b4a387/ADKWinPEAddons/adkwinpesetup.exe" }
		'2' { $ADKWinPEURL = "https://download.microsoft.com/download/c/6/8/c68972f8-9148-4240-818e-7288e1e54256/adkwinpeaddons/adkwinpesetup.exe" }
	}
	$ADKWinPEFile = "$($env:windir)\TEMP\adkwinpesetup.exe"
	$ADKWinPEInstallFile = Invoke-WebRequest -Uri "$ADKWinPEURL" -Passthru -Outfile "$ADKWinPEFile"
	
	$Process = Start-Process $ADKWinPEInstallFile -ArgumentList "/quiet /norestart" -Passthru -Wait
	if ($Process.ExitCode -eq 0){
		Write-Host -Foreground Yellow "Windows ADK WinPE Plugin successfully installed."
	} else {
		Write-Host -Foreground Red "Windows ADK WinPE Plugin was not installed, aborting..."
		Break
	}
} else {
	Write-Host -ForegroundColor DarkGreen "Windows ADK WinPE Plugin is detected, continuing..."
}
#EndRegion CheckInstallADK

#Region GetUserInputWithValidation
$DirectoryValidationScriptBlock = {
	if( [System.IO.Directory]::Exists($_) -or $_ -eq "" -or $null -eq $_ ){
		return $true
	} else {
		return $false
	}
}

$FileValidationScriptBlock = {
	if( [System.IO.Directory]::Exists($_) -or $_ -eq "" -or $null -eq $_ ){
		return $true
	} else {
		return $false
	}
}

[ValidateScript({. $DirectoryValidationScriptBlock})]$WorkspaceRootPath = Read-Host "Please enter the root path for your OSDCloud workspace (if nothing is entered, 'C:\' will be used)"
[ValidateScript({. $DirectoryValidationScriptBlock})]$WallpaperPath     = Read-Host "Please enter a path to your desired wallpaper (or leave blank to use the default)"
[String]$Brand                                                          = Read-Host "Please enter a brand name to use for the title (or leave blank to use the default)"
[ValidateScript({. $FileValidationScriptBlock})]$WifiProfile            = Read-Host "Please enter an XML WiFi profile, if desired (must be in plain-text)"
#EndRegion GetUserInputWithValidation

#Region BuildOSDCloud
if ( "OSD" -notin $(Get-InstalledModule).Name ){
	Install-Module OSD -Force
}
Import-Module OSD -Force

if (-not [String]::IsNullOrEmpty("$WorkspaceRootPath")) {
	$WorkspaceRootPath = "C:\"
}

New-Item -ItemType Directory -Path "$WorkspaceRootPath" -Name "OSDCloud" -Force
Set-Location -Path "$WorkspaceRootPath\OSDCloud" | Out-Null

New-OSDCloudTemplate -Name "WinRE" -SetAllIntl en-us -WinRE | Out-Null
New-OSDCloudWorkspace "OSDCloud_Dev"  | Out-Null
New-OSDCloudWorkspace "OSDCloud_Prod" | Out-Null

Set-OSDCloudWorkSpace -WorkspacePath "$WorkspaceRootPath\OSDCloud\OSDCloud_Prod" | Out-Null
Write-Host "OSDcloud workspace was set to OSDCloud_Prod"

$UserDefinedParameters = @{}

switch ($true) {
	(-not [String]::IsNullOrEmpty("$WallpaperPath")) { $UserDefinedParameters["Wallpaper"]   = $WallpaperPath }
	(-not [String]::IsNullOrEmpty("$Brand"))         { $UserDefinedParameters["Brand"]       = $Brand         }
	(-not [String]::IsNullOrEmpty("$WifiProfile"))   { $UserDefinedParameters["WifiProfile"] = $WifiProfile   }
}

Edit-OSDCloudWinPE -CloudDriver Dell,HP,IntelNet,LenovoDock,Nutanix,Surface,USB,WiFi -StartOSDCloudGUI -WirelessConnect @UserDefinedParameters
#EndRegion BuildOSDCloud

#Region Provisioning
New-Item -ItemType Directory -Path "$WorkspaceRootPath\OSDCloud" -Name "Automate" -Force
New-Item -ItemType Directory -Path "$WorkspaceRootPath\OSDCloud\Automate" -Name "Provisioning" -Force

[ValidateScript({. $FileValidationScriptBlock})]$PPKGFile = Read-Host "Please enter the path to your ImmyBot provisioning package"
Move-Item -Path $PPKGFile -Destination "$WorkspaceRootPath\OSDCloud\Automate\Provisioning" -Force
#EndRegion Provisioning

Write-Host -ForegroundColor Green "Hydration Is Complete For Your OSDCloud ImmyBot Environment!"
PAUSE