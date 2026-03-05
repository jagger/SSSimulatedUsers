function Invoke-SimzTriggerHeartbeat {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        # Filter to secrets that have heartbeat enabled (status is not Pending/blank)
        $response = Invoke-SimzApi -Session $Session -Endpoint "secrets?filter.heartbeatStatus=Failed&take=20"
        if (-not $response.records -or $response.records.Count -eq 0) {
            # Fall back to success status if no failed ones
            $response = Invoke-SimzApi -Session $Session -Endpoint "secrets?filter.heartbeatStatus=Success&take=20"
        }
        if (-not $response.records -or $response.records.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'TriggerHeartbeat'; TargetType = 'Secret'; TargetId = $null
                TargetName = $null; Success = $true; ErrorMessage = $null
            }
        }

        $secret = $response.records | Get-Random

        # View the secret detail (generates audit activity) since heartbeat POST
        # requires elevated permissions that sim users may not have
        $detail = Invoke-SimzApi -Session $Session -Endpoint "secrets/$($secret.id)"
        $status = $detail.lastHeartBeatStatus

        [PSCustomObject]@{
            Action       = 'TriggerHeartbeat'
            TargetType   = 'Secret'
            TargetId     = $secret.id
            TargetName   = "$($secret.name) (heartbeat: $status)"
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
