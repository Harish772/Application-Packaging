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
	[string]$appVendor = 'AFT' #Should not Contain any extra white Spaces#
	[string]$appName = 'Arrow-Fathom-Chempak' #Should not Contain any extra white Spaces#
	[string]$appVersion = '2020'
	[string]$appArch = 'x64'
    [string]$appLang = 'EN'
    [string]$appARPVersion = '2020' #should get this from Add Remove Programs
    [string]$appRevision = 'B01' #B stands for Build
    [string]$DeploymentType = 'Install' #Acceptable values = Install, Uninstall, Repair
	[string]$appScriptDate = '07/23/2020'
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
$processesToKill = @("Arrow", "Fathom")

#Creating a log file folder

if (!(test-path $logfile)) {
    new-item -Path $logfile -ItemType File -Force | Out-Null
}

if (!(test-path $logpath)) {
    new-item -Path $logpath -ItemType Directory -Force | Out-Null
}

$ArrowMSI = "$scriptpath\Source\1.Arrow\MSI\AFT Arrow 8.msi"
$FathomMSI = "$scriptpath\Source\2.Fathom\MSI\AFT Fathom 11.msi" 
$ChempakMSI = "$scriptpath\Source\3.Chempak\MSI\Chempak Data.msi" 

#Detection if the older version already exists (File or Folder or Reg Key)"
$OldAppDetection1 = "C:\Program Files (x86)\AFT Products\AFT Arrow 6\Arrow.exe"
$OldAppDetection2 = "C:\Program Files (x86)\AFT Products\AFT Fathom 9\Fathom.exe"
$OldAppDetection3 = "C:\Program Files (x86)\AFT Products\Chempak Data\CP8C.DTR"


#Detection if the Current version already exists (File or Folder or Reg Key)"
$AppDetection1 = "C:\AFT Products\AFT Arrow 8\Arrow.exe"
$AppDetection2 = "C:\AFT Products\AFT Fathom 11\Fathom.exe"
$AppDetection3 = "C:\AFT Products\Chempak Data\CP2.DTR"

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
     Write-Host "Older Version of the Application (AFT Products 2019 detected). Executing the Uninstall Logic"
     Write-Log ("Older Version of the Application (AFT Products 2019 detected). Executing the Uninstall Logic")

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
    $OldappScriptFilename = "AFTProducts2019"
    Write-Log "Older Version of the Application detected. Executing the Uninstall Logic"
    $procstartinfo = new-object System.Diagnostics.ProcessStartInfo
    $procstartinfo.FileName = "$scriptpath\Source\4.Uninstall-2019\AFT_Products_Uninstaller.EXE"
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
    Start-sleep -s 30
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
	 ##* INSTALLATION (1. AFT: Arrow 2020)
	 ##*===============================================
     

Write-Log "Installing $appScriptFilename.exe (Main)"

Write-Host "Installing $appScriptFilename.exe (Main)"

$AppInstall1 = "Arrow 2020"

Write-Log "Installing $AppInstall1.exe"

Write-Host "Installing $AppInstall1.exe"

    $proc1startinfo = new-object System.Diagnostics.ProcessStartInfo
    $proc1startinfo.FileName = "C:\windows\system32\Msiexec.exe"
    $proc1startinfo.Arguments = "/i `"$ArrowMSI`" SERIALNUM=01110-12217 /qb! /l*v $logpath\$appScriptFoldername\Arrow-2020-Install.log"
    $proc1startinfo.UseShellExecute = $false
    $proc1startinfo.RedirectStandardOutput = $true
try {$proc1 = [System.Diagnostics.Process]::Start($proc1startinfo)}
catch {
    Write-Log "Error executing $scriptpath\$AppInstall1, file likely missing"
    exit 1603
}
$proc1.WaitForExit()

$exitcode1 = $proc1.ExitCode


if (($proc1.ExitCode -eq 0) -or ($proc1.ExitCode -eq 3010) -or ($proc1.ExitCode -eq 1641) -or ($proc1.ExitCode -eq 1603)) {

    Write-Log ("$AppInstall1 install completed successfully with code: " + $proc1.ExitCode)
}
else {

    Write-Log ("$AppInstall1 install failed with code " + $proc1.ExitCode) -type Error
    exit $exitcode1
}
    Write-Log ("Start - Deferring clean up of packages/files, if any exist after $AppInstall1 Install")
    Write-Host ("Start - Deferring clean up of packages/files, if any exist after $AppInstall1 Install")
    Start-sleep -s 20
    Write-Log ("End - Deferring clean up of packages/files, if any exist after $AppInstall1 Install")
    Write-Host ("End - Deferring clean up of packages/files, if any exist after $AppInstall1 Install")




     
     
     ##*===============================================
	 ##* INSTALLATION (2.AFT: Fathom 2020)
	 ##*===============================================
     
$AppInstall2 = "Fathom 2020"
Write-Log "Installing $AppInstall2"

Write-Host "Installing $AppInstall2"

    $proc2startinfo = new-object System.Diagnostics.ProcessStartInfo
    $proc2startinfo.FileName = "C:\windows\system32\Msiexec.exe"
    $proc2startinfo.Arguments = "/i `"$FathomMSI`" SERIALNUM=0680-11052 /qb! /l*v $logpath\$appScriptFoldername\Fathom-2020-Install.log"
    $proc2startinfo.UseShellExecute = $false
    $proc2startinfo.RedirectStandardOutput = $true
