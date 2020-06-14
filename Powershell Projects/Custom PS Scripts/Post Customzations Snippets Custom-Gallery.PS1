#Delete Start Menu Shortcut If Exists
$sh1 = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\TIMET Business Apps\SAP Logon.lnk"

if((Test-Path $sh1)) {
Remove-Item $sh1 -Recurse -Force -ErrorAction silentlycontinue
Write-Log ("Removed the Empty SAP Logon SHortcut from StartMenu")
}
#Delete Start Menu Shortcut If Exists
$sh2 = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\TIMET Business Apps\SAP Front End\SAP Logon.lnk"
if((Test-Path $sh2)) {
Remove-Item $sh2 -Recurse -Force -ErrorAction silentlycontinue
Write-Log ("Removed the Empty SAP Front end - Logon SHortcut from StartMenu")
}

#Delete Start Menu Shortcut If Exists
$sh3 = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\TIMET Business Apps\SAP Front End\SAP GUI Configuration.lnk"
if((Test-Path $sh3)) {
Remove-Item $sh3 -Recurse -Force -ErrorAction silentlycontinue
Write-Log ("Removed the Empty SAP GUI SHortcut from StartMenu")
}

#Delete Desktop Shortcut If Exists
$sh4 = "C:\Users\Public\Desktop\SAP Logon.lnk"
if((Test-Path $sh4)) {
Remove-Item $sh4 -Recurse -Force -ErrorAction silentlycontinue
Write-Log ("Removed the Empty Desktop SAP Logon SHortcut from StartMenu")
Write-Log ("End of Script - Application Uninstalltion completed with Post Configurations")
}

######### Start Post Configurations#################
######### Copy Files from Current Directory to SOme path (saplogon.ini)#################
Write-Log ("Copying saplogon.ini")
Copy-Item -path "$scriptpath\SAP\4.SAP Config\saplogon.ini" $path2 -Force
Write-Log ("Copied saplogon.ini")

Write-Log ("Copying sapmsg.ini")
Copy-Item -path "$scriptpath\SAP\4.SAP Config\sapmsg.ini" $path2 -Force
Write-Log ("Copied saplogon.ini")

Write-Log ("Copying Services")
Copy-Item -path "$scriptpath\SAP\4.SAP Config\services" $path3 -Force
Write-Log ("Copied services")

#Creating an Environment Vairable by writing a value to Registry

Write-Log ("Retriving the Environment Variable")
$regkeypath= "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" 
$value1 = (Get-ItemProperty $regkeypath).SAPLOGON_INI_FILE -eq $null 
If ($value1 -eq $False) {Remove-ItemProperty -path $regkeypath -name SAPLOGON_INI_FILE} 
Else {Write-Host "The value does not exist"}
Write-Log ("Deleted if Value exists")
Write-Log ("Creating a New Environment Variable")
Set-ItemProperty -Path $regkeypath -Name SAPLOGON_INI_FILE -Value "C:\Windows\saplogon.ini" -Type string
Write-Log ("Created a New Environment Variable")


# Create a Primary subkey Key under Main Key 
New-Item -Path HKLM:\SOFTWARE\WOW6432Node\CData\RegInfo -Force
# Create the Key properties 
New-ItemProperty -Path HKLM:\SOFTWARE\WOW6432Node\CData\RegInfo -Name email -PropertyType String -Value tuser4@Domain.com -Force
New-ItemProperty -Path HKLM:\SOFTWARE\WOW6432Node\CData\RegInfo -Name name -PropertyType String -Value tuser -Force
New-ItemProperty -Path HKLM:\SOFTWARE\WOW6432Node\CData\RegInfo -Name canemail -PropertyType String -Value 0 -Force
New-ItemProperty -Path HKLM:\SOFTWARE\WOW6432Node\CData\RegInfo -Name uid -PropertyType String -Value 153237635 -Force


#Delete Desktop Shortcut
$folder = "C:\Users\Public\Desktop\Tableau 2018.1.lnk"
Remove-Item $folder -Recurse -Force -ErrorAction silentlycontinue

# The script appends to the existing Services File for SAP Buisness Analysis to Connect to the BA Server. 

$file = "$env:windir\System32\drivers\etc\services"
"sapmsXYAX2        3681/tcp     # SAP System Message Server Port" | Add-Content -PassThru $file
"sapmsAQSD1        3631/tcp     # SAP System Message Server Port" | Add-Content -PassThru $file
"sapmZXSA1        3611/tcp     # SAP System Message Server Port" | Add-Content -PassThru $file
