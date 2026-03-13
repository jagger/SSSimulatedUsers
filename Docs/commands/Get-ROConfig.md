# Get-ROConfig

## Synopsis
Read configuration values.

## Syntax
```powershell
Get-ROConfig [-Key <String>]
```

## Description
Reads one or all configuration values from the RobOtters Config table. When called
with -Key it returns the value for that single key as a string. Without -Key it
returns all nine configuration entries as objects.

The nine configuration keys are: SecretServerUrl, DefaultDomain,
MinActionsPerCycle, MaxActionsPerCycle, LogRetentionDays, PasswordRotationDays,
AuthFailureAction, LauncherTemplateId, and AccessSnapshotMaxAgeDays.

## Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| Key | String | No | -- | The specific configuration key to retrieve |

## Examples

### Example 1: Get all configuration values
```powershell
Get-ROConfig
```
Returns all nine configuration entries with their keys and values.

### Example 2: Get a single value
```powershell
Get-ROConfig -Key 'SecretServerUrl'
```
Returns the Secret Server base URL as a string.

## Outputs

| Property | Type | Description |
|----------|------|-------------|
| Key | String | Configuration key name (when returning all) |
| Value | String | Configuration value (when returning all) |
| (value) | String | Plain string value (when using -Key) |

## Related Commands
- [Set-ROConfig](Set-ROConfig.md)
- [Initialize-RODatabase](Initialize-RODatabase.md)
