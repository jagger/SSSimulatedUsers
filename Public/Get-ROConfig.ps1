function Get-ROConfig {
    <#
    .SYNOPSIS
        Read configuration values from the RobOtters database
    .DESCRIPTION
        Retrieves configuration from the Config table. With no parameters,
        returns all key-value pairs. Use -Key to retrieve a single value.
        The 9 config keys are: SecretServerUrl, DefaultDomain,
        MinActionsPerCycle, MaxActionsPerCycle, LogRetentionDays,
        PasswordRotationDays, AuthFailureAction, LauncherTemplateId,
        AccessSnapshotMaxAgeDays.
    .PARAMETER Key
        Name of a specific config key to retrieve. If omitted, returns all keys.
    .EXAMPLE
        Get-ROConfig
        Show all configuration.
    .EXAMPLE
        Get-ROConfig -Key 'SecretServerUrl'
        Get a single value.
    .OUTPUTS
        System.String
            When -Key is specified, returns the value as a string.
        PSCustomObject[]
            When no key is specified, returns objects with Key and Value properties.
    .LINK
        Docs/commands/Get-ROConfig.md
    #>
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
