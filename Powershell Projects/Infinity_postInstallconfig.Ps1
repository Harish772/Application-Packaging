<#
.Synopsis
   The Script acts as a Post Install Config File for Infinty Application
.EXAMPLE
   Powershell.exe -ExecutionPolicy Bypass -File <Pathto.ps1>
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   Collection Infinity workstation gage configurations files
   Copy files from local directory to network share
.COMPONENT
   The component this cmdlet belongs to
.Goals:
    Copy C:\ProgramData\InfinityQS International\Proficient\Private\lks_gage.cfg to (unc path)\COMMON\clf\Infinity_test\$env:Computername_orgfilemodifieddate_lks_gage.cfg" 
    Find ALL instances of c:\Users\%username%\AppData\Local\VirtualStore\ProgramData\InfinityQS International\Proficient\Private\lks_gage.cfg and copy to
    S:\COMMON\clf\Infinity_test\$env:Computername_%username%_lks_gage.cfg - using directoy name it's being copied from not current username and keeping current file modified date
    S:\COMMON\clf\Infinity_test is just for testing any network location can be used as it will change when we go to PROD anyway.
    Once the logic is completed and working successfully add two additional files for same IQS_SPC.ini and IQS_SYS.ini
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
#Retrive Current Directory
#$PSScriptRoot = Split-Path $MyInvocation.MyCommand.path -Parent
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptname =  ($MyInvocation.MyCommand.Name) -replace ".ps1",""

    ##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================
	## Variables: Application
	[string]$appVendor = 'Infinity' #Should not Contain any extra white Spaces#
	[string]$appName = 'Post Install Configurations' #Should not Contain any extra white Spaces#
	[string]$appVersion = ''
	[string]$appArch = 'x64'
    [string]$appLang = 'EN'
    [string]$appARPVersion = '' #should get this from Add Remove Programs
    [string]$appRevision = 'B01' #B stands for Build
    [string]$DeploymentType = 'Install' #Acceptable values = Install, Uninstall, Repair
	[string]$appScriptDate = '02/23/2022'
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

#To ensure logfile is just for this run
If (test-path $logfile){
    # Existing log file found, will be deleted
    Remove-Item -Path $logfile -Force
}

#Creating a log file folder

if (!(test-path $logpath)) {
    new-item -Path $logpath -ItemType Directory -Force | Out-Null
}

if (!(test-path $logfile)) {
    new-item -Path $logfile -ItemType File -Force | Out-Null
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

    $formattedlogcontent = '<![LOG[' + $typestring + $message + ']LOG]!><time="' + $formattedtime + '+300" date="' + $formatteddate + '" component="' + $script:scriptname + '" context="" type="' + $typecode + '" thread="1234">'

    Add-Content $script:logfile -Value $formattedlogcontent
}

    #endregion
    ##* Do not modify section above

<#
$FolderCheck1 = Test-Path -Path  "\\Replaced\Wise"

If(!($FolderCheck1)){
    New-Item -Path "\\Replaced\" -Name "Wise" -ItemType 'Directory' -Force
}

$FolderCheck2 = Test-Path -Path  "\\Replaced\Wise\Pkg_Projects"

If(!($FolderCheck2)){
    New-Item -Path "\\Replaced\Wise" -Name "Pkg_Projects" -ItemType 'Directory' -Force
}

$FolderCheck3 = Test-Path -Path  "\\Replaced\Wise\Pkg_Projects\Post Config Infinity"

If(!($FolderCheck3)){
    New-Item -Path "\\Replaced\Wise\Pkg_Projects" -Name "Post Config Infinity" -ItemType 'Directory' -Force
}


$FolderCheck4 = Test-Path -Path  "\\Replaced\Wise\Pkg_Projects\Post Config Infinity\Infinity_test"

