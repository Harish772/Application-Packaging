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
	[string]$appName = 'Client-DNCMAX&Editor' #Should not Contain any extra white Spaces#
	[string]$appVersion = '8.09.07'
	[string]$appArch = 'x64'
    [string]$appLang = 'EN'
    [string]$appARPVersion = '8.09.07' #should get this from Add Remove Programs
    [string]$appRevision = 'B01' #B stands for Build
    [string]$DeploymentType = 'Install' #Acceptable values = Install, Uninstall, Repair
	[string]$appScriptDate = '12/15/2020'
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

$Installer1 = "$scriptpath\Source\Cimco_Client-DNCMAX.msi"

$Installer2 = "$scriptpath\Source\Cimco_Client-DNCMAX.Mst"

#enter names of any processes (without .exe) to terminate, comma delimited
$processesToKill = @("DNCAdmin","CIMCOEdit")

#Detection if the Current version already exists (File or Folder or Reg Key)"
$AppDetection1 = "C:\Program Files (x86)\CIMCO\DNCMax8\DNCAdmin.exe"
$AppDetection2 = "C:\CIMCO\DNCMax8\DNCAdmin.exe"
$AppDetection3 = "C:\Program Files (x86)\CIMCO\DNCMax8\DNCMaxCtrl.exe"

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
    
    "CIMCO_Client-DNCMAX_or_Editor_8.09.07" = "{66AFD3DB-B0D5-4EA4-BEE8-7AED2D14A966}"
    "CIMCO_Cleint-DNCMAX_7.2"= "{CA55E49B-AE0B-4A96-9E67-F6ECC5CCE609}"
    "CIMCO_DNC_Editor_7.2" = "{1110C510-A930-44D9-973A-DEF1B9FEC753}"
    
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

