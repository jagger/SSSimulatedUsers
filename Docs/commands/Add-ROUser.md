# Add-ROUser

## Synopsis
Register a simulated AD user.

## Syntax
```powershell
Add-ROUser [-Username] <String> [-Password] <String> [-Domain] <String>
           [-ActiveHourStart] <String> [-ActiveHourEnd] <String>
```

## Description
Adds a new simulated Active Directory user to the RobOtters SQLite database. The
password is encrypted via DPAPI before storage. Action weights are automatically
seeded from the SeedActionWeights.psd1 data file so the user is ready to participate
in simulation cycles immediately.

## Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| Username | String | Yes | -- | AD username for the simulated user |
| Password | String | Yes | -- | Plain-text password (encrypted via DPAPI before storage) |
| Domain | String | Yes | -- | AD domain the user belongs to |
| ActiveHourStart | String | No | '07:00' | Start of the user's active window (HH:mm) |
| ActiveHourEnd | String | No | '17:00' | End of the user's active window (HH:mm) |

## Examples

### Example 1: Add a user with defaults
```powershell
Add-ROUser -Username 'svc-simuser01' -Password 'P@ssw0rd!' -Domain 'lab.local'
```
Registers the user with the default active hours of 07:00 to 17:00.

### Example 2: Add a user with custom active hours
```powershell
Add-ROUser -Username 'svc-simuser02' -Password 'S3cur3!' -Domain 'lab.local' `
           -ActiveHourStart '09:00' -ActiveHourEnd '21:00'
```
Registers the user with an extended active window from 09:00 to 21:00.

## Outputs

| Property | Type | Description |
|----------|------|-------------|
| Username | String | The registered username |
| Password | String | The encrypted password value |
| Domain | String | The AD domain |
| ActiveHourStart | String | Start of active window |
| ActiveHourEnd | String | End of active window |
| IsEnabled | Boolean | Whether the user is enabled (true by default) |
| UserId | Int | Auto-generated database ID |

## Related Commands
- [Get-ROUser](Get-ROUser.md)
- [Set-ROUser](Set-ROUser.md)
- [Remove-ROUser](Remove-ROUser.md)
