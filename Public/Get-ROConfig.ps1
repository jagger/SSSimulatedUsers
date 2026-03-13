function Get-ROConfig {
    [CmdletBinding()]
    param(
        [string]$Key
    )

    if ($Key) {
        Invoke-ROQuery -Query "SELECT Value FROM Config WHERE Key = @Key" -SqlParameters @{ Key = $Key } -Scalar
    }
    else {
        Invoke-ROQuery -Query "SELECT Key, Value FROM Config ORDER BY Key"
    }
}
