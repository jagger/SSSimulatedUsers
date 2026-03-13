<#
.SYNOPSIS
    One-time migration from TheSimz to RobOtters branding on a live deployment.

.DESCRIPTION
    Performs the following idempotent migration steps:

    1. Renames SQLite table SimUser -> ROUser (if not already renamed)
    2. Renames DB file TheSimz.sqlite -> RobOtters.sqlite (if needed)
    3. Moves ProgramData\TheSimz -> ProgramData\RobOtters (if needed)
    4. Migrates environment variables SIMZ_* -> RO_*
    5. Unregisters "TheSimz" scheduled task, registers "RobOtters" inline
    6. Verifies by importing module and running Initialize-RODatabase

    This script is self-contained and idempotent - safe to run multiple times.
    Must be run as Administrator for scheduled task and Machine-scope env var changes.

.EXAMPLE
    .\Scripts\Migrate-ToRobOtters.ps1
#>
[CmdletBinding()]
param()

Import-Module PSSQLite -ErrorAction Stop

# -- Resolve data root (check both old and new env vars) -----------------------

$dataRoot = $null
if ($env:RO_DATA_PATH) {
    $dataRoot = $env:RO_DATA_PATH
}
elseif ($env:SIMZ_DATA_PATH) {
    $dataRoot = $env:SIMZ_DATA_PATH
}
else {
    # Check ProgramData locations
    $newDir = Join-Path $env:ProgramData 'RobOtters'
    $oldDir = Join-Path $env:ProgramData 'TheSimz'
    if (Test-Path $newDir) {
        $dataRoot = $newDir
    }
    elseif (Test-Path $oldDir) {
        $dataRoot = $oldDir
    }
    else {
        $dataRoot = $oldDir
    }
}

Write-Host "`n=== RobOtters Migration ===" -ForegroundColor Yellow
Write-Host "  Data root: $dataRoot" -ForegroundColor Cyan

# == Step 1: Database table rename =============================================

Write-Host "`n--- Step 1: Database Table Rename ---" -ForegroundColor Yellow

$oldDb = Join-Path $dataRoot 'TheSimz.sqlite'
$newDb = Join-Path $dataRoot 'RobOtters.sqlite'

# Find whichever DB file exists
$dbPath = $null
if (Test-Path $newDb) {
    $dbPath = $newDb
}
elseif (Test-Path $oldDb) {
    $dbPath = $oldDb
}
else {
    Write-Warning "  No database found at $oldDb or $newDb - skipping table rename"
}

if ($dbPath) {
    $tables = Invoke-SqliteQuery -DataSource $dbPath -Query "SELECT name FROM sqlite_master WHERE type='table' AND name='SimUser'"
    if ($tables) {
        Invoke-SqliteQuery -DataSource $dbPath -Query "ALTER TABLE SimUser RENAME TO ROUser"
        Write-Host "  Renamed table SimUser -> ROUser" -ForegroundColor Green
    }
    else {
        Write-Host "  Table SimUser not found (already renamed or doesn't exist) - skipping" -ForegroundColor DarkGray
    }
}

# == Step 2: Database file rename ==============================================

Write-Host "`n--- Step 2: Database File Rename ---" -ForegroundColor Yellow

if ((Test-Path $oldDb) -and -not (Test-Path $newDb)) {
    Move-Item -Path $oldDb -Destination $newDb
    # Also move journal file if present
    $oldJournal = "$oldDb-journal"
    $newJournal = "$newDb-journal"
    if (Test-Path $oldJournal) {
        Move-Item -Path $oldJournal -Destination $newJournal
    }
    Write-Host "  Renamed database: TheSimz.sqlite -> RobOtters.sqlite" -ForegroundColor Green
}
elseif (Test-Path $newDb) {
    Write-Host "  RobOtters.sqlite already exists - skipping" -ForegroundColor DarkGray
}
else {
    Write-Host "  No database file found to rename" -ForegroundColor DarkGray
}

# == Step 3: ProgramData directory rename ======================================

Write-Host "`n--- Step 3: ProgramData Directory ---" -ForegroundColor Yellow

$oldProgramData = Join-Path $env:ProgramData 'TheSimz'
$newProgramData = Join-Path $env:ProgramData 'RobOtters'

if ((Test-Path $oldProgramData) -and -not (Test-Path $newProgramData)) {
    Move-Item -Path $oldProgramData -Destination $newProgramData
    Write-Host "  Moved: $oldProgramData -> $newProgramData" -ForegroundColor Green
}
elseif (Test-Path $newProgramData) {
    Write-Host "  $newProgramData already exists - skipping" -ForegroundColor DarkGray
}
else {
    Write-Host "  $oldProgramData not found - skipping" -ForegroundColor DarkGray
}

# == Step 4: Environment variables =============================================

Write-Host "`n--- Step 4: Environment Variables ---" -ForegroundColor Yellow

