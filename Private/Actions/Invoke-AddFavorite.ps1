function Invoke-AddFavorite {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        $response = Invoke-SecretServerApi -Session $Session -Endpoint "secrets?take=50"
        if (-not $response.records -or $response.records.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'AddFavorite'; TargetType = 'Secret'; TargetId = $null
                TargetName = $null; Success = $false; ErrorMessage = 'No secrets available'
            }
        }

        $secret = $response.records | Get-Random

        # Toggle favorite via the secret detail update
        $detail = Invoke-SecretServerApi -Session $Session -Endpoint "secrets/$($secret.id)/favorite"
        $newState = -not $detail.isFavorite

        Invoke-SecretServerApi -Session $Session -Endpoint "secrets/$($secret.id)/favorite" -Method PUT -Body @{ isFavorite = $newState } | Out-Null

        $action = if ($newState) { 'favorited' } else { 'unfavorited' }

        [PSCustomObject]@{
            Action       = 'AddFavorite'
            TargetType   = 'Secret'
            TargetId     = $secret.id
            TargetName   = "$($secret.name) ($action)"
            Success      = $true
            ErrorMessage = $null
        }
    }
    catch {
        [PSCustomObject]@{
            Action = 'AddFavorite'; TargetType = 'Secret'; TargetId = $null
            TargetName = $null; Success = $false; ErrorMessage = $_.Exception.Message
        }
    }
}
