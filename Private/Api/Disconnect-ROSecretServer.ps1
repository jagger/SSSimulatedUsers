function Disconnect-ROSecretServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        Invoke-ROApi -Session $Session -Endpoint 'oauth-expiration' -Method POST | Out-Null
        Write-ROLog -Message "Disconnected '$($Session.Username)'" -Level DEBUG -Component 'API'
    }
    catch {
        Write-ROLog -Message "Disconnect failed for '$($Session.Username)' (non-fatal): $_" -Level WARN -Component 'API'
    }
}