#Function to Retrive Installed Applications (PSADT's Logic)
Function Get-InstalledApplication {
  [CmdletBinding()]
  Param(
    [Parameter(
      Position=0,
      ValueFromPipeline=$true,
      ValueFromPipelineByPropertyName=$true
    )]
    [String[]]$ComputerName=$ENV:COMPUTERNAME,

    [Parameter(Position=1)]
    [String[]]$Properties,

    [Parameter(Position=2)]
    [String]$IdentifyingNumber,

    [Parameter(Position=3)]
    [String]$Name,

    [Parameter(Position=4)]
    [String]$Publisher
  )
  Begin{
    Function IsCpuX86 ([Microsoft.Win32.RegistryKey]$hklmHive){
      $regPath='SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
      $key=$hklmHive.OpenSubKey($regPath)

      $cpuArch=$key.GetValue('PROCESSOR_ARCHITECTURE')

      if($cpuArch -eq 'x86'){
        return $true
      }else{
        return $false
      }
    }
  }
  Process{
    foreach($computer in $computerName){
      $regPath = @(
        'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
      )

      Try{
        $hive=[Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey(
          [Microsoft.Win32.RegistryHive]::LocalMachine, 
          $computer
        )
        if(!$hive){
          continue
        }
        
        # if CPU is x86 do not query for Wow6432Node
        if($IsCpuX86){
          $regPath=$regPath[0]
        }

        foreach($path in $regPath){
          $key=$hive.OpenSubKey($path)
          if(!$key){
            continue
          }
          foreach($subKey in $key.GetSubKeyNames()){
            $subKeyObj=$null
            if($PSBoundParameters.ContainsKey('IdentifyingNumber')){
              if($subKey -ne $IdentifyingNumber -and 
                $subkey.TrimStart('{').TrimEnd('}') -ne $IdentifyingNumber){
                continue
              }
            }
            $subKeyObj=$key.OpenSubKey($subKey)
            if(!$subKeyObj){
              continue
            }
            $outHash=New-Object -TypeName Collections.Hashtable
            $appName=[String]::Empty
            $appName=($subKeyObj.GetValue('DisplayName'))
            if($PSBoundParameters.ContainsKey('Name')){
              if($appName -notlike $name){
                continue
              }
            }
            if($appName){
              if($PSBoundParameters.ContainsKey('Properties')){
                if($Properties -eq '*'){
                  foreach($keyName in ($hive.OpenSubKey("$path\$subKey")).GetValueNames()){
                    Try{
                      $value=$subKeyObj.GetValue($keyName)
                      if($value){
                        $outHash.$keyName=$value
                      }
                    }Catch{
                      Write-Warning "Subkey: [$subkey]: $($_.Exception.Message)"
                      continue
                    }
                  }
                }else{
                  foreach ($prop in $Properties){
                    $outHash.$prop=($hive.OpenSubKey("$path\$subKey")).GetValue($prop)
                  }
                }
              }
              $outHash.Name=$appName
              $outHash.IdentifyingNumber=$subKey
              $outHash.Publisher=$subKeyObj.GetValue('Publisher')
              if($PSBoundParameters.ContainsKey('Publisher')){
                if($outHash.Publisher -notlike $Publisher){
                  continue
                }
              }
              $outHash.ComputerName=$computer
              $outHash.Path=$subKeyObj.ToString()
              New-Object -TypeName PSObject -Property $outHash
            }
          }
        }
      }Catch{
        Write-Error $_
      }
    }
  }
  End{}
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







     Write-Host ("Executing the Uninstall Logic")
     Write-Log ("Executing the Uninstall Logic")


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
$sh1 = "C:\Program Files (x86)\CIMCO\CIMCOEdit7\cfg\cimco.ini"

if((Test-Path $sh1)) {

    Remove-Item $sh1 -Recurse -Force -ErrorAction silentlycontinue

}

#Delete Orphaned files If Exists
$sh2 = "C:\Program Files (x86)\CIMCO\CIMCOEdit7"

if((Test-Path $sh2)) {

    Remove-Item $sh2 -Recurse -Force -ErrorAction silentlycontinue

}


 #Delete Orphaned files If Exists
$sh3 = "C:\Program Files (x86)\CIMCO\DNCMax7\cfg\DNCAdm.ini"

if((Test-Path $sh3)) {

    Remove-Item $sh3 -Recurse -Force -ErrorAction silentlycontinue

}

#Delete Orphaned files If Exists
$sh4 = "C:\Program Files (x86)\CIMCO\DNCMax7"

if((Test-Path $sh4)) {

    Remove-Item $sh4 -Recurse -Force -ErrorAction silentlycontinue

}

#Delete Orphaned files If Exists
$sh5 = "C:\Program Files (x86)\CIMCO\CIMCOEdit8\cfg\Cimco.ini"

if((Test-Path $sh5)) {

    Remove-Item $sh5 -Recurse -Force -ErrorAction silentlycontinue

}

#Delete Orphaned files If Exists
$sh6 = "C:\Program Files (x86)\CIMCO\CIMCOEdit8"

if((Test-Path $sh6)) {

    Remove-Item $sh6 -Recurse -Force -ErrorAction silentlycontinue

}
          
   #Delete Orphaned files If Exists
$sh7 = "C:\Program Files (x86)\CIMCO\DNCMax8\cfg\DNCAdm.ini"

if((Test-Path $sh7)) {

    Remove-Item $sh7 -Recurse -Force -ErrorAction silentlycontinue

}

#Delete Orphaned files If Exists
$sh8 = "C:\Program Files (x86)\CIMCO\DNCMax8"

if((Test-Path $sh8)) {

    Remove-Item $sh8-Recurse -Force -ErrorAction silentlycontinue

}

#Actual Installation starts here. 

     ##*===============================================
	 ##* PRE-INSTALLATION
	 ##*===============================================


$checkforVC2005 = Get-InstalledApplication -name "Microsoft visual c++ 2005*"
        if ($checkforVC2005){
         Write-Host ("VC++ 2005 is already installed on the system..Now searching for another Dependency ")
        }
        Else {      
    
        Write-Host ("VC++ 2005 is not installed on the system... Executing Install Logic")
        Start-Process -FilePath "$scriptpath\Source\vcredist2005\vcredist_x86.exe" -ArgumentList "/q " -Wait -Passthru
    
        }


  
  $checkforVC2010 = Get-InstalledApplication -name "Microsoft visual C++ 2010  x86 *"
        if ($checkforVC2010){
         Write-Host ("VC++ 2010 is already installed on the system..Now searching for another Dependency ")
        }
        Else {

       
        Write-Host ("VC++ 2010 is not installed on the system... Executing Install Logic")
        Start-Process -FilePath "$scriptpath\Source\vcredist2010\vcredist2010sp1_x86.exe" -ArgumentList "/passive /norestart /l*v $logpath\$appScriptFoldername\VC2010-Install.log " -Wait -Passthru
         
        }
      
      
  $checkforVC2012 = Get-InstalledApplication -name "Microsoft visual C++ 2012 Redistributable (x86)*"
        if ($checkforVC2012){
         Write-Host ("VC++ 2012 is already installed on the system..Now searching for another Dependency ")
        }
        Else {

      
        Write-Host ("VC++ 2012 is not installed on the system... Executing Install Logic")
        Start-Process -FilePath "$scriptpath\Source\vcredist2012\vcredist2012_x86.exe" -ArgumentList "/passive /norestart /l*v $logpath\$appScriptFoldername\VC2012-Install.log " -Wait -Passthru
        
        }
      

          
  $checkforVC2013 = Get-InstalledApplication -name "Microsoft visual C++ 2013 Redistributable (x86)*"
        if ($checkforVC2013){
         Write-Host ("VC++ 2013 is already installed on the system..Now searching for another Dependency ")
        }
        Else {

       
        Write-Host ("VC++ 2013 is not installed on the system... Executing Install Logic")
        Start-Process -FilePath "$scriptpath\Source\vcredist2013\vcredist2013_x86.exe" -ArgumentList "/passive /norestart /l*v $logpath\$appScriptFoldername\VC2013-Install.log " -Wait -Passthru
        }




   $checkforVC2015 = Get-InstalledApplication -name "Microsoft visual C++ 2015*"
        if ($checkforVC2015){
         Write-Host ("VC++ 2015 is already installed on the system..Now searching for another Dependency ")
        }
        Else {

      
        Write-Host ("VC++ 2015 is not installed on the system... Executing Install Logic")
        Start-Process -FilePath "$scriptpath\Source\vcredist2015\vcredist2015_x86.exe" -ArgumentList "/passive /norestart /l*v $logpath\$appScriptFoldername\VC2015-Install.log " -Wait -Passthru
        }



     
     ##*===============================================
	 ##* Main - INSTALLATION
	 ##*===============================================
     
     #### Main Script Execution ####
     #Install $appScriptFilename main package

     
     
     ##*===============================================
	 ##* INSTALLATION (1.CIMCO_Client-DNCMAX_8.09.07(Main))
	 ##*===============================================
     

Write-Log "Installing $appScriptFilename.exe (Main)"

Write-Host "Installing $appScriptFilename.exe (Main)"

    $proc2startinfo = new-object System.Diagnostics.ProcessStartInfo
    $proc2startinfo.FileName = "c:\windows\system32\msiexec.exe"
    $proc2startinfo.Arguments = "/i `"$Installer1`" TRANSFORMS=`"$Installer2`" /qb! /l*v $logpath\$appScriptFoldername\CIMCO_Client-DNCMAX&Editor_8.09.07-MSI-Install.log"
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
    Write-Log ("Start - Deferring clean up of packages/files, if any exist after (Main) Install")
    Write-Host ("Start - Deferring clean up of packages/files, if any exist after  (Main) Install")
    Start-sleep -s 30
    Write-Log ("End - Deferring clean up of packages/files, if any exist after  (Main) Install")
    Write-Host ("End - Deferring clean up of packages/files, if any exist after  (Main) Install")



     ##*===============================================
	 ##* POST-INSTALLATION
	 ##*===============================================
     
     ######### Start Post Configurations#################
     #Adding Firewall Rules 
Write-log ("Start..Adding the Firewall Rules")

    netsh advfirewall firewall add rule name="CIMCO DNC-Max Client" dir=in action=allow program="C:\program files (x86)\cimco\dncmax8\dncadmin.exe" enable=yes profile=domain

Write-log ("End..Adding the Firewall Rules")


Write-log ("Start..Copying the CFG File")

    $CFGFolder = "C:\Program Files (x86)\CIMCO\DNCMax8\cfg"
    
    $cfgfile = "$scriptPath\Source\DNCAdm.ini"

    new-item -Path $CFGFolder -ItemType Directory -Force | Out-Null
    
    Copy-Item -path "$cfgfile" $CFGFolder -Recurse -force

Write-log ("End..Copying the CFG File")


Write-log ("Start..Copying the CFG2 File")

    $CFGFolder2 = "C:\Program Files (x86)\CIMCO\CIMCOEdit8\cfg"
    
    $cfgfile2 = "$scriptPath\Source\cimco.ini"

    new-item -Path $CFGFolder2 -ItemType Directory -Force | Out-Null
    Copy-Item -path "$cfgfile2" $CFGFolder2 -Recurse -force

Write-log ("End..Copying the CFG2 File")



Write-log ("Start..Adding folder permissions")

$DestPath24 = "C:\Program Files (x86)\CIMCO\DNCMax8"

if ((Test-path $DestPath24)){

    Icacls $DestPath24 /grant:r '"Users":(OI)(CI)M' /T
}
Write-log ("End..Adding folder permissions")

Write-log ("Start..Adding folder permissions")

$DestPath25 = "C:\Program Files (x86)\CIMCO\CIMCOEdit8"

if ((Test-path $DestPath25)){

    Icacls $DestPath25 /grant:r '"Users":(OI)(CI)M' /T
}
Write-log ("End..Adding folder permissions")




    Write-Log ("End of Script - $appScriptFilename Installtion completed Succesfully ")
    Write-Host ("End of Script - $appScriptFilename Installtion completed with Succesfully")







######### End of Application Installation#################

