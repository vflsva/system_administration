# workstation management for the vfl

References for hot to use ansible to manage windows: 

- [Ansible Windows Guides](https://docs.ansible.com/ansible/latest/user_guide/windows.html)
- [A Step-by-Step Guide to Getting Started with Ansible on Windows](https://adamtheautomator.com/ansible-windows/)

- [devopssolver/ansible-winrm-cert-auth](https://github.com/devopssolver/ansible-winrm-cert-auth)

- [setup winrm](https://docs.ansible.com/ansible/latest/user_guide/windows_setup.html#winrm-setup)
- [How to Configure WinRM over HTTPS for Ansible](https://adamtheautomator.com/ansible-winrm/)
- [Ansible Windows Management using HTTPS and SSL](https://www.techbeatly.com/ansible-windows-management-using-https-and-ssl/)
- [Setup WinRM for Ansible with Certificate Authentication in 8 Easy Steps (youtube)](https://www.youtube.com/watch?v=vcx0bIgGJXI)

## general overview

The workstation computers at the vfl are desktop computers (from boxx) running Windows 10. There are 4 computers (see breakdown below): two general workstations, one render workstation, and one VR workstation. 

To manage the computers (permissions, updates, etc.) I use [ansible](https://www.ansible.com/). 

The process to setup a windows machine for management by ansible requires a bunch of steps. The idea is to only do this once on one new windows machine, then make a system image of the computer, which then can be used for any new machines. The new machines then can all be managed and maintained via ansible.

I have included all the code necessary to do this setup in this readme. The scripts are meant to be run in a *nix shell (bash, zsh) or powershell. I have also created scripts that can be used. They can be found in this repo under `ansible_control_host/` and `windows_host/`. Please run scripts from the root of this repo (relative paths in scripts assume this).

## initial setup 

Process for computer with new install of windows 10.

### 1) windows desktop setup

Before ansible can manage a windows machine, some initial setup is required.

Setup station and turn computer on. Follows steps for windows setup. The following are the configuration options I used (in January 2022):

a) *setup for personal use*

- "Offline account"
- "Limited experience"
- create user
  - user: `SysAdmin`
  - password: see VFL account info spreadsheet for current SysAdmin password
- security questions
  - use security questions answers for vflinfo@sva.edu (see VFL account info spreadsheet)
  - What is the name of your first pet?
  - What's the name of the city where you were born?
  - What's the name of the first school you attended?

b) *Choose privacy settings for your device*
  
  - disable all (toggle no)

c) *Let's customize your experience*

- "Skip"
  
d) *Let Cortana help you get things done*

- "Not now"

e) *We reccomend Windows 11 for your device*

- "Decline upgrade"
  
f) *Not sure about Windows 11*
  
- "Skip for now"

### 2) setup ansible control host

These steps are to be on on the __ansible control host__. The ansible control host is the computer which has ansible installed (laptop, server, etc.) that will manage the hosts. My control host is my macbook. I used homebrew to install ansible: `brew install ansible`.

Do this before continuing to setup the windows host. The windows host requires certs generated on the ansible control host.

I have configured ansible to connect to the host machines over HTTPS. Although this may be a bit excessive given the network and computer setup in the lab, it is a best practice not to transmit unencrypted credentials. 

*a) generate the ssl cert*

The cert generate will be valid for 10 years. 

```bash
# generate ssl certs for use with ansible 
# (run on ansible control host)

# set username (one to be used on windows host)
set WINUSERNAME="ansible"

# create openssl.conf 
cat > openssl.conf << EOL
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req_client]
extendedKeyUsage = clientAuth
subjectAltName = otherName:1.3.6.1.4.1.311.20.2.3;UTF8:$WINUSERNAME@localhost
EOL

# set config file for openssl
export OPENSSL_CONF=openssl.conf

# create cert
 openssl req -x509 -nodes \
    -days 3650 -newkey rsa:2048 \
    -out ansible_cert.pem \
    -outform PEM \
    -keyout ansible_cert_key.pem \
    -subj "/CN=$WINUSERNAME" \
    -extensions \
    v3_req_client
```

Move a copy of `ansible_cert.pem` and `ansible_cert_key.pem` to the windows host. The script expects the location of the certs to be in the directory: `certs/`

### 2) allow scripts in powershell

If using scripts, enable powershell to run them.

a) open powershell (run as administrator)
b) allow scripts to be run: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`
c) enable: `Y` (yes)

### 3) import certs (from ansible control host) on windows host

```powershell
# import certs to the certificate store in windows
# (run on windows host)

