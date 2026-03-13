# Export-ROConfig

## Synopsis
Export configuration and users to JSON.

## Syntax
```powershell
Export-ROConfig [-Path] <String> [-IncludePasswords]
```

## Description
Exports the current RobOtters configuration and all registered users to a JSON file.
The output includes an ExportedAt timestamp, all Config key-value pairs, and the full
user list with their action weights. Passwords are set to null unless the
-IncludePasswords switch is specified.

## Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| Path | String | Yes | -- | File path where the JSON export will be written |
| IncludePasswords | Switch | No | -- | Include decrypted passwords in the export |

## Examples

### Example 1: Export without passwords
```powershell
Export-ROConfig -Path 'C:\backups\robotters-config.json'
```
Writes configuration and user data to the specified file with passwords set to null.

### Example 2: Export with passwords for migration
```powershell
Export-ROConfig -Path 'C:\backups\robotters-full.json' -IncludePasswords
```
Includes decrypted passwords in the export for use when migrating to another machine.

## Outputs

| Property | Type | Description |
|----------|------|-------------|
| (message) | String | Confirmation message with the export file path |

## Related Commands
- [Import-ROConfig](Import-ROConfig.md)
- [Get-ROConfig](Get-ROConfig.md)
