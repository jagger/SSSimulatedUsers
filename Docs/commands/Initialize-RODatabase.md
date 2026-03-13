# Initialize-RODatabase

## Synopsis
Create or upgrade the RobOtters SQLite database.

## Syntax
```powershell
Initialize-RODatabase
```

## Description
Creates the RobOtters SQLite database if it does not already exist, or upgrades it
by applying any pending migrations. The command is idempotent and safe to run
repeatedly. It executes the schema definition, runs all migrations, seeds the nine
default configuration values, backfills missing action weights for existing users,
and encrypts any plain-text passwords found in the Users table.

## Parameters

This command has no parameters.

## Examples

### Example 1: Create a fresh database
```powershell
Initialize-RODatabase
```
Creates the SQLite database file under Data/RobOtters.sqlite with the full schema and default configuration values.

### Example 2: Upgrade after pulling new code
```powershell
Initialize-RODatabase
```
Re-running after a code update applies any new migrations and seed data without affecting existing records.

## Outputs

| Property | Type | Description |
|----------|------|-------------|
| (message) | String | Confirmation message including the database file path |

## Related Commands
- [Get-ROConfig](Get-ROConfig.md)
- [Add-ROUser](Add-ROUser.md)
