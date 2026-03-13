# RobOtters - Secret Server Activity Simulator

![RobOtter mascot](RobOtter.jpg)

PowerShell module that simulates realistic Secret Server user activity for lab and demo environments. AD-authenticated users perform randomized actions (0-15 per 30-minute cycle) against an on-prem Delinea Secret Server instance, generating audit trail data that looks like real-world usage*. Add as many or as few simulated accounts as your environment needs.


<sub>\* assuming your users login one at a time every 30 min and take a few random actions that don't relate to each other
## Prerequisites

- Windows Server 2016+ with PowerShell 5.1+
- Active Directory domain with user accounts for simulation
- [PSSQLite](https://github.com/RamblingCookieMonster/PSSQLite) module
- Delinea Secret Server instance with REST API enabled (`/api/v1/*`)
- Secrets and folders that the simulated users have access to

## Installation

```powershell
# Clone the repo
git clone https://github.com/jagger/SSSimulatedUsers.git C:\projects\TheSimz

# Install PSSQLite (if not already installed)
Install-Module -Name PSSQLite -Scope CurrentUser

# Import the module
Import-Module C:\projects\TheSimz\RobOtters.psd1
```

## Initial Setup

```powershell
# 1. Create the SQLite database and seed default config
Initialize-RODatabase

# 2. Point to your Secret Server instance
Set-ROConfig -Key 'SecretServerUrl' -Value 'https://yourserver/SecretServer'
Set-ROConfig -Key 'DefaultDomain' -Value 'YOURDOMAIN'

# 3. Verify connectivity
Test-ROConnection
```

## User Management

Simulated users are AD accounts whose credentials are stored locally in the SQLite database. Each user gets default action weights on creation.

### Add a user

```powershell
Add-ROUser -Username 'svc.sim01' -Password 'P@ssw0rd!' -Domain 'LAB'
```

Optional parameters:
- `-ActiveHourStart` (default `07:00`) - earliest time the user will be active
- `-ActiveHourEnd` (default `17:00`) - latest time the user will be active

### List users

```powershell
Get-ROUser                         # all users
Get-ROUser -Username 'svc.sim01'   # specific user
```

### Update a user

```powershell
Set-ROUser -Username 'svc.sim01' -ActiveHourEnd '19:00'
Set-ROUser -Username 'svc.sim01' -IsEnabled $false   # disable without deleting
```

### Remove a user

```powershell
Remove-ROUser -Username 'svc.sim01'
```

## Running

### Manual execution

```powershell
Import-Module C:\projects\TheSimz\RobOtters.psd1
Start-ROCycle
```

Each cycle iterates through all enabled users, checks whether they are within their active hours, selects a random number of actions (0-15), and executes them against Secret Server.

### Scheduled task (recommended)

Run `Register-ROTask.ps1` as Administrator to create a Windows Task Scheduler job that fires every 30 minutes:

```powershell
.\Register-ROTask.ps1
```

> **Note:** Edit the script first if your module is installed at a path other than `C:\projects\TheSimz`.

## Configuration

All configuration is stored in the `Config` SQLite table. View current values with `Get-ROConfig` and update with `Set-ROConfig`.

| Key | Default | Description |
|-----|---------|-------------|
| `SecretServerUrl` | `https://yoursecretserver/SecretServer` | Base URL of the Secret Server instance |
| `DefaultDomain` | `LAB` | AD domain used when authenticating users |
| `MinActionsPerCycle` | `0` | Minimum actions a user performs per cycle |
| `MaxActionsPerCycle` | `15` | Maximum actions a user performs per cycle |
| `LogRetentionDays` | `30` | Days to retain action log entries |
| `PasswordRotationDays` | `14` | Days between automatic password rotations |
| `AuthFailureAction` | `AlertOnly` | Auth failure behavior: `AlertOnly` (skip user) or `RotateAndAlert` (rotate password + retry) |

## Action Weights

Each user has per-action weights that control how likely each action is to be selected. Higher weight = more frequent. Defaults are seeded from `Data/SeedActionWeights.psd1`:

| Action | Default Weight |
|--------|---------------|
| ViewSecret | 25 |
| SearchSecrets | 20 |
| CheckoutPassword | 15 |
| ListFolderSecrets | 15 |
| BrowseFolders | 15 |
| CheckinSecret | 10 |
| CreateSecret | 5 |
| EditSecret | 5 |
| RunReport | 5 |
| AddFavorite | 5 |
| ViewSecretPolicy | 5 |
| ExpireSecret | 3 |
| ChangePassword | 3 |
| CreateFolder | 3 |
| MoveSecret | 3 |
| TriggerHeartbeat | 3 |
| ToggleComment | 2 |
| ToggleCheckout | 2 |

To customize weights for a specific user, update the `ActionWeight` table directly via SQLite or modify `SeedActionWeights.psd1` before adding users.

## AD Group & Secret Server Reports

For easy monitoring inside Secret Server, put all your simulated accounts into a single AD group and sync it into SS.

### Setup

1. **Create an AD group** (e.g. `SimulatedUsers`) and add every sim account as a member
2. **Sync the group** into Secret Server via Admin > Active Directory > Synchronize Now
3. **Create custom reports** in Secret Server (Admin > Reports > New Report) using the SQL files in `Data/Reports/`:

| Report | File | Description |
|--------|------|-------------|
| User Activity Summary | `ROUserActivity.sql` | Per-user action counts and last-active timestamps (today, 7d, 30d) |
| Full Audit Trail | `ROFullAuditTrail.sql` | All secret, folder, and user audit events with SS date picker support |

4. **Update the group name** in each SQL file to match your AD group (default: `SimulatedUsers`)

### Example: creating the report

In Secret Server:
1. Go to **Admin > Reports > New Report**
2. Set **Category** to `User`
3. Paste the contents of `Data/Reports/ROUserActivity.sql`
4. Name it something like "Simulated User Activity"
5. Save and run

## Monitoring

### Action log

```powershell
# Last 20 actions
Get-ROActionLog -Last 20

# Filter by user
Get-ROActionLog -Username 'svc.sim01' -Since (Get-Date).AddDays(-1)

# Filter by action type
Get-ROActionLog -ActionName 'ViewSecret' -Last 50
```

### Log files

Daily rotating log files are written to the `Logs/` directory. Each entry includes timestamp, component, and message.

## Project Structure

```
TheSimz/
├── RobOtters.psd1          # Module manifest
├── RobOtters.psm1          # Dot-source loader
├── Register-ROTask.ps1     # Task Scheduler registration script
├── Data/                   # Schema, seed data, SS reports, SQLite DB (runtime)
├── Public/                 # Exported cmdlets (13 functions)
├── Private/
│   ├── Actions/            # 18 Secret Server action functions
│   ├── Api/                # REST client + OAuth2 auth
│   ├── Data/               # SQLite helpers
│   ├── Engine/             # Cycle orchestration + action selection
│   └── Logging/            # File + DB logging
├── Logs/                   # Daily rotating logs (gitignored)
└── Tests/                  # Pester tests
```

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the [MIT License](LICENSE).
