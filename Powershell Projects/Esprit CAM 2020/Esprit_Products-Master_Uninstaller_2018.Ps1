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
	[string]$appVendor = 'D.P Technologies'
	[string]$appName = 'EspritCam_2018_Uninstaller'
	[string]$appVersion = '2020(2018-Uninst)'
	[string]$appArch = 'x86/x64'
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '1.0.0'
	[string]$appScriptDate = '9/6/2020'
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
	[string]$deployAppScriptDate = '08/05/2020'
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
		Show-InstallationWelcome -CloseApps 'iexplore' -CheckDiskSpace -PersistPrompt
		
		
		## Show Progress Message (with the default message)
		## None Show-InstallationProgress

		## <Perform Pre-Installation tasks here>

        Show-InstallationProgress

        ######### Uninstall SQL server 2014 Components #####################
        
        #Execute-Process -Path "C:\Program Files (x86)\Microsoft SQL Server\120\Setup Bootstrap\SQLServer2014\setup.exe" -Parameters "/q /ACTION=UNINSTALL /FEATURES=SQL,AS,RS,IS,Tools /INSTANCENAME=MSSQLSERVER,KBMSS14" -Wait

        Execute-MSI -Action 'Uninstall' -Path "{79BF7CB8-1E09-489F-9547-DB3EE8EA3F16}"

        Execute-MSI -Action 'Uninstall' -Path "{49D665A2-4C2A-476E-9AB8-FCC425F526FC}"

        Execute-MSI -Action 'Uninstall' -Path "{53F5C3EE-05ED-4830-994B-50B2F0D50FCE}"

        Execute-MSI -Action 'Uninstall' -Path "{8F72E2D4-1E48-4534-8DB8-1E8E012899C6}"

        Execute-MSI -Action 'Uninstall' -Path "{68BA34E8-9B9D-4A74-83F0-7D366B532D75}"

        Execute-MSI -Action 'Uninstall' -Path "{E735E90E-FE0B-4B10-90D5-4AC6D3899BFD}"

        Execute-MSI -Action 'Uninstall' -Path "{1F9EB3B6-AED7-4AA7-B8F1-8E314B74B2A5}"


        ############################## ***Esprit Visual Basic Components Removal*** #########

        Execute-MSI -Action 'Uninstall' -Path "{90F50409-6000-11D3-8CFE-0150048383C9}"

        Execute-MSI -Action 'Uninstall' -Path "{90F60804-6000-11D3-8CFE-0150048383C9}"

        Execute-MSI -Action 'Uninstall' -Path "{90F60404-6000-11D3-8CFE-0150048383C9}"

        Execute-MSI -Action 'Uninstall' -Path "{90F60409-6000-11D3-8CFE-0150048383C9}"

        Execute-MSI -Action 'Uninstall' -Path "{90F60407-6000-11D3-8CFE-0150048383C9}"

        Execute-MSI -Action 'Uninstall' -Path "{90F60411-6000-11D3-8CFE-0150048383C9}"

        Execute-MSI -Action 'Uninstall' -Path "{90120000-0070-0000-0000-4000000FF1CE}"

        Execute-MSI -Action 'Uninstall' -Path "{D94034F0-CD98-4FDD-B1C1-0D71EA130DC9}"

        Execute-MSI -Action 'Uninstall' -Path "{A4C7F0E4-25D0-445F-B38F-CEFC952AC248}"

        Execute-MSI -Action 'Uninstall' -Path "{BAB89D31-4C55-472B-8909-6CBE2CC276B1}"

        Execute-MSI -Action 'Uninstall' -Path "{9EF200A3-1CAC-462E-990B-EC902279BAAA}"

        Execute-MSI -Action 'Uninstall' -Path "{B03BB003-A884-4487-8DAC-BEA9409C1C18}"

		##*===============================================
		##* INSTALLATION
		##*===============================================
		[string]$installPhase = 'Installation'

		
		## <Perform Installation tasks here>
		## Example command lines
		#Execute-MSI -Action Install -Path 'eDrawings.msi' -Transform 'eDrawings.mst'
		#Execute-Process -path "$dirFiles\64bit\sldim\sldim.exe" -Parameters "/adminclient /new /source `"$var1`" /norunsw /pushdeployment /skipcountdown" -wait
		

        ###########'***Esprit General Components Removal*** #######################
		Execute-MSI -Action 'Uninstall' -Path "{C238971D-5059-4B2F-B760-BB237AF4206A}"

        Execute-MSI -Action 'Uninstall' -Path "{26426BE5-B6CF-4474-A4C4-A85DCD10EB18}" ##'***Esprit 2016 Removal***##

        Execute-MSI -Action 'Uninstall' -Path "{BD3903F8-179C-48E2-BBD2-816570BAFA4E}"

        $CheckForProcessE = Get-Process -Name "esprit" -ErrorAction SilentlyContinue
        if($CheckForProcessE){
        Stop-Process -Name "esprit" -ErrorAction SilentlyContinue }
		Execute-MSI -Action 'Uninstall' -Path "{3DEA1F25-F509-4D5B-A899-DE8964FD7D9D}"
        
        $CheckForProcessD = Get-Process -Name "DpTechnology.SecurityManager" -ErrorAction SilentlyContinue
        if($CheckForProcessD){
        Stop-Process -Name "DpTechnology.SecurityManager" -ErrorAction SilentlyContinue}
        Execute-MSI -Action 'Uninstall' -Path "{83566275-6E03-4DF3-B064-2AEA8668BF47}"
        
        Execute-MSI -Action 'Uninstall' -Path "{CD888ADC-A959-4D49-B7D6-3C583406103A}"  ### '***Esprit 2017 Removal***###

        Execute-MSI -Action 'Uninstall' -Path "{48E0484B-96BE-4989-B0E5-49C7219960B3}"

        $CheckForProcessE1 = Get-Process -Name "esprit" -ErrorAction SilentlyContinue
        if($CheckForProcessE1){
        Stop-Process -Name "esprit" -ErrorAction SilentlyContinue }
        Execute-MSI -Action 'Uninstall' -Path "{2AEF76AA-8414-4A62-BD71-9F0FF9CE8E1E}"

        $CheckForProcessD1 = Get-Process -Name "DpTechnology.SecurityManager" -ErrorAction SilentlyContinue
        if($CheckForProcessD1){
        Stop-Process -Name "DpTechnology.SecurityManager" -ErrorAction SilentlyContinue}
        Execute-MSI -Action 'Uninstall' -Path "{2FD5868A-8451-47E3-A682-A7D7886121FE}"

        Execute-MSI -Action 'Uninstall' -Path "{07F98730-B945-4680-BD33-0F06FB9EC512}" ###'***Esprit 2018 Removal***###

        Execute-MSI -Action 'Uninstall' -Path "{75F0C429-EFEE-4228-A00F-FA95A579B769}"

        $CheckForProcessE2 = Get-Process -Name "esprit" -ErrorAction SilentlyContinue
        if($CheckForProcessE){
        Stop-Process -Name "esprit" -ErrorAction SilentlyContinue }
        Execute-MSI -Action 'Uninstall' -Path "{1E735D6F-9E1F-452D-96B2-02D7826A0646}"
       
        $CheckForProcessD2 = Get-Process -Name "DpTechnology.SecurityManager" -ErrorAction SilentlyContinue
        if($CheckForProcessD2){
        Stop-Process -Name "DpTechnology.SecurityManager" -ErrorAction SilentlyContinue}
        Execute-MSI -Action 'Uninstall' -Path "{E8AFBC07-5E77-4D40-AE24-D98730D9152A}"

		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'

		## <Perform Post-Installation tasks here>
        
        ####### '***Esprit Add-ins Removal*** #######

        Execute-MSI -Action 'Uninstall' -Path "{44AB55D0-C2A6-4B4C-AD85-A9D8DDBDAD79}"

        Execute-MSI -Action 'Uninstall' -Path "{AE8D4E0D-B4B6-423C-8BC5-680F6EB805B5}"

        Execute-MSI -Action 'Uninstall' -Path "{A67A98E9-6C17-4211-B1AE-D446ED16F674}"

        Execute-MSI -Action 'Uninstall' -Path "{EE8EA93E-7088-4B59-92FF-E6EB6178FA10}"

        $CHECKFORAPP = Get-InstalledApplication -Name "EspritCAM ETIME Add-in 08242018"
        If($CHECKFORAPP){
        #New-Item -Path "C:\Windows\Temp\APPLogs\EspritCam_2018_Uninstaller" -Name "Esprit_ETIME.LOG" -ItemType File -Force 
        Execute-Process -Path "C:\Windows\UNWISE.EXE" -Parameters "/S C:\Windows\Temp\Esprit_ETIME.LOG" }

        Execute-MSI -Action 'Uninstall' -Path "{44AB55D0-C2A6-4B4C-AD85-A9D8DDBDAD79}"

        Execute-MSI -Action 'Uninstall' -Path "{AE8D4E0D-B4B6-423C-8BC5-680F6EB805B5}"

        $CHECKFORAPP1 = Get-InstalledApplication -Name "VBAIntMSMSetup"
        If($CHECKFORAPP1){
        
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/X {ABBBAE74-401F-4ED6-B995-623C146C4FE3} /qn /L*v 'C:\Windows\Temp\APPLogs\EspritCam_2018_Uninstaller\VBAIntMSMSetup.LOG'"
        }


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
