function Invoke-ROCheckoutPassword {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        $response = Invoke-ROApi -Session $Session -Endpoint "secrets?take=50"
        if (-not $response.records -or $response.records.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'CheckoutPassword'; TargetType = 'Secret'; TargetId = $null
                TargetName = $null; Success = $false; ErrorMessage = 'No secrets available'
            }
        }

        # Try up to 3 secrets in case some can't be accessed
        $candidates = $response.records | Get-Random -Count ([Math]::Min(3, $response.records.Count))
        foreach ($secret in $candidates) {
            try {
                $detail = Invoke-ROApi -Session $Session -Endpoint "secrets/$($secret.id)"
            }
            catch {
                Write-ROLog -Message "CheckoutPassword: cannot access secret $($secret.id), trying next: $_" -Level WARN -Component 'Actions'
                continue
            }

            if ($detail.checkOutEnabled) {
                try {
                    Invoke-ROApi -Session $Session -Endpoint "secrets/$($secret.id)/check-out" -Method POST | Out-Null
                    $targetName = "$($detail.name) (checked-out)"
                }
                catch {
                    Write-ROLog -Message "CheckoutPassword: checkout of '$($detail.name)' denied: $_" -Level WARN -Component 'Actions'
                    $targetName = "$($detail.name) (checkout denied)"
                }
            }
            else {
                $targetName = "$($detail.name) (metadata-only, checkout not enabled)"
            }

            return [PSCustomObject]@{
                Action       = 'CheckoutPassword'
                TargetType   = 'Secret'
                TargetId     = $secret.id
                TargetName   = $targetName
                Success      = $true
                ErrorMessage = $null
            }
        }

        # All candidates inaccessible
        [PSCustomObject]@{
            Action       = 'CheckoutPassword'
            TargetType   = 'Secret'
            TargetId     = $null
            TargetName   = 'All candidates inaccessible'
            Success      = $true
            ErrorMessage = $null
        }
    }
    catch {
        [PSCustomObject]@{
            Action = 'CheckoutPassword'; TargetType = 'Secret'; TargetId = $null
            TargetName = $null; Success = $false; ErrorMessage = $_.Exception.Message
        }
    }
}
