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

    Write-Output $javaApp
}
