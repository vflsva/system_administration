# make a new user for ansible and map to certificate to it
# (run on windows host)

# ref:
#   a) https://github1s.com/devopssolver/ansible-winrm-cert-auth/blob/HEAD/windows_host/create_ansible_user.ps1
#   b) https://adamtheautomator.com/ansible-winrm/

# create new user for ansible
$ansibleUsername = 'ansible'
$ansiblePassword = (Read-Host "enter new password for user: $ansibleUsername" -AsSecureString)

if (-not (Get-LocalUser -Name $ansibleUsername -ErrorAction Ignore)) {
    $newUserParams = @{
        Name                 = $ansibleUsername
        AccountNeverExpires  = $true
        PasswordNeverExpires = $true
        Password             = $ansiblePassword
    }
    $null = New-LocalUser @newUserParams
}

# add new user to the administrator's group
Get-LocalUser -Name $ansibleUsername | Add-LocalGroupMember -Group 'Administrators'

# allow winrm with user account control (uac)
$newItemParams = @{
    Path         = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
    Name         = 'LocalAccountTokenFilterPolicy'
    Value        = 1
    PropertyType = 'DWORD'
    Force        = $true
}
$null = New-ItemProperty @newItemParams

# map generated certificates to the ansible runner
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ansibleUsername, $ansiblePassword

# find the cert thumbprint for the client certificate created on the ansible host
$ansibleCert = Get-ChildItem -Path 'Cert:\LocalMachine\Root' | Where-Object {$_.Subject -eq "CN=$ansibleUsername"}

$params = @{
	Path = 'WSMan:\localhost\ClientCertificate'
	Subject = "$ansibleUsername@localhost"
	URI = '*'
	Issuer = $ansibleCert.Thumbprint
    Credential = $credential
	Force = $true
}
New-Item @params

Write-Output "created new user: $ansibleUsername"
Write-Output ""