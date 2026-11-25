function Invoke-ROListExpiredSecrets {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        $response = Invoke-ROApi -Session $Session -Endpoint "secrets?filter.isExpirationInRange=true&take=30"

        $count = 0
        if ($response.records) {
            $count = $response.records.Count
        }

        [PSCustomObject]@{
            Action       = 'ListExpiredSecrets'
            TargetType   = 'Search'
            TargetId     = $null
            TargetName   = "$count expired/expiring secrets found"
            Success      = $true
            ErrorMessage = $null
        }
    }
    catch {
        [PSCustomObject]@{
            Action = 'ListExpiredSecrets'; TargetType = 'Search'; TargetId = $null
            TargetName = $null; Success = $false; ErrorMessage = $_.Exception.Message
        }
    }
}
