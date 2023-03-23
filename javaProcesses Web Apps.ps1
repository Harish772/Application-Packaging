$javaProcesses = Get-Process -Name java | Select-Object -Property Id

foreach ($process in $javaProcesses) {
    $javaProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $javaProcessInfo.FileName = "cmd.exe"
    $javaProcessInfo.RedirectStandardInput = $true
    $javaProcessInfo.RedirectStandardOutput = $true
    $javaProcessInfo.UseShellExecute = false
    $javaProcessInfo.CreateNoWindow = true

    $javaProcess = New-Object System.Diagnostics.Process
    $javaProcess.StartInfo = $javaProcessInfo
    $javaProcess.Start()

    $javaProcess.StandardInput.WriteLine("wmic process where ProcessId=$($process.Id) get CommandLine")
    $javaProcess.StandardInput.WriteLine("exit")
    $output = $javaProcess.StandardOutput.ReadToEnd()
    $javaProcess.WaitForExit()

    $outputLines = $output.Split("`r`n") | Select-String "java.exe"
    $javaApp = $outputLines -replace ".*?java.exe", "java.exe"

    # Get the URL or application name by searching for specific patterns in the command line
    $urlRegex = "(http[s]?://[\w\.\-\_]+(:\d+)?(/[\w\.\-\_]+)*)"
    $appRegex = "(\-Dcatalina\.base=[\w\.\-\_\\\:\(\)]+\/?([\w\.\-\_]+)?)"

    if ($outputLines -match $urlRegex) {
        $url = $Matches[0]
        Write-Output "Java app $javaApp is being used by $url"
    } elseif ($outputLines -match $appRegex) {
        $appName = $Matches[2]
        Write-Output "Java app $javaApp is being used by $appName"
    } else {
        Write-Output "Java app $javaApp is running but no web application or URL found."
    }
}
