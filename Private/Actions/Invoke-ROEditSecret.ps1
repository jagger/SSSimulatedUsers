function Invoke-ROEditSecret {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        $response = Invoke-ROApi -Session $Session -Endpoint "secrets?take=50"
        if (-not $response.records -or $response.records.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'EditSecret'; TargetType = 'Secret'; TargetId = $null
                TargetName = $null; Success = $false; ErrorMessage = 'No secrets available'
            }
        }

        # Try up to 3 random secrets in case some are checked out or inaccessible
        $candidates = $response.records | Get-Random -Count ([Math]::Min(3, $response.records.Count))
        foreach ($secret in $candidates) {
            try {
                $detail = Invoke-ROApi -Session $Session -Endpoint "secrets/$($secret.id)"

                # Only edit safe fields that won't break heartbeat, RPC, or SS integrations
                $safeFields = @('notes', 'password')
                $editableField = $detail.items | Where-Object { -not $_.isFile -and $_.slug -in $safeFields } | Get-Random
                if (-not $editableField) {
                    continue
                }

                $newValue = switch ($editableField.slug) {
                    'notes'    { "Updated by RobOtters at $(Get-Date -Format 'yyyy-MM-dd HH:mm')" }
                    'password' { New-ROPassword }
                }
                Invoke-ROApi -Session $Session -Endpoint "secrets/$($secret.id)/fields/$($editableField.slug)" -Method PUT -Body @{ value = $newValue } | Out-Null

                return [PSCustomObject]@{
                    Action       = 'EditSecret'
                    TargetType   = 'Secret'
                    TargetId     = $secret.id
                    TargetName   = "$($secret.name) (field: $($editableField.slug))"
                    Success      = $true
                    ErrorMessage = $null
                }
            }
            catch {
                Write-ROLog -Message "EditSecret: cannot edit secret $($secret.id), trying next: $_" -Level WARN -Component 'Actions'
                continue
            }
        }

        # All candidates failed
        [PSCustomObject]@{
            Action       = 'EditSecret'
            TargetType   = 'Secret'
            TargetId     = $null
            TargetName   = 'All candidates inaccessible or no editable fields'
            Success      = $true
            ErrorMessage = $null
        }
    }
    catch {
        [PSCustomObject]@{
            Action = 'EditSecret'; TargetType = 'Secret'; TargetId = $null
            TargetName = $null; Success = $false; ErrorMessage = $_.Exception.Message
        }
    }
}
