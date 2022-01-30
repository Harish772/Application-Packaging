<# Whenever a Powershell Command encounter a Non-Terminating Error, it checks a Buiiltin Variable = $ErrorActionPreference 

    -Contiune: This is the Default. It Displays error and keeps Running 
    -SilentlyContinue: Keeps Running in the backend but doesnot display error
    -Stop: Displays error and stops further execution
    -Inquire: Prompts you for the next action 
-EV = ErrorVariable 

#>
$ErrorActionPreference

Get-WmiObject win32_bios -ComputerNAme DC,NotOnline,Client

Get-WmiObject win32_bios -ComputerNAme DC,NotOnline,Client -EA SilentlyContinue -EV MyError $MyError

Get-WmiObject win32_bios -ComputerNAme DC,NotOnline,Client -EA Stop

Get-WmiObject win32_bios -ComputerNAme DC,NotOnline,Client -EA Inquire

