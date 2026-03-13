# Running Cycles

## Full Cycle (All Users)
```powershell
Import-Module .\RobOtters.psd1
Start-ROCycle
```
A full cycle:
1. Rotates passwords for users due for rotation (based on PasswordRotationDays)
2. Gets all enabled users within their active hours
3. For each user: authenticates, picks a random number of actions (MinActionsPerCycle to MaxActionsPerCycle), executes them, logs results

Returns a cycle summary: StartTime, EndTime, TotalUsers, ActiveUsers, TotalActions, Errors.

## Single-User Mode
```powershell
Start-ROCycle -User 'svc.sim01'
```
Runs only for the specified user. Does not run password rotation. Still checks active hours unless -Force is used.

## Forcing Execution
```powershell
Start-ROCycle -User 'svc.sim01' -Force
```
Overrides active hour restrictions.

## Preview Mode
```powershell
Start-ROCycle -WhatIf
```
Shows what would happen without executing any actions.

## Scheduled Execution
For unattended operation, register a scheduled task that runs every 30 minutes:
```powershell
.\Register-ROTask.ps1
```
The task runs as the highest privilege level and executes: Import-Module + Start-ROCycle.
