function Get-SimzConfig {
    [CmdletBinding()]
    param(
        [string]$Key
    )

    if ($Key) {
        Invoke-SimzQuery -Query "SELECT Value FROM Config WHERE Key = @Key" -SqlParameters @{ Key = $Key } -Scalar
    }
    else {
        Invoke-SimzQuery -Query "SELECT Key, Value FROM Config ORDER BY Key"
    }
}
