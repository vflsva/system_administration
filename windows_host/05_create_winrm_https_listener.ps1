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