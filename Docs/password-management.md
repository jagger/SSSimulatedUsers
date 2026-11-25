# Password Management

## Encryption at Rest
User passwords in the SQLite database are encrypted using one of two methods:

### DPAPI (Default)
Data Protection API, tied to the Windows user account. No extra setup required. Passwords can only be decrypted by the same Windows account that encrypted them.

### AES-256 (Optional)
Supply a Base64-encoded 32-byte key. When one is available, all password operations use AES-256 encryption instead of DPAPI.

The key is resolved in this order:

1. `$env:RO_ENCRYPT_KEY` - for interactive or development sessions.
2. `<DataRoot>\encryption.key` - DPAPI-protected (LocalMachine scope), ACL'd to SYSTEM, Administrators and the service account. This is what the scheduled task uses.

```powershell
# Generate a key with a CSPRNG - Get-Random is NOT suitable for key material
$key = [Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))

# Store it in the protected key file for the scheduled task
.\Register-ROTask.ps1 -EncryptionKey (ConvertTo-SecureString $key -AsPlainText -Force) `
                      -ServiceAccountPassword (Read-Host 'Service account password' -AsSecureString)

# Current session only
$env:RO_ENCRYPT_KEY = $key
```

> **Never** store the key in a machine-level environment variable. `BUILTIN\Users` has read access to that registry key, so any authenticated user on the server could recover it and decrypt every stored password.

### Migrating from DPAPI to AES
Use the Convert-ROPasswordEncryption.ps1 script:
```powershell
.\Scripts\Convert-ROPasswordEncryption.ps1
```
This re-encrypts all passwords and updates the scheduled task action. The key itself is never written into the task arguments.

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
