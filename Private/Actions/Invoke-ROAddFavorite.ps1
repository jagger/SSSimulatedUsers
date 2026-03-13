function Invoke-ROAddFavorite {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        $response = Invoke-ROApi -Session $Session -Endpoint "secrets?take=50"
        if (-not $response.records -or $response.records.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'AddFavorite'; TargetType = 'Secret'; TargetId = $null
                TargetName = $null; Success = $false; ErrorMessage = 'No secrets available'
            }
        }

        $secret = $response.records | Get-Random

        # Toggle favorite on via POST
        Invoke-ROApi -Session $Session -Endpoint "secrets/$($secret.id)/favorite" -Method POST -Body @{ isFavorite = $true } | Out-Null

        [PSCustomObject]@{
            Action       = 'AddFavorite'
            TargetType   = 'Secret'
            TargetId     = $secret.id
            TargetName   = "$($secret.name) (favorited)"
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
