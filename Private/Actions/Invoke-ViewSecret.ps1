function Invoke-ViewSecret {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        # Find a secret to view by searching
        $response = Invoke-SecretServerApi -Session $Session -Endpoint "secrets?take=50"
        if (-not $response.records -or $response.records.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'ViewSecret'; TargetType = 'Secret'; TargetId = $null
                TargetName = $null; Success = $false; ErrorMessage = 'No secrets available'
            }
        }

        $secret = $response.records | Get-Random
        $detail = Invoke-SecretServerApi -Session $Session -Endpoint "secrets/$($secret.id)"

        [PSCustomObject]@{
            Action       = 'ViewSecret'
            TargetType   = 'Secret'
            TargetId     = $detail.id
            TargetName   = $detail.name
            Success      = $true
            ErrorMessage = $null
        }
    }
    catch {
        [PSCustomObject]@{
            Action = 'ViewSecret'; TargetType = 'Secret'; TargetId = $null
            TargetName = $null; Success = $false; ErrorMessage = $_.Exception.Message
        }
    }
}
