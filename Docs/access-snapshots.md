# Access Snapshots

## Overview
Get-ROAccess shows what each simulated user can access in Secret Server: folder count, secret count, template count, and template names.

## Viewing Access
```powershell
# All users
Get-ROAccess

# Single user
Get-ROAccess -Username 'svc.sim01'
```

Output:
```
Username      FolderCount SecretCount TemplateCount TemplateNames    CheckedAt
--------      ----------- ----------- ------------- -------------    ---------
svc.sim01     12          45          3             Password,SSH Key 2024-01-15 09:00:00
svc.sim02     8           30          2             Password         2024-01-15 09:00:00
```

## Caching
Access data is cached in the UserAccess table. The AccessSnapshotMaxAgeDays config key (default: 7) controls how long cached data is considered fresh. When you run Get-ROAccess, stale entries are automatically refreshed from Secret Server.

```powershell
# Change staleness threshold
Set-ROConfig -Key 'AccessSnapshotMaxAgeDays' -Value '3'
```

## Forcing a Refresh
```powershell
Get-ROAccess -Refresh                          # Refresh all users
Get-ROAccess -Username 'svc.sim01' -Refresh    # Refresh one user
```

## Purging Cache
```powershell
Get-ROAccess -Purge
```
Deletes all rows from the UserAccess table. The next Get-ROAccess call will repopulate from Secret Server.
