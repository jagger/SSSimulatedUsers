# Troubleshooting

## Common Issues

| Problem | Cause | Fix |
|---------|-------|-----|
| "PSSQLite module not found" | Module not installed | `Install-Module PSSQLite -Scope CurrentUser` or copy manually to a PSModulePath |
| "SecretServerUrl not configured" | Default placeholder value | `Set-ROConfig -Key SecretServerUrl -Value 'https://...'` |
| "Auth failed for user X" | Wrong password or AD lockout | `Test-ROConnection -Username X`, check password with `Get-ROUser -ShowPassword` |
| Scheduled task runs but 0 actions | All users outside active hours | Check with `Get-ROUser`, use `-Force`, or adjust ActiveHourStart/End |
| "No active users for this cycle" | All users disabled or outside hours | `Set-ROUser -Username X -IsEnabled $true` |
| Database location unknown | RO_DATA_PATH env var or ProgramData | Check `Get-ROConfig` output, or `$env:RO_DATA_PATH` |
| Passwords changed in AD externally | Mismatch between AD and SQLite | `Set-ROUser -Username X -Password 'newpass'` |
| "Schema file not found" | Incomplete module copy | Ensure Data/Schema.sql exists alongside the module |
| Token expired errors | Session timeout during long cycles | Automatic retry handles this; check LogRetentionDays logs |
| DPAPI decryption fails | Running as different Windows account | Passwords encrypted under one account cannot be decrypted by another; see [Password Management](password-management.md) |
| "RO_ENCRYPT_KEY is not set" | AES passwords but env var missing | Set `RO_ENCRYPT_KEY` at Machine level and restart PowerShell |
| All users show empty username/password | Stale module loaded in session | Close PowerShell and reimport in a fresh window |
| "API_SecretTypeCannotBeCreatedByUser" | User lacks template permissions | Fixed in v0.3.0; CreateSecret now queries available templates dynamically |

## Diagnostic Steps

### Check Module Loads
```powershell
Import-Module .\RobOtters.psd1 -Force
Get-Command -Module RobOtters
```

### Verify Database
```powershell
Initialize-RODatabase   # Idempotent, safe to re-run
Get-ROConfig            # Should show all 9 config keys
Get-ROUser              # Should list registered users
```

### Test Connectivity
```powershell
Test-ROConnection -Username 'svc.sim01'
```

### Check Logs
Log files are in the Logs/ directory (or Logs subfolder under $env:RO_DATA_PATH). Check the most recent file for errors:
```powershell
Get-Content (Get-ChildItem Logs\*.log | Sort-Object LastWriteTime -Descending | Select-Object -First 1)
```

### Review Action History
```powershell
Get-ROActionLog -Last 10
```
