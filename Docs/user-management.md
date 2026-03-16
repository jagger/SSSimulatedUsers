# User Management

Simulated users are AD accounts whose credentials are stored in the RobOtters SQLite database. All username lookups are case-insensitive.

## Adding Users
```powershell
Add-ROUser -Username 'svc.sim01' -Password 'P@ssw0rd!' -Domain 'LAB'

# With custom active hours
Add-ROUser -Username 'svc.sim02' -Password 'S3cret!' -Domain 'LAB' -ActiveHourStart '09:00' -ActiveHourEnd '21:00'
```
The AD account is validated via `Get-ADUser` before insertion -- the command fails if the account does not exist in Active Directory. Passwords are encrypted before storage (DPAPI by default, or AES-256 if `RO_ENCRYPT_KEY` is set). Default action weights are seeded automatically.

## Listing Users
```powershell
Get-ROUser                                    # All users
Get-ROUser -Username 'svc.sim01'              # Single user
Get-ROUser -IncludeWeights                    # Include action weights
Get-ROUser -Username 'svc.sim01' -ShowPassword  # Show decrypted password
```

## Updating Users
```powershell
Set-ROUser -Username 'svc.sim01' -ActiveHourEnd '19:00'
Set-ROUser -Username 'svc.sim01' -IsEnabled $false      # Disable
Set-ROUser -Username 'svc.sim01' -RandomPassword         # New random password
Set-ROUser -Username 'svc.sim01' -ActionWeights @{ ViewSecret = 50 }
```
When changing passwords (-Password or -RandomPassword), the AD account is updated first. If the AD update fails, the SQLite record is not changed.

## Removing Users
```powershell
Remove-ROUser -Username 'svc.sim01'
Remove-ROUser -Username 'svc.sim01' -WhatIf   # Preview
```
ActionWeight rows are deleted. ActionLog entries are preserved for history.

## Active Hours
Each user has ActiveHourStart and ActiveHourEnd (HH:mm format). During a cycle, users outside their active hours are skipped unless -Force is used with Start-ROCycle.
