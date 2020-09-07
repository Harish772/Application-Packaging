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

##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================
	## Variables: Application
	[string]$appVendor = 'CNC' #Should not Contain any extra white Spaces#
	[string]$appName = 'MasterCAM' #Should not Contain any extra white Spaces#
	[string]$appVersion = '2020'
	[string]$appArch = 'x64'
    [string]$appLang = 'EN'
    [string]$appARPVersion = '22.0.25841.0' #should get this from Add Remove Programs
    [string]$appRevision = 'B01' #B stands for Build
    [string]$DeploymentType = 'Install' #Acceptable values = Install, Uninstall, Repair
	[string]$appScriptDate = '06/25/2020'
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

#Creating a log file folder

if (!(test-path $logfile)) {
    new-item -Path $logfile -ItemType File -Force | Out-Null
}

if (!(test-path $logpath)) {
    new-item -Path $logpath -ItemType Directory -Force | Out-Null
}

$var1 = "/silent /action=install /language=en-us /CNC_SIM_TYPE=H"
#Detection if the older version already exists (File or Folder or Reg Key)"
$OldAppDetection1 = "C:\Program Files\Mcam2019\McamAdvConfig.exe"
$OldAppDetection2 = "C:\Program Files\Mcam2019\MastercamLauncher.exe"
$OldAppDetection3 = "C:\Program Files\Mcam2019\common\reports\ActiveReports_Designer.exe"


#Detection if the Current version already exists (File or Folder or Reg Key)"
$AppDetection1 = "C:\Program Files\Mastercam 2020\Mastercam\MastercamLauncher.exe"
$AppDetection2 = "C:\Program Files\Mastercam 2020\Mastercam\McamAdvConfig.exe"
$AppDetection3 = "C:\Program Files\Mastercam 2020\Mastercam\common\reports\ActiveReports_Designer.exe"

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

    $formattedlogcontent = '<![LOG[' + $typestring + $message + ']LOG]!><time="' + $formattedtime + '+300" date="' + $formatteddate + '" component="' + $script:scriptname + '" context="" type="' + $typecode + '" thread="1234">'

    Add-Content $script:logfile -Value $formattedlogcontent
}
    #endregion
    ##* Do not modify section above
    
#Older Version Un-instllation Logic Begins here
if((Test-Path $OldAppDetection1) -or (Test-Path $OldAppDetection2) -or (Test-Path $OldAppDetection3)) {
      #uninstall - older version logic goes here
     Write-Host "Older Version of the Application (MasterCAM 2019 detected). Executing the Uninstall Logic"
     Write-Log ("Older Version of the Application (MasterCAM 2019 detected). Executing the Uninstall Logic")

     #### Uninstall Script Execution ####
     # Uninstall Older version
     ##*===============================================
	 ##* PRE-UNINSTALLATION
	 ##*===============================================

     Write-Log "Uninstall operations for package $parentPackageName initiated at $datestring"
if ($processesToKill.Count -gt 0) {
    Write-Log "Terminating potentially interfering applications..."
    $allprocesses = Get-Process
    foreach ($proc in ($allprocesses | Where-Object {$processesToKill -contains $_.Name})) {
        Write-Log -message ("Stopping process " + $proc.name + " with PID " + $proc.id)
        $proc | Stop-Process -Force
    }
}

     ##*===============================================
	 ##* UNINSTALLATION
	 ##*===============================================
    $OldappScriptFilename = "MasterCAM2019"
    Write-Log "Older Version of the Application detected. Executing the Uninstall Logic"
    $procstartinfo = new-object System.Diagnostics.ProcessStartInfo
    $procstartinfo.FileName = "$scriptpath\Source\7.Uninstall 2019\Mastercam_Uninstaller.EXE"
    $procstartinfo.Arguments = "/s"
    $procstartinfo.UseShellExecute = $false
    $procstartinfo.RedirectStandardOutput = $true
try {$proc = [System.Diagnostics.Process]::Start($procstartinfo)}
catch {
    Write-Log "Error executing $scriptpath\$OldappScriptFilename, file likely missing"
    exit 1603
}
$proc.WaitForExit()

$exitcode = $proc.ExitCode

if (($proc.ExitCode -eq 0) -or ($proc.ExitCode -eq 3010) -or ($proc.ExitCode -eq 1641) -or ($proc.ExitCode -eq 1603)) {

    Write-Log ("$OldappScriptFilename main Un-install completed successfully with code: " + $proc.ExitCode)
}
else {

    Write-Log ("$OldappScriptFilename Un-install failed with code " + $proc.ExitCode) -type Error
    exit $exitcode
}

     ##*===============================================
	 ##* POST-UNINSTALLATION
	 ##*===============================================
    Write-log ("Older version uninstallation completed Succesfully now entering the Current version Installation logic")
    Write-host ("Older version uninstallation completed Succesfully now entering the Current version Installation logic")
    
    Write-Log ("Start - Deferring clean up of packages/files, if any exist after $OldappScriptFilename Uninstall")
    Write-Host ("Start - Deferring clean up of packages/files, if any exist after $OldappScriptFilename Uninstall")
    Start-sleep -s 180
    Write-Log ("End - Deferring clean up of packages/files, if any exist after $OldappScriptFilename Uninstall")
    Write-Host ("End - Deferring clean up of packages/files, if any exist after $OldappScriptFilename Uninstall")

}


