<#
.DESCRIPTION
    The script is provided as a template to perform an install or uninstall of an application(s) 
.Example
    Powershell.exe -ExecutionPolicy Bypass -File <Filename.ps1> -Force
.Synopsis
    Master Uninstaller for 2018 Dassault Systemes Abaqus CAE, Fe-safe, Tosca Structure, Isight
.Logs
    All Installtion and Uninstallation Logs will be Written to  C:\Temp\AppLogs
.Remaining Items
    2. Add find by ARP Name to Detection Logic
    4. Double check GUIDs in $appRemoveTable

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
	[string]$appName = 'Products-Master_Uninstaller' #Should not Contain any extra white Spaces#
	[string]$appVersion = '2018'
	[string]$appArch = 'x64'
    [string]$appLang = 'EN'
    [string]$appARPVersion = '6.420.0.0' #should get this from Add Remove Programs
    [string]$appRevision = 'B01' #B stands for Build
    [string]$DeploymentType = 'Uninstall' #Acceptable values = Install, Uninstall, Repair
	[string]$appScriptDate = '06/15/2020'
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

#Enter package name and GUID information here in $appRemoveTable variable
#format should be: $appRemoveTable = @{"appname"="{productGUID}"}. 
$appRemoveTable = @{
    
    "Microsoft_MPI_2016-Uninstall"="{95160000-0052-0409-1000-018976818989098}"

}

#enter names of any processes (without .exe) to terminate, comma delimited
$processesToKill = @("abqlauncher", "fe-safe", "tosca_view", "TFluid", "tosca_gui", "dashboard", "gateway", "editcpr", "library", "rt_gateway", "sdkGenerator", "station" )

#Creating a log file folder

if (!(test-path $logfile)) {
    new-item -Path $logfile -ItemType File -Force | Out-Null
}

if (!(test-path $logpath)) {
    new-item -Path $logpath -ItemType Directory -Force | Out-Null
}


#Detection if the 2018 Abaqus CAE already exists (File or Folder or Reg Key)"
$CAEOldAppDetection1 = "C:\SIMULIA\CAE\2018\win_b64\code\bin\ABQLauncher.exe"
$CAEOldAppDetection2 = "C:\SIMULIA\CAE\2018\win_b64\code\bin\CATSTART.exe"



#Detection if the 2018 Fe-Safe already exists (File or Folder or Reg Key)"
$FeSafeOldAppDetection1 = "C:\SIMULIA\fe-safe\2018\win_b64\code\bin\fe-safe.exe"
$FesafeOldAppDetection2 = "C:\SIMULIA\fe-safe\2018\win_b64\code\bin\CATSTART.exe"


#Detection if the 2018 Tosca already exists (File or Folder or Reg Key)"
$ToscaOldAppDetection1 = "C:\SIMULIA\Tosca\2018\win_b64\SMATfoResources\gui\TFluid.exe"
$ToscaOldAppDetection2 = "C:\SIMULIA\Tosca\2018\win_b64\code\bin\SMAExternal\ToscaView\tosca_view.exe"


#Detection if the 2018 Isight already exists (File or Folder or Reg Key)"
$IsightOldAppDetection1 = "C:\SIMULIA\Isight\2018\win_b64\code\bin\dashboard.exe"
$IsightOldAppDetection2 = "C:\SIMULIA\Isight\2018\win_b64\code\bin\gateway.exe"


#Validate the Path for Below
#Detection if the 2018 Abaqus Designer already exists (File or Folder or Reg Key)"
$DesOldAppDetection1 = "C:\SIMULIA\Commands\abaqus_gui.bat"
$DesOldAppDetection2 = "C:\SIMULIA\Commands\abaqus_gui.bat"

#Validate the Path for Below
#Detection if the 2018 Abaqus HPC2012R2_Update3_Full already exists (File or Folder or Reg Key)"
$HPCOldAppDetection1 = "C:\Program Files\Microsoft HPC Pack 2012"
$HPCOldAppDetection2 = "C:\Program Files\Microsoft HPC Pack 2012"


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
	 ##* UNINSTALLATION (1.Simulia Abaqus 2018)
	 ##*===============================================
    
