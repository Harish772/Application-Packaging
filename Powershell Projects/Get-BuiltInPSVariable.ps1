#With PSversion 5 you can eliminate this function and use: 
    #get-childitem variable:

function Get-BuiltInPSVariable($Name='*')
{
  # create a new PowerShell
  $ps = [PowerShell]::Create()
  # get all variables inside of it
  $null = $ps.AddScript('$null=$host;Get-Variable') 
  $ps.Invoke() |
    Where-Object Name -like $Name
  # dispose new PowerShell
  $ps.Runspace.Close()
  $ps.Dispose()
}
Get-BuiltInPSVariable($Name='*')