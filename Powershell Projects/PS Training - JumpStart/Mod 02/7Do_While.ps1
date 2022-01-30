# Do loop
$i= 1
Do {
    write-output "powershell is Great! $i"
    #Each time your script enters into the Loop it's value gets increamentd by 1 while exiting the loop $i=$i+1
    #$i=$i+1 

     #$i+2 -------> This will take you into an Infinite loop so the correct way of writing it would be $i+=2
     $i+= 2
} while ( $i -le 5) #Also DO-Until 

# While Loop 
$i=5 
While ($i -ge 1) {
    Write-output "scripting is great! $i"
    #Each time your script enters into the Loop it's value gets decreamentd by 1 while exiting the loop 

    $i--
}
