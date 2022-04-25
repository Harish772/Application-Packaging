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
	[string]$appVendor = 'PTC'
	[string]$appName = 'MathCAD Prime'
	[string]$appVersion = '7.0.0.0'
	[string]$appArch = 'x64'
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '1.0.0'
	[string]$appScriptDate = '1/14/2022'
	[string]$appScriptAuthor = 'Harish Kakarla'
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
	[version]$deployAppScriptVersion = [version]'3.8.4'
	[string]$deployAppScriptDate = '26/01/2021'
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

		## Show Welcome Message, close Internet Explorer if required, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt
		#Show-InstallationWelcome -CloseApps 'iexplore' -AllowDefer -DeferTimes 3 -CheckDiskSpace -PersistPrompt

		## Show Progress Message (with the default message)
		Show-InstallationProgress -StatusMessage 'Previous version of MathCAD Prime is Uninstalling, please wait....'

		## <Perform Pre-Installation tasks here>
         
         #### App 1 uninstallation #####
         
         $Proc2Kill = Get-Process -Name "mathcad" -ErrorAction SilentlyContinue
         If($Proc2Kill){
         Stop-Process -Name "mathcad" -Force -ErrorAction SilentlyContinue
         }

         Execute-MSI -Action 'Uninstall' -Path "{8FD0167F-A752-467A-86BE-3728D71F68B8}" -Parameters "/QN"

         $Folder2Del = Test-Path -Path "$envProgramData\Microsoft\Windows\Start Menu\Programs\Mathcad"
         If($Folder2Del){
         Remove-Item -Path "$envProgramData\Microsoft\Windows\Start Menu\Programs\Mathcad" -Recurse -Force
         }

         #### App 2 uninstallation #####
         
         $Proc2Kill2 = Get-Process -Name "MathcadPrime" -ErrorAction SilentlyContinue
         If($Proc2Kill2){
         Stop-Process -Name "MathcadPrime" -Force -ErrorAction SilentlyContinue
         }

         Execute-MSI -Action 'Uninstall' -Path "{A52BF788-47BD-48E4-975A-AE5F107D559E}" -Parameters "/QN"

         

         #### App 3 uninstallation #####
         
         $Proc2Kill3 = Get-Process -Name "acrodist" -ErrorAction SilentlyContinue
         If($Proc2Kill3){
         Stop-Process -Name "acrodist" -Force -ErrorAction SilentlyContinue
         }

         Execute-MSI -Action 'Uninstall' -Path "{AC76D478-1033-0000-3478-000000000004}" -Parameters "/QN"

         $Folder2Del2 = Test-Path -Path "$envProgramFiles\Adobe\Acrobat 9.0"
         If($Folder2Del2){
         Remove-Item -Path "$envProgramFiles\Adobe\Acrobat 9.0" -Recurse -Force
         }

         #### App 4 uninstallation #####
         
         $Proc2Kill4 = Get-Process -Name "NSEXSetup" -ErrorAction SilentlyContinue
         If($Proc2Kill4){
         Stop-Process -Name "NSEXSetup" -Force -ErrorAction SilentlyContinue
         }

         Execute-MSI -Action 'Uninstall' -Path "{A9FAD2D5-1C42-4C5C-B5DD-291DA9863BEA}" -Parameters "/QN"

        
         #### App 5 uninstallation #####
         
         $Proc2Kill5 = Get-Process -Name "MathcadPrime" -ErrorAction SilentlyContinue
         If($Proc2Kill5){
         Stop-Process -Name "MathcadPrime" -Force -ErrorAction SilentlyContinue
         }

         Execute-MSI -Action 'Uninstall' -Path "{2BCBC575-8A52-401B-BE39-DCCA97470D3A}" -Parameters "/QN"

         
         #### App 6 uninstallation #####
         
         Execute-MSI -Action 'Uninstall' -Path "{7FF72FA4-BC28-46BA-B8D7-D9940E02801A}" -Parameters "/QN"


		##*===============================================
		##* INSTALLATION
		##*===============================================
		[string]$installPhase = 'Installation'

		## Handle Zero-Config MSI Installations
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Install'; Path = $defaultMsiFile }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat; If ($defaultMspFiles) { $defaultMspFiles | ForEach-Object { Execute-MSI -Action 'Patch' -Path $_ } }
		}

		## <Perform Installation tasks here>

        Show-InstallationProgress -StatusMessage 'PTC MathCAD Prime 7.0.0 is installing on your computer, please wait....'

        Execute-MSI -Action 'Install' -Path "$dirFiles\Source\ptcsh0\PrimeWixInstaller_64bit.msi" -Parameters 'LICENSEPATHFORM="ServerAndPort" LICENSEPATH="7788@IS1LIC04" REBOOT=ReallySuppress ALLUSERS=1 /QN'

        Start-Sleep -Seconds 3
        Refresh-Desktop

        ### Removing Desktop Shortcut #####
        Remove-Item -Path "$envSystemDrive\Users\Public\Desktop\PTC Mathcad Prime 7.0.0.0.lnk" -Recurse -Force

        Execute-MSI -Action 'Install' -Path "$dirFiles\Source\install\addon\qualityagent_64.msi" -Parameters "/QN"
        Start-Sleep -Seconds 3
        Refresh-Desktop

		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'

		## <Perform Post-Installation tasks here>

		## Display a message at the end of the install
		##sIf (-not $useDefaultMsi) { Show-InstallationPrompt -Message 'You can customize text to appear at the end of an install or remove it completely for unattended installations.' -ButtonRightText 'OK' -Icon Information -NoWait }
	}
	ElseIf ($deploymentType -ieq 'Uninstall')
	{
		##*===============================================
		##* PRE-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Uninstallation'

		## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing
		#Show-InstallationWelcome -CloseApps 'iexplore' -CloseAppsCountdown 60

		## Show Progress Message (with the default message)
		Show-InstallationProgress -StatusMessage 'PTC MathCAD Prime 7.0.0 is uninstalling from your computer, please wait....'

		## <Perform Pre-Uninstallation tasks here>


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
        
         $ProcessStop1 = Get-Process -Name "mathcad" -ErrorAction SilentlyContinue
         If($ProcessStop1){
         Stop-Process -Name "mathcad" -Force -ErrorAction SilentlyContinue
         }
         
         $ProcessStop2 = Get-Process -Name "MathcadPrime" -ErrorAction SilentlyContinue
         If($ProcessStop2){
         Stop-Process -Name "MathcadPrime" -Force -ErrorAction SilentlyContinue
         }
         
         $ProcessStop3 = Get-Process -Name "acrodist" -ErrorAction SilentlyContinue
         If($ProcessStop3){
         Stop-Process -Name "acrodist" -Force -ErrorAction SilentlyContinue
         }
         
         $ProcessStop4 = Get-Process -Name "NSEXSetup" -ErrorAction SilentlyContinue
         If($ProcessStop4){
         Stop-Process -Name "NSEXSetup" -Force -ErrorAction SilentlyContinue
         }

         
         $ProcessStop5 = Get-Process -Name "MathcadPrime" -ErrorAction SilentlyContinue
         If($ProcessStop5){
         Stop-Process -Name "MathcadPrime" -Force -ErrorAction SilentlyContinue
         }

         Execute-MSI -Action 'Uninstall' -Path "{D58BBD10-9F37-4A3C-86B7-CBB35230522E}" -Parameters "/QN"
         Start-Sleep -Seconds 3
         Refresh-Desktop

         Execute-MSI -Action 'Uninstall' -Path "{649E4386-2691-42CB-9D6F-21E3E67E7F0B}" -Parameters "/QN"

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
		Show-InstallationProgress

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
