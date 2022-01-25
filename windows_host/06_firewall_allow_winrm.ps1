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
