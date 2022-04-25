<#
.SYNOPSIS
	This script performs the installation or uninstallation of an application(s).
	# LICENSE #
	PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows.
	Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.
	This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
	You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
.DESCRIPTION
	The script is provided as a template to perform an install or uninstall of an application(s).
	The script either performs an "Install" deployment type or an "Uninstall" deployment type.
	The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.
	The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.
.PARAMETER DeploymentType
	The type of deployment to perform. Default is: Install.
.PARAMETER DeployMode
	Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.
.PARAMETER AllowRebootPassThru
	Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.
.PARAMETER TerminalServerMode
	Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Destkop Session Hosts/Citrix servers.
.PARAMETER DisableLogging
	Disables logging to file for the script. Default is: $false.
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"
.EXAMPLE
    Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"
.NOTES
	Toolkit Exit Code Ranges:
	60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
	69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
	70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.LINK
	http://psappdeploytoolkit.com
#>
[CmdletBinding()]
Param (
	[Parameter(Mandatory=$false)]
	[ValidateSet('Install','Uninstall','Repair')]
	[string]$DeploymentType = 'Install',
	[Parameter(Mandatory=$false)]
	[ValidateSet('Interactive','Silent','NonInteractive')]
	[string]$DeployMode = 'Interactive',
	[Parameter(Mandatory=$false)]
	[switch]$AllowRebootPassThru = $false,
	[Parameter(Mandatory=$false)]
	[switch]$TerminalServerMode = $false,
	[Parameter(Mandatory=$false)]
	[switch]$DisableLogging = $false
)

