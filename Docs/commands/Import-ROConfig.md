# Import-ROConfig

## Synopsis
Import configuration and users from JSON.

## Syntax
```powershell
Import-ROConfig [-Path] <String> [-ConfigOnly] [-UsersOnly] [-WhatIf] [-Confirm]
```

## Description
Imports RobOtters configuration and user data from a JSON file previously created by
Export-ROConfig. Existing users are updated with the imported values while new users
are created. New users that do not have a password in the import file receive a
random password that is set in Active Directory automatically. Use -ConfigOnly or
-UsersOnly to import a subset of the data. Supports -WhatIf and -Confirm for safe
operation.

## Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| Path | String | Yes | -- | Path to the JSON file to import |
| ConfigOnly | Switch | No | -- | Import only the configuration keys, skip users |
| UsersOnly | Switch | No | -- | Import only users, skip configuration keys |
| WhatIf | Switch | No | -- | Show what would change without making modifications |
| Confirm | Switch | No | -- | Prompt for confirmation before applying changes |

## Examples

### Example 1: Import everything
```powershell
Import-ROConfig -Path 'C:\backups\robotters-config.json'
```
Imports both configuration values and user data from the specified file.

### Example 2: Import only configuration
```powershell
Import-ROConfig -Path 'C:\backups\robotters-config.json' -ConfigOnly
```
Updates configuration keys without modifying any user records.

### Example 3: Preview an import
```powershell
Import-ROConfig -Path 'C:\backups\robotters-config.json' -WhatIf
```
Displays what changes would be applied without actually importing anything.

## Outputs

| Property | Type | Description |
|----------|------|-------------|
| (message) | String | Confirmation message summarizing what was imported |

## Related Commands
- [Export-ROConfig](Export-ROConfig.md)
