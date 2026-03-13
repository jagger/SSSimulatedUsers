function Invoke-ROSearchSecrets {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    $searchTerms = @('admin', 'server', 'database', 'service', 'backup', 'root', 'test', 'prod', 'dev', 'api', 'key', 'cert', 'sql', 'web', 'ftp')
    $term = $searchTerms | Get-Random

    try {
        $response = Invoke-ROApi -Session $Session -Endpoint "secrets?filter.searchText=$term&take=25"
        $count = if ($response.records) { $response.records.Count } else { 0 }

        [PSCustomObject]@{
            Action       = 'SearchSecrets'
            TargetType   = 'Search'
            TargetId     = $null
            TargetName   = "term:$term (${count} results)"
            Success      = $true
            ErrorMessage = $null
        }
    }
    catch {
        [PSCustomObject]@{
            Action       = 'SearchSecrets'
            TargetType   = 'Search'
            TargetId     = $null
            TargetName   = "term:$term"
            Success      = $false
            ErrorMessage = $_.Exception.Message
        }
    }
}