# Uninstall Operations for Simulia Abaqus 2018 {PROC1}
if((Test-Path $CAEOldAppDetection1) -or (Test-Path $CAEOldAppDetection2)) {
      #uninstall - older version logic goes here
      $AppUninstall1 = "Simulia Abaqus 2018"
     Write-Host ("Older Version of the Application $AppUninstall1 detected. Executing the Uninstall Logic")
     Write-Log ("Older Version of the Application $AppUninstall1 detected. Executing the Uninstall Logic")

  
    $proc1startinfo = new-object System.Diagnostics.ProcessStartInfo
    $proc1startinfo.FileName = "$scriptpath\Source\2018\1.Simulia Abaqus CAE Products\Client\Abaqus_Uninstaller.EXE"
    $proc1startinfo.Arguments = "/s"
    $proc1startinfo.UseShellExecute = $false
    $proc1startinfo.RedirectStandardOutput = $true

try {$proc1 = [System.Diagnostics.Process]::Start($proc1startinfo)}

catch {
    Write-Log "Error executing $scriptpath\$AppUninstall1, file likely missing"
    exit 1603
}

$proc1.WaitForExit()

$exitcode1 = $proc1.ExitCode

if (($exitcode1 -eq 0) -or ($exitcode1 -eq 3010) -or ($exitcode1 -eq 1641) -or ($exitcode1 -eq 1603)) {

    Write-Log ("$AppUninstall1.exe main Uninstall completed successfully with code: " + $exitcode1)
}
else {

    Write-Log ("$AppUninstall1 Uninstall failed with code " + $exitcode1) -type Error
    
}

     ##*===============================================
	 ##* POST-UNINSTALLATION
	 ##*===============================================


    Write-log ("Older version uninstallation for $AppUninstall1 completed Succesfully now entering the Another Application Unistallation logic")
    Write-host ("Older version uninstallation for $AppUninstall1 completed Succesfully now entering the Another Application Unistallation logic")
    
    Write-Log ("Start - Deferring clean up of packages/files, if any exist after $AppUninstall1 Un-install")
    Write-Host ("Start - Deferring clean up of packages/files, if any exist after $AppUninstall1 Un-install")
    Start-sleep -s 180
    Write-Log ("End - Deferring clean up of packages/files, if any exist after $AppUninstall1 Un-install")
    Write-Host ("End - Deferring clean up of packages/files, if any exist after $AppUninstall1 Un-install")

}



     ##*===============================================
	 ##* UNINSTALLATION (2.Simulia Fe-safe 2018)
	 ##*===============================================
 
# Uninstall Operations for Simulia Fe-safe 2018 {PROC2}
if((Test-Path $FeSafeOldAppDetection1) -or (Test-Path $FeSafeOldAppDetection2)) {
      #uninstall - older version logic goes here

      $AppUninstall2 = "Simulia Fe-safe 2018"
     Write-Host ("Older Version of the Application $AppUninstall2 detected. Executing the Uninstall Logic")
     Write-Log ("Older Version of the Application $AppUninstall2 detected. Executing the Uninstall Logic")


    Write-Log "Older Version of the Application $AppUninstall2  detected. Executing the Uninstall Logic"
    $proc2startinfo = new-object System.Diagnostics.ProcessStartInfo
    $proc2startinfo.FileName = "$scriptpath\Source\2018\2.Simulia Fe-safe\FE-Safe_Uninstaller.EXE"
    $proc2startinfo.Arguments = "/s"
    $proc2startinfo.UseShellExecute = $false
    $proc2startinfo.RedirectStandardOutput = $true
try {$proc2 = [System.Diagnostics.Process]::Start($proc2startinfo)}
catch {
    Write-Log "Error executing $scriptpath\$AppUninstall2, file likely missing"
    exit 1603
}
$proc2.WaitForExit()

$exitcode2 = $proc2.ExitCode

if (($exitcode2 -eq 0) -or ($exitcode2 -eq 3010) -or ($exitcode2 -eq 1641) -or ($exitcode2 -eq 1603)) {

    Write-Log ("$AppUninstall2.exe main Uninstall completed successfully with code: " + $exitcode2)
}
else {

    Write-Log ("$AppUninstall2 Uninstall failed with code " + $exitcode2) -type Error
    
}

     ##*===============================================
	 ##* POST-UNINSTALLATION
	 ##*===============================================


    Write-log ("Older version uninstallation for $AppUninstall2 completed Succesfully now entering the Another Application Unistallation logic")
    Write-host ("Older version uninstallation for $AppUninstall2 completed Succesfully now entering the Another Application Unistallation logic")
    
    Write-Log ("Start - Deferring clean up of packages/files, if any exist after $AppUninstall2 Un-install")
    Write-Host ("Start - Deferring clean up of packages/files, if any exist after $AppUninstall2 Un-install")
    Start-sleep -s 180
    Write-Log ("End - Deferring clean up of packages/files, if any exist after $AppUninstall2 Un-install")
    Write-Host ("End - Deferring clean up of packages/files, if any exist after $AppUninstall2 Un-install")

}



     ##*===============================================
	 ##* UNINSTALLATION (3.Simulia Tosca 2018)
	 ##*===============================================
 
