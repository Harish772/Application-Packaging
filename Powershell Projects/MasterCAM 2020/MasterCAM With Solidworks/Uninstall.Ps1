<#
.DESCRIPTION
    The script is provided as a template to perform an install or uninstall of an application(s) 
.Example
    Powershell.exe -ExecutionPolicy Bypass -File <Filename.ps1> -Force
.Logs
    All Installtion and Uninstallation Logs will be Written to  C:\Temp\AppLogs

    #### Template Creation Date : 04/23/2020  ####
    ####Author: Harish Kakarla  ####

##>

#Retrive Current Directory
#$PSScriptRoot = Split-Path $MyInvocation.MyCommand.path -Parent
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptname =  ($MyInvocation.MyCommand.Name) -replace ".ps1",""
$parentPackageName = $scriptpath.Substring($scriptpath.LastIndexOf("\") + 1)

##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================
	## Variables: Application
	[string]$appVendor = 'CNC' #Should not Contain any extra white Spaces#
	[string]$appName = 'MasterCAMforSolidWorks' #Should not Contain any extra white Spaces#
	[string]$appVersion = '2020'
	[string]$appArch = 'x64'
    [string]$appLang = 'EN'
    [string]$appARPVersion = '22.0.25838.10' #should get this from Add Remove Programs
    [string]$appRevision = 'B01' #B stands for Build
    [string]$DeploymentType = 'Uninstall' #Acceptable values = Install, Uninstall, Repair
	[string]$appScriptDate = '07/02/2020'
    [string]$appScriptAuthor = 'Harish Kakarla'
    [string]$appScriptFilename = $appVendor +'_' + $appName + '_' + $appArch +'_' + $appVersion + '-' + $deploymentType
    [string]$appScriptFoldername = $appVendor +'_' + $appName + '_' + $appArch +'_' + $appVersion
    $datestring = [string](get-date -Format yyyyMMdd-HHmm)
    ##*===============================================
    	##* END VARIABLE DECLARATION
##*===============================================

#Variable Declaration - Log File name
$logfile = [string]$env:windir + "\Temp\APPLogs\$appScriptFoldername\$appScriptFilename.log"

#Variable Declaration - Log Folder
$logpath = [string]$env:windir + "\Temp\APPLogs\"
$exitcode = 0

#enter names of any processes (without .exe) to terminate, comma delimited
$processesToKill = @("CmWebAdmin", "Codemeter", "CodemeterCC", "CmWebAdmin", "GridComputeServer", "MCLogr", "hasplms")


#Detection if the Current version already exists (File or Folder or Reg Key)"
$AppDetection1 ="C:\Program Files\Mastercam 2020\Mastercam for SOLIDWORKS\McamAdvConfig.exe"
$AppDetection2 = "C:\Program Files\Mastercam 2020\Mastercam for SOLIDWORKS\Extensions\ToolManager.exe"
$AppDetection3 = "C:\Program Files\Mastercam 2020\Mastercam for SOLIDWORKS\common\Editors\CIMCOEdit8\CimcoDNC.exe"

#Creating a log file folder

if (!(test-path $logfile)) {
    new-item -Path $logfile -ItemType File -Force | Out-Null
}

if (!(test-path $logpath)) {
    new-item -Path $logpath -ItemType Directory -Force | Out-Null
}


#Enter package name and GUID information here in $appRemoveTable variable
#format should be: $appRemoveTable = @{"appname"="{productGUID}"}. 
$appRemoveTable = @{
    "CNC_MasterCam_2020_22.0.25841.0" = "{DEC00F01-E8BD-4D06-B531-ECD782BA6FF2}"
    "CNC_MasterCamforSolidWorks_2020_22.0.25838.10"="{12235532-EEF4-4300-8DDE-1F3983CF288B}"
    "WIBU_CodeMeter_6.70"="{B2CDE2C4-6E58-4F45-85C4-8B9ADBD19F2F}"
    "CNC_MasterCAm_LicensingInstaller"="{BEE1101B-8C98-44C8-BCFD-42AC5E76C6F3}"
    "HASP_Sentinel_RunTime"="{77545D5B-A492-47A6-9C4A-F474AAF1BA7D}"
    
    
}
	##* Do not modify section below
	#region DoNotModify
####Functions to Write the Log File####

function Write-Log {
    param (
    [Parameter(Mandatory=$true)]
    $message,

    [ValidateSet('Error','Warning')]
    $type = "Info"
    )

    $formattedlogcontent = ""
    $typecode = 1
    $typestring = "$type" + ": "

    if ($type -eq "Error") {$typecode = "3"}
    elseif ($type -eq "Warning") {$typecode = "2"}
    elseif ($type -eq "Info") {
        $typecode = "1"
        $typestring = ""
    }

    
    $formattedtime = [string](get-date -Format HH:mm:ss.fff)
    $formatteddate = [string](get-date -Format MM-dd-yyyy)

    $formattedlogcontent = '<![LOG[' + $typestring + $message + ']LOG]!><time="' + $formattedtime + '+300" date="' + $formatteddate + '" component="' + $parentPackageName + '" context="" type="' + $typecode + '" thread="1234">'

    Add-Content $script:logfile -Value $formattedlogcontent
    
}

function Get-InstalledApplicationList {
    $fullapplist = @()
    
    $regapplist = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    if (test-path "HKLM:\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall") {$regapplist = $regapplist + (Get-ChildItem "HKLM:\SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall")}

    foreach ($entry in $regapplist) {
        $fullapplist += Get-ItemProperty $entry.PSPath
    }

    return $fullapplist
}

####Execution####
$appsToRemove = @()
Write-Log "Uninstall operations for package $parentPackageName initiated at $datestring"
Write-Log "Creating a table of Applications and associated GUIDs to remove based on input parameters..."

#create a table of applications and GUIDs to remove
foreach ($appentry in $appRemoveTable.keys) {
    $properties = @{'AppName'=$appentry;'AppGUID'=$appRemoveTable[$appentry]}
    $appobject = New-Object –TypeName PSObject –Prop $properties
    $appstoremove += $appobject
}
    #endregion
    ##* Do not modify section above





if ((Test-Path $AppDetection1) -or (Test-Path $AppDetection2) -or (Test-Path $AppDetection3)) {

     Write-Host ("The Application $appScriptFilename is detected on the system. Executing the Uninstall Logic")
     Write-Log ("The Application $appScriptFilename is detected on the system. Executing the Uninstall Logic")


if ($processesToKill.Count -gt 0) {
    Write-Log "Terminating potentially interfering applications..."
    $allprocesses = Get-Process
    foreach ($proc in ($allprocesses | Where-Object {$processesToKill -contains $_.Name})) {
        Write-Log -message ("Stopping process " + $proc.name + " with PID " + $proc.id)
        $proc | Stop-Process -Force
    }
}

Start-sleep -s 60
     
     ##*===============================================
	 ##* UN-INSTALLATION
	 ##*===============================================
     
     #### Main Script Execution ####
     #Install $appScriptFilename main package
     
    
     
     ##*===============================================
	 ##* UN-INSTALLATION (MSI Based Installers)
	 ##*===============================================
    

#enumerate installed applications
Write-Log "Enumerating installed application list..."
$installedapplist = Get-InstalledApplicationList
$installedapplistkeys = @()
foreach ($app in $installedapplist) {$installedapplistkeys += $app.pschildname}

foreach ($application in $appstoremove) {
    Write-Log ("Looking for " + $application.appname  + " in installed app list based on GUID " + $application.appguid)
    #note: this dual lookup is included for PS2.0 backwards compatibility (in PS3.0 you just need the second check)
    if (($installedapplist.pschildname -contains $application.appguid) -or ($installedapplistkeys -contains $application.appguid)) {
        $removeappname = $application.appname
        $removeappguid = $application.appguid

        Write-Log "$removeappguid found in installed application list; beginning removal"
       # Write-Log "Logs will be written to $logpath\$appScriptFilename.log"

        #start the uninstall process and wait for exit
        $procstartinfo = new-object System.Diagnostics.ProcessStartInfo
        $procstartinfo.FileName = "c:\windows\system32\msiexec.exe"
        $procstartinfo.Arguments = "/x$removeappguid /passive MSIRESTARTMANAGERCONTROL=Disable /norestart /l*v $logpath\$appScriptFoldername\$removeappname-Uninstall.log"
        $procstartinfo.UseShellExecute = $false
        $procstartinfo.RedirectStandardOutput = $true
        $proc = [System.Diagnostics.Process]::Start($procstartinfo)
        $proc.WaitForExit()

        if (($proc.ExitCode -eq 0) -or ($proc.ExitCode -eq 3010) -or ($proc.ExitCode -eq 1641)) {Write-Log ($application.appname + "removal completed successfully with code: " + $proc.ExitCode)}
        else {Write-Log ($application.appname + "removal Upgrade failed with code " + $proc.ExitCode) -type Error}
    }
    else {Write-Log ($application.appguid  + " not found in installed application list; no removal needed")}
}


    Write-Log ("Start - Deferring clean up of packages/files, if any exist after MSI Based Apps Un-install")
    Write-Host ("Start - Deferring clean up of packages/files, if any exist after MSI Based Apps Un-install")
    Start-sleep -s 180
    Write-Log ("End - Deferring clean up of packages/files, if any exist after MSI Based Apps Un-install")
    Write-Host ("End - Deferring clean up of packages/files, if any exist after MSI Based Apps Un-install")

          
     
     ##*===============================================
	 ##* UN-INSTALLATION (2.MasterCAM HASPX 2020)
	 ##*===============================================
    
$AppUninstall2 = "2.MasterCAM HASPX 2020"
$AppUninstallString2 = "C:\Windows\AppPatch\CustomSDB\{32c229e8-ea25-41bd-95bd-00650b385a5f}.sdb"
Write-Log "Un-installing $AppUninstall2"

Write-Host "Un-installing $AppUninstall2"

    $proc2startinfo = new-object System.Diagnostics.ProcessStartInfo
    $proc2startinfo.FileName = "C:\Windows\system32\sdbinst.exe"
    $proc2startinfo.Arguments = "-u `"$AppUninstallString2`""
    $proc2startinfo.UseShellExecute = $false
    $proc2startinfo.RedirectStandardOutput = $true
try {$proc2 = [System.Diagnostics.Process]::Start($proc2startinfo)}
catch {
    Write-Log "Error executing $scriptpath\$AppUninstall2, file likely missing"
    exit 1603
}
$proc2.WaitForExit()

$exitcode2 = $proc2.ExitCode

if (($proc2.ExitCode -eq 0) -or ($proc2.ExitCode -eq 1) -or ($proc2.ExitCode -eq 3010) -or ($proc2.ExitCode -eq 1641) -or ($proc2.ExitCode -eq 1603)) {

    Write-Log ("$AppUninstall2 main install completed successfully with code: " + $proc2.ExitCode)
}
else {

    Write-Log ("$AppUninstall2 install failed with code " + $proc2.ExitCode) -type Error
    
}


    Write-Log ("Start - Deferring clean up of packages/files, if any exist after $AppUninstall2 Un-install")
    Write-Host ("Start - Deferring clean up of packages/files, if any exist after $AppUninstall2 Un-install")
    Start-sleep -s 180
    Write-Log ("End - Deferring clean up of packages/files, if any exist after $AppUninstall2 Un-install")
    Write-Host ("End - Deferring clean up of packages/files, if any exist after $AppUninstall2 Un-install")



          
     
     ##*===============================================
	 ##* UN-INSTALLATION (3.Mastercam_DotComLinking_2020)
	 ##*===============================================
    

$AppUninstall3 = "3.Mastercam_DotComLinking_2020"
$AppUninstallString3 = "C:\Windows\AppPatch\CustomSDB\{3654e100-799b-460a-9509-72ce87fe32d0}.sdb"
Write-Log "Un-installing $AppUninstall3"

Write-Host "Un-installing $AppUninstall3"


    $proc3startinfo = new-object System.Diagnostics.ProcessStartInfo
    $proc3startinfo.FileName = "C:\Windows\system32\sdbinst.exe"
    $proc3startinfo.Arguments = "-u `"$AppUninstallString3`""
    $proc3startinfo.UseShellExecute = $false
    $proc3startinfo.RedirectStandardOutput = $true
try {$proc3 = [System.Diagnostics.Process]::Start($proc3startinfo)}
catch {
    Write-Log "Error executing $scriptpath\$AppUninstall3, file likely missing"
    exit 1603
}
$proc3.WaitForExit()

$exitcode3 = $proc3.ExitCode

if (($proc3.ExitCode -eq 0) -or ($proc2.ExitCode -eq 1) -or ($proc3.ExitCode -eq 3010) -or ($proc3.ExitCode -eq 1641) -or ($proc3.ExitCode -eq 1603)) {

    Write-Log ("$AppUninstall3 main install completed successfully with code: " + $proc3.ExitCode)
}
else {

    Write-Log ("$AppUninstall3 install failed with code " + $proc3.ExitCode) -type Error
    
}


    Write-Log ("Start - Deferring clean up of packages/files, if any exist after $AppUninstall2 Un-install")
    Write-Host ("Start - Deferring clean up of packages/files, if any exist after $AppUninstall2 Un-install")
    Start-sleep -s 60
    Write-Log ("End - Deferring clean up of packages/files, if any exist after $AppUninstall2 Un-install")
    Write-Host ("End - Deferring clean up of packages/files, if any exist after $AppUninstall2 Un-install")



          
     
     ##*===============================================
	 ##* UN-INSTALLATION (4.NHaspX)
	 ##*===============================================
    

$AppUninstall4 = "4.MasterCAM NHHASPX 2020"
$AppUninstallString4 = "C:\Windows\AppPatch\CustomSDB\{e3fc8a16-2ea1-4745-8e6a-84ea7c900972}.sdb"
Write-Log "Un-installing $AppUninstall4"

Write-Host "Un-installing $AppUninstall4"


    $proc4startinfo = new-object System.Diagnostics.ProcessStartInfo
    $proc4startinfo.FileName = "C:\Windows\system32\sdbinst.exe"
    $proc4startinfo.Arguments = "-u `"$AppUninstallString4`""
    $proc4startinfo.UseShellExecute = $false
    $proc4startinfo.RedirectStandardOutput = $true
try {$proc4 = [System.Diagnostics.Process]::Start($proc4startinfo)}
catch {
    Write-Log "Error executing $scriptpath\$AppUninstall4, file likely missing"
    exit 1603
}
$proc4.WaitForExit()

$exitcode4 = $proc4.ExitCode

if (($proc4.ExitCode -eq 0) -or ($proc2.ExitCode -eq 1) -or ($proc4.ExitCode -eq 3010) -or ($proc4.ExitCode -eq 1641) -or ($proc4.ExitCode -eq 1603)) {

    Write-Log ("$AppUninstall4 install completed successfully with code: " + $proc4.ExitCode)
}
else {

    Write-Log ("$AppUninstall4 install failed with code " + $proc4.ExitCode) -type Error
    
}

    Write-Log ("Start - Deferring clean up of packages/files, if any exist after $AppUninstall4 Un-install")
    Write-Host ("Start - Deferring clean up of packages/files, if any exist after $AppUninstall4 Un-install")
    Start-sleep -s 180
    Write-Log ("End - Deferring clean up of packages/files, if any exist after $AppUninstall4 Un-install")
    Write-Host ("End - Deferring clean up of packages/files, if any exist after $AppUninstall4 Un-install")



     ##*===============================================
	 ##* POST-UNINSTALLATION
	 ##*===============================================

     ##*===============================================
	 ##* POST-UNINSTALLATION 
	 ##*===============================================
     


Write-Log "POST-UNINSTALLATION Phase : UNInstalling CNC_MasterCam_2020_22.0.25841.0"

Write-Host "POST-UNINSTALLATION Phase: UNInstalling CNC_MasterCam_2020_22.0.25841.0"    


    $MCappScriptFilename = "CNC_MasterCam_2020_22.0.25841.0"
    $varx = "$scriptPath\Source\8.Uninstall 2020\CNC_MasterCam_2020_22.0.25841.0-Uninstall.ps1"
    $proc5startinfo = new-object System.Diagnostics.ProcessStartInfo
    $proc5startinfo.FileName = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    $proc5startinfo.Arguments = "-ExecutionPolicy Bypass -File `"$Varx`" -Force"
    $proc5startinfo.UseShellExecute = $false
    $proc5startinfo.RedirectStandardOutput = $true
    try {$proc5 = [System.Diagnostics.Process]::Start($proc5startinfo)}
catch {
    Write-Log "Error executing $scriptpath\$MCappScriptFilename, file likely missing"
    exit 1603
}
$proc5.WaitForExit()

$exitcode5 = $proc5.ExitCode

if (($proc5.ExitCode -eq 0) -or ($proc2.ExitCode -eq 1) -or ($proc5.ExitCode -eq 3010) -or ($proc5.ExitCode -eq 1641) -or ($proc5.ExitCode -eq 1603)) {

    Write-Log ("$MCappScriptFilename Un-Install completed successfully with code: " + $proc5.ExitCode)
}
else {

    Write-Log ("$MCappScriptFilename Un-Install failed with code " + $proc5.ExitCode) -type Error
    
}


    Write-Log ("Start - Deferring clean up of packages/files, if any exist after $MCappScriptFilename Un-install")
    Write-Host ("Start - Deferring clean up of packages/files, if any exist after $MCappScriptFilename Un-install")
    Start-sleep -s 180
    Write-Log ("End - Deferring clean up of packages/files, if any exist after $MCappScriptFilename Un-install")
    Write-Host ("End - Deferring clean up of packages/files, if any exist after $MCappScriptFilename Un-install")


}

Else {

     Write-Host ("The Application $appScriptFilename is not installed on the system ... No Action needed.. Terminating the Script Execution")
     Write-Log ("The Application $appScriptFilename is not installed on the system ... No Action needed.. Terminating the Script Execution")
}


Write-Log "Uninstall operations for package $appScriptFilename completed"

######### End of Application Installation#################

