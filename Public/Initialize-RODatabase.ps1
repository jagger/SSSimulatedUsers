function Initialize-RODatabase {
    <#
    .SYNOPSIS
        Create or upgrade the RobOtters SQLite database
    .DESCRIPTION
        Creates the SQLite database if it does not exist, applies schema from
        Data/Schema.sql, runs migrations (adds PasswordLastChanged column,
        UserAccess table, TemplateCount column), seeds 9 default config values,
        backfills missing action weights from SeedActionWeights.psd1, and
        encrypts any plain-text passwords via DPAPI. Idempotent -- safe to run
        multiple times. Migrates database from old module-local path if found.
    .EXAMPLE
        Initialize-RODatabase
        Create or upgrade the database.
    .EXAMPLE
        Import-Module .\RobOtters.psd1; Initialize-RODatabase
        First-time setup after importing the module.
    .OUTPUTS
        System.String - confirmation message with database path
    .LINK
        Docs/commands/Initialize-RODatabase.md
    #>
    [CmdletBinding()]
    param()

    $dbPath = Get-RODbPath
    $schemaPath = Join-Path $PSScriptRoot '..\Data\Schema.sql'
    $schemaPath = [System.IO.Path]::GetFullPath($schemaPath)

    # Migrate: copy database from old module-local location if it exists
    $oldDbPath = Join-Path $PSScriptRoot '..\Data\RobOtters.sqlite'
    $oldDbPath = [System.IO.Path]::GetFullPath($oldDbPath)
    if ((Test-Path $oldDbPath) -and -not (Test-Path $dbPath)) {
        Copy-Item -Path $oldDbPath -Destination $dbPath
        Write-ROLog -Message "Migrated database from $oldDbPath to $dbPath" -Component 'Database'
    }

    Write-ROLog -Message "Initializing database at $dbPath" -Component 'Database'

    if (-not (Test-Path $schemaPath)) {
        throw "Schema file not found: $schemaPath"
    }

    $schema = Get-Content -Path $schemaPath -Raw

    # Split on semicolons to execute each statement separately
    $statements = $schema -split ';\s*\r?\n' | Where-Object { $_.Trim() -ne '' }

    foreach ($stmt in $statements) {
        Invoke-ROQuery -Query ($stmt.Trim() + ';')
    }

    # Migrate: add PasswordLastChanged column if missing
    $columns = Invoke-ROQuery -Query "PRAGMA table_info(ROUser)"
    if ($columns -and -not ($columns | Where-Object { $_.name -eq 'PasswordLastChanged' })) {
        Invoke-ROQuery -Query "ALTER TABLE ROUser ADD COLUMN PasswordLastChanged TEXT;"
        Write-ROLog -Message 'Migrated ROUser: added PasswordLastChanged column' -Component 'Database'
    }

    # Seed default config if empty
    $existing = Invoke-ROQuery -Query "SELECT COUNT(*) AS Cnt FROM Config" -Scalar
    if ($existing -eq 0) {
        $defaults = @{
            SecretServerUrl    = 'https://yoursecretserver/SecretServer'
            MinActionsPerCycle = '0'
            MaxActionsPerCycle = '15'
            LogRetentionDays   = '30'
            DefaultDomain        = 'LAB'
            PasswordRotationDays = '14'
            AuthFailureAction          = 'AlertOnly'
            LauncherTemplateId         = '6052'
            AccessSnapshotMaxAgeDays   = '7'
            DisabledActions            = ''
            DisabledCategories         = ''
        }

        foreach ($kv in $defaults.GetEnumerator()) {
            Invoke-ROQuery -Query "INSERT INTO Config (Key, Value) VALUES (@Key, @Value)" -SqlParameters @{
                Key   = $kv.Key
                Value = $kv.Value
            }
        }

        Write-ROLog -Message 'Seeded default config values' -Component 'Database'
    }

    # Ensure PasswordRotationDays config exists (for existing DBs)
    $rotCfg = Invoke-ROQuery -Query "SELECT Value FROM Config WHERE Key = 'PasswordRotationDays'" -Scalar
    if (-not $rotCfg) {
        Invoke-ROQuery -Query "INSERT INTO Config (Key, Value) VALUES ('PasswordRotationDays', '14')"
        Write-ROLog -Message 'Seeded PasswordRotationDays config (default: 14)' -Component 'Database'
    }

    # Ensure AuthFailureAction config exists (for existing DBs)
    $authCfg = Invoke-ROQuery -Query "SELECT Value FROM Config WHERE Key = 'AuthFailureAction'" -Scalar
    if (-not $authCfg) {
        Invoke-ROQuery -Query "INSERT INTO Config (Key, Value) VALUES ('AuthFailureAction', 'AlertOnly')"
        Write-ROLog -Message 'Seeded AuthFailureAction config (default: AlertOnly)' -Component 'Database'
    }

    # Ensure LauncherTemplateId config exists (for existing DBs)
    $launcherCfg = Invoke-ROQuery -Query "SELECT Value FROM Config WHERE Key = 'LauncherTemplateId'" -Scalar
    if (-not $launcherCfg) {
        Invoke-ROQuery -Query "INSERT INTO Config (Key, Value) VALUES ('LauncherTemplateId', '6052')"
        Write-ROLog -Message 'Seeded LauncherTemplateId config (default: 6052)' -Component 'Database'
    }

    # Ensure AccessSnapshotMaxAgeDays config exists (for existing DBs)
    $accessAgeCfg = Invoke-ROQuery -Query "SELECT Value FROM Config WHERE Key = 'AccessSnapshotMaxAgeDays'" -Scalar
    if (-not $accessAgeCfg) {
        Invoke-ROQuery -Query "INSERT INTO Config (Key, Value) VALUES ('AccessSnapshotMaxAgeDays', '7')"
        Write-ROLog -Message 'Seeded AccessSnapshotMaxAgeDays config (default: 7)' -Component 'Database'
    }

    # Ensure DisabledActions config exists (for existing DBs)
    $disActCfg = Invoke-ROQuery -Query "SELECT Value FROM Config WHERE Key = 'DisabledActions'" -Scalar
    if ($null -eq $disActCfg) {
        Invoke-ROQuery -Query "INSERT INTO Config (Key, Value) VALUES ('DisabledActions', '')"
        Write-ROLog -Message 'Seeded DisabledActions config (default: empty)' -Component 'Database'
    }

    # Ensure DisabledCategories config exists (for existing DBs)
    $disCatCfg = Invoke-ROQuery -Query "SELECT Value FROM Config WHERE Key = 'DisabledCategories'" -Scalar
    if ($null -eq $disCatCfg) {
        Invoke-ROQuery -Query "INSERT INTO Config (Key, Value) VALUES ('DisabledCategories', '')"
        Write-ROLog -Message 'Seeded DisabledCategories config (default: empty)' -Component 'Database'
    }

    # Migrate: backfill missing action weights for existing users
    $seedWeightPath = Join-Path $PSScriptRoot '..\Data\SeedActionWeights.psd1'
    $seedWeightPath = [System.IO.Path]::GetFullPath($seedWeightPath)
    if (Test-Path $seedWeightPath) {
        $seedWeights = Invoke-Expression (Get-Content -Path $seedWeightPath -Raw)
        $users = Invoke-ROQuery -Query "SELECT UserId FROM ROUser"
        if ($users) {
            foreach ($user in $users) {
                foreach ($kv in $seedWeights.GetEnumerator()) {
                    Invoke-ROQuery -Query @"
INSERT OR IGNORE INTO ActionWeight (UserId, ActionName, Weight)
VALUES (@UserId, @ActionName, @Weight)
"@ -SqlParameters @{
                        UserId     = $user.UserId
                        ActionName = $kv.Key
                        Weight     = $kv.Value
                    }
                }
            }
            Write-ROLog -Message 'Backfilled any missing action weights for existing users' -Component 'Database'
        }
    }

    # Migrate: create UserAccess table if missing (for existing DBs)
    $tables = Invoke-ROQuery -Query "SELECT name FROM sqlite_master WHERE type='table' AND name='UserAccess'"
    if (-not $tables) {
        Invoke-ROQuery -Query @"
CREATE TABLE IF NOT EXISTS UserAccess (
    AccessId      INTEGER PRIMARY KEY AUTOINCREMENT,
    UserId        INTEGER NOT NULL REFERENCES ROUser(UserId) ON DELETE CASCADE,
    Username      TEXT NOT NULL,
    FolderCount   INTEGER NOT NULL DEFAULT 0,
    SecretCount   INTEGER NOT NULL DEFAULT 0,
    TemplateCount INTEGER NOT NULL DEFAULT 0,
    TemplateNames TEXT,
    CheckedAt     TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(UserId)
);
"@
        Write-ROLog -Message 'Migrated: created UserAccess table' -Component 'Database'
    }

    # Migrate: add TemplateCount column to UserAccess if missing
    $uaCols = Invoke-ROQuery -Query "PRAGMA table_info(UserAccess)"
    if ($uaCols -and -not ($uaCols | Where-Object { $_.name -eq 'TemplateCount' })) {
        Invoke-ROQuery -Query "ALTER TABLE UserAccess ADD COLUMN TemplateCount INTEGER NOT NULL DEFAULT 0;"
        Write-ROLog -Message 'Migrated UserAccess: added TemplateCount column' -Component 'Database'
    }

    # Migrate: encrypt any plain-text passwords (DPAPI strings are 300+ chars)
    $plainUsers = Invoke-ROQuery -Query "SELECT UserId, Password FROM ROUser"
    if ($plainUsers) {
        foreach ($u in @($plainUsers)) {
            if ($u.Password.Length -lt 200) {
                $encrypted = Protect-ROPassword -PlainText $u.Password
                Invoke-ROQuery -Query "UPDATE ROUser SET Password = @Pw WHERE UserId = @Id" `
                    -SqlParameters @{ Pw = $encrypted; Id = $u.UserId }
            }
        }
        Write-ROLog -Message 'Migrated plain-text passwords to encrypted storage' -Component 'Database'
    }

    Write-ROLog -Message 'Database initialized successfully' -Component 'Database'
    Write-Output "Database initialized at $dbPath"
}
