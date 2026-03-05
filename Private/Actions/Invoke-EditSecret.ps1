function Invoke-EditSecret {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        $response = Invoke-SecretServerApi -Session $Session -Endpoint "secrets?take=50"
        if (-not $response.records -or $response.records.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'EditSecret'; TargetType = 'Secret'; TargetId = $null
                TargetName = $null; Success = $false; ErrorMessage = 'No secrets available'
            }
        }

        $secret = $response.records | Get-Random
        $detail = Invoke-SecretServerApi -Session $Session -Endpoint "secrets/$($secret.id)"

        # Only edit safe fields that won't break heartbeat, RPC, or SS integrations
        $safeFields = @('notes', 'password')
        $editableField = $detail.items | Where-Object { -not $_.isFile -and $_.slug -in $safeFields } | Get-Random
        if (-not $editableField) {
            return [PSCustomObject]@{
                Action = 'EditSecret'; TargetType = 'Secret'; TargetId = $secret.id
                TargetName = "$($secret.name) (no safe editable fields)"; Success = $true; ErrorMessage = $null
            }
        }

        $newValue = switch ($editableField.slug) {
            'notes'    { "Updated by TheSimz at $(Get-Date -Format 'yyyy-MM-dd HH:mm')" }
            'password' { New-SimzPassword }
        }
        Invoke-SecretServerApi -Session $Session -Endpoint "secrets/$($secret.id)/fields/$($editableField.slug)" -Method PUT -Body @{ value = $newValue } | Out-Null

        [PSCustomObject]@{
            Action       = 'EditSecret'
            TargetType   = 'Secret'
            TargetId     = $secret.id
            TargetName   = "$($secret.name) (field: $($editableField.slug))"
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
