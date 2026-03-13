function Invoke-SimzLaunchSecret {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    # Read RDP launcher template ID from config (instance-specific value)
    $rdpTemplateId = Get-SimzConfig -Key 'LauncherTemplateId'
    if (-not $rdpTemplateId) { $rdpTemplateId = 6052 }

    try {
        # Search for secrets using the RDP launcher template
        $response = Invoke-SimzApi -Session $Session `
            -Endpoint "secrets?filter.secretTemplateId=$rdpTemplateId&take=50"

        if (-not $response.records -or $response.records.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'LaunchSecret'; TargetType = 'Secret'; TargetId = $null
                TargetName = $null; Success = $false
                ErrorMessage = "No secrets found for RDP template $rdpTemplateId"
            }
        }

        $secret = $response.records | Get-Random

        # View the full secret detail (mimics UI load before clicking Launch)
        $detail = Invoke-SimzApi -Session $Session -Endpoint "secrets/$($secret.id)"

        # Fetch launcher session history (mimics the UI launcher-sessions panel seen in HAR)
        Invoke-SimzApi -Session $Session `
            -Endpoint "secrets/launcher-sessions?filter.secretId=$($secret.id)&skip=0&take=250&sortBy[0].direction=desc&sortBy[0].name=StartDate" | Out-Null

        # Fire the launch API for audit trail — no actual RDP session is established
        $launchBody = @{
            secretId       = $secret.id
            launcherTypeId = 1   # 1 = RDP launcher
        }
        Invoke-SimzApi -Session $Session -Endpoint 'launchers/launch-now' -Method POST -Body $launchBody | Out-Null

        [PSCustomObject]@{
            Action       = 'LaunchSecret'
            TargetType   = 'Secret'
            TargetId     = $detail.id
            TargetName   = "$($detail.name) (RDP launch)"
            Success      = $true
            ErrorMessage = $null
        }
    }
    catch {
        [PSCustomObject]@{
            Action = 'LaunchSecret'; TargetType = 'Secret'; TargetId = $null
            TargetName = $null; Success = $false; ErrorMessage = $_.Exception.Message
        }
    }
}
