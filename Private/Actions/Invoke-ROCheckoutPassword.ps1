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

        $secret = $response.records | Get-Random

        # Always fetch detail (generates realistic traffic)
        $detail = Invoke-ROApi -Session $Session -Endpoint "secrets/$($secret.id)"

        if ($detail.checkOutEnabled) {
            Invoke-ROApi -Session $Session -Endpoint "secrets/$($secret.id)/check-out" -Method POST | Out-Null
            $targetName = "$($detail.name) (checked-out)"
        }
        else {
            $targetName = "$($detail.name) (metadata-only, checkout not enabled)"
        }

        [PSCustomObject]@{
            Action       = 'CheckoutPassword'
            TargetType   = 'Secret'
            TargetId     = $secret.id
            TargetName   = $targetName
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