# path to the genereated client cert
$pubKeyFilePath = 'certs\cert.pem'

# import the public key into trusted root certification authorities and trusted people
$null = Import-Certificate -FilePath $pubKeyFilePath -CertStoreLocation 'Cert:\LocalMachine\Root'
$null = Import-Certificate -FilePath $pubKeyFilePath -CertStoreLocation 'Cert:\LocalMachine\TrustedPeople'
```

### 4) setup ansible user on windows host

NOTE: This script prompts for a new password. Please see the VFL account info spreadsheet for the current ansible user password

```powershell
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
```

### 5) install winrm 

```powershell
# install winrm and set to automatic boot
# (run on windows host)

Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$url = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
$file = "$env:temp\ConfigureRemotingForAnsible.ps1"

(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)

powershell.exe -ExecutionPolicy ByPass -File $file

# start the winrm service and enable automatic boot
Set-Service -Name "WinRM" -StartupType Automatic
Start-Service -Name "WinRM"

# ensure powershell remoting is enabled
if (-not (Get-PSSessionConfiguration) -or (-not (Get-ChildItem WSMan:\localhost\Listener))) {
    Enable-PSRemoting -SkipNetworkProfileCheck -Force
}
```

### 6) create winrm https listener

```powershell
# create winrm https listener
# (run on windows host)
# WARN: will delete and recreate the winrm https listener 

# get the current Hostname
$hostname = hostname

# generate the server cert
$serverCert = New-SelfSignedCertificate -DnsName $hostname -CertStoreLocation 'Cert:\LocalMachine\My'

# find active https listners
$httpsListeners = Get-ChildItem -Path WSMan:\localhost\Listener\ | where-object { $_.Keys -match 'Transport=HTTPS' }

# remove active https listners
if ($httpsListeners){
    $selectorset = @{
        Address = "*"
        Transport = "HTTPS"
    }
    Remove-WSManInstance -ResourceURI 'winrm/config/Listener' -SelectorSet $selectorset
}

# create new https listener
$newWsmanParams = @{
    ResourceUri = 'winrm/config/Listener'
    SelectorSet = @{ Transport = "HTTPS"; Address = "*" }
    ValueSet    = @{ Hostname = $hostName; CertificateThumbprint = $serverCert.Thumbprint }
}
$null = New-WSManInstance @newWsmanParams

# set to certificate authentication
winrm set WinRM/Config/Client/Auth '@{Basic="false";Digest="false";Kerberos="false";Negotiate="true";Certificate="true";CredSSP="false"}'

# enable winrm service certificate auth
Set-Item -Path WSMan:\localhost\Service\Auth\Certificate -Value $true
```

### 7) create winrm https listener

```powershell
# open firewall for winrm https
# (run on windows host)

# open port 5986 in the firewall
$ruleDisplayName = 'Windows Remote Management (HTTPS-In)'
if (-not (Get-NetFirewallRule -DisplayName $ruleDisplayName -ErrorAction Ignore)) {
    $newRuleParams = @{
        DisplayName   = $ruleDisplayName
        Direction     = 'Inbound'
        LocalPort     = 5986
        RemoteAddress = 'Any'
        Protocol      = 'TCP'
        Action        = 'Allow'
        Enabled       = 'True'
        Group         = 'Windows Remote Management'
    }
    $null = New-NetFirewallRule @newRuleParams
}
```