Try {
	## Set the script execution policy for this process
	Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}

	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================
	## Variables: Application
	[string]$appVendor = 'DP Tech'
	[string]$appName = 'EspritCAM'
	[string]$appVersion = '2021'
	[string]$appArch = 'x86/x64'
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '1.0.0'
	[string]$appScriptDate = '12/06/2021'
	[string]$appScriptAuthor = 'Harish K'
	##*===============================================
	## Variables: Install Titles (Only set here to override defaults set by the toolkit)
	[string]$installName = ''
	[string]$installTitle = ''

	##* Do not modify section below
	#region DoNotModify

	## Variables: Exit Code
	[int32]$mainExitCode = 0

	## Variables: Script
	[string]$deployAppScriptFriendlyName = 'Deploy Application'
	[version]$deployAppScriptVersion = [version]'3.8.2'
	[string]$deployAppScriptDate = '11/08/2021'
	[hashtable]$deployAppScriptParameters = $psBoundParameters

	## Variables: Environment
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
	[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent

	## Dot source the required App Deploy Toolkit Functions
	Try {
		[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
		If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
		If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
	}
	Catch {
		If ($mainExitCode -eq 0){ [int32]$mainExitCode = 60008 }
		Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
		## Exit the script, returning the exit code to SCCM
		If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $mainExitCode; Exit } Else { Exit $mainExitCode }
	}

	#endregion
	##* Do not modify section above
	##*===============================================
	##* END VARIABLE DECLARATION
	##*===============================================

	If ($deploymentType -ine 'Uninstall' -and $deploymentType -ine 'Repair') {
		##*===============================================
		##* PRE-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Installation'

		## Show Welcome Message, close Internet Explorer or other apps if required, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt
		## Org:  Show-InstallationWelcome -CloseApps 'iexplore' -AllowDefer -DeferTimes 3 -CheckDiskSpace -PersistPrompt
		#Show-InstallationWelcome -CloseApps 'iexplore' -CheckDiskSpace -PersistPrompt
		
		
		## Show Progress Message (with the default message)
		## None Show-InstallationProgress

		## <Perform Pre-Installation tasks here>
        Show-InstallationProgress -StatusMessage "Esprit 2021 products are getting installed on your computer. Please wait for the installation to complete"

        Start-sleep -s 10
        Execute-Process -Path "$dirFiles\Deploy\BootSetupPrerequisites\vcredist_86_2008\vcredist_x86.exe" -Parameters "/q" -wait

        Execute-Process -Path "$dirFiles\Deploy\BootSetupPrerequisites\vcredist_64_2008\vcredist_x64.exe" -Parameters "/q" -wait

        Execute-Process -Path "$dirFiles\Deploy\BootSetupPrerequisites\vcredist_86_2010\vcredist_x86.exe" -Parameters "/passive /norestart" -wait

        $CHECKFORAPP1 = Get-InstalledApplication -Name "Microsoft Visual C++ 2010  x64 Redistributable - 10.0.40219"
        if($CHECKFORAPP1){
        # Do not install vcredist_64_2010
        }
        else{
        Execute-Process -Path "$dirFiles\Deploy\BootSetupPrerequisites\vcredist_64_2010\vcredist_x64.exe" -Parameters "/passive /norestart" -wait
        }

        Execute-Process -Path "$dirFiles\Deploy\BootSetupPrerequisites\vcredist_86_2012\vcredist_x86.exe" -Parameters "/passive /norestart" -wait

        Execute-Process -Path "$dirFiles\Deploy\BootSetupPrerequisites\vcredist_64_2012\vcredist_x64.exe" -Parameters "/passive /norestart" -wait

        Execute-Process -Path "$dirFiles\Deploy\BootSetupPrerequisites\vcredist_86_2013\vcredist_x86.exe" -Parameters "/passive /norestart" -wait

        Execute-Process -Path "$dirFiles\Deploy\BootSetupPrerequisites\vcredist_64_2013\vcredist_x64.exe" -Parameters "/passive /norestart" -wait

        Start-sleep -s 10

        $checkforVC15x64 = Get-InstalledApplication -name "Microsoft visual c++ 2015-2019 Redistributable (x64)"
        if ($checkforVC15x64){
         # Do not install vcredist_x64_2019
        }
        Else {
         Execute-Process -Path "$dirFiles\Deploy\BootSetupPrerequisites\vcredist_64_2019\VCredist_x64.exe" -Parameters "/passive /norestart" -wait
        }

        Start-sleep -s 10

       $checkforVC15x86 = Get-InstalledApplication -name "Microsoft visual c++ 2015-2019 Redistributable (x86)"
        if ($checkforVC15x86){
         # Do not install vcredist_x86_2019
        }
        Else {
          Execute-Process -Path "$dirFiles\Deploy\BootSetupPrerequisites\vcredist_86_2019\VCredist_x86.exe" -Parameters "/passive /norestart" -wait
        }
        Refresh-Desktop

        
         
        $CHECKFORAPP2 = Get-InstalledApplication -Name "Microsoft SQL Server 2014"
        if($CHECKFORAPP2){
        # Do not install SQL Server 2014
        }
        else{
        Execute-Process -Path "$dirFiles\Deploy\BootSetupPrerequisites\SqlExpress2014\SQLEXPR2014_x86_ENU.EXE" -Parameters '/Q /ACTION="Install" /IACCEPTSQLSERVERLICENSETERMS /ROLE="AllFeatures_WithDefaults" /INSTANCEID="KBMSS14" /HELP="False" /INDICATEPROGRESS="True" /X86="True" /ERRORREPORTING="False" /SQMREPORTING="False" /INSTANCENAME="KBMSS14" /AGTSVCSTARTUPTYPE="Manual" /ISSVCSTARTUPTYPE="Automatic" /ISSVCACCOUNT="NT AUTHORITY\NetworkService" /ASSVCSTARTUPTYPE="Automatic" /SECURITYMODE="SQL" /ASDATADIR="Data" /ASLOGDIR="Log" /ASBACKUPDIR="Backup" /ASTEMPDIR="Temp" /ASCONFIGDIR="Config" /SQLSVCSTARTUPTYPE="Automatic" /FILESTREAMLEVEL="0" /ENABLERANU="True" /SQLSVCACCOUNT="NT AUTHORITY\NETWORK SERVICE" /ADDCURRENTUSERASSQLADMIN="True" /TCPENABLED="0" /NPENABLED="0" /BROWSERSVCSTARTUPTYPE="Disabled" /RSSVCSTARTUPTYPE="Automatic" /SECURITYMODE="SQL" /ERRORREPORTING="True" /UPDATEENABLED="False" /SAPWD="KBMsa64125#"' -Wait
        }

       
        Start-sleep -s 20

		##*===============================================
		##* INSTALLATION
		##*===============================================
		[string]$installPhase = 'Installation'

		
		## <Perform Installation tasks here>
		## Example command lines

        Execute-MSI -Action Install -Path 'Sentinel Protection Installer 7.6.9.msi'  -Parameters "/passive /norestart" 

        Execute-MSI -Action Install -Path 'VBAIntMSMSetup.msi'  -Parameters "/passive /norestart" 

        Execute-MSI -Action Install -Path 'Vba71.msi'  -Parameters "/passive /norestart"

        Execute-MSI -Action Install -Path 'Vba71_1033.msi'  -Parameters "/passive /norestart" 

        Execute-Process -Path 'ESPRIT Security Manager.exe' -Parameters '/S'
                        
        Execute-MSI -Action Install -Path 'NotificationManager.msi'  -Parameters "/passive /norestart" 

        Start-sleep -s 10
        Refresh-Desktop

		Execute-MSI -Action Install -Path 'Esprit.msi' -Transform 'ESprit_2021_China.mst' 

        Start-sleep -s 10

        Execute-MSI -Action Install -Path 'ESPRIT 2021 Accessories Pack.msi' -Parameters 'TARGETDIR="C:\Program Files (x86)\D.P.Technology\ESPRIT" /passive /norestart' 

        Execute-MSI -Action Install -Path 'SolidWorksFXAddIn_x64.msi' -Transform 'SolidWorksFXAddIn_x64.mst'
        Refresh-Desktop
        	

		
		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'

		## <Perform Post-Installation tasks here>

        Execute-MSI -Action Install -Path 'ESPRIT 2021 Accessories Pack.msi'

        Execute-MSI -Action Install -Path "$dirFiles\PostInstall\ESPRIT 2021 R1\ESPRIT for DMG MORI.msi"  -Parameters "/passive /norestart" 

             
       # Execute-Process -Path "$dirSupportFiles\ISSetupPrerequisites\{DA7AFFF7-054B-46CD-B660-F0E83F2DC985}\vcredist_x86.exe" -Parameters "/passive /q /norestart" -wait
        
        Start-sleep -s 5
		Execute-Process -path "$dirSupportFiles\setup.exe" -Parameters "/S /v/qn" -wait

        Execute-MSI -Action Install -Path "$dirFiles\PostInstall\ESPRIT Swagelok Custom Bore Add-In (E2021 R2)\ESPRIT Swagelok Custom Bore Add-In.msi"

        
        Execute-MSI -Action Install -Path "$dirFiles\PostInstall\EspritCAM_ECOP_11282021.msi"  -Parameters "/passive /norestart" 

        Copy-File -Path "$dirFiles\PostInstall\ECOP Addin\ECOP.bas" -Destination "C:\Program Files (x86)\D.P.Technology\ESPRIT\Data\KBM\VBModules"

        Write-log -Message "End...Importing ECOP.Bas after ECOP Addin Install." -LogType 'CMTrace'

        Copy-File -Path "$dirFiles\PostInstall\ECOP Addin\esprit.exe.config" -Destination "C:\Program Files (x86)\D.P.Technology\ESPRIT\Prog"

        Write-log -Message "End...Importing esprit.exe.config after ECOP Addin Install." -LogType 'CMTrace'

        start-process -Filepath 'C:\Program Files (x86)\D.P.Technology\ESPRIT\AddIns\ECOP\RegECOPIPE.bat'

       # Execute-Process -Path "$dirFiles\PostInstall\ECOP_Release_(ws-PROD)-(FULL)_(Esprit2020-without-supporting-E2020-libraries)_06.04.2020_10.02.05.exe" -Parameters "/VERYSILENT"
        
        Start-sleep -s 10
        Refresh-Desktop

        ######################### Copying .xml file to INSTALLDIR  #############################3##################

        Copy-File -Path "$dirFiles\PostInstall\configFile\China\DptSecConfigClient.xml" -Destination "C:\Program Files (x86)\D.P.Technology\Security\DPTechnology.SecSystem"
         

        Write-log -Message "Start...Importing the Registry 1  to UserHive." -LogType 'CMTrace'

         PowerShell.exe -File "$dirFiles\PostInstall\configFile\China\WriteToHkcuFromSystem.ps1" -RegFile "$dirFiles\PostInstall\configFile\China\Esprit_User_Lic.reg" –CurrentUser –AllUsers –DefaultProfile
     
        Write-log -Message "End...Importing the Registry 1  to UserHive." -LogType 'CMTrace'

       
        Start-sleep -s 10
        Refresh-Desktop


        
        #-------------------Fix for MoriSeikiMachineSetupChecker XML lookup Error--------------------------------------------------------------------------------------------------

        $TargetFolder = "C:\AddIns\MoriSeikiMachineSetupChecker"

        $DestFolder1 = "C:\Program Files (x86)\D.P.Technology\ESPRIT\AddIns\MoriSeikiMachineSetupChecker"

        $DestFolder2 = "C:\Program Files (x86)\D.P.Technology\ESPRIT\AddIns\MoriSeikiMachineSetupChecker\"


        If (!(Test-Path $DestFolder1)) {


                Write-log -Message "Start...Creating $DestFolder1 on the system to copy the files Recursively." -LogType 'CMTrace'


                new-item -Path $DestFolder1 -ItemType Directory -Force | Out-Null


                Write-log -Message "End...Creating $DestFolder1 on the system to copy the files Recursively." -LogType 'CMTrace'
           }

            Copy-Item -path "$TargetFolder\*" $DestFolder2 -Recurse -Force

            Write-log -Message "Coping of Files for MoriSeikiMachineSetupChecker Completed SUccessfully." -LogType 'CMTrace'

            Start-sleep -s 10
             #######################################################################################################################################################################################################################################



             Write-log -Message "Start...Adding the Firewall Rule on the system." -LogType 'CMTrace'

             netsh advfirewall firewall add rule name="Esprit MFC Application" dir=in action=allow program="C:\Program Files (x86)\D.P.Technology\ESPRIT\Prog\esprit.exe" enable=yes profile=domain


             Write-log -Message "End...Adding the Firewall Rule on the system." -LogType 'CMTrace'
             Write-log -Message "Successfull Installed  EspritCAM 2021." -LogType 'CMTrace'
             Start-sleep -s 10
             Refresh-Desktop

             

           #######################################################################################################################################################################################################################################





        #######################################################################################################################################################################################################################################



		## Display a message at the end of the install
		## None  If (-not $useDefaultMsi) { Show-InstallationPrompt -Message 'You can customize text to appear at the end of an install or remove it completely for unattended installations.' -ButtonRightText 'OK' -Icon Information -NoWait }
		
	}
	ElseIf ($deploymentType -ieq 'Uninstall')
	{
		##*===============================================
		##* PRE-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Uninstallation'

		## Show Welcome Message, close Internet Explorer or other apps with a 60 second countdown before automatically closing
		## None Show-InstallationWelcome -CloseApps 'iexplore' -CloseAppsCountdown 60

		## Show Progress Message (with the default message)
		## None Show-InstallationProgress

		## <Perform Pre-Uninstallation tasks here>
         Show-InstallationProgress -StatusMessage "Esprit 2021 products are getting Uninstalled from your computer. Please wait for the Uninstallation to complete"

           #enter names of any processes (without .exe) to terminate, comma delimited

         $processesToKill = @("esprit", "CustomSettingCaptionDesigner", "ESPRIT.KBMManager", "ESPRIT.NCEDIT", "DpTechnology.SecurityManager", "ESPRIT.SettingsManager")

             if ($processesToKill.Count -gt 0) 
         {
                        $allprocesses = Get-Process
            foreach ($proc in ($allprocesses | Where-Object {$processesToKill -contains $_.Name})) 
            {
        
            $proc | Stop-Process -Force

            }
        }
         Start-sleep -s 10
           
         Copy-File -Path "$dirFiles\PostInstall\configFile\ConfigurationFile.ini" -Destination "C:\Program Files (x86)\Microsoft SQL Server\120\Setup Bootstrap\SQLServer2014" 

         Execute-MSI -Action 'Uninstall' -Path '{020CDFE0-C127-4047-B571-37C82396B662}'

         Execute-MSI -Action 'Uninstall' -Path '{5474FDB3-9879-4A28-8518-9043294BC1E4}'

         Execute-MSI -Action 'Uninstall' -Path '{C6E88BEF-D9C5-4664-BCC0-02522D4C2998}'

         Execute-Process -Path "C:\Program Files (x86)\Microsoft SQL Server\120\Setup Bootstrap\SQLServer2014\setup.exe" -Parameters '/ConfigurationFile="C:\Program Files (x86)\Microsoft SQL Server\120\Setup Bootstrap\SQLServer2014\ConfigurationFile.ini"'

         Execute-MSI -Action 'Uninstall' -Path '{49D665A2-4C2A-476E-9AB8-FCC425F526FC}'

         Execute-MSI -Action 'Uninstall' -Path '{A106FA6F-E94C-44C9-8A0F-C34BD82C9FE6}'

         Start-sleep -s 10
         Refresh-Desktop

		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'

		## Handle Zero-Config MSI Uninstallations
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Uninstall'; Path = $defaultMsiFile }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat
		}

		# <Perform Uninstallation tasks here>

         Execute-MSI -Action 'Uninstall' -Path '{FF9C78D7-858D-4B49-A4B6-847638353AFE}'
          
         Execute-MSI -Action 'Uninstall' -Path '{ABBBAE74-401F-4ED6-B995-623C146C4FE3}'

         Execute-MSI -Action 'Uninstall' -Path '{90120000-0070-0000-0000-4000000FF1CE}'

         ## Execute-MSI -Action 'Uninstall' -Path '{90120000-0070-0000-0000-4000000FF1CE}'

         Execute-MSI -Action 'Uninstall' -Path '{BAB89D31-4C55-472B-8909-6CBE2CC276B1}'

         Execute-MSI -Action 'Uninstall' -Path '{B35FB4D0-070A-463B-9B0F-A48E255C217C}'
         
         Execute-Process -Path "C:\ProgramData\Package Cache\{7870e975-b79b-4826-837d-9b72002535f3}\ESPRIT Security Manager.exe" -Parameters "/Uninstall /S"

         Execute-MSI -Action 'Uninstall' -Path '{386D360D-C8E9-40D1-A647-4A3AC312B631}'

         Execute-MSI -Action 'Uninstall' -Path '{A2D1CB38-0453-4838-9C51-F2BC538C8D95}'

         Execute-MSI -Action 'Uninstall' -Path '{6B03A05B-C881-4CA9-B72B-1E42D53452AD}'

         # Execute-Process -Path "$dirSupportFiles\ISSetupPrerequisites\{DA7AFFF7-054B-46CD-B660-F0E83F2DC985}\vcredist_x86.exe" -Parameters "/passive /qu /norestart" -wait

         Execute-MSI -Action 'Uninstall' -Path '{A67A98E9-6C17-4211-B1AE-D446ED16F674}' #Custom Bore Addin#

         Execute-MSI -Action 'Uninstall' -Path '{96042A15-4E3E-4B2D-A9FB-A7AACEB07EDB}'
                  
         Execute-MSI -Action 'Uninstall' -Path '{E419312B-3E9A-45FC-975B-198EB2C00714}'

         # Execute-Process -Path "C:\Program Files (x86)\D.P.Technology\ESPRIT\AddIns\ECOP\unins000.exe" -Parameters "/SILENT"
         Write-log -Message "Successfull Uninstalled  EspritCAM 2021." -LogType 'CMTrace'
         Start-sleep -s 10
         Refresh-Desktop

        
		##*===============================================
		##* POST-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Uninstallation'

		## <Perform Post-Uninstallation tasks here>


	}
	ElseIf ($deploymentType -ieq 'Repair')
	{
		##*===============================================
		##* PRE-REPAIR
		##*===============================================
		[string]$installPhase = 'Pre-Repair'

		## Show Progress Message (with the default message)
		## None Show-InstallationProgress

		## <Perform Pre-Repair tasks here>

		##*===============================================
		##* REPAIR
		##*===============================================
		[string]$installPhase = 'Repair'

		## Handle Zero-Config MSI Repairs
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Repair'; Path = $defaultMsiFile; }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
		Execute-MSI @ExecuteDefaultMSISplat
		}
		# <Perform Repair tasks here>

		##*===============================================
		##* POST-REPAIR
		##*===============================================
		[string]$installPhase = 'Post-Repair'

		## <Perform Post-Repair tasks here>


    }
	##*===============================================
	##* END SCRIPT BODY
	##*===============================================

	## Call the Exit-Script function to perform final cleanup operations
	Exit-Script -ExitCode $mainExitCode
}
Catch {
	[int32]$mainExitCode = 60001
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
	Exit-Script -ExitCode $mainExitCode
}
