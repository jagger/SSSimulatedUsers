function Initialize-SimzDatabase {
    [CmdletBinding()]
    param()

    $dbPath = Get-SimzDbPath
    $schemaPath = Join-Path $PSScriptRoot '..\Data\Schema.sql'
    $schemaPath = [System.IO.Path]::GetFullPath($schemaPath)

    Write-SimzLog -Message "Initializing database at $dbPath" -Component 'Database'

    if (-not (Test-Path $schemaPath)) {
        throw "Schema file not found: $schemaPath"
    }

    $schema = Get-Content -Path $schemaPath -Raw

    # Split on semicolons to execute each statement separately
    $statements = $schema -split ';\s*\r?\n' | Where-Object { $_.Trim() -ne '' }

    foreach ($stmt in $statements) {
        Invoke-SimzQuery -Query ($stmt.Trim() + ';')
    }

    # Migrate: add PasswordLastChanged column if missing
    $columns = Invoke-SimzQuery -Query "PRAGMA table_info(SimUser)"
    if ($columns -and -not ($columns | Where-Object { $_.name -eq 'PasswordLastChanged' })) {
        Invoke-SimzQuery -Query "ALTER TABLE SimUser ADD COLUMN PasswordLastChanged TEXT;"
        Write-SimzLog -Message 'Migrated SimUser: added PasswordLastChanged column' -Component 'Database'
    }

    # Seed default config if empty
    $existing = Invoke-SimzQuery -Query "SELECT COUNT(*) AS Cnt FROM Config" -Scalar
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
        }

        foreach ($kv in $defaults.GetEnumerator()) {
            Invoke-SimzQuery -Query "INSERT INTO Config (Key, Value) VALUES (@Key, @Value)" -SqlParameters @{
                Key   = $kv.Key
                Value = $kv.Value
            }
        }

        Write-SimzLog -Message 'Seeded default config values' -Component 'Database'
    }

    # Ensure PasswordRotationDays config exists (for existing DBs)
    $rotCfg = Invoke-SimzQuery -Query "SELECT Value FROM Config WHERE Key = 'PasswordRotationDays'" -Scalar
    if (-not $rotCfg) {
        Invoke-SimzQuery -Query "INSERT INTO Config (Key, Value) VALUES ('PasswordRotationDays', '14')"
        Write-SimzLog -Message 'Seeded PasswordRotationDays config (default: 14)' -Component 'Database'
    }

    # Ensure AuthFailureAction config exists (for existing DBs)
    $authCfg = Invoke-SimzQuery -Query "SELECT Value FROM Config WHERE Key = 'AuthFailureAction'" -Scalar
    if (-not $authCfg) {
        Invoke-SimzQuery -Query "INSERT INTO Config (Key, Value) VALUES ('AuthFailureAction', 'AlertOnly')"
        Write-SimzLog -Message 'Seeded AuthFailureAction config (default: AlertOnly)' -Component 'Database'
    }

    # Ensure LauncherTemplateId config exists (for existing DBs)
    $launcherCfg = Invoke-SimzQuery -Query "SELECT Value FROM Config WHERE Key = 'LauncherTemplateId'" -Scalar
    if (-not $launcherCfg) {
        Invoke-SimzQuery -Query "INSERT INTO Config (Key, Value) VALUES ('LauncherTemplateId', '6052')"
        Write-SimzLog -Message 'Seeded LauncherTemplateId config (default: 6052)' -Component 'Database'
    }

    # Ensure AccessSnapshotMaxAgeDays config exists (for existing DBs)
    $accessAgeCfg = Invoke-SimzQuery -Query "SELECT Value FROM Config WHERE Key = 'AccessSnapshotMaxAgeDays'" -Scalar
    if (-not $accessAgeCfg) {
        Invoke-SimzQuery -Query "INSERT INTO Config (Key, Value) VALUES ('AccessSnapshotMaxAgeDays', '7')"
        Write-SimzLog -Message 'Seeded AccessSnapshotMaxAgeDays config (default: 7)' -Component 'Database'
    }

    # Migrate: create UserAccess table if missing (for existing DBs)
    $tables = Invoke-SimzQuery -Query "SELECT name FROM sqlite_master WHERE type='table' AND name='UserAccess'"
    if (-not $tables) {
        Invoke-SimzQuery -Query @"
CREATE TABLE IF NOT EXISTS UserAccess (
    AccessId      INTEGER PRIMARY KEY AUTOINCREMENT,
    UserId        INTEGER NOT NULL REFERENCES SimUser(UserId) ON DELETE CASCADE,
    Username      TEXT NOT NULL,
    FolderCount   INTEGER NOT NULL DEFAULT 0,
    SecretCount   INTEGER NOT NULL DEFAULT 0,
    TemplateNames TEXT,
    CheckedAt     TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(UserId)
);
"@
        Write-SimzLog -Message 'Migrated: created UserAccess table' -Component 'Database'
    }

    Write-SimzLog -Message 'Database initialized successfully' -Component 'Database'
    Write-Output "Database initialized at $dbPath"
}
