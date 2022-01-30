#Parameterizing your Script
<##
 . The point of Adding [CmdletBinding()] in your parameterized script is the next click in Formalization; 
 . It really transfroms a function into a full cmdlet. 
 . A full cmdlet is a real deal, so when you hit Tab-Completion you'll a ton of extra variables that aren't defined here. 
 . When you put this [CmdletBinding()] in the top you are telling powershell engine, please do whole bunch of work for me. 
 . [CmdletBinding()] also ensures that the target values you are putting in the paramter values are valid and won't let you 
 . go crazy and do whole bunch of other unnecessary stuff. 
 . [CmdletBinding()] : Pretty much works like Gaurd Rails. 
##>
#Add the Param block

[CmdletBinding()]
param (
    [String]$ComputerName='Client',
    [String]$Drive='C:'
)

Get-WmiObject -class Win32_logicalDisk -Filter "DeviceID='$Drive'" -computerName $ComputerName
