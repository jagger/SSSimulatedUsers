function Test-SimzConnection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Username
    )

    $user = Get-SimzUser -Username $Username
    if (-not $user) {
        Write-Error "User '$Username' not found in database."
        return
    }

    $baseUrl = Get-SimzConfig -Key 'SecretServerUrl'
    if (-not $baseUrl) {
        Write-Error "SecretServerUrl not configured. Run Set-SimzConfig -Key SecretServerUrl -Value 'https://...'"
        return
    }

    try {
        $session = Connect-SecretServer -BaseUrl $baseUrl -Username $user.Username -Password $user.Password -Domain $user.Domain
        Disconnect-SecretServer -Session $session

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
