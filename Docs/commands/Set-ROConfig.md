# Set-ROConfig

## Synopsis
Set a configuration value.

## Syntax
```powershell
Set-ROConfig [-Key] <String> [-Value] <String>
```

## Description
Sets a configuration value in the RobOtters Config table using upsert behavior. If
the key already exists it is updated; otherwise a new row is inserted. Valid keys
are: SecretServerUrl, DefaultDomain, MinActionsPerCycle, MaxActionsPerCycle,
LogRetentionDays, PasswordRotationDays, AuthFailureAction, LauncherTemplateId,
and AccessSnapshotMaxAgeDays.

## Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| Key | String | Yes | -- | The configuration key to set |
| Value | String | Yes | -- | The value to assign to the key |

## Examples

### Example 1: Set the Secret Server URL
```powershell
Set-ROConfig -Key 'SecretServerUrl' -Value 'https://ss.lab.local/SecretServer'
```
Configures the base URL for the Secret Server instance.

### Example 2: Increase the maximum actions per cycle
```powershell
Set-ROConfig -Key 'MaxActionsPerCycle' -Value '25'
```
Raises the upper bound of randomized actions per user per cycle to 25.

## Outputs

This command produces no output.

## Related Commands
- [Get-ROConfig](Get-ROConfig.md)
