# Changelog

All notable changes to the RobOtters module will be documented in this file.

## [1.2.0] - 2026-03-20

### Fixed
- Reduced action failure rate from ~31% to <10% by adding resilience to all 12 action functions
- **CheckinSecret**: Per-secret detail fetch wrapped in try/catch; skips inaccessible secrets
- **LaunchSecret**: No-template result reclassified as success; launch POST wrapped in inner try/catch
- **ViewSecret**: Retry loop with up to 3 candidates when secrets require checkout/comment
- **RunReport**: No-reports result reclassified as success; report execution wrapped in inner try/catch
- **CreateSecret**: Retry with different template on stub/validation failures; smarter field filling
- **CheckoutPassword**: Retry loop for detail fetch; checkout denial treated as graceful result
- **ChangePassword**: Detail fetch per candidate wrapped in try/catch; skips inaccessible secrets
- **ExpireSecret**: Retry loop with up to 3 candidates for expire POST
- **EditSecret**: Retry loop with up to 3 candidates for field PUT
- **MoveSecret**: Prefers personal folders for move target; retry loop with inner try/catch
- **ToggleComment**: Skips checked-out secrets; retry loop with up to 3 candidates
- **ToggleCheckout**: Retry loop with up to 3 candidates; inner try/catch on PUT

### Improved
- API error logging now extracts response body from 400 errors for easier debugging

## [1.1.0] - 2026-03-17

### Added
- 7 new Secret Server actions (26 total):
  - **Core**: ViewSecretAudit, RemoveFavorite, ViewRecentActivity
  - **Management**: RenameFolder
  - **Advanced**: ListExpiredSecrets, ViewSecretDependencies, GeneratePassword
- Existing users automatically receive new action weights via backfill logic

## [1.0.0] - 2026-03-16

### Added
- `Test-ROHealth` pre-flight validation command
- Cycle lock file to prevent overlapping runs
- Log retention enforcement (auto-cleanup old log files)
- Configurable inter-action delay (`MinActionDelaySec`, `MaxActionDelaySec`)
- Token expiry check before API calls
- CHANGELOG.md
- SECURITY.md
- Pester unit tests for all 13 public functions

### Fixed
- Encryption key no longer embedded in scheduled task arguments

### Changed
- Module manifest updated with tags, release notes, copyright

## [0.5.0] - 2026-03-08

### Added
- Global action/category enable/disable via `DisabledActions` and `DisabledCategories` config keys
- Per-user action/category enable/disable via `Set-ROUser -EnableAction/-DisableAction/-EnableCategory/-DisableCategory`
- `Get-ROActionRegistry` returns category metadata for all 19 actions

## [0.4.0] - 2026-03-05

### Added
- AD account validation on `Add-ROUser` (user must exist in AD)
- Case-insensitive username lookups across all queries

### Changed
- Updated documentation to reflect AD validation requirements

## [0.3.0] - 2026-02-28

### Fixed
- PowerShell 7 cycle failure caused by parameter binding differences
- `CreateSecret` template permissions for non-admin users

### Changed
- Documentation rewrite to match current codebase

## [0.2.0] - 2026-02-20

### Changed
- Rebranded from TheSimz/Simz to RobOtters/RO
- All function prefixes changed from `Simz` to `RO`
- Scheduled task renamed from `TheSimz` to `RobOtters`
- Environment variables renamed from `SIMZ_*` to `RO_*`

### Added
- Migration script `Migrate-ToRobOtters.ps1`

## [0.1.0] - 2026-02-10

### Added
- Initial release with 18 Secret Server action functions
- SQLite-backed user and config storage
- OAuth2 password grant authentication
- Weighted random action selection per user
- Active hour restrictions
- Configurable action counts per cycle (0-15)
- DPAPI and AES-256 password encryption
- File and database logging
- Windows Task Scheduler integration