# Uninstall Operations for Simulia Tosca 2018 {PROC3}
if((Test-Path $ToscaOldAppDetection1) -or (Test-Path $ToscaOldAppDetection2)) {
      #uninstall - older version logic goes here
      
      $AppUninstall3 = "Simulia Tosca 2018"
     Write-Host "Older Version of the Application $AppUninstall3 detected. Executing the Uninstall Logic"
     Write-Log ("Older Version of the Application $AppUninstall3 detected. Executing the Uninstall Logic")

     
    $proc3startinfo = new-object System.Diagnostics.ProcessStartInfo
    $proc3startinfo.FileName = "$scriptpath\Source\2018\3.Simulia Tosca\Tosca_Uninstaller.EXE"
    $proc3startinfo.Arguments = "/s"
    $proc3startinfo.UseShellExecute = $false
    $proc3startinfo.RedirectStandardOutput = $true
try {$proc3 = [System.Diagnostics.Process]::Start($proc3startinfo)}
catch {
    Write-Log "Error executing $scriptpath\$AppUninstall3, file likely missing"
    exit 1603
}
$proc3.WaitForExit()

$exitcode3 = $proc3.ExitCode

if (($exitcode3 -eq 0) -or ($exitcode3 -eq 3010) -or ($exitcode3 -eq 1641) -or ($exitcode3 -eq 1603)) {

    Write-Log ("$AppUninstall3.exe main Uninstall completed successfully with code: " + $exitcode3)
}
else {

    Write-Log ("$AppUninstall3 Uninstall failed with code " + $exitcode3) -type Error
    
}

     ##*===============================================
	 ##* POST-UNINSTALLATION
	 ##*===============================================


    Write-log ("Older version uninstallation for $AppUninstall3 completed Succesfully now entering the Another Application Unistallation logic")
    Write-host ("Older version uninstallation for $AppUninstall3 completed Succesfully now entering the Another Application Unistallation logic")
    
    Write-Log ("Start - Deferring clean up of packages/files, if any exist after $AppUninstall3 Un-install")
    Write-Host ("Start - Deferring clean up of packages/files, if any exist after $AppUninstall3 Un-install")
    Start-sleep -s 180
    Write-Log ("End - Deferring clean up of packages/files, if any exist after $AppUninstall3 Un-install")
    Write-Host ("End - Deferring clean up of packages/files, if any exist after $AppUninstall3 Un-install")

}



     ##*===============================================
	 ##* UNINSTALLATION (4.Simulia Isight 2018)
	 ##*===============================================
 
