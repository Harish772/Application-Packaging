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
	[string]$appVendor = 'Simulia' #Should not Contain any extra white Spaces#
	[string]$appName = 'Abaqus_SW-AssociativeInterface' #Should not Contain any extra white Spaces#
	[string]$appVersion = '2.3'
	[string]$appArch = 'x64'
    [string]$appLang = 'EN'
    [string]$appARPVersion = '2.3' #should get this from Add Remove Programs
    [string]$appRevision = 'B01' #B stands for Build
    [string]$DeploymentType = 'Uninstall' #Acceptable values = Install, Uninstall, Repair
	[string]$appScriptDate = '04/23/2020'
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
#Creating a log file folder

if (!(test-path $logfile)) {
    new-item -Path $logfile -ItemType File -Force | Out-Null
}

if (!(test-path $logpath)) {
    new-item -Path $logpath -ItemType Directory -Force | Out-Null
}

#Detection if the Application already exists (File or Folder or Reg Key)"
$AppDetection1 = "C:\Program Files\SOLIDWORKS Corp\SolidWorks_2.3_Associative_Interface"
$AppDetection2 = "C:\Program Files\SOLIDWORKS Corp\SolidWorks_2.3_Associative_Interface\Sw2AbqPlugin.dll"


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
    

if((Test-Path $AppDetection1) -or (Test-Path $AppDetection2) ) {


    remove-item "C:\Program Files\SOLIDWORKS Corp\SolidWorks_2.3_Associative_Interface" -Recurse -Force -ErrorAction silentlycontinue
        


    Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Simulia Abaqus SolidWorks-Associative Interface 2.3" -Recurse -Force
     
}




else {

     Write-Host ("$appScriptFilename is not installed on the Target system.. No Action needed.. Terminating the Script Execution")
     Write-Log ("$appScriptFilename is not installed on the Target system.. No Action needed.. Terminating the Script Execution")
}


######### Start Post Configurations#################

Write-Log ("End of Script - $appScriptFilename Uninstalltion completed with Post Configurations")

######### End of Application Installation#################