If(!($FolderCheck4)){
    New-Item -Path "\\Replaced\Wise\Pkg_Projects\Post Config Infinity" -Name "Infinity_test" -ItemType 'Directory' -Force
}
#>


     ##*========================================================================================================================================
	 ##* Goal - 1 : Rename the lks_gage.cfg (in ProgramData folder) to $env:Computername_orgfilemodifieddate_lks_gage.cfg and copy to UNC Share
	 ##*========================================================================================================================================


$FolderCheck1 = Test-Path -Path "$Env:windir\temp\infinity"

If(!($FolderCheck1)){

    New-Item -Path "$Env:windir\temp\" -Name "infinity" -ItemType 'Directory' -Force

}

$FileCheck = Test-Path -Path "$env:ProgramData\InfinityQS International\Proficient\Private\lks_gage.cfg"

If($FileCheck){

    Copy-Item -Path "$env:ProgramData\InfinityQS International\Proficient\Private\lks_gage.cfg" -Destination "$Env:windir\temp\infinity\" -Recurse -Force
}

$FN = $env:COMPUTERNAME

$moddate = (Get-Item -Path "$env:ProgramData\InfinityQS International\Proficient\Private\lks_gage.cfg") | Get-date -DisplayHint Time

$Filetry = Add-Content -Path "$Env:windir\temp\infinity\test.txt" -Value "$FN,$moddate,lks_gage.cfg" | Set-Content -Path "$Env:windir\temp\infinity\test.txt"

$Filetry2 = (Get-Content "$Env:windir\temp\infinity\test.txt")-replace',','_' | Set-Content -Path "$Env:windir\temp\infinity\test.txt"

$Filetry3 = (Get-Content "$Env:windir\temp\infinity\test.txt")-replace'/','-' | Set-Content -Path "$Env:windir\temp\infinity\test.txt"

$Filetry4 = (Get-Content "$Env:windir\temp\infinity\test.txt")-replace':','-' | Set-Content -Path "$Env:windir\temp\infinity\test.txt"

$Filetry5 = (Get-Content "$Env:windir\temp\infinity\test.txt")-replace'14-24-05','' | Set-Content -Path "$Env:windir\temp\infinity\test.txt"

$Filetry6 = (Get-Content "$Env:windir\temp\infinity\test.txt")-replace' ','' | Set-Content -Path "$Env:windir\temp\infinity\test.txt"

[String]$filename = Get-Content "$Env:windir\temp\infinity\test.txt"
$filename

Rename-Item -Path "$Env:windir\temp\infinity\lks_gage.cfg" -NewName $filename -Force

Remove-item -Path "$Env:windir\temp\infinity\test.txt" -Force

Copy-Item -Path "$Env:windir\temp\infinity\*" -Destination "\\Replaced\Wise\Pkg_Projects\Post Config Infinity\Infinity_test\" -Recurse -Force

Remove-item -Path "$Env:windir\temp\infinity\*" -Force

     ##*========================================================================================================================================
	 ##* Goal - 2 : Rename the lks_gage.cfg (in %UserProfile% folder) to $env:Computername_%username%_lks_gage.cfg and copy to UNC Share
	 ##*========================================================================================================================================


$Profile = @{ }

$ErrorActionPreference = "SilentlyContinue"

$CurrentUser = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty UserName

$UserProfiles = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\ProfileList\*"

