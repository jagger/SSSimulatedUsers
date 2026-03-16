# RobOtters -- Project Conventions

## Overview
PowerShell module (RobOtters) that simulates Secret Server user activity for lab environments.
AD-authenticated users perform randomized actions (0-15 per 30-min cycle) against
an on-prem Delinea Secret Server instance to generate realistic audit trail data.

## Architecture
- **PowerShell module** (`RobOtters.psd1` / `RobOtters.psm1`) with Public/Private function split
- **SQLite** via PSSQLite module for credential store, config, and action logs
- **REST API** calls to Secret Server `/api/v1/*` endpoints with OAuth2 password grant
- Runs unattended via **Windows Task Scheduler** every 30 minutes

## Directory Layout
```
RobOtters/
+-- RobOtters.psd1          # Module manifest
+-- RobOtters.psm1          # Dot-source loader
+-- Register-ROTask.ps1     # Task Scheduler registration
+-- assets/                 # Images
+-- Data/                   # Schema, seed data, SS reports
+-- Docs/                   # Guides and command reference
+-- Public/                 # Exported cmdlets (13 commands)
+-- Private/                # Internal functions
|   +-- Data/               # DB helpers
|   +-- Api/                # Secret Server REST client
|   +-- Actions/            # 19 Secret Server action functions
|   +-- Engine/             # Cycle orchestration
|   +-- Logging/            # File + DB logging
+-- Scripts/                # Migration utilities
+-- Tests/                  # Pester tests
```

## Data Storage
- **SQLite DB** lives in `$env:ProgramData\RobOtters\` (or `$env:RO_DATA_PATH` if set)
- **Log files** in a `Logs/` subfolder under the data root
- DB and logs are outside the repo directory; gitignored

## Coding Conventions
- **Verb-Noun** naming: all functions use `RO` prefix (`Verb-RO<Noun>`)
- All functions use `[CmdletBinding()]` and named parameters
- Action functions return uniform `[PSCustomObject]@{ Action; TargetType; TargetId; TargetName; Success; ErrorMessage }`
- Use `Write-ROLog` for all operational logging (not Write-Host)
- Errors: use `Write-Error` / `throw` for unrecoverable; `Write-Warning` + continue for transient
- SQL: always parameterized queries via `-SqlParameters` (no string interpolation)
- Secrets: passwords encrypted at rest (DPAPI by default, AES-256 if `RO_ENCRYPT_KEY` env var is set)
- No aliases in scripts; use full cmdlet names
- Prefer splatting for calls with 3+ parameters

## Key Dependencies
- **PSSQLite** -- SQLite access (`Invoke-SqliteQuery`)
- **Secret Server REST API** -- `/api/v1/*` with OAuth2 bearer tokens

## Config Defaults (stored in Config table)
- `SecretServerUrl` -- base URL of the SS instance
- `MinActionsPerCycle` -- 0
- `MaxActionsPerCycle` -- 15
- `LogRetentionDays` -- 30
- `DefaultDomain` -- lab domain name
- `PasswordRotationDays` -- 14 (days between automatic password rotations)
- `AuthFailureAction` -- AlertOnly (or RotateAndAlert)
- `LauncherTemplateId` -- template ID for launcher-based actions
- `AccessSnapshotMaxAgeDays` -- max age for user access snapshots
- `DisabledActions` -- comma-separated list of globally disabled action names
- `DisabledCategories` -- comma-separated list of globally disabled categories (Core, Management, Advanced)

## Testing
- Pester v5+ for unit tests
- `Tests/Unit/` -- pure logic tests (no network/DB)
- `Tests/Integration/` -- requires live SS instance
