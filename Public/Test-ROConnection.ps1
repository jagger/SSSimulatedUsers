function Test-ROConnection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Username
    )

    $user = Get-ROUser -Username $Username
    if (-not $user) {
        Write-Error "User '$Username' not found in database."
        return
    }

    $baseUrl = Get-ROConfig -Key 'SecretServerUrl'
    if (-not $baseUrl) {
        Write-Error "SecretServerUrl not configured. Run Set-ROConfig -Key SecretServerUrl -Value 'https://...'"
        return
    }

    try {
        $session = Connect-ROSecretServer -BaseUrl $baseUrl -Username $user.Username -Password $user.Password -Domain $user.Domain
        Disconnect-ROSecretServer -Session $session

        [PSCustomObject]@{
            Username = $Username
            BaseUrl  = $baseUrl
            Status   = 'Success'
            Message  = "Authentication successful. Token expires at $($session.Expiry)"
        }
    }
    catch {
        [PSCustomObject]@{
            Username = $Username
            BaseUrl  = $baseUrl
            Status   = 'Failed'
            Message  = $_.Exception.Message
        }
    }
}
