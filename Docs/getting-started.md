# Getting Started with RobOtters

## Prerequisites
- Windows Server 2016+ with PowerShell 5.1+
- Active Directory domain with user accounts for simulation
- PSSQLite module (Install-Module PSSQLite -Scope CurrentUser, or manual copy)
- Delinea Secret Server instance with REST API enabled (/api/v1/*)
- Secrets and folders that simulated users have access to

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

## Encryption (Optional)
By default, passwords are encrypted with DPAPI (tied to the Windows account). For AES-256 encryption (portable across accounts), set the `RO_ENCRYPT_KEY` environment variable:
```powershell
$key = [Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))
[Environment]::SetEnvironmentVariable('RO_ENCRYPT_KEY', $key, 'Machine')
$env:RO_ENCRYPT_KEY = $key
```
See [Password Management](password-management.md) for details.

## Setting Up the Scheduled Task
For automated execution every 30 minutes:
```powershell
.\Register-ROTask.ps1
```
This creates a Windows Task Scheduler job that imports the module and runs Start-ROCycle.

## Next Steps
- [Configuration](configuration.md) - tune action counts, rotation, and more
- [User Management](user-management.md) - add/remove/update simulated users
- [Running Cycles](running-cycles.md) - manual, single-user, and scheduled execution
