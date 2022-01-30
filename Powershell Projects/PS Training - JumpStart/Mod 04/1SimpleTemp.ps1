<#
    Comment based help
#>
#Below Funtion is part of Template 
function Verb-Noun {

    [CmdletBinding()]
    param (
        [Parameter()][String]$MyString,
        [Parameter()][Int]$MyInt
    )
    
    Begin{<#Code#>}
    Process{<#Code#>}
    End{<#Code#>}


}

#Below is the example from Jeffrey; 
# The Process block is Not Parallel. In Java all the Processes are thread safe. but in .Net the Objects are not Threadsafe . 
# the User/Caller/Scripter always is responsible for handling the Thread Concurency Control and where do the Lacking itself 


function Verb-Noun {

    [CmdletBinding()]
    param (
        [Parameter(ValuefromPipeline = $true)] 
        [Int]$x
    )
    
    Begin{<#Code#> $total=0}
    Process{<#Code#> $total += $x}
    End{<#Code#> "Total = $total"}


}

#Begin is for gahering your tools connections and setting up the floor 
#Process is everything is getting piped to it and does all your prcocesses in here in this block
#End is for ending it properly 