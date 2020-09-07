<#
.DESCRIPTION
    The script is provided as a template to perform an install or uninstall of an application(s) 
.Example
    Powershell.exe -ExecutionPolicy Bypass -File <Filename.ps1> -Force
.Logs
    All Installtion and Uninstallation Logs will be Written to  C:\Temp\SCCMAppLogs

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
	[string]$appVendor = 'Simulia' #Should not Contain any extra white Spaces#
	[string]$appName = 'Isight' #Should not Contain any extra white Spaces#
	[string]$appVersion = '2020'
	[string]$appArch = 'x64'
    [string]$appLang = 'EN'
    [string]$appARPVersion = '6.422.0.0' #should get this from Add Remove Programs
    [string]$appRevision = 'B01' #B stands for Build
    [string]$DeploymentType = 'Install' #Acceptable values = Install, Uninstall, Repair
	[string]$appScriptDate = '06/09/2020'
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
$processesToKill = @("dashboard", "gateway", "editcpr", "library", "rt_gateway", "sdkGenerator", "station")

#Creating a log file folder

if (!(test-path $logfile)) {
    new-item -Path $logfile -ItemType File -Force | Out-Null
}

if (!(test-path $logpath)) {
    new-item -Path $logpath -ItemType Directory -Force | Out-Null
}

$var1 = "$scriptpath\Source\1\Install.bat"
#Detection if the older version already exists (File or Folder or Reg Key)"
$OldAppDetection1 = "C:\SIMULIA\Isight\2018\win_b64\code\bin\dashboard.exe"
$OldAppDetection2 = "C:\SIMULIA\Isight\2018\win_b64\code\bin\gateway.exe"
$OldAppDetection3 = "C:\windows\system32\drivers\etc\"


#Detection if the Current version already exists (File or Folder or Reg Key)"
$AppDetection1 = "C:\SIMULIA\Isight\2020\win_b64\code\bin\dashboard.exe"
$AppDetection2 = "C:\SIMULIA\Isight\2020\win_b64\code\bin\gateway.exe"
$AppDetection3 = "C:\windows\system32\drivers\etc\"


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
#Write-Log "Uninstall operations for package $parentPackageName initiated at $datestring"
$appsToRemove = @()

Write-Log "Creating a table of Applications and associated GUIDs to remove based on input parameters..."

#create a table of applications and GUIDs to remove
foreach ($appentry in $appRemoveTable.keys) {
    $properties = @{'AppName'=$appentry;'AppGUID'=$appRemoveTable[$appentry]}
    $appobject = New-Object –TypeName PSObject –Prop $properties
    $appstoremove += $appobject
}

    #endregion
    ##* Do not modify section above
    

