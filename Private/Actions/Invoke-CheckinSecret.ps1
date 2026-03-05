function Invoke-CheckinSecret {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        if (-not $Session.SSUserId) {
            return [PSCustomObject]@{
                Action = 'CheckinSecret'; TargetType = 'Secret'; TargetId = $null
                TargetName = 'Cannot filter: SSUserId unknown'; Success = $false
                ErrorMessage = 'Session missing SSUserId'
            }
        }

        # Find secrets that might be checked out
        $response = Invoke-SecretServerApi -Session $Session -Endpoint "secrets?filter.isCheckedOut=true&take=20"

        if (-not $response.records -or $response.records.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'CheckinSecret'; TargetType = 'Secret'; TargetId = $null
                TargetName = 'No checked-out secrets found'; Success = $true; ErrorMessage = $null
            }
        }

        # Filter to only secrets checked out by the current user
        $myCheckouts = @()
        foreach ($rec in $response.records) {
            $detail = Invoke-SecretServerApi -Session $Session -Endpoint "secrets/$($rec.id)"
            if ($detail.checkOutUserId -eq $Session.SSUserId) {
                $myCheckouts += $rec
            }
        }

        if ($myCheckouts.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'CheckinSecret'; TargetType = 'Secret'; TargetId = $null
                TargetName = 'No secrets checked out by current user'; Success = $true; ErrorMessage = $null
            }
        }

        $secret = $myCheckouts | Get-Random

        $comments = @('Done with testing', 'Finished maintenance', 'Password verified', 'Access no longer needed', 'Routine check-in')
        $body = @{ comment = $comments | Get-Random }

        Invoke-SecretServerApi -Session $Session -Endpoint "secrets/$($secret.id)/check-in" -Method POST -Body $body | Out-Null

        [PSCustomObject]@{
            Action       = 'CheckinSecret'
            TargetType   = 'Secret'
            TargetId     = $secret.id
            TargetName   = $secret.name
            Success      = $true
            ErrorMessage = $null
        }
    }
    catch {
        [PSCustomObject]@{
            Action = 'CheckinSecret'; TargetType = 'Secret'; TargetId = $null
            TargetName = $null; Success = $false; ErrorMessage = $_.Exception.Message
        }
    }
}
