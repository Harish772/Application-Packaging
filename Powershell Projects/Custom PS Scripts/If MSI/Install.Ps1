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
$Installer = "$scriptpath\Source\7-Zip_Swagelok.msi"

##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================
	## Variables: Application
	[string]$appVendor = 'IgorPavlov' #Should not Contain any extra white Spaces#
	[string]$appName = '7Zip' #Should not Contain any extra white Spaces#
	[string]$appVersion = '16.04'
	[string]$appArch = 'x64'
    [string]$appLang = 'EN'
    [string]$appARPVersion = '18.06' #should get this from Add Remove Programs
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


#Enter package name and GUID information here in $appRemoveTable variable
#format should be: $appRemoveTable = @{"appname"="{productGUID}"}. 
$appRemoveTable = @{
    "IgorPavlov_7Zip_18.06"="{ED7C1013-39EF-4650-BFF6-2FA5D44E7191}"
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



Write-Log "Install operations for package: $parentPackageName initiated at $datestring"


Write-Log "Creating a table of Applications and associated GUIDs to evaluate based on input parameters..."

#create a table of applications and GUIDs to remove
foreach ($appentry in $appRemoveTable.keys) {
    $properties = @{'AppName'=$appentry;'AppGUID'=$appRemoveTable[$appentry]}
    $appobject = New-Object –TypeName PSObject –Prop $properties
    $appstoremove += $appobject
}
    #endregion
    ##* Do not modify section above
#enumerate installed applications
Write-Log "Enumerating installed application list..."
$installedapplist = Get-InstalledApplicationList
$installedapplistkeys = @()
foreach ($app in $installedapplist) {$installedapplistkeys += $app.pschildname}

foreach ($application in $appstoremove) {
    Write-Log ("Looking for " + $application.appname  + " in installed app list based on GUID " + $application.appguid)
    #note: this dual lookup is included for PS2.0 backwards compatibility (in PS3.0 you just need the second check)
    if (($installedapplist.pschildname -contains $application.appguid) -or ($installedapplistkeys -contains $application.appguid)) {
    Write-Log ($application.appguid  + " found in installed application list; no re-Installation needed")
        
    }
    else {
    $removeappname = $application.appname
        $removeappguid = $application.appguid

        Write-Log "$removeappguid found to be not installed on this machine; Installing "
        #Write-Log "Logs will be written to $logpath\$removeappname-Install.log"

        #start the uninstall process and wait for exit
        $procstartinfo = new-object System.Diagnostics.ProcessStartInfo
        $procstartinfo.FileName = "c:\windows\system32\msiexec.exe"
        $procstartinfo.Arguments = "/i `"$Installer`" /qb! /l*v $logfile"
        $procstartinfo.UseShellExecute = $false
        $procstartinfo.RedirectStandardOutput = $true
        $proc = [System.Diagnostics.Process]::Start($procstartinfo)
        $proc.WaitForExit()

        if (($proc.ExitCode -eq 0) -or ($proc.ExitCode -eq 3010) -or ($proc.ExitCode -eq 1641)) {Write-Log ($application.appname + "Installation Completed successfully with code: " + $proc.ExitCode)}
        else {Write-Log ($application.appname + "Installation failed with code " + $proc.ExitCode) -type Error}}
}

Write-Log "Install operations for package: $appScriptFilename completed"

######### End of Application Installation#################
