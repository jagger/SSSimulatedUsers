function Invoke-TriggerHeartbeat {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        $response = Invoke-SecretServerApi -Session $Session -Endpoint "secrets?take=50"
        if (-not $response.records -or $response.records.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'TriggerHeartbeat'; TargetType = 'Secret'; TargetId = $null
                TargetName = $null; Success = $false; ErrorMessage = 'No secrets available'
            }
        }

        $secret = $response.records | Get-Random
        Invoke-SecretServerApi -Session $Session -Endpoint "secrets/$($secret.id)/heartbeat" -Method POST | Out-Null

        [PSCustomObject]@{
            Action       = 'TriggerHeartbeat'
            TargetType   = 'Secret'
            TargetId     = $secret.id
            TargetName   = $secret.name
            Success      = $true
            ErrorMessage = $null
        }
    }
    catch {
        [PSCustomObject]@{
            Action = 'TriggerHeartbeat'; TargetType = 'Secret'; TargetId = $null
            TargetName = $null; Success = $false; ErrorMessage = $_.Exception.Message
        }
    }
}
