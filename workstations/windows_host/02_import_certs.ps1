# import certs to the certificate store in windows
# (run on windows host)

# path to the genereated client cert
$pubKeyFilePath = 'certs\ansible_cert.pem'

# import the public key into trusted root certification authorities and trusted people
$null = Import-Certificate -FilePath $pubKeyFilePath -CertStoreLocation 'Cert:\LocalMachine\Root'
$null = Import-Certificate -FilePath $pubKeyFilePath -CertStoreLocation 'Cert:\LocalMachine\TrustedPeople'

Write-Output "added public key: $pubKeyFilePath"
Write-Output ""