try {$proc2 = [System.Diagnostics.Process]::Start($proc2startinfo)}
catch {
    Write-Log "Error executing $scriptpath\$AppInstall2, file likely missing"
    exit 1603
}
$proc2.WaitForExit()

$exitcode2 = $proc2.ExitCode

if (($proc2.ExitCode -eq 0) -or ($proc2.ExitCode -eq 3010) -or ($proc2.ExitCode -eq 1641) -or ($proc2.ExitCode -eq 1603)) {

    Write-Log ("$AppInstall2 install completed successfully with code: " + $proc2.ExitCode)
}
else {

    Write-Log ("$AppInstall2 install failed with code " + $proc2.ExitCode) -type Error
    exit $exitcode2
}
    Write-Log ("Start - Deferring clean up of packages/files, if any exist after $AppInstall2 Install")
    Write-Host ("Start - Deferring clean up of packages/files, if any exist after $AppInstall2 Install")
    Start-sleep -s 20
    Write-Log ("End - Deferring clean up of packages/files, if any exist after $AppInstall2 Install")
    Write-Host ("End - Deferring clean up of packages/files, if any exist after $AppInstall2 Install")

     
     
     ##*===============================================
	 ##* INSTALLATION (3.AFT: Chempak)
	 ##*===============================================

$AppInstall3 = "Chempak Data 2020"
Write-Log "Installing $AppInstall3"

Write-Host "Installing $AppInstall3"

    $proc3startinfo = new-object System.Diagnostics.ProcessStartInfo
    $proc3startinfo.FileName = "C:\windows\system32\Msiexec.exe"
    $proc3startinfo.Arguments = "/i `"$ChempakMSI`" /qb! /l*v $logpath\$appScriptFoldername\ChempakDataMSI-2020-Install.log"
    $proc3startinfo.UseShellExecute = $false
    $proc3startinfo.RedirectStandardOutput = $true
try {$proc3 = [System.Diagnostics.Process]::Start($proc3startinfo)}
catch {
    Write-Log "Error executing $scriptpath\$AppInstall3, file likely missing"
    exit 1603
}
$proc3.WaitForExit()

$exitcode3 = $proc3.ExitCode

if (($proc3.ExitCode -eq 0) -or ($proc3.ExitCode -eq 3010) -or ($proc3.ExitCode -eq 1641) -or ($proc3.ExitCode -eq 1603)) {

    Write-Log ("$AppInstall3 install completed successfully with code: " + $proc3.ExitCode)
}
else {

    Write-Log ("$AppInstall3 install failed with code " + $proc3.ExitCode) -type Error
    exit $exitcode3
}
    Write-Log ("Start - Deferring clean up of packages/files, if any exist after $AppInstall3 Install")
    Write-Host ("Start - Deferring clean up of packages/files, if any exist after $AppInstall3 Install")
    Start-sleep -s 20
    Write-Log ("End - Deferring clean up of packages/files, if any exist after $AppInstall3 Install")
    Write-Host ("End - Deferring clean up of packages/files, if any exist after $AppInstall3 Install")

 
     
    ##*===============================================
	 ##* POST-INSTALLATION
	 ##*===============================================
     
     ######### Start Post Configurations#################

      ######### Copy Nethasp.ini to Installation Directory#################

$ArrowInstDir = "C:\afT Products\AFT Arrow 8\" 
Write-Log ("Start..Copying Nethasp.ini to Arrow Installation Directory")
Copy-Item -path "$scriptpath\Source\nethasp.ini" $ArrowInstDir -Force
Write-Log ("End..Copying Nethasp.ini to Arrow Installation Directory")

$FathomInstDir = "C:\afT Products\AFT Fathom 11\" 
Write-Log ("Start..Copying Nethasp.ini to Fathom Installation Directory")
Copy-Item -path "$scriptpath\Source\nethasp.ini" $FathomInstDir -Force
Write-Log ("End..Copying Nethasp.ini to Fathom Installation Directory")

$ChempakInstDir = "C:\afT Products\Chempak Data\" 
Write-Log ("Start..Copying Nethasp.ini to Chempak Installation Directory")
Copy-Item -path "$scriptpath\Source\nethasp.ini" $ChempakInstDir -Force
Write-Log ("End..Copying Nethasp.ini to Chempak Installation Directory")




     $DestPath2 = "C:\AFT Products"
if ((Test-path $DestPath2)){

    Icacls $DestPath2 /grant:r '"Users":(OI)(CI)M' /T
}
else {

    new-item -Path $Destpath2 -ItemType Directory -Force | Out-Null
    Icacls $DestPath2 /grant:r '"Users":(OI)(CI)M' /T


}

    Write-Log ("Start - Deferring clean up of packages/files, if any exist after Post Install Configurations")
    Write-Host ("Start - Deferring clean up of packages/files, if any exist after Post Install Configurations")
    Start-sleep -s 20
    Write-Log ("End - Deferring clean up of packages/files, if any exist after Post Install Configurations")
    Write-Host ("End - Deferring clean up of packages/files, if any exist after Post Install Configurations")





   
    Write-Log ("End of Script - $appScriptFilename Installtion completed with Post Configurations")
    Write-Host ("End of Script - $appScriptFilename Installtion completed with Post Configurations")

    ######### End of Application Installation#################

}


    
    ##*===============================================
	##* END SCRIPT BODY
	##*===============================================
