# Start-ROCycle

## Synopsis
Run a simulation cycle.

## Syntax
```powershell
Start-ROCycle [-Force] [-WhatIf]

Start-ROCycle [-User] <String> [-Force] [-WhatIf]
```

## Description
Executes a simulation cycle where active users perform randomized Secret Server
actions. In full mode (no -User parameter), the cycle rotates passwords for users
due for rotation and then runs actions for every active user. In single-user mode
only the specified user is processed. The -Force switch bypasses active-hour
filtering. Supports -WhatIf for dry runs.

## Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| User | String | No | -- | Run the cycle for a single user only |
| Force | Switch | No | -- | Bypass active-hour checks and run for all enabled users |
| WhatIf | Switch | No | -- | Show what actions would be taken without executing them |

## Examples

### Example 1: Run a full cycle
```powershell
Start-ROCycle
```
Processes all active users within their configured active hours.

### Example 2: Force a full cycle outside business hours
```powershell
Start-ROCycle -Force
```
Runs all enabled users regardless of their active-hour settings.

### Example 3: Run a single user
```powershell
Start-ROCycle -User 'svc-simuser01'
```
Executes a cycle for only the specified user.

### Example 4: Preview a cycle
```powershell
Start-ROCycle -WhatIf
```
Displays what would happen without performing any actions.

## Outputs

| Property | Type | Description |
|----------|------|-------------|
| StartTime | DateTime | When the cycle began |
| EndTime | DateTime | When the cycle completed |
| TotalUsers | Int32 | Number of enabled users |
| ActiveUsers | Int32 | Number of users that ran actions |
| TotalActions | Int32 | Total actions executed across all users |
| Errors | Int32 | Number of actions that failed |

## Related Commands
- [Get-ROActionLog](Get-ROActionLog.md)
- [Get-ROUser](Get-ROUser.md)
- [Get-ROConfig](Get-ROConfig.md)
