function Set-ROConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        [string]$Value
    )

    Invoke-ROQuery -Query @"
INSERT INTO Config (Key, Value) VALUES (@Key, @Value)
ON CONFLICT(Key) DO UPDATE SET Value = @Value
"@ -SqlParameters @{
        Key   = $Key
        Value = $Value
    }

    Write-ROLog -Message "Config '$Key' set to '$Value'" -Component 'Config'
}
