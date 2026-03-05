function Set-SimzConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        [string]$Value
    )

    Invoke-SimzQuery -Query @"
INSERT INTO Config (Key, Value) VALUES (@Key, @Value)
ON CONFLICT(Key) DO UPDATE SET Value = @Value
"@ -SqlParameters @{
        Key   = $Key
        Value = $Value
    }

    Write-SimzLog -Message "Config '$Key' set to '$Value'" -Component 'Config'
}
