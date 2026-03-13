# Password Management

## Encryption at Rest
User passwords in the SQLite database are encrypted using one of two methods:

### DPAPI (Default)
Data Protection API, tied to the Windows user account. No extra setup required. Passwords can only be decrypted by the same Windows account that encrypted them.

### AES-256 (Optional)
Set the RO_ENCRYPT_KEY environment variable to a Base64-encoded 32-byte key. When set, all password operations use AES-256 encryption instead of DPAPI.

```powershell
# Generate a key
$key = [Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))
[Environment]::SetEnvironmentVariable('RO_ENCRYPT_KEY', $key, 'Machine')
$env:RO_ENCRYPT_KEY = $key
```

### Migrating from DPAPI to AES
Use the Convert-ROPasswordEncryption.ps1 script:
```powershell
.\Scripts\Convert-ROPasswordEncryption.ps1
```
This re-encrypts all passwords and updates the scheduled task to include the encryption key.

## Automatic Password Rotation
The PasswordRotationDays config key (default: 14) controls how often passwords are rotated. During each full cycle, Start-ROCycle checks which users are due for rotation and generates new random passwords.

```powershell
# Change rotation interval
Set-ROConfig -Key 'PasswordRotationDays' -Value '7'
```

## Auth Failure Recovery
The AuthFailureAction config key controls what happens when a user fails to authenticate:

- **AlertOnly** (default): Logs a warning and skips the user for that cycle.
- **RotateAndAlert**: Automatically rotates the password and retries authentication.

```powershell
Set-ROConfig -Key 'AuthFailureAction' -Value 'RotateAndAlert'
```

## Manual Password Changes
```powershell
# Set a specific password (updates AD + SQLite)
Set-ROUser -Username 'svc.sim01' -Password 'NewP@ss!'

# Generate a random password (updates AD + SQLite)
Set-ROUser -Username 'svc.sim01' -RandomPassword
```
