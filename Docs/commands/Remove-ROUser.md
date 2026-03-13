# Remove-ROUser

## Synopsis
Remove a simulated user from the database.

## Syntax
```powershell
Remove-ROUser [-Username] <String> [-WhatIf] [-Confirm]
```

## Description
Deletes a simulated user and their associated ActionWeight rows from the RobOtters
SQLite database. Existing ActionLog entries for the user are preserved for audit
purposes. Supports the standard -WhatIf and -Confirm parameters for safe operation.

## Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| Username | String | Yes | -- | The username of the simulated user to remove |
| WhatIf | Switch | No | -- | Shows what would happen without making changes |
| Confirm | Switch | No | -- | Prompts for confirmation before removing the user |

## Examples

### Example 1: Remove a user
```powershell
Remove-ROUser -Username 'svc-simuser01'
```
Deletes the user and their action weights from the database.

### Example 2: Preview removal with WhatIf
```powershell
Remove-ROUser -Username 'svc-simuser01' -WhatIf
```
Displays what would be removed without actually deleting anything.

## Outputs

This command produces no output.

## Related Commands
- [Add-ROUser](Add-ROUser.md)
- [Get-ROUser](Get-ROUser.md)
