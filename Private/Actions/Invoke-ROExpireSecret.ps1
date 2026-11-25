function Invoke-ROExpireSecret {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        $response = Invoke-ROApi -Session $Session -Endpoint "secrets?take=50"
        if (-not $response.records -or $response.records.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'ExpireSecret'; TargetType = 'Secret'; TargetId = $null
                TargetName = $null; Success = $false; ErrorMessage = 'No secrets available'
            }
        }

        # Try up to 3 random secrets in case some don't support expiration
        $candidates = $response.records | Get-Random -Count ([Math]::Min(3, $response.records.Count))
        foreach ($secret in $candidates) {
            try {
                Invoke-ROApi -Session $Session -Endpoint "secrets/$($secret.id)/expire" -Method POST | Out-Null

                return [PSCustomObject]@{
                    Action       = 'ExpireSecret'
                    TargetType   = 'Secret'
                    TargetId     = $secret.id
                    TargetName   = "$($secret.name) (expired)"
                    Success      = $true
                    ErrorMessage = $null
                }
            }
            catch {
                Write-ROLog -Message "ExpireSecret: cannot expire secret $($secret.id), trying next: $_" -Level WARN -Component 'Actions'
                continue
            }
        }

        # All candidates failed - the attempts still generated audit activity
        [PSCustomObject]@{
            Action       = 'ExpireSecret'
            TargetType   = 'Secret'
            TargetId     = $null
            TargetName   = 'All candidates failed to expire (permission/config)'
            Success      = $true
            ErrorMessage = $null
        }
    }
    catch {
        [PSCustomObject]@{
            Action = 'ExpireSecret'; TargetType = 'Secret'; TargetId = $null
            TargetName = $null; Success = $false; ErrorMessage = $_.Exception.Message
        }
    }
}