# Uninstall Operations for Simulia Isight 2018 {PROC4}
if((Test-Path $IsightOldAppDetection1) -or (Test-Path $IsightOldAppDetection2)) {
      #uninstall - older version logic goes here
      
      $AppUninstall4 = "Simulia Isight 2018"
     Write-Host "Older Version of the Application $AppUninstall4 detected. Executing the Uninstall Logic"
     Write-Log ("Older Version of the Application $AppUninstall4 detected. Executing the Uninstall Logic")

     

    $proc4startinfo = new-object System.Diagnostics.ProcessStartInfo
    $proc4startinfo.FileName = "$scriptpath\Source\2018\4.Simulia Isight\Isight_Uninstaller.EXE"
    $proc4startinfo.Arguments = "/s"
    $proc4startinfo.UseShellExecute = $false
    $proc4startinfo.RedirectStandardOutput = $true
try {$proc4 = [System.Diagnostics.Process]::Start($proc4startinfo)}
catch {
    Write-Log "Error executing $scriptpath\$AppUninstall4, file likely missing"
    exit 1603
}
$proc4.WaitForExit()

$exitcode4 = $proc4.ExitCode

if (($exitcode4 -eq 0) -or ($exitcode4 -eq 3010) -or ($exitcode4 -eq 1641) -or ($exitcode4 -eq 1603)) {

    Write-Log ("$AppUninstall4.exe main Uninstall completed successfully with code: " + $exitcode4)
}
else {

    Write-Log ("$AppUninstall4 Uninstall failed with code " + $exitcode4) -type Error
    
}
     ##*===============================================
	 ##* POST-UNINSTALLATION
	 ##*===============================================


    Write-log ("Older version uninstallation for $AppUninstall4 completed Succesfully now entering the Another Application Unistallation logic")
    Write-host ("Older version uninstallation for $AppUninstall4 completed Succesfully now entering the Another Application Unistallation logic")
    
    Write-Log ("Start - Deferring clean up of packages/files, if any exist after $AppUninstall4 Un-install")
    Write-Host ("Start - Deferring clean up of packages/files, if any exist after $AppUninstall4 Un-install")
    Start-sleep -s 180
    Write-Log ("End - Deferring clean up of packages/files, if any exist after $AppUninstall4 Un-install")
    Write-Host ("End - Deferring clean up of packages/files, if any exist after $AppUninstall4 Un-install")

}


#Intentionally left taking the number 5. 

     ##*===============================================
	 ##* UNINSTALLATION (6.Simulia Designer 2018)
	 ##*===============================================
 
# Uninstall Operations for Simulia Designer 2018 {PROC6}
if((Test-Path $DesOldAppDetection1) -or (Test-Path $DesOldAppDetection2)) {
      #uninstall - older version logic goes here
       
       $AppUninstall6 = "Simulia Designer 2018"
     Write-Host "Older Version of the Application $AppUninstall6 detected. Executing the Uninstall Logic"
     Write-Log ("Older Version of the Application $AppUninstall6 detected. Executing the Uninstall Logic")
     

    $proc6startinfo = new-object System.Diagnostics.ProcessStartInfo
    $proc6startinfo.FileName = "$scriptpath\Source\2018\1.Simulia Abaqus CAE Products\Designer\ABQ_Designer_Uninstall.EXE"
    $proc6startinfo.Arguments = "/s"
    $proc6startinfo.UseShellExecute = $false
    $proc6startinfo.RedirectStandardOutput = $true
try {$proc6 = [System.Diagnostics.Process]::Start($proc6startinfo)}
catch {
    Write-Log "Error executing $scriptpath\$AppUninstall6, file likely missing"
    exit 1603
}
$proc6.WaitForExit()

$exitcode6 = $proc6.ExitCode

if (($exitcode6 -eq 0) -or ($exitcode6 -eq 3010) -or ($exitcode6 -eq 1641) -or ($exitcode6 -eq 1603)) {

    Write-Log ("$AppUninstall6.exe main Uninstall completed successfully with code: " + $exitcode6)
}
else {

    Write-Log ("$AppUninstall6e Uninstall failed with code " + $exitcode6) -type Error
    
}
     ##*===============================================
	 ##* POST-UNINSTALLATION
	 ##*===============================================


    Write-log ("Older version uninstallation for $AppUninstall6 completed Succesfully now entering the Another Application Unistallation logic")
    Write-host ("Older version uninstallation for $AppUninstall6 completed Succesfully now entering the Another Application Unistallation logic")
    
    Write-Log ("Start - Deferring clean up of packages/files, if any exist after $AppUninstall6 Un-install")
    Write-Host ("Start - Deferring clean up of packages/files, if any exist after $AppUninstall6 Un-install")
    Start-sleep -s 180
    Write-Log ("End - Deferring clean up of packages/files, if any exist after $AppUninstall6 Un-install")
    Write-Host ("End - Deferring clean up of packages/files, if any exist after $AppUninstall6 Un-install")

}



Write-Log ("Uninstall operations for package $appScriptFilename completed")
Write-Host ("Uninstall operations for package $appScriptFilename completed")


######### End of Application Un-installation#################
