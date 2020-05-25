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
	[string]$appVendor = 'Microsoft' #Should not Contain any extra white Spaces#
	[string]$appName = 'VisioViewer' #Should not Contain any extra white Spaces#
	[string]$appVersion = '2016'
	[string]$appArch = 'x64'
    [string]$appLang = 'EN'
    [string]$appARPVersion = '16.0.4339.1001' #should get this from Add Remove Programs
    [string]$appRevision = 'B01' #B stands for Build
    [string]$DeploymentType = 'Install' #Acceptable values = Install, Uninstall, Repair
	[string]$appScriptDate = '04/23/2020'
    [string]$appScriptAuthor = 'Harish Kakarla'
    [string]$appScriptFilename = $appVendor +'_' + $appName + '_' + $appArch +'_' + $appVersion + '-' + $deploymentType
    [string]$appScriptFoldername = $appVendor +'_' + $appName + '_' + $appArch +'_' + $appVersion
    $datestring = [string](get-date -Format yyyyMMdd-HHmm)
    ##*===============================================
    	##* END VARIABLE DECLARATION
##*===============================================

#Variable Declaration - Log File name
$logfile = [string]$env:windir + "\Temp\SCCMAPPLogs\$appScriptFoldername\$appScriptFilename.log"

#Variable Declaration - Log Folder
$logpath = [string]$env:windir + "\Temp\SCCMAPPLogs\"
$exitcode = 0
#Creating a log file folder

if (!(test-path $logfile)) {
    new-item -Path $logfile -ItemType File -Force | Out-Null
}

if (!(test-path $logpath)) {
    new-item -Path $logpath -ItemType Directory -Force | Out-Null
}

#Detection if the Application already exists (File or Folder or Reg Key)"
$AppDetection1 = "C:\Program Files (x86)\Microsoft Office\Office16\VVIEWDWG.DLL"
$AppDetection2 = "C:\Windows\"
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
    #endregion
    ##* Do not modify section above
    

if((Test-Path $AppDetection1)) {
      #uninstall - older version logic goes here
     Write-Host "The Application $appScriptFilename is already installed ... No Action needed.. Terminating the Script Execution"
     Write-Log ("The Application $appScriptFilename is already installed ... No Action needed.. Terminating the Script Execution")
}
else {

#### Main Script Execution ####
#Install $appScriptFilename main package
Write-Log "Installing $appScriptFilename.exe (Main)"
$procstartinfo = new-object System.Diagnostics.ProcessStartInfo
$procstartinfo.FileName = "$scriptpath\Source\visioviewer_4339-1001_x64_en-us.exe"
$procstartinfo.Arguments = "/quiet /norestart"
$procstartinfo.UseShellExecute = $false
$procstartinfo.RedirectStandardOutput = $true
try {$proc = [System.Diagnostics.Process]::Start($procstartinfo)}
catch {
    Write-Log "Error executing $scriptpath\$appScriptFilename, file likely missing"
    exit 1603
}
$proc.WaitForExit()

$exitcode = $proc.ExitCode

if (($proc.ExitCode -eq 0) -or ($proc.ExitCode -eq 3010) -or ($proc.ExitCode -eq 1641)) {

    Write-Log ("$appScriptFilename.exe main install completed successfully with code: " + $proc.ExitCode)
}
else {

    Write-Log ("$appScriptFilename install failed with code " + $proc.ExitCode) -type Error
    exit $exitcode
}

######### Start Post Configurations#################

Write-Log ("End of Script - $appScriptFilename Installtion completed with Post Configurations")

######### End of Application Installation#################
}
