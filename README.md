# RobOtters

![RobOtter mascot](assets/RobOtter.jpg)

PowerShell module that simulates realistic Secret Server user activity for lab and demo environments. AD-authenticated users perform randomized actions against an on-prem Delinea Secret Server instance, generating audit trail data that looks like real-world usage.

## Quickstart

```powershell
# Import the module (from the repo root)
Import-Module .\RobOtters.psd1

# Create the database
Initialize-RODatabase

# Configure your Secret Server
Set-ROConfig -Key 'SecretServerUrl' -Value 'https://yourserver/SecretServer'
Set-ROConfig -Key 'DefaultDomain' -Value 'YOURDOMAIN'

# Add a simulated user
Add-ROUser -Username 'svc.sim01' -Password 'P@ssw0rd!' -Domain 'YOURDOMAIN'

# Test connectivity
Test-ROConnection -Username 'svc.sim01'

# Run a cycle
Start-ROCycle
```

## Features

- **User simulation** with configurable action weights -- [Configuration](Docs/configuration.md)
- **Automatic password rotation** and auth failure recovery -- [Password Management](Docs/password-management.md)
- **Export/import** for environment portability -- [Export & Import](Docs/export-import.md)
- **User access snapshots** -- [Access Snapshots](Docs/access-snapshots.md)
- **Secret Server reports** from SQL templates -- [Reports](Docs/secret-server-reports.md)

## Commands

| Command | Description |
|---------|-------------|
| [Initialize-RODatabase](Docs/commands/Initialize-RODatabase.md) | Create or upgrade the SQLite database |
| [Add-ROUser](Docs/commands/Add-ROUser.md) | Register a simulated AD user |
| [Remove-ROUser](Docs/commands/Remove-ROUser.md) | Remove a simulated user |
| [Get-ROUser](Docs/commands/Get-ROUser.md) | List simulated users |
| [Set-ROUser](Docs/commands/Set-ROUser.md) | Update user properties |
| [Start-ROCycle](Docs/commands/Start-ROCycle.md) | Run a simulation cycle |
| [Get-ROActionLog](Docs/commands/Get-ROActionLog.md) | Query the action history |
| [Get-ROConfig](Docs/commands/Get-ROConfig.md) | Read configuration values |
| [Set-ROConfig](Docs/commands/Set-ROConfig.md) | Set a configuration value |
| [Test-ROConnection](Docs/commands/Test-ROConnection.md) | Test Secret Server authentication |
| [Get-ROAccess](Docs/commands/Get-ROAccess.md) | View user access snapshots |
| [Export-ROConfig](Docs/commands/Export-ROConfig.md) | Export configuration and users to JSON |
| [Import-ROConfig](Docs/commands/Import-ROConfig.md) | Import configuration and users from JSON |

## Installation

### Git Clone
```powershell
git clone https://github.com/yourorg/RobOtters.git
Import-Module .\RobOtters\RobOtters.psd1
```

### ZIP Download
Download from GitHub, extract, and import:
```powershell
Import-Module .\RobOtters\RobOtters.psd1
```

### Module Path
Copy the module folder to a directory in `$env:PSModulePath`, then:
```powershell
Import-Module RobOtters
```

### Prerequisites
- Windows Server 2016+ with PowerShell 5.1+
- Active Directory domain with user accounts for simulation
- [PSSQLite](https://github.com/RamblingCookieMonster/PSSQLite) module
- Delinea Secret Server with REST API enabled

See [Getting Started](Docs/getting-started.md) for a full walkthrough.

## Configuration

All settings are stored in the Config SQLite table. Key settings:

| Key | Default | Description |
|-----|---------|-------------|
| SecretServerUrl | (placeholder) | Secret Server base URL |
| DefaultDomain | LAB | AD domain name |
| MinActionsPerCycle | 0 | Min actions per user per cycle |
| MaxActionsPerCycle | 15 | Max actions per user per cycle |
| PasswordRotationDays | 14 | Days between password rotations |

See [Configuration](Docs/configuration.md) for the full list of 9 config keys and action weight customization.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| PSSQLite not found | `Install-Module PSSQLite -Scope CurrentUser` |
| SecretServerUrl not configured | `Set-ROConfig -Key SecretServerUrl -Value '...'` |
| Auth failed | `Test-ROConnection -Username X` and check password |
| 0 actions in scheduled task | Users may be outside active hours; use `-Force` or adjust times |

See [Troubleshooting](Docs/troubleshooting.md) for the full guide.

## Project Structure

```
RobOtters/
+-- RobOtters.psd1          # Module manifest
+-- RobOtters.psm1          # Dot-source loader
+-- Register-ROTask.ps1     # Task Scheduler registration
+-- assets/                 # Images
+-- Data/                   # Schema, seed data, SS reports
+-- Docs/                   # Guides and command reference
+-- Public/                 # 13 exported commands
+-- Private/
|   +-- Actions/            # 18 Secret Server action functions
|   +-- Api/                # REST client + OAuth2
|   +-- Data/               # SQLite helpers
|   +-- Engine/             # Cycle orchestration
|   +-- Logging/            # File + DB logging
+-- Scripts/                # Migration utilities
+-- Logs/                   # Daily rotating logs (gitignored)
+-- Tests/                  # Pester tests
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

[MIT License](LICENSE)
