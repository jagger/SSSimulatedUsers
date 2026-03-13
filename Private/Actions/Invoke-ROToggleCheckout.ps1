function Invoke-ROToggleCheckout {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        $response = Invoke-ROApi -Session $Session -Endpoint "secrets?take=50"
        if (-not $response.records -or $response.records.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'ToggleCheckout'; TargetType = 'Secret'; TargetId = $null
                TargetName = $null; Success = $false; ErrorMessage = 'No secrets available'
            }
        }

        $secret = $response.records | Get-Random
        $detail = Invoke-ROApi -Session $Session -Endpoint "secrets/$($secret.id)"

        # Toggle checkOutEnabled - don't disable if the secret is currently checked out
        $newState = -not $detail.checkOutEnabled
        if (-not $newState -and $detail.checkedOut) {
            return [PSCustomObject]@{
                Action = 'ToggleCheckout'; TargetType = 'Secret'; TargetId = $secret.id
                TargetName = "$($secret.name) (skipped, currently checked out)"; Success = $true; ErrorMessage = $null
            }
        }
        $detail.checkOutEnabled = $newState

        if ($newState) {
            # Set a reasonable checkout interval when enabling
            $intervals = @(15, 30, 60, 120)
            $detail.checkOutIntervalMinutes = Get-Random -InputObject $intervals
            $detail.checkOutChangePasswordEnabled = $false
        }
        else {
            $detail.checkOutIntervalMinutes = -1
        }

        Invoke-ROApi -Session $Session -Endpoint "secrets/$($secret.id)" -Method PUT -Body $detail | Out-Null

        $label = if ($newState) { "enabled ($($detail.checkOutIntervalMinutes)min)" } else { 'disabled' }

        [PSCustomObject]@{
            Action       = 'ToggleCheckout'
            TargetType   = 'Secret'
            TargetId     = $secret.id
            TargetName   = "$($secret.name) (checkout $label)"
            Success      = $true
            ErrorMessage = $null
        }
    }
    catch {
        [PSCustomObject]@{
            Action = 'ToggleCheckout'; TargetType = 'Secret'; TargetId = $null
            TargetName = $null; Success = $false; ErrorMessage = $_.Exception.Message
        }
    }
}