forEach ($UserProfile in $UserProfiles){

        $SecID = New-Object -TypeName System.Security.Principal.SecurityIdentifier($UserProfile.PSChildName)

        $DomUserName = $SecID.Translate([System.Security.Principal.NTAccount])

        $Profile.Add($DomUserName.Value, $UserProfile.ProfileImagePath)

        $input = $DomUserName

        $domain,$username = $input -split '\\'

        #$PathToUser = $Profile[$DomUserName]

        $PathToCFG = Join-Path -Path "C:\Users\$username" -ChildPath "\AppData\Local\VirtualStore\ProgramData\InfinityQS International\Proficient\Private\lks_gage.cfg"


if (Test-Path -LiteralPath $PathToCFG){

        Copy-Item -Path "$PathToCFG" -Destination "$Env:windir\temp\infinity\" -Recurse -Force

        $FN = $env:COMPUTERNAME

        $UN = $username

        $moddate = (Get-Item -Path $PathToCFG) | Get-date -DisplayHint Time

        $Filetry = Add-Content -Path "$Env:windir\temp\infinity\test.txt" -Value "$FN,$UN,$moddate,lks_gage.cfg" | Set-Content -Path "$Env:windir\temp\infinity\test.txt"

        $Filetry2 = (Get-Content "$Env:windir\temp\infinity\test.txt")-replace',','_' | Set-Content -Path "$Env:windir\temp\infinity\test.txt"

        $Filetry3 = (Get-Content "$Env:windir\temp\infinity\test.txt")-replace'/','-' | Set-Content -Path "$Env:windir\temp\infinity\test.txt"

        $Filetry4 = (Get-Content "$Env:windir\temp\infinity\test.txt")-replace':','-' | Set-Content -Path "$Env:windir\temp\infinity\test.txt"

        $Filetry5 = (Get-Content "$Env:windir\temp\infinity\test.txt")-replace'14-24-05','' | Set-Content -Path "$Env:windir\temp\infinity\test.txt"

        $Filetry6 = (Get-Content "$Env:windir\temp\infinity\test.txt")-replace' ','' | Set-Content -Path "$Env:windir\temp\infinity\test.txt"

        [String]$filename = Get-Content "$Env:windir\temp\infinity\test.txt"

        Rename-Item -Path "$Env:windir\temp\infinity\lks_gage.cfg" -NewName $filename -Force

        Remove-item -Path "$Env:windir\temp\infinity\test.txt" -Force

        Copy-Item -Path "$Env:windir\temp\infinity\*" -Destination "\\Replaced\Wise\Pkg_Projects\Post Config Infinity\Infinity_test\" -Recurse -Force

        Remove-item -path "$env:WinDir\Temp\Infinity\*" -Force


    }


}

     ##*==================================================================================================================================
	 ##* Goal - 3 : : Rename the IQS_SPC.ini (in ProgramData folder) to $env:Computername_orgfilemodifieddate_IQS_SPC.ini and copy to UNC Share
	 ##*==================================================================================================================================



$FolderCheck1G3 = Test-Path -Path "$Env:windir\temp\infinity"

If(!($FolderCheck1G3)){

    New-Item -Path "$Env:windir\temp\" -Name "infinity" -ItemType 'Directory' -Force

}

$FileCheckG3 = Test-Path -Path "$env:ProgramData\InfinityQS International\Proficient\Private\IQS_SPC.ini"

If($FileCheckG3){

    Copy-Item -Path "$env:ProgramData\InfinityQS International\Proficient\Private\IQS_SPC.ini" -Destination "$Env:windir\temp\infinity\" -Recurse -Force
}

$FNG3 = $env:COMPUTERNAME

$moddateG3 = (Get-Item -Path "$env:ProgramData\InfinityQS International\Proficient\Private\IQS_SPC.ini") | Get-date -DisplayHint Time

$FiletryG3 = Add-Content -Path "$Env:windir\temp\infinity\testG3.txt" -Value "$FN,$moddate,IQS_SPC.ini" | Set-Content -Path "$Env:windir\temp\infinity\testG3.txt"

$Filetry2G3 = (Get-Content "$Env:windir\temp\infinity\testG3.txt")-replace',','_' | Set-Content -Path "$Env:windir\temp\infinity\testG3.txt"

$Filetry3G3 = (Get-Content "$Env:windir\temp\infinity\testG3.txt")-replace'/','-' | Set-Content -Path "$Env:windir\temp\infinity\testG3.txt"

$Filetry4G3 = (Get-Content "$Env:windir\temp\infinity\testG3.txt")-replace':','-' | Set-Content -Path "$Env:windir\temp\infinity\testG3.txt"

