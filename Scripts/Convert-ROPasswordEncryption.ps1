<#
.SYNOPSIS
    One-off migration: relocates database to ProgramData, converts passwords to AES encryption,
    and updates the RobOtters scheduled task with the RO_ENCRYPT_KEY environment variable.

.DESCRIPTION
    Performs three migration steps:

    1. DATABASE RELOCATION
       Copies RobOtters.sqlite from the old module-local path (Data\RobOtters.sqlite) to
       the new runtime location ($env:RO_DATA_PATH or $env:ProgramData\RobOtters\).

    2. PASSWORD RE-ENCRYPTION
       Reads every ROUser password and re-encrypts it using the AES key from
       $env:RO_ENCRYPT_KEY. Handles plain text (short) and DPAPI-encrypted (long) passwords.
       DPAPI decryption requires running as the same Windows account that originally encrypted.

    3. SCHEDULED TASK UPDATE
       Updates the "RobOtters" scheduled task action to include the RO_ENCRYPT_KEY env var
       so the task can decrypt passwords at runtime.

    This script is self-contained - it does NOT depend on the RobOtters module being loaded.
    It is idempotent - safe to run multiple times.

.EXAMPLE
    # Generate a key (once) and set it:
    $key = [Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))
    [Environment]::SetEnvironmentVariable('RO_ENCRYPT_KEY', $key, 'Machine')
    $env:RO_ENCRYPT_KEY = $key

    # Then run (as Administrator for scheduled task update):
    .\Scripts\Convert-ROPasswordEncryption.ps1
#>
[CmdletBinding()]
param()

Import-Module PSSQLite -ErrorAction Stop

# -- Resolve paths (inline, no module dependency) --------------------------------

if ($env:RO_DATA_PATH) {
    $newDataRoot = $env:RO_DATA_PATH
} else {
    $newDataRoot = Join-Path $env:ProgramData 'RobOtters'
}

if (-not (Test-Path $newDataRoot)) {
    New-Item -Path $newDataRoot -ItemType Directory -Force | Out-Null
}

$newDbPath = Join-Path $newDataRoot 'RobOtters.sqlite'
$oldDbPath = Join-Path $PSScriptRoot '..\Data\RobOtters.sqlite'
$oldDbPath = [System.IO.Path]::GetFullPath($oldDbPath)

# -- Resolve AES key (inline, no module dependency) ------------------------------

if (-not $env:RO_ENCRYPT_KEY) {
    throw 'Environment variable RO_ENCRYPT_KEY is not set. Generate one with: [Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))'
}

[byte[]]$aesKey = [Convert]::FromBase64String($env:RO_ENCRYPT_KEY)
if ($aesKey.Length -ne 32) {
    throw "RO_ENCRYPT_KEY must decode to exactly 32 bytes (AES-256). Got $($aesKey.Length) bytes."
}

# == Step 1: Database relocation =================================================

Write-Host "`n=== Step 1: Database Relocation ===" -ForegroundColor Yellow

if ((Test-Path $oldDbPath) -and -not (Test-Path $newDbPath)) {
    Copy-Item -Path $oldDbPath -Destination $newDbPath
    Write-Host "  Copied database:" -ForegroundColor Cyan
    Write-Host "    From: $oldDbPath" -ForegroundColor Cyan
    Write-Host "    To:   $newDbPath" -ForegroundColor Cyan
}
elseif (Test-Path $newDbPath) {
    Write-Host "  Database already exists at $newDbPath - skipping copy" -ForegroundColor DarkGray
}
else {
    Write-Warning "  No existing database found at $oldDbPath - run Initialize-RODatabase first"
    return
}

Write-Host "  Data root: $newDataRoot" -ForegroundColor Green

# == Step 2: Password re-encryption ==============================================

Write-Host "`n=== Step 2: Password Re-encryption ===" -ForegroundColor Yellow
Write-Host "  AES encryption key loaded ($($aesKey.Length) bytes)" -ForegroundColor Green

$users = Invoke-SqliteQuery -DataSource $newDbPath -Query "SELECT UserId, Username, Password FROM ROUser"
if (-not $users) {
    Write-Host '  No users found in database.' -ForegroundColor DarkGray
}
else {
    $converted = 0
    $skipped = 0

    foreach ($u in @($users)) {
        $plainText = $null

        if ($u.Password.Length -lt 200) {
            # Plain text password
            $plainText = $u.Password
            Write-Host "  $($u.Username): plain text -> AES" -ForegroundColor Cyan
        }
        else {
            # Long string - try DPAPI decryption first (no -Key)
            try {
                $secure = ConvertTo-SecureString $u.Password
                $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
                try {
                    $plainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
                } finally {
                    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
                }
                Write-Host "  $($u.Username): DPAPI -> AES" -ForegroundColor Cyan
            }
            catch {
                # Not DPAPI - try decrypting with current AES key (already migrated?)
                try {
                    $secure = ConvertTo-SecureString $u.Password -Key $aesKey
                    Write-Host "  $($u.Username): already AES-encrypted, skipping" -ForegroundColor DarkGray
                    $skipped++
                    continue
                }
                catch {
                    Write-Warning "  $($u.Username): cannot decrypt password (not plain text, DPAPI, or current AES key) - SKIPPED"
                    $skipped++
                    continue
                }
            }
        }

        # Encrypt with AES key and update
        $secure = ConvertTo-SecureString $plainText -AsPlainText -Force
        $encrypted = ConvertFrom-SecureString $secure -Key $aesKey

        Invoke-SqliteQuery -DataSource $newDbPath -Query "UPDATE ROUser SET Password = @Pw WHERE UserId = @Id" `
            -SqlParameters @{ Pw = $encrypted; Id = $u.UserId }
        $converted++
    }

    Write-Host "  Passwords: $converted converted, $skipped skipped." -ForegroundColor Green
}

# == Step 3: Scheduled task update ===============================================

Write-Host "`n=== Step 3: Scheduled Task Update ===" -ForegroundColor Yellow

$taskName = 'RobOtters'

try {
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction Stop
}
catch {
    Write-Warning "  Scheduled task '$taskName' not found - skipping task update"
    Write-Host "`nMigration complete (task update skipped)." -ForegroundColor Green
    return
}

$envKey = $env:RO_ENCRYPT_KEY
$modulePath = Join-Path $PSScriptRoot '..\RobOtters.psd1'
$modulePath = [System.IO.Path]::GetFullPath($modulePath)
$newArgs = "-ExecutionPolicy Bypass -NoProfile -Command `"`$env:RO_ENCRYPT_KEY = '$envKey'; Import-Module '$modulePath'; Start-ROCycle`""

$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $newArgs
Set-ScheduledTask -TaskName $taskName -Action $action | Out-Null

Write-Host "  Updated '$taskName' scheduled task action" -ForegroundColor Cyan
Write-Host "  Command now sets RO_ENCRYPT_KEY before importing the module" -ForegroundColor Cyan

# Verify
$updated = Get-ScheduledTask -TaskName $taskName | Select-Object -ExpandProperty Actions
Write-Host "  Verify: $($updated.Execute) $($updated.Arguments)" -ForegroundColor DarkGray

Write-Host "`nMigration complete." -ForegroundColor Green
Write-Host "  Database: $newDbPath" -ForegroundColor Green
Write-Host "  Logs:     $(Join-Path $newDataRoot 'Logs')" -ForegroundColor Green
Write-Host "  Old DB at $oldDbPath was NOT deleted (safe fallback)." -ForegroundColor DarkGray
