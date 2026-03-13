function Test-ROConnection {
    <#
    .SYNOPSIS
        Test Secret Server authentication for a simulated user
    .DESCRIPTION
        Authenticates the specified user against Secret Server using their
        stored credentials, then disconnects. Returns a status object
        indicating success or failure. Requires SecretServerUrl to be
        configured.
    .PARAMETER Username
        Username of the simulated user to test.
    .EXAMPLE
        Test-ROConnection -Username 'svc.sim01'
    .EXAMPLE
        Get-ROUser | ForEach-Object { Test-ROConnection -Username $_.Username }
        Test all users.
    .OUTPUTS
        PSCustomObject with Username, BaseUrl, Status (Success/Failed), Message properties.
    .LINK
        Docs/commands/Test-ROConnection.md
    #>
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