$Filetry5G3 = (Get-Content "$Env:windir\temp\infinity\testG3.txt")-replace'14-24-05','' | Set-Content -Path "$Env:windir\temp\infinity\testG3.txt"

$Filetry6G3 = (Get-Content "$Env:windir\temp\infinity\testG3.txt")-replace' ','' | Set-Content -Path "$Env:windir\temp\infinity\testG3.txt"

[String]$filenameG3 = Get-Content "$Env:windir\temp\infinity\testG3.txt"
$filenameG3

Rename-Item -Path "$Env:windir\temp\infinity\IQS_SPC.ini" -NewName $filenameG3 -Force

Remove-item -Path "$Env:windir\temp\infinity\testG3.txt" -Force

Copy-Item -Path "$Env:windir\temp\infinity\*" -Destination "\\Replaced\Wise\Pkg_Projects\Post Config Infinity\Infinity_test\" -Recurse -Force

Remove-item -Path "$Env:windir\temp\infinity\*" -Force


     ##*==================================================================================================================================
	 ##* Goal - 4 : : Rename the IQS_SYS.ini (in ProgramData folder) to $env:Computername_orgfilemodifieddate_IQS_SYS.ini and copy to UNC Share
	 ##*==================================================================================================================================


$FolderCheck1G4 = Test-Path -Path "$Env:windir\temp\infinity"

If(!($FolderCheck1G4)){

    New-Item -Path "$Env:windir\temp\" -Name "infinity" -ItemType 'Directory' -Force

}

$FileCheckG4 = Test-Path -Path "$env:ProgramData\InfinityQS International\Proficient\Private\IQS_SYS.ini"

If($FileCheckG4){

    Copy-Item -Path "$env:ProgramData\InfinityQS International\Proficient\Private\IQS_SYS.ini" -Destination "$Env:windir\temp\infinity\" -Recurse -Force
}

$FNG4 = $env:COMPUTERNAME

$moddateG4 = (Get-Item -Path "$env:ProgramData\InfinityQS International\Proficient\Private\IQS_SYS.ini") | Get-date -DisplayHint Time

$FiletryG4 = Add-Content -Path "$Env:windir\temp\infinity\testG4.txt" -Value "$FN,$moddate,IQS_SYS.ini" | Set-Content -Path "$Env:windir\temp\infinity\testG4.txt"

$Filetry2G4 = (Get-Content "$Env:windir\temp\infinity\testG4.txt")-replace',','_' | Set-Content -Path "$Env:windir\temp\infinity\testG4.txt"

$Filetry3G4 = (Get-Content "$Env:windir\temp\infinity\testG4.txt")-replace'/','-' | Set-Content -Path "$Env:windir\temp\infinity\testG4.txt"

$Filetry4G4 = (Get-Content "$Env:windir\temp\infinity\testG4.txt")-replace':','-' | Set-Content -Path "$Env:windir\temp\infinity\testG4.txt"

$Filetry5G4 = (Get-Content "$Env:windir\temp\infinity\testG4.txt")-replace'14-24-05','' | Set-Content -Path "$Env:windir\temp\infinity\testG4.txt"

$Filetry6G4 = (Get-Content "$Env:windir\temp\infinity\testG4.txt")-replace' ','' | Set-Content -Path "$Env:windir\temp\infinity\testG4.txt"

[String]$filenameG4 = Get-Content "$Env:windir\temp\infinity\testG4.txt"
$filenameG4

Rename-Item -Path "$Env:windir\temp\infinity\IQS_SYS.ini" -NewName $filenameG4 -Force

Remove-item -Path "$Env:windir\temp\infinity\testG4.txt" -Force

Copy-Item -Path "$Env:windir\temp\infinity\*" -Destination "\\Replaced\Wise\Pkg_Projects\Post Config Infinity\Infinity_test\" -Recurse -Force

Remove-item -Path "$Env:windir\temp\infinity\*" -Force
