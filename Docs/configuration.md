# Configuration

## Config Keys

All configuration is stored in the Config SQLite table (11 keys). Use Get-ROConfig and Set-ROConfig to read and write values.

| Key | Default | Description |
|-----|---------|-------------|
| SecretServerUrl | https://yoursecretserver/SecretServer | Base URL of the Secret Server instance |
| DefaultDomain | LAB | AD domain for user authentication |
| MinActionsPerCycle | 0 | Minimum actions per user per cycle |
| MaxActionsPerCycle | 15 | Maximum actions per user per cycle |
| LogRetentionDays | 30 | Days to keep action log entries |
| PasswordRotationDays | 14 | Days between automatic AD password rotations |
| AuthFailureAction | AlertOnly | Auth failure behavior: AlertOnly or RotateAndAlert |
| LauncherTemplateId | 6052 | Template ID for launcher-based secret actions |
| AccessSnapshotMaxAgeDays | 7 | Days before user access snapshots are considered stale |
| DisabledActions | (empty) | Comma-separated list of globally disabled action names |
| DisabledCategories | (empty) | Comma-separated list of globally disabled categories (Core, Management, Advanced) |

## Examples
```powershell
# View all config
Get-ROConfig

# Set a single value
Set-ROConfig -Key 'MaxActionsPerCycle' -Value '20'
```

## Action Weights

Each user has per-action weights controlling how likely each action is selected. Higher weight = more frequent.

Defaults come from Data/SeedActionWeights.psd1 and are assigned when a user is created via Add-ROUser.

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
| LaunchSecret | 8 |
| ToggleComment | 2 |
| ToggleCheckout | 2 |

### Customizing Weights
```powershell
# Update weights for a single user
Set-ROUser -Username 'svc.sim01' -ActionWeights @{
    ViewSecret = 50
    CreateSecret = 10
    CreateFolder = 0  # disable this action
}

# View a user's current weights
Get-ROUser -Username 'svc.sim01' -IncludeWeights
```

To change defaults for all new users, edit Data/SeedActionWeights.psd1 before running Add-ROUser.

### Disabling Actions Globally
```powershell
# Disable specific actions for all users
Set-ROConfig -Key 'DisabledActions' -Value 'CreateSecret,CreateFolder'

# Disable an entire category for all users
Set-ROConfig -Key 'DisabledCategories' -Value 'Management'

# Clear (re-enable all)
Set-ROConfig -Key 'DisabledActions' -Value ''
Set-ROConfig -Key 'DisabledCategories' -Value ''
```

Categories: **Core** (SearchSecrets, ViewSecret, CheckoutPassword, ListFolderSecrets, BrowseFolders), **Management** (CreateFolder, CreateSecret, EditSecret, MoveSecret, ToggleComment, ToggleCheckout, ExpireSecret), **Advanced** (CheckinSecret, RunReport, AddFavorite, TriggerHeartbeat, ViewSecretPolicy, ChangePassword, LaunchSecret).

Global disables take precedence over per-user weights.

### Disabling Actions Per User
```powershell
# Disable an entire category for one user
Set-ROUser -Username 'svc.sim01' -DisableCategory 'Management'

# Re-enable (restores default weights)
Set-ROUser -Username 'svc.sim01' -EnableCategory 'Management'

# Disable/enable a single action
Set-ROUser -Username 'svc.sim01' -DisableAction 'CreateSecret'
Set-ROUser -Username 'svc.sim01' -EnableAction 'CreateSecret'
```