#Current Version Instllation Logic Begins here

if((Test-Path $AppDetection1) -or (Test-Path $AppDetection2) -or (Test-Path $AppDetection3)) {
     
     Write-Host "The Application $appScriptFilename is already installed ... No Action needed.. Terminating the Script Execution"
     Write-Log ("The Application $appScriptFilename is already installed ... No Action needed.. Terminating the Script Execution")
}
else {

     ##*===============================================
	 ##* PRE-INSTALLATION
	 ##*===============================================


     
     ##*===============================================
	 ##* Main - INSTALLATION
	 ##*===============================================
     
     #### Main Script Execution ####
     #Install $appScriptFilename main package

     
     
     ##*===============================================
	 ##* INSTALLATION (1. MasterCAM 2020(Main))
	 ##*===============================================
     

Write-Log "Installing $appScriptFilename.exe (Main)"

Write-Host "Installing $appScriptFilename.exe (Main)"

    $proc2startinfo = new-object System.Diagnostics.ProcessStartInfo
    $proc2startinfo.FileName = "$scriptpath\Source\1.Mastercam\setup.exe"
    $proc2startinfo.Arguments = "-sp`"$var1`" /qn"
    $proc2startinfo.UseShellExecute = $false
    $proc2startinfo.RedirectStandardOutput = $true
try {$proc2 = [System.Diagnostics.Process]::Start($proc2startinfo)}
catch {
    Write-Log "Error executing $scriptpath\$appScriptFilename, file likely missing"
    exit 1603
}
$proc2.WaitForExit()

$exitcode2 = $proc2.ExitCode


if (($proc2.ExitCode -eq 0) -or ($proc2.ExitCode -eq 3010) -or ($proc2.ExitCode -eq 1641) -or ($proc2.ExitCode -eq 1603)) {

    Write-Log ("$appScriptFilename.exe main install completed successfully with code: " + $proc2.ExitCode)
}
else {

    Write-Log ("$appScriptFilename install failed with code " + $proc2.ExitCode) -type Error
    exit $exitcode2
}
    Write-Log ("Start - Deferring clean up of packages/files, if any exist after 1.MasterCAM 2020 (Main) Install")
    Write-Host ("Start - Deferring clean up of packages/files, if any exist after 1.MasterCAM 2020 (Main) Install")
    Start-sleep -s 180
    Write-Log ("End - Deferring clean up of packages/files, if any exist after 1.MasterCAM 2020 (Main) Install")
    Write-Host ("End - Deferring clean up of packages/files, if any exist after 1.MasterCAM 2020 (Main) Install")




     
     
     ##*===============================================
	 ##* INSTALLATION (2.MasterCAM Update 22.0.24719.0)
	 ##*===============================================
     
$AppInstall2 = "2.MasterCAM Update 22.0.24719.0"
Write-Log "Installing $AppInstall2"

Write-Host "Installing $AppInstall2"

    $proc3startinfo = new-object System.Diagnostics.ProcessStartInfo
    $proc3startinfo.FileName = "$scriptpath\Source\2.Update 22.0.24719.0\mastercam-Update1-PC8.exe"
    $proc3startinfo.Arguments = "/s /v/qn"
    $proc3startinfo.UseShellExecute = $false
    $proc3startinfo.RedirectStandardOutput = $true
try {$proc3 = [System.Diagnostics.Process]::Start($proc3startinfo)}
catch {
    Write-Log "Error executing $scriptpath\$AppInstall2, file likely missing"
    exit 1603
}
$proc3.WaitForExit()

$exitcode3 = $proc3.ExitCode

if (($proc3.ExitCode -eq 0) -or ($proc3.ExitCode -eq 3010) -or ($proc3.ExitCode -eq 1641) -or ($proc3.ExitCode -eq 1603)) {

    Write-Log ("$AppInstall2 install completed successfully with code: " + $proc3.ExitCode)
}
else {

    Write-Log ("$AppInstall2 install failed with code " + $proc3.ExitCode) -type Error
    exit $exitcode3
}
    Write-Log ("Start - Deferring clean up of packages/files, if any exist after $AppInstall2 Install")
    Write-Host ("Start - Deferring clean up of packages/files, if any exist after $AppInstall2 Install")
    Start-sleep -s 360
    Write-Log ("End - Deferring clean up of packages/files, if any exist after $AppInstall2 Install")
    Write-Host ("End - Deferring clean up of packages/files, if any exist after $AppInstall2 Install")

     
     
     ##*===============================================
	 ##* INSTALLATION (3.MasterCAM Update 1.1)
	 ##*===============================================
     
$AppInstall3 = "3.MasterCAM Update 1.1"
Write-Log "Installing $AppInstall3"

Write-Host "Installing $AppInstall3"

    $proc4startinfo = new-object System.Diagnostics.ProcessStartInfo
    $proc4startinfo.FileName = "$scriptpath\Source\3.Update 1.1\mastercam2020-update1_1-patch.exe"
    $proc4startinfo.Arguments = "/s /v/qn"
    $proc4startinfo.UseShellExecute = $false
    $proc4startinfo.RedirectStandardOutput = $true
try {$proc4 = [System.Diagnostics.Process]::Start($proc4startinfo)}
catch {
    Write-Log "Error executing $scriptpath\$AppInstall3, file likely missing"
    exit 1603
}
$proc4.WaitForExit()

$exitcode4 = $proc4.ExitCode

if (($proc4.ExitCode -eq 0) -or ($proc4.ExitCode -eq 3010) -or ($proc4.ExitCode -eq 1641) -or ($proc4.ExitCode -eq 1603)) {

    Write-Log ("$AppInstall3 main install completed successfully with code: " + $proc4.ExitCode)
}
else {

    Write-Log ("$AppInstall3 install failed with code " + $proc4.ExitCode) -type Error
    exit $exitcode4
}

    Write-Log ("Start - Deferring clean up of packages/files, if any exist after $AppInstall3 Install")
    Write-Host ("Start - Deferring clean up of packages/files, if any exist after $AppInstall3 Install")
    Start-sleep -s 240
    Write-Log ("End - Deferring clean up of packages/files, if any exist after $AppInstall3 Install")
    Write-Host ("End - Deferring clean up of packages/files, if any exist after $AppInstall3 Install")


     
     
     ##*===============================================
	 ##* INSTALLATION (4.MasterCAM Update 2)
	 ##*===============================================
     
$AppInstall4 = "4.MasterCAM Update 2"
Write-Log "Installing $AppInstall4"

Write-Host "Installing $AppInstall4"

    $proc5startinfo = new-object System.Diagnostics.ProcessStartInfo
    $proc5startinfo.FileName = "$scriptpath\Source\4.Update 2\mastercam2020-update2-patch.exe"
    $proc5startinfo.Arguments = "/s /v/qn"
    $proc5startinfo.UseShellExecute = $false
    $proc5startinfo.RedirectStandardOutput = $true
try {$proc5 = [System.Diagnostics.Process]::Start($proc5startinfo)}
catch {
    Write-Log "Error executing $scriptpath\$AppInstall4, file likely missing"
    exit 1603
}
$proc5.WaitForExit()

$exitcode5 = $proc5.ExitCode

if (($proc5.ExitCode -eq 0) -or ($proc5.ExitCode -eq 3010) -or ($proc5.ExitCode -eq 1641) -or ($proc5.ExitCode -eq 1603)) {

    Write-Log ("$AppInstall4 install completed successfully with code: " + $proc5.ExitCode)
}
else {

    Write-Log ("$AppInstall4 install failed with code " + $proc5.ExitCode) -type Error
    exit $exitcode5
}


    Write-Log ("Start - Deferring clean up of packages/files, if any exist after $AppInstall4 Install")
    Write-Host ("Start - Deferring clean up of packages/files, if any exist after $AppInstall4 Install")
    Start-sleep -s 240
    Write-Log ("End - Deferring clean up of packages/files, if any exist after $AppInstall4 Install")
    Write-Host ("End - Deferring clean up of packages/files, if any exist after $AppInstall4 Install")



     
     
     ##*===============================================
	 ##* INSTALLATION (5.HASP Sentinel Drivers )
	 ##*===============================================

#Detection if the Current version already exists (File or Folder or Reg Key)"
$HASPAppDetection1 = "C:\Program Files (x86)\Common Files\Aladdin Shared\HASP\haspds_msi.dll"
$HASPAppDetection2 = "C:\Program Files (x86)\Common Files\Aladdin Shared\HASP\haspds_windows.dll"

$HASPMSI = "$scriptpath\Source\6.HASP Sentinel Drivers\HASP_Setup.msi"

$AppInstall5 = "5.HASP Sentinel Drivers"

if((Test-Path $HASPAppDetection1) -or (Test-Path $HASPAppDetection2)) {

    Write-Log ("$AppInstall5 already detected on the System..Terminating the Script")
    Write-Host ("$AppInstall5 already detected on the System..Terminating the Script")
}

else {

    Write-Log ("$AppInstall6 Not detected on the System..Executing Installation logic to install $AppInstall6")
    Write-Host ("$AppInstall6 Not detected on the System..Executing Installation logic to install $AppInstall6")
    
    Write-Log "Installing $AppInstall5"
    Write-Host "Installing $AppInstall5"

    $proc6startinfo = new-object System.Diagnostics.ProcessStartInfo
    $proc6startinfo.FileName = "$scriptpath\Source\6.HASP Sentinel Drivers\HASPUserSetup.exe"
    $proc6startinfo.Arguments = "/s /v/qn"
    $proc6startinfo.UseShellExecute = $false
    $proc6startinfo.RedirectStandardOutput = $true
try {$proc6 = [System.Diagnostics.Process]::Start($proc6startinfo)}
catch {
    Write-Log "Error executing $scriptpath\$AppInstall5, file likely missing"
    exit 1603
}
$proc6.WaitForExit()

$exitcode6 = $proc6.ExitCode

if (($proc6.ExitCode -eq 0) -or ($proc6.ExitCode -eq 3010) -or ($proc6.ExitCode -eq 1641) -or ($proc6.ExitCode -eq 1603)) {

    Write-Log ("$AppInstall5 install completed successfully via EXE Approach with code: " + $proc6.ExitCode)
}
else {

    Write-Log ("$AppInstall5 install failed via EXE Approach with code " + $proc6.ExitCode) -type Error
    exit $exitcode6
}
}


    Write-Log ("Start - Deferring clean up of packages/files, if any exist after $AppInstall5 Install")
    Write-Host ("Start - Deferring clean up of packages/files, if any exist after $AppInstall5 Install")
    Start-sleep -s 240
    Write-Log ("End - Deferring clean up of packages/files, if any exist after $AppInstall5 Install")
    Write-Host ("End - Deferring clean up of packages/files, if any exist after $AppInstall5 Install")


if((Test-Path $HASPAppDetection1) -or (Test-Path $HASPAppDetection2)) {

    Write-Log ("$AppInstall5 already detected on the System..Terminating the Script")
    Write-Host ("$AppInstall5 already detected on the System..Terminating the Script")
}

else {

    Write-Log ("$AppInstall6 Not detected on the System..Executing Installation logic to install $AppInstall6")
    Write-Host ("$AppInstall6 Not detected on the System..Executing Installation logic to install $AppInstall6")
    
    Write-Log "Installing $AppInstall5"
    Write-Host "Installing $AppInstall5"

    $proc6startinfo = new-object System.Diagnostics.ProcessStartInfo
    $proc6startinfo.FileName = "C:\windows\system32\Msiexec.exe"
    $proc6startinfo.Arguments = "/i `"$HASPMSI`" /qb!"
    $proc6startinfo.UseShellExecute = $false
    $proc6startinfo.RedirectStandardOutput = $true
try {$proc6 = [System.Diagnostics.Process]::Start($proc6startinfo)}
catch {
    Write-Log "Error executing $scriptpath\$AppInstall5, file likely missing"
    exit 1603
}
$proc6.WaitForExit()

$exitcode6 = $proc6.ExitCode

if (($proc6.ExitCode -eq 0) -or ($proc6.ExitCode -eq 3010) -or ($proc6.ExitCode -eq 1641) -or ($proc6.ExitCode -eq 1603)) {

    Write-Log ("$AppInstall5 install completed successfully via MSI Approach with code: " + $proc6.ExitCode)
}
else {

    Write-Log ("$AppInstall5 install failed via MSI Approach with code " + $proc6.ExitCode) -type Error
    exit $exitcode6
}
}


     ##*===============================================
	 ##* POST-INSTALLATION
	 ##*===============================================
     
     ######### Start Post Configurations#################

    Write-Log ("End of Script - $appScriptFilename Installtion completed with Post Configurations")
    Write-Host ("End of Script - $appScriptFilename Installtion completed with Post Configurations")

    ######### End of Application Installation#################
    
    ##*===============================================
	##* END SCRIPT BODY
	##*===============================================
}
