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
$AppDetection1 = "C:\Program Files\SOLIDWORKS Corp\SOLIDWORKS\SLDWORKS.exe"
$AppDetection2 = "C:\Program Files\SOLIDWORKS Corp\SOLIDWORKS\cef\swCefSubProc.exe"
$AppDetection3 = "C:\Program Files\SOLIDWORKS Corp\SOLIDWORKS\sldProcMon.exe"

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
    

if((Test-Path $AppDetection1) -or (Test-Path $AppDetection2) -or (Test-Path $AppDetection3)) {


$Destpath = "C:\Program Files\SOLIDWORKS Corp\SolidWorks_2.3_Associative_Interface"
if (!(test-path $Destpath)) {
    new-item -Path $Destpath -ItemType Directory -Force | Out-Null
}

$DllPath = "$scriptpath\Source\2.3\Sw2AbqPlugin.dll"

Write-Host ("Copying Sw2AbqPlugin")
Write-Log ("Copying Sw2AbqPlugin")
Copy-Item -path $DllPath $Destpath -Force
Write-Log ("Copied Sw2AbqPlugin")
Write-Host ("Copied Sw2AbqPlugin")

Write-Host ("Start ... Creating a System Environment Variable for SW2ABQ_PLUGIN_DLL_PATH")
Write-Log ("Start ... Creating a System Environment Variable for SW2ABQ_PLUGIN_DLL_PATH")
[System.Environment]::SetEnvironmentVariable('SW2ABQ_PLUGIN_DLL_PATH','C:\Program Files\SOLIDWORKS Corp\SOLIDWORKS\SolidWorks_2.3_Associative_Interface\SAI_2.3\Sw2AbqPlugin.dll',[System.EnvironmentVariableTarget]::Machine)
Write-Log ("End ... Creating a System Environment Variable for SW2ABQ_PLUGIN_DLL_PATH")
Write-Host ("End ... Creating a System Environment Variable for SW2ABQ_PLUGIN_DLL_PATH")

Write-Host ("Start ... Creating a System Environment Variable for ABQ_GUI")
Write-Log ("Start ... Creating a System Environment Variable for ABQ_GUI")
[System.Environment]::SetEnvironmentVariable('ABQ_GUI','T:\Solidworks\AbaqusGUI',[System.EnvironmentVariableTarget]::Machine)
Write-Log ("End ... Creating a System Environment Variable for ABQ_GUI")
Write-Host ("End ... Creating a System Environment Variable for ABQ_GUI")

$DestPath2 = "c:\Program Files\ABAQUS\Solidworks"
if ((Test-path $DestPath2)){

    Icacls $DestPath2 /grant:r '"Users":(OI)(CI)M' /T
}
else {

    new-item -Path $Destpath2 -ItemType Directory -Force | Out-Null
    Icacls $DestPath2 /grant:r '"Users":(OI)(CI)M' /T


}

New-Item –Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\" –Name "Simulia Abaqus SolidWorks-Associative Interface 2.3" -Force

New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Simulia Abaqus SolidWorks-Associative Interface 2.3" -Name "DisplayName" -Value ”Simulia Abaqus SolidWorks-Associative Interface 2.3”  -PropertyType "String" -Force


New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Simulia Abaqus SolidWorks-Associative Interface 2.3" -Name "Publisher" -Value ”Swagelok Company”  -PropertyType "String" -Force

New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Simulia Abaqus SolidWorks-Associative Interface 2.3" -Name "DisplayVersion" -Value ”2.3”  -PropertyType "String" -Force

New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Simulia Abaqus SolidWorks-Associative Interface 2.3" -Name "Comments" -Value ”Contact your local administrator”  -PropertyType "String" -Force

New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Simulia Abaqus SolidWorks-Associative Interface 2.3" -Name "InstallLocation" -Value "C:\Program Files\SOLIDWORKS Corp\SolidWorks_2.3_Associative_Interface"  -PropertyType "String" -Force


     
}




else {

        
     $wshell = New-Object -ComObject Wscript.Shell

     $wshell.Popup("SolidWorks 2020 is not found on your Workstation, Please proceed to install Solidworks 2020 and run this Application",0,"Done",0x1)
     Write-Host ("SolidWorks 2020 is not installed on the Target system.. No Action needed.. Terminating the Script Execution")
     Write-Log ("SolidWorks 2020 is not installed on the Target system.. No Action needed.. Terminating the Script Execution")
}


######### Start Post Configurations#################

Write-Log ("End of Script - $appScriptFilename Installtion completed with Post Configurations")

######### End of Application Installation#################
