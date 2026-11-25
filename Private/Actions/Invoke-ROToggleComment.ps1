function Invoke-ROToggleComment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        $response = Invoke-ROApi -Session $Session -Endpoint "secrets?take=50"
        if (-not $response.records -or $response.records.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'ToggleComment'; TargetType = 'Secret'; TargetId = $null
                TargetName = $null; Success = $false; ErrorMessage = 'No secrets available'
            }
        }

        # Try up to 3 candidates, skipping checked-out secrets
        $candidates = $response.records | Get-Random -Count ([Math]::Min(3, $response.records.Count))
        foreach ($secret in $candidates) {
            try {
                $detail = Invoke-ROApi -Session $Session -Endpoint "secrets/$($secret.id)"

                # Skip secrets that are currently checked out (PUT will fail)
                if ($detail.checkedOut) {
                    Write-ROLog -Message "ToggleComment: secret '$($secret.name)' is checked out, skipping" -Level WARN -Component 'Actions'
                    continue
                }

                # Toggle requiresComment
                $newState = -not $detail.requiresComment
                $detail.requiresComment = $newState
                Invoke-ROApi -Session $Session -Endpoint "secrets/$($secret.id)" -Method PUT -Body $detail | Out-Null

                $label = if ($newState) { 'enabled' } else { 'disabled' }

                return [PSCustomObject]@{
                    Action       = 'ToggleComment'
                    TargetType   = 'Secret'
                    TargetId     = $secret.id
                    TargetName   = "$($secret.name) (comment $label)"
                    Success      = $true
                    ErrorMessage = $null
                }
            }
            catch {
                Write-ROLog -Message "ToggleComment: cannot update secret $($secret.id), trying next: $_" -Level WARN -Component 'Actions'
                continue
            }
        }

        # All candidates failed
        [PSCustomObject]@{
            Action       = 'ToggleComment'
            TargetType   = 'Secret'
            TargetId     = $null
            TargetName   = 'All candidates inaccessible (checked out or no permission)'
            Success      = $true
            ErrorMessage = $null
        }
    }
    catch {
        [PSCustomObject]@{
            Action = 'ToggleComment'; TargetType = 'Secret'; TargetId = $null
            TargetName = $null; Success = $false; ErrorMessage = $_.Exception.Message
        }
    }
}
