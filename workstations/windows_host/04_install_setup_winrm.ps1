# install winrm and set to automatic boot
# (run on windows host)

Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$url = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
$file = "$env:temp\ConfigureRemotingForAnsible.ps1"

(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)

powershell.exe -ExecutionPolicy ByPass -File $file

# Start the winrm service and enable automatic boot
Set-Service -Name "WinRM" -StartupType Automatic
Start-Service -Name "WinRM"

# ensure powershell remoting is enabled
if (-not (Get-PSSessionConfiguration) -or (-not (Get-ChildItem WSMan:\localhost\Listener))) {
    Enable-PSRemoting -SkipNetworkProfileCheck -Force
}

Write-Output "created new user: $ansibleUsername"
Write-Output ""