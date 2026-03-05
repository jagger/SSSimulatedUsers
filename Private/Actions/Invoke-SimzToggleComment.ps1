function Invoke-SimzToggleComment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        $response = Invoke-SimzApi -Session $Session -Endpoint "secrets?take=50"
        if (-not $response.records -or $response.records.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'ToggleComment'; TargetType = 'Secret'; TargetId = $null
                TargetName = $null; Success = $false; ErrorMessage = 'No secrets available'
            }
        }

        $secret = $response.records | Get-Random
        $detail = Invoke-SimzApi -Session $Session -Endpoint "secrets/$($secret.id)"

        # Toggle requiresComment
        $newState = -not $detail.requiresComment
        $detail.requiresComment = $newState
        Invoke-SimzApi -Session $Session -Endpoint "secrets/$($secret.id)" -Method PUT -Body $detail | Out-Null

        $label = if ($newState) { 'enabled' } else { 'disabled' }

        [PSCustomObject]@{
            Action       = 'ToggleComment'
            TargetType   = 'Secret'
            TargetId     = $secret.id
            TargetName   = "$($secret.name) (comment $label)"
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
