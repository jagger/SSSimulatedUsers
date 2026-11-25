function Invoke-ROViewSecretAudit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        $response = Invoke-ROApi -Session $Session -Endpoint "secrets?take=50"
        if (-not $response.records -or $response.records.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'ViewSecretAudit'; TargetType = 'Secret'; TargetId = $null
                TargetName = $null; Success = $false; ErrorMessage = 'No secrets available'
            }
        }

        $secret = $response.records | Get-Random
        $audits = Invoke-ROApi -Session $Session -Endpoint "secrets/$($secret.id)/audits?take=10"

        $auditCount = 0
        if ($audits.records) {
            $auditCount = $audits.records.Count
        }

        [PSCustomObject]@{
            Action       = 'ViewSecretAudit'
            TargetType   = 'Secret'
            TargetId     = $secret.id
            TargetName   = "$($secret.name) ($auditCount audit entries)"
            Success      = $true
            ErrorMessage = $null
        }
    }
    catch {
        [PSCustomObject]@{
            Action = 'ViewSecretAudit'; TargetType = 'Secret'; TargetId = $null
            TargetName = $null; Success = $false; ErrorMessage = $_.Exception.Message
        }
    }
}
