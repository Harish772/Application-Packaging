$computer = 'NotOnline'


Try{
       $OS = Get-WmiObject -ComputerName $computer -Class Win32_opertatingSystem `
       -ErrorAction Stop -ErrorVariable currenterror

}


Catch{
    Write-Warning "You've done made a boo-boo with computer $computer"

}