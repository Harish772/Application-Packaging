<#
. Jefrey's Explination: CMDLETS have deault builtin ImapctLEVELS. Meaning if you are going to Reboot the machine = High Impact, If you are about to Delete a User Profile = High Imapct, If you are to Kill a Process= Medium Impact. etc., 
. Then you've the variables for these CMDLETS based on Imapct Level asking the parser hey what should I do? if I have these high Impact, Medium Impact etc., like should I COnfirm? 
.Values for Impact Level are Low, Medium and High
. WhatIfPreference is set to $false by default. If you change it to $True, then all commands that support -Whatif whill run as if whatif has been specified. 
. $confirmPrefrence is set to High by default. If the command impact level is equal to or higher than the preferece, then -confirm is automatically added. 
#>
Function Set-stuff {

    [cmdletbinding(SupportshouldProcess=$true,
                   ConfirmImpact='Medium')]
    param(
        [Parameter(Mandatory=$True)]
        [String]$computerName
    
    )
    Process {
    If($PSCmdlet.ShouldProcess("$computerName")){
        Write-Output 'Im changing something Right Now'
     }
        
   }
   

}