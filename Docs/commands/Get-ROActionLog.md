# Get-ROActionLog

## Synopsis
Query the action history.

## Syntax
```powershell
Get-ROActionLog [-Last <Int32>] [-Username <String>] [-ActionName <String>]
                [-Since <DateTime>] [-Until <DateTime>]
```

## Description
Retrieves action log entries from the RobOtters SQLite database. Results can be
filtered by username, action name, and date range. The -Last parameter limits how
many rows are returned, ordered by most recent first.

## Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| Last | Int32 | No | -- | Return only the N most recent entries |
| Username | String | No | -- | Filter by the username that performed the action |
| ActionName | String | No | -- | Filter by action name (e.g. GetSecret, CreateFolder) |
| Since | DateTime | No | -- | Return entries on or after this timestamp |
| Until | DateTime | No | -- | Return entries on or before this timestamp |

## Examples

### Example 1: Get the last 20 actions
```powershell
Get-ROActionLog -Last 20
```
Returns the 20 most recent action log entries.

### Example 2: Filter by user and date
```powershell
Get-ROActionLog -Username 'svc-simuser01' -Since (Get-Date).AddDays(-7)
```
Returns all actions for the specified user in the past seven days.

### Example 3: Find failed actions of a specific type
```powershell
Get-ROActionLog -ActionName 'CreateSecret' | Where-Object { -not $_.Success }
```
Returns all failed CreateSecret actions.

## Outputs

| Property | Type | Description |
|----------|------|-------------|
| LogId | Int32 | Unique log entry ID |
| Username | String | User who performed the action |
| ActionName | String | Name of the action executed |
| TargetType | String | Type of target (e.g. Secret, Folder) |
| TargetId | Int32 | ID of the target object |
| TargetName | String | Name of the target object |
| Success | Boolean | Whether the action succeeded |
| ErrorMessage | String | Error details if the action failed |
| Timestamp | DateTime | When the action was executed |

## Related Commands
- [Start-ROCycle](Start-ROCycle.md)
