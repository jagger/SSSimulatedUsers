function Set-ROConfig {
    <#
    .SYNOPSIS
        Set a configuration value in the RobOtters database
    .DESCRIPTION
        Sets or updates a config key in the Config table. Uses upsert
        behavior -- inserts if the key does not exist, updates if it does.
        Valid config keys: SecretServerUrl, DefaultDomain,
        MinActionsPerCycle, MaxActionsPerCycle, LogRetentionDays,
        PasswordRotationDays, AuthFailureAction (AlertOnly or
        RotateAndAlert), LauncherTemplateId, AccessSnapshotMaxAgeDays.
    .PARAMETER Key
        The config key to set.
    .PARAMETER Value
        The value to assign.
    .EXAMPLE
        Set-ROConfig -Key 'SecretServerUrl' -Value 'https://ss.lab.local/SecretServer'
    .EXAMPLE
        Set-ROConfig -Key 'MaxActionsPerCycle' -Value '20'
    .EXAMPLE
        Set-ROConfig -Key 'AuthFailureAction' -Value 'RotateAndAlert'
    .OUTPUTS
        None
    .LINK
        Docs/commands/Set-ROConfig.md
    #>
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