# SIMZ_DATA_PATH -> RO_DATA_PATH
$oldDataPath = [Environment]::GetEnvironmentVariable('SIMZ_DATA_PATH', 'Machine')
$newDataPath = [Environment]::GetEnvironmentVariable('RO_DATA_PATH', 'Machine')
if ($oldDataPath -and -not $newDataPath) {
    # Update the value to point to the new directory name
    $migratedPath = $oldDataPath -replace 'TheSimz', 'RobOtters'
    [Environment]::SetEnvironmentVariable('RO_DATA_PATH', $migratedPath, 'Machine')
    [Environment]::SetEnvironmentVariable('SIMZ_DATA_PATH', $null, 'Machine')
    $env:RO_DATA_PATH = $migratedPath
    $env:SIMZ_DATA_PATH = $null
    Write-Host "  SIMZ_DATA_PATH -> RO_DATA_PATH = $migratedPath" -ForegroundColor Green
}
elseif ($newDataPath) {
    Write-Host "  RO_DATA_PATH already set ($newDataPath) - skipping" -ForegroundColor DarkGray
}
else {
    Write-Host "  SIMZ_DATA_PATH not set - skipping" -ForegroundColor DarkGray
}

# SIMZ_ENCRYPT_KEY -> RO_ENCRYPT_KEY
$oldKey = [Environment]::GetEnvironmentVariable('SIMZ_ENCRYPT_KEY', 'Machine')
$newKey = [Environment]::GetEnvironmentVariable('RO_ENCRYPT_KEY', 'Machine')
if ($oldKey -and -not $newKey) {
    [Environment]::SetEnvironmentVariable('RO_ENCRYPT_KEY', $oldKey, 'Machine')
    [Environment]::SetEnvironmentVariable('SIMZ_ENCRYPT_KEY', $null, 'Machine')
    $env:RO_ENCRYPT_KEY = $oldKey
    $env:SIMZ_ENCRYPT_KEY = $null
    Write-Host "  SIMZ_ENCRYPT_KEY -> RO_ENCRYPT_KEY" -ForegroundColor Green
}
elseif ($newKey) {
    Write-Host "  RO_ENCRYPT_KEY already set - skipping" -ForegroundColor DarkGray
}
else {
    Write-Host "  SIMZ_ENCRYPT_KEY not set - skipping" -ForegroundColor DarkGray
}

# == Step 5: Scheduled task ====================================================

Write-Host "`n--- Step 5: Scheduled Task ---" -ForegroundColor Yellow

$oldTaskName = 'TheSimz'
$newTaskName = 'RobOtters'

# Check if new task already exists
$newTask = $null
try { $newTask = Get-ScheduledTask -TaskName $newTaskName -ErrorAction Stop } catch {}

if ($newTask) {
    Write-Host "  Scheduled task '$newTaskName' already exists - skipping" -ForegroundColor DarkGray
}
else {
    # Unregister old task if it exists
    try {
        $oldTask = Get-ScheduledTask -TaskName $oldTaskName -ErrorAction Stop
        Unregister-ScheduledTask -TaskName $oldTaskName -Confirm:$false
        Write-Host "  Unregistered old task '$oldTaskName'" -ForegroundColor Cyan
    }
    catch {
        Write-Host "  Old task '$oldTaskName' not found - creating new task" -ForegroundColor DarkGray
    }

    # Build the command - include encryption key env var if available
    $encKey = $env:RO_ENCRYPT_KEY
    if ($encKey) {
        $cmdArgs = "-ExecutionPolicy Bypass -NoProfile -Command `"`$env:RO_ENCRYPT_KEY = '$encKey'; Import-Module C:\projects\TheSimz\RobOtters.psd1; Start-ROCycle`""
    }
    else {
        $cmdArgs = "-ExecutionPolicy Bypass -NoProfile -Command `"Import-Module C:\projects\TheSimz\RobOtters.psd1; Start-ROCycle`""
    }

    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $cmdArgs
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Minutes 30) -RepetitionDuration (New-TimeSpan -Days 9999)
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 25)

    Register-ScheduledTask -TaskName $newTaskName -Action $action -Trigger $trigger -Settings $settings -Description 'Secret Server user activity simulator - runs every 30 minutes' -RunLevel Highest -Force
    Write-Host "  Registered new task '$newTaskName'" -ForegroundColor Green
}

# == Step 6: Verify ============================================================

Write-Host "`n--- Step 6: Verification ---" -ForegroundColor Yellow

try {
    Import-Module C:\projects\TheSimz\RobOtters.psd1 -Force
    Write-Host "  Import-Module RobOtters: OK" -ForegroundColor Green
}
catch {
    Write-Warning "  Import-Module RobOtters failed: $_"
}

try {
    Initialize-RODatabase
    Write-Host "  Initialize-RODatabase: OK" -ForegroundColor Green
}
catch {
    Write-Warning "  Initialize-RODatabase failed: $_"
}

try {
    $users = Get-ROUser
    $count = if ($users) { @($users).Count } else { 0 }
    Write-Host "  Get-ROUser: $count users found" -ForegroundColor Green
}
catch {
    Write-Warning "  Get-ROUser failed: $_"
}

Write-Host "`nMigration complete." -ForegroundColor Green
