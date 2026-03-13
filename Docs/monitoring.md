# Monitoring

## Action Logs
Query the action history stored in the ActionLog table:
```powershell
# Last 20 actions
Get-ROActionLog -Last 20

# Filter by user
Get-ROActionLog -Username 'svc.sim01' -Since (Get-Date).AddDays(-1)

# Filter by action type
Get-ROActionLog -ActionName 'ViewSecret' -Last 50

# Date range
Get-ROActionLog -Since '2024-01-01' -Until '2024-01-31'
```

## Log Files
Daily rotating log files are written to the Logs/ directory (or the Logs subfolder under $env:RO_DATA_PATH). Each entry includes timestamp, level, component, and message. Files are named RobOtters_YYYY-MM-DD.log.

## Cycle Summaries
Start-ROCycle returns a summary object:
```
StartTime    : 2024-01-15 09:00:01
EndTime      : 2024-01-15 09:02:34
TotalUsers   : 10
ActiveUsers  : 7
TotalActions : 42
Errors       : 1
```

Cycle summaries are also stored in the CycleLog table in the database.
