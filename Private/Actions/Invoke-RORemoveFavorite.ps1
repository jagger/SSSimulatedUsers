function Invoke-RORemoveFavorite {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        $response = Invoke-ROApi -Session $Session -Endpoint "secrets?take=50"
        if (-not $response.records -or $response.records.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'RemoveFavorite'; TargetType = 'Secret'; TargetId = $null
                TargetName = $null; Success = $false; ErrorMessage = 'No secrets available'
            }
        }

        $secret = $response.records | Get-Random

        Invoke-ROApi -Session $Session -Endpoint "secrets/$($secret.id)/favorite" -Method POST -Body @{ isFavorite = $false } | Out-Null

        [PSCustomObject]@{
            Action       = 'RemoveFavorite'
            TargetType   = 'Secret'
            TargetId     = $secret.id
            TargetName   = "$($secret.name) (unfavorited)"
            Success      = $true
            ErrorMessage = $null
        }
    }
    catch {
        [PSCustomObject]@{
            Action = 'RemoveFavorite'; TargetType = 'Secret'; TargetId = $null
            TargetName = $null; Success = $false; ErrorMessage = $_.Exception.Message
        }
    }
}
