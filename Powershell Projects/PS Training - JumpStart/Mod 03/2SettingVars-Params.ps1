#Parameterization of a script varibles

#Sometimes Param is alos seen as Arg(0), Arg(1), so don't get confused. 

param (
    [String]$ComputerName= 'Client',
    [String]$Drive='C:'
)
Get-WmiObject -class Win32_logicalDisk -Filter "DeviceID='$Drive'" -computerName $ComputerName