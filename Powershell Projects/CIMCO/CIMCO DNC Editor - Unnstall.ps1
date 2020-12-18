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
	[string]$appVendor = 'CIMCO' #Should not Contain any extra white Spaces#
	[string]$appName = 'DNC_Editor' #Should not Contain any extra white Spaces#
	[string]$appVersion = '8.09.07'
	[string]$appArch = 'x64'
    [string]$appLang = 'EN'
    [string]$appARPVersion = '8.09.07' #should get this from Add Remove Programs
    [string]$appRevision = 'B01' #B stands for Build
    [string]$DeploymentType = 'Uninstall' #Acceptable values = Install, Uninstall, Repair
	[string]$appScriptDate = '12/05/2020'
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
$processesToKill = @("CIMCOEdit")

#Detection if the Current version already exists (File or Folder or Reg Key)"
$AppDetection1 = "C:\Program Files (x86)\CIMCO\CIMCOEdit8\CIMCOEdit.exe"
$AppDetection2 = "C:\Program Files (x86)\CIMCO\CIMCOEdit8\CimcoDNC.exe"
$AppDetection3 = "C:\Program Files (x86)\CIMCO\CIMCOEdit8\Sys\KeyManager.exe"

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
    
    "CIMCO_DNC_Editor_8.09.07" = "{66AFD3DB-B0D5-4EA4-BEE8-7AED2D14A966}"
    
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

Start-sleep -s 30
     
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
    Start-sleep -s 20
    Write-Log ("End - Deferring clean up of packages/files, if any exist after MSI Based Apps Un-install")
    Write-Host ("End - Deferring clean up of packages/files, if any exist after MSI Based Apps Un-install")

          
   #Delete Orphaned files If Exists
$sh1 = "C:\Program Files (x86)\CIMCO\CIMCOEdit8\cfg\Cimco.ini"

if((Test-Path $sh1)) {

    Remove-Item $sh1 -Recurse -Force -ErrorAction silentlycontinue

}

#Delete Orphaned files If Exists
$sh2 = "C:\Program Files (x86)\CIMCO\CIMCOEdit8"

if((Test-Path $sh2)) {

    Remove-Item $sh2 -Recurse -Force -ErrorAction silentlycontinue

}


}

Else {

     Write-Host "The Application $appScriptFilename is not installed on the system ... No Action needed.. Terminating the Script Execution"
     Write-Log ("The Application $appScriptFilename is not installed on the system ... No Action needed.. Terminating the Script Execution")
}


Write-Log "Uninstall operations for package $appScriptFilename completed"

######### End of Application Installation#################

