# Security

## Encryption Model

RobOtters stores user passwords encrypted at rest in the SQLite database. Two encryption modes are supported:

- **DPAPI (default):** Uses Windows Data Protection API, tied to the Windows account that encrypted the data. Suitable for single-server deployments where the same account runs the module.
- **AES-256:** Enabled by supplying a base64-encoded 32-byte key, either via the `RO_ENCRYPT_KEY` environment variable (interactive use) or, for the scheduled task, a DPAPI-protected key file. Portable across accounts and servers.

### Key Management

- Generate a key with a CSPRNG: `[Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))`
  (`Get-Random` is **not** cryptographically secure and must not be used for key material.)
- Store it for the scheduled task with `Register-ROTask.ps1 -EncryptionKey`. That writes `<DataRoot>\encryption.key`, DPAPI-protected at LocalMachine scope, with inheritance broken and access limited to SYSTEM, Administrators and the service account.
- **Do not** store the key in a machine-level environment variable. `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment` grants `BUILTIN\Users` read access, so every authenticated user on the server could read it.
- **Do not** embed the key in scheduled task arguments, scripts, or source control
- `RO_ENCRYPT_KEY` is still honoured and takes precedence over the key file. Prefer it only for interactive or development sessions, scoped to the current process.
- Back up the key securely; losing it means passwords cannot be decrypted
- Rotate the key by running `Convert-ROPasswordEncryption.ps1` after updating the env var

## Threat Boundaries

RobOtters is designed for **lab environments** only. It simulates user activity against a non-production Secret Server instance.

- **Single-server scope:** The module runs on one Windows server, accessing one Secret Server instance
- **Lab-only:** Not intended for production Secret Server instances; simulated users should have limited, lab-appropriate permissions
- **Local trust:** The SQLite database, log files, and encryption key all reside on the same server; local admin access grants full access to all stored data

## Log File Contents

Log files in `<DataRoot>/Logs/` contain:
- Timestamps, usernames, action names, target IDs and names
- Error messages (may include API response details)
- No passwords or tokens are logged

Log files are retained for `LogRetentionDays` (default 30), after which they are automatically cleaned up.

## Export Password Warning

`Export-ROConfig -IncludePasswords` writes **plaintext passwords** to a JSON file. Handle exported files with the same care as the encryption key. Delete export files after use.

## Responsible Disclosure

To report a security issue, contact the project maintainer directly via the repository's issue tracker or email. Do not open a public issue for security vulnerabilities.