if((Test-Path $OldAppDetection1) -or (Test-Path $OldAppDetection2)) {
      #uninstall - older version logic goes here
     Write-Host "Older Version of the Application detected. Executing the Uninstall Logic"
     Write-Log ("Older Version of the Application detected. Executing the Uninstall Logic")

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

Write-Log "Older Version of the Application detected. Executing the Uninstall Logic"
$procstartinfo = new-object System.Diagnostics.ProcessStartInfo
$procstartinfo.FileName = "$scriptpath\Source\2018-Uninstall\Isight_Uninstaller.EXE"
$procstartinfo.Arguments = "/s"
$procstartinfo.UseShellExecute = $false
$procstartinfo.RedirectStandardOutput = $true
try {$proc = [System.Diagnostics.Process]::Start($procstartinfo)}
catch {
    Write-Log "Error executing $scriptpath\$appScriptFilename, file likely missing"
    exit 1603
}
$proc.WaitForExit()

$exitcode = $proc.ExitCode

if (($proc.ExitCode -eq 0) -or ($proc.ExitCode -eq 3010) -or ($proc.ExitCode -eq 1641) -or ($proc.ExitCode -eq 1603)) {

    Write-Log ("$appScriptFilename.exe main install completed successfully with code: " + $proc.ExitCode)
}
else {

    Write-Log ("$appScriptFilename install failed with code " + $proc.ExitCode) -type Error
    exit $exitcode
}

Start-sleep -s 60

# Uninstall Dassault Systemes Pre-req VC10.1

$var2 = "{7C534131-6431-4ECB-9069-525CB5F75CC8}"
$install_exec4 = Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $var2 /quiet MSIRESTARTMANAGERCONTROL=Disable /norestart " -Wait -Passthru

try {$install_Exec4}

catch {
    Write-Log "Error executing Uninstall for Dassault Systemes Pre-req VC10.1, file likely missing"
    exit 1603
}
$exitcode4 = $install_exec4.ExitCode


if (($exitcode4 -eq 0) -or ($exitcode4 -eq 3010) -or ($exitcode4 -eq 1641)) {

    Write-Log ("Uninstall for Dassault Systemes Pre-req VC10.1 completed successfully with code: " + $exitcode4)
}
else {

    Write-Log ("Uninstall for Dassault Systemes Pre-req VC10.1 failed with code " + $exitcode4) -type Error
    exit $exitcode4
}

     ##*===============================================
	 ##* POST-UNINSTALLATION
	 ##*===============================================
    Write-log ("Older version uninstallation completed Succesfully now entering the Current version Installation logic")
    Write-host ("Older version uninstallation completed Succesfully now entering the Current version Installation logic")
    
    Write-Log ("Start - Deferring clean up of packages/files, if any exist after Old Version Uninstall")
    Write-Host ("Start - Deferring clean up of packages/files, if any exist after Old Version Uninstall")
    Start-sleep -s 30
    Write-Log ("End - Deferring clean up of packages/files, if any exist after Old Version Uninstall")
    Write-Host ("End - Deferring clean up of packages/files, if any exist after Old Version Uninstall")

}




if((Test-Path $AppDetection1) -or (Test-Path $AppDetection2)) {
     
     Write-Host "The Application $appScriptFilename is already installed ... No Action needed.. Terminating the Script Execution"
     Write-Log ("The Application $appScriptFilename is already installed ... No Action needed.. Terminating the Script Execution")
}
else {

     ##*===============================================
	 ##* PRE-INSTALLATION
	 ##*===============================================


     
     ##*===============================================
	 ##* INSTALLATION
	 ##*===============================================
     
     #### Main Script Execution ####
     #Install $appScriptFilename main package

Write-Log "Installing $appScriptFilename.exe (Main)"

Write-Host "Installing $appScriptFilename.exe (Main)"


$install_exec = start-process "cmd.exe" "/c `"$var1`"" -Wait -Passthru

try {$install_Exec}

catch {
    Write-Log "Error executing $scriptpath\$appScriptFilename, file likely missing"
    exit 1603
}
$exitcode2 = $install_exec.ExitCode


if (($exitcode2 -eq 0) -or ($exitcode2 -eq 3010) -or ($exitcode2 -eq 1641)) {

    Write-Log ("$appScriptFilename.exe main install completed successfully with code: " + $exitcode2)
}
else {

    Write-Log ("$appScriptFilename.exe install failed with code " + $exitcode2) -type Error
    exit $exitcode2
}


     ##*===============================================
	 ##* POST-INSTALLATION
	 ##*===============================================
     
     ######### Start Post Configurations#################
    Write-Log ("Start - Deferring clean up of packages/files, if any exist after $appScriptFilename Install")
    Write-Host ("Start - Deferring clean up of packages/files, if any exist after $appScriptFilename Install")
    Start-sleep -s 30
    Write-Log ("End - Deferring clean up of packages/files, if any exist after $appScriptFilename Install")
    Write-Host ("End - Deferring clean up of packages/files, if any exist after $appScriptFilename Install")


}

Write-Log ("End of Script - $appScriptFilename Installtion completed with Post Configurations")
Write-Host ("End of Script - $appScriptFilename Installtion completed with Post Configurations")

    ######### End of Application Installation#################
    
    ##*===============================================
	##* END SCRIPT BODY
	##*===============================================
