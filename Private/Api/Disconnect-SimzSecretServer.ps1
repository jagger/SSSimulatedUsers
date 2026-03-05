function Disconnect-SimzSecretServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        Invoke-SimzApi -Session $Session -Endpoint 'oauth-expiration' -Method POST | Out-Null
        Write-SimzLog -Message "Disconnected '$($Session.Username)'" -Level DEBUG -Component 'API'
    }
    catch {
        Write-SimzLog -Message "Disconnect failed for '$($Session.Username)' (non-fatal): $_" -Level WARN -Component 'API'
    }
}
