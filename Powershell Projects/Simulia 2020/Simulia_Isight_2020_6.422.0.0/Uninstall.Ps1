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
$parentPackageName = $scriptpath.Substring($scriptpath.LastIndexOf("\") + 1)

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
    [string]$DeploymentType = 'Uninstall' #Acceptable values = Install, Uninstall, Repair
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

    $formattedlogcontent = '<![LOG[' + $typestring + $message + ']LOG]!><time="' + $formattedtime + '+300" date="' + $formatteddate + '" component="' + $parentPackageName + '" context="" type="' + $typecode + '" thread="1234">'

    Add-Content $script:logfile -Value $formattedlogcontent
    
}


    #endregion
    ##* Do not modify section above

if((Test-Path $AppDetection1) -or (Test-Path $AppDetection2)) {
     
     Write-Host "The Application $appScriptFilename is Currently installed ... Performing Uninstallation"
     Write-Log ("The Application $appScriptFilename is Currently installed ... Performing Uninstallation")


if ($processesToKill.Count -gt 0) {
    Write-Log "Terminating potentially interfering applications..."
    $allprocesses = Get-Process
    foreach ($proc in ($allprocesses | Where-Object {$processesToKill -contains $_.Name})) {
        Write-Log -message ("Stopping process " + $proc.name + " with PID " + $proc.id)
        $proc | Stop-Process -Force
    }
}

Start-sleep -s 30
     
     ##*===============================================
	 ##* UN-INSTALLATION
	 ##*===============================================
     
     #### Main Script Execution ####
     #Un-Install $appScriptFilename main package

Write-Log "Installing $appScriptFilename.exe (Main)"

Write-Host "Installing $appScriptFilename.exe (Main)"


$Uninstall_exec = start-process "cmd.exe" "/c C:\SIMULIA\Isight\2020\Uninstall.bat -quiet" -Wait -Passthru

try {$Uninstall_exec}

catch {
    Write-Log "Error executing $scriptpath\$appScriptFilename, file likely missing"
    exit 1603
}
$exitcode2 = $Uninstall_exec.ExitCode


if (($exitcode2 -eq 0) -or ($exitcode2 -eq 3010) -or ($exitcode2 -eq 1641) -or ($exitcode2 -eq 145)) {

    Write-Log ("$appScriptFilename.exe main Un-install completed successfully with code: " + $exitcode2)
}
else {

    Write-Log ("$appScriptFilename.exe Un-install failed with code " + $exitcode2) -type Error
    exit $exitcode2
}

Start-sleep -s 30
# Uninstall Dassault Systemes Pre-req VC10.1

$var2 = "{7C534131-6431-4ECB-9069-525CB5F75CC8}"

$install_exec4 = Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $var2 /quiet /norestart " -Wait -Passthru

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

}

else {
    Write-log ("The Application $appScriptFilename is not installed ... No Action needed.. Terminating the Script Execution")
    Write-Host ("The Application $appScriptFilename is not installed ... No Action needed.. Terminating the Script Execution")

}

Write-Log "Uninstall operations for package $appScriptFilename completed"

######### End of Application Un-Installation ##########
