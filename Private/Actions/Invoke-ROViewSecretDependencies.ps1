function Invoke-ROViewSecretDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        $response = Invoke-ROApi -Session $Session -Endpoint "secrets?take=50"
        if (-not $response.records -or $response.records.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'ViewSecretDependencies'; TargetType = 'Secret'; TargetId = $null
                TargetName = $null; Success = $false; ErrorMessage = 'No secrets available'
            }
        }

        $secret = $response.records | Get-Random
        $deps = Invoke-ROApi -Session $Session -Endpoint "secrets/$($secret.id)/dependencies"

        $depCount = 0
        if ($deps -is [array]) {
            $depCount = $deps.Count
        }
        elseif ($deps.records) {
            $depCount = $deps.records.Count
        }

        [PSCustomObject]@{
            Action       = 'ViewSecretDependencies'
            TargetType   = 'Secret'
            TargetId     = $secret.id
            TargetName   = "$($secret.name) ($depCount dependencies)"
            Success      = $true
            ErrorMessage = $null
        }
    }
    catch {
        [PSCustomObject]@{
            Action = 'ViewSecretDependencies'; TargetType = 'Secret'; TargetId = $null
            TargetName = $null; Success = $false; ErrorMessage = $_.Exception.Message
        }
    }
}
