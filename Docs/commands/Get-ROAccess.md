# Get-ROAccess

## Synopsis
View user access snapshots.

## Syntax
```powershell
Get-ROAccess [-Username <String>] [-Refresh]

Get-ROAccess -Purge
```

## Description
Retrieves cached access snapshots from the UserAccess table showing what each
simulated user can see in Secret Server (folders, secrets, and templates). Snapshots
are automatically refreshed when they exceed the AccessSnapshotMaxAgeDays
configuration value. Use -Refresh to force a live update, or -Purge to remove all
cached data.

## Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| Username | String | No | -- | Filter results to a single user (Query parameter set) |
| Refresh | Switch | No | -- | Force a live refresh of the access snapshot (Query parameter set) |
| Purge | Switch | Yes | -- | Delete all cached access data (Purge parameter set) |

## Examples

### Example 1: View all user access snapshots
```powershell
Get-ROAccess
```
Returns the cached access summary for every registered user.

### Example 2: Refresh a single user
```powershell
Get-ROAccess -Username 'svc-simuser01' -Refresh
```
Queries Secret Server live and updates the cached snapshot for the specified user.

### Example 3: Purge all cached data
```powershell
Get-ROAccess -Purge
```
Removes all rows from the UserAccess table.

## Outputs

| Property | Type | Description |
|----------|------|-------------|
| Username | String | The simulated user |
| FolderCount | Int32 | Number of folders accessible |
| SecretCount | Int32 | Number of secrets accessible |
| TemplateCount | Int32 | Number of secret templates available |
| TemplateNames | String[] | List of template names |
| CheckedAt | DateTime | When the snapshot was last refreshed |

## Related Commands
- [Get-ROUser](Get-ROUser.md)
- [Get-ROConfig](Get-ROConfig.md)
