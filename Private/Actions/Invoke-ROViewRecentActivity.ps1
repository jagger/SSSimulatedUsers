function Invoke-ROViewRecentActivity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        $response = Invoke-ROApi -Session $Session -Endpoint "secrets?filter.recentProperty=LastAccessed&take=20"

        $count = 0
        if ($response.records) {
            $count = $response.records.Count
        }

        [PSCustomObject]@{
            Action       = 'ViewRecentActivity'
            TargetType   = 'Search'
            TargetId     = $null
            TargetName   = "$count recently accessed secrets"
            Success      = $true
            ErrorMessage = $null
        }
    }
    catch {
        [PSCustomObject]@{
            Action = 'ViewRecentActivity'; TargetType = 'Search'; TargetId = $null
            TargetName = $null; Success = $false; ErrorMessage = $_.Exception.Message
        }
    }
}
