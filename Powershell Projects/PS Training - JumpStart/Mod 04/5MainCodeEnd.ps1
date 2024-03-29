
function Get-CompInfo{
    [CmdletBinding()]
    param (
        #Want to support multiple computers
        [string[]]$ComputerName,
        #Switch to run on Error Logging
        [Switch]$ErrorLog,
        [String]$LogFile = 'c:\errorlog.txt'  
    )
    begin {
        if($ErrorLog){
                Write-Verbose 'Error logging turned on'
            } else {
                Write-Verbose 'Error logging turned off'
            }
            foreach($Computer in $ComputerName){
                Write-Verbose "Computer: $Computer"
             }
    }
    process {     
        foreach($Computer in $ComputerName){
            $os=Get-Wmiobject -ComputerName $Computer -Class Win32_OperatingSystem
            $Disk=Get-WmiObject -ComputerName $Computer -class Win32_LogicalDisk -filter "DeviceID='c:'"

            #Hash Tables are well known to provide the output not in an Ordered fashion. that is why [ordered] needs to be added - Literal Hash
            
            $Prop=[ordered]@{
                'ComputerName'=$Computer;
                'OS Name'=$os.caption;
                'OS Build'=$os.buildnumbre;
                'FreeSpace'=$Disk.FreeSpace / 1gb -as [int]
            }
        #This doesn't produce objects yet - just for testing
        Write-output $Prop
        }
    }
    end {        
    }
}