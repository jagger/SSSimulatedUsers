# Getting Started with RobOtters

## Prerequisites
- Windows Server 2016+ with PowerShell 5.1+
- Active Directory domain with user accounts for simulation
- PSSQLite module (Install-Module PSSQLite -Scope CurrentUser, or manual copy)
- Delinea Secret Server instance with REST API enabled (/api/v1/*)
- Secrets and folders that simulated users have access to
- AD user accounts must exist before adding them to RobOtters

## Installation

### Option 1: Git Clone
```powershell
git clone https://github.com/jagger/SSSimulatedUsers.git RobOtters
```

### Option 2: ZIP Download
Download and extract from GitHub releases.

### Option 3: Copy to Module Path
Copy the module folder to a path in $env:PSModulePath.

## First-Time Setup
```powershell
# Import the module
Import-Module .\RobOtters.psd1

# Create/upgrade the database
Initialize-RODatabase

# Configure Secret Server connection
Set-ROConfig -Key 'SecretServerUrl' -Value 'https://yourserver/SecretServer'
Set-ROConfig -Key 'DefaultDomain' -Value 'YOURDOMAIN'

# Add your first simulated user
Add-ROUser -Username 'svc.sim01' -Password 'P@ssw0rd!' -Domain 'YOURDOMAIN'

# Test connectivity
Test-ROConnection -Username 'svc.sim01'

# Run a single cycle
Start-ROCycle
```

## Encryption (Optional but Recommended)
By default, passwords are encrypted with DPAPI (tied to the Windows account). For AES-256 encryption (portable across accounts), generate a key and hand it to `Register-ROTask.ps1`, which stores it in a protected key file:
```powershell
# Cryptographically secure - do not use Get-Random for key material
$key = [Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))

# Writes <DataRoot>\encryption.key, DPAPI-protected and ACL'd to
# SYSTEM, Administrators and the service account.
.\Register-ROTask.ps1 -EncryptionKey (ConvertTo-SecureString $key -AsPlainText -Force) `
                      -ServiceAccountPassword (Read-Host 'Service account password' -AsSecureString)

# Current session only, for interactive use:
$env:RO_ENCRYPT_KEY = $key
```
The scheduled task reads the key file at runtime. **Do not** embed the key in task arguments, and **do not** store it in a machine-level environment variable - that registry location is readable by every authenticated user on the server. See [Password Management](password-management.md) for details.

## Setting Up the Scheduled Task
Pass the key via `-EncryptionKey` (if using AES encryption) when running:
```powershell
.\Register-ROTask.ps1
```
This creates a Windows Task Scheduler job that imports the module and runs Start-ROCycle.

## Next Steps
- [Configuration](configuration.md) - tune action counts, rotation, and more
- [User Management](user-management.md) - add/remove/update simulated users
- [Running Cycles](running-cycles.md) - manual, single-user, and scheduled execution
