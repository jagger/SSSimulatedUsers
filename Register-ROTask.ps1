<#
.SYNOPSIS
    Register (or re-register) the RobOtters simulator scheduled task.
.DESCRIPTION
    Creates the scheduled task that runs Start-ROCycle on an interval.

    The task is registered with LogonType = Password ("run whether user is
    logged on or not"). Do NOT switch this to an interactive principal or to
    S4U:
      * Interactive  - the task silently refuses to launch whenever nobody is
                       logged on at the console. This is how the task sat idle
                       for 810 missed runs.
      * S4U          - yields a token with no network credentials, so
                       Invoke-ROPasswordRotation's Set-ADAccountPassword call
                       fails for every user while the rest of the cycle appears
                       healthy.

    The service account needs:
      * 'Log on as a batch job' on this server
      * FullControl on the data root (default C:\ProgramData\RobOtters)
      * Reset Password + write pwdLastSet, delegated on the OU containing the
        simulated users
      * Read access to this module's directory
      * PSSQLite installed machine-wide (NOT in a user profile) - otherwise the
        service account cannot load it and every cycle dies on the first query

    RO_ENCRYPT_KEY is read from a machine-scoped environment variable rather
    than being embedded in the task arguments, so the AES key is not readable
    from the task definition by anyone who can list scheduled tasks.
.PARAMETER TaskName
    Name of the scheduled task. Must match the task already in production.
.PARAMETER ServiceAccount
    DOMAIN\sam account the task runs as.
.PARAMETER ServiceAccountPassword
    Password for ServiceAccount, used only to register the task.
.PARAMETER EncryptionKey
    Base64 AES-256 key. If supplied it is written to the machine-scoped
    RO_ENCRYPT_KEY variable. If omitted, that variable must already be set.
.EXAMPLE
    .\Register-ROTask.ps1 -ServiceAccountPassword (Read-Host -AsSecureString)
#>
[CmdletBinding()]
param(
    [string]$TaskName = 'TheSimz',

    [string]$ServiceAccount = 'JAGGERLAB\svc-robotters',

    [Parameter(Mandatory)]
    [securestring]$ServiceAccountPassword,

    [securestring]$EncryptionKey,

    [int]$IntervalMinutes = 30,

    [int]$ExecutionTimeLimitMinutes = 50,

    [string]$DataRoot = (Join-Path $env:ProgramData 'RobOtters')
)

$ErrorActionPreference = 'Stop'

$modulePath = Join-Path $PSScriptRoot 'RobOtters.psd1'
if (-not (Test-Path $modulePath)) {
    throw "Module manifest not found at $modulePath"
}

# --- encryption key: machine-scoped env var, never embedded in the task ---
$keyFile = Join-Path $DataRoot 'encryption.key'

if ($EncryptionKey) {
    if (-not (Test-Path $DataRoot)) {
        New-Item -Path $DataRoot -ItemType Directory -Force | Out-Null
    }

    Add-Type -AssemblyName System.Security
    $plainKey = [System.Net.NetworkCredential]::new('', $EncryptionKey).Password

    # Validate before storing - a bad key is far harder to diagnose later.
    try { $keyBytes = [Convert]::FromBase64String($plainKey) }
    catch { throw 'EncryptionKey is not valid base64.' }
    if ($keyBytes.Length -ne 32) {
        throw "EncryptionKey must decode to exactly 32 bytes (AES-256). Got $($keyBytes.Length)."
    }

    $allowed = @('NT AUTHORITY\SYSTEM', 'BUILTIN\Administrators', $ServiceAccount)

    # Ordinary users must not be able to create files in the data root, or they
    # can pre-create (or symlink) the key file and win a race against this
    # script. Strip write access from BUILTIN\Users before touching anything
    # inside it; read access is left alone so operators can still read logs.
    $usersAccount = (New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-545')).Translate(
        [System.Security.Principal.NTAccount]).Value
    # Rights that let an identity put something in this directory, remove what is
    # already there, or hand itself more access. ChangePermissions and
    # TakeOwnership matter as much as CreateFiles: either one lets the holder
    # grant itself the rest, so checking only for create rights would miss the
    # shortest path in.
    #
    # Do NOT add Modify or FullControl here. Those masks contain the read bits,
    # so ReadAndExecute would match and we would silently strip read access while
    # reporting that only write had been removed. Every one of them already
    # includes CreateFiles, so the narrower bits still catch them.
    $R = [System.Security.AccessControl.FileSystemRights]
    $writeish = $R::CreateFiles `
        -bor $R::CreateDirectories `
        -bor $R::Delete `
        -bor $R::DeleteSubdirectoriesAndFiles `
        -bor $R::ChangePermissions `
        -bor $R::TakeOwnership

    # A junction or symlink here would send every write below to somewhere we
    # have not vetted, so refuse before touching anything.
    $rootItem = Get-Item -LiteralPath $DataRoot -Force
    if ($rootItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        throw "Refusing to continue: $DataRoot is a reparse point (junction or symlink)."
    }
    if (-not $rootItem.PSIsContainer) {
        throw "Refusing to continue: $DataRoot is not a directory."
    }

    # Ownership outranks the DACL - an owner can always rewrite permissions, so
    # this has to be checked BEFORE we change it. Checking only afterwards would
    # be tautological: we would be asserting the value we had just assigned, and
    # the one thing worth knowing - that something untrusted owned the directory
    # we are about to put a key in - would be lost.
    $ownerBefore = (Get-Acl $DataRoot).Owner
    $acceptableOwners = @($allowed) + @([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
    if ($ownerBefore -notin $acceptableOwners) {
        throw "Refusing to continue: $DataRoot is owned by $ownerBefore. An unexpected owner can rewrite the directory's permissions at will, so inspect how it came to own this path before re-running."
    }

    $rootAcl = Get-Acl $DataRoot
    $rootAcl.SetOwner((New-Object System.Security.Principal.NTAccount('BUILTIN', 'Administrators')))
    $rootAcl.SetAccessRuleProtection($true, $true)
    Set-Acl -Path $DataRoot -AclObject $rootAcl

    # Second check, now genuinely about whether the write took effect.
    $ownerNow = (Get-Acl $DataRoot).Owner
    if ($ownerNow -notin $allowed) {
        throw "Refusing to continue: ownership of $DataRoot did not change as expected (still $ownerNow)."
    }

    # Strip create rights from EVERY identity that is not expected to have them,
    # not just BUILTIN\Users - another group granted write here would reopen the
    # same race. CREATOR OWNER is left alone: it is inherit-only and applies to
    # whoever creates a file, which can now only be an allowed identity.
    $rootAcl = Get-Acl $DataRoot
    $stripped = @()
    foreach ($ace in @($rootAcl.Access)) {
        $identity = $ace.IdentityReference.Value
        if ($identity -in $allowed) { continue }
        # CREATOR OWNER is harmless only while it is inherit-only: it then applies
        # to whoever creates a file, and only allowed identities can do that now.
        # A non-inherit-only CREATOR OWNER ACE applies to the current owner
        # directly and has to be treated like any other.
        if ($identity -eq 'CREATOR OWNER' -and
            ($ace.PropagationFlags -band [System.Security.AccessControl.PropagationFlags]::InheritOnly)) { continue }
        if ($ace.AccessControlType -eq 'Allow' -and ($ace.FileSystemRights -band $writeish)) {
            [void]$rootAcl.RemoveAccessRuleSpecific($ace)
            $stripped += $identity
        }
    }
    if ($stripped.Count -gt 0) {
        Set-Acl -Path $DataRoot -AclObject $rootAcl
        Write-Host "Removed create access on $DataRoot for: $(($stripped | Sort-Object -Unique) -join ', ')."
    }

    # Verify no unexpected identity can still create entries in the data root.
    $stillWritable = (Get-Acl $DataRoot).Access | Where-Object {
        $_.AccessControlType -eq 'Allow' -and
        $_.IdentityReference.Value -notin $allowed -and
        -not ($_.IdentityReference.Value -eq 'CREATOR OWNER' -and
              ($_.PropagationFlags -band [System.Security.AccessControl.PropagationFlags]::InheritOnly)) -and
        ($_.FileSystemRights -band $writeish)
    }
    if ($stillWritable) {
        throw "Refusing to continue: $DataRoot is still writable by $(($stillWritable.IdentityReference.Value | Sort-Object -Unique) -join ', ')."
    }

    # Re-read the attributes now the lockdown is done. Get-Acl and Set-Acl work by
    # path, so in principle the directory could have been swapped for a junction
    # between the earlier check and here. Closing that window properly would mean
    # holding a single directory handle across every operation, which needs
    # P/Invoke; this at least refuses to put a key anywhere the swap succeeded.
    $rootItem = Get-Item -LiteralPath $DataRoot -Force
    if (($rootItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -or -not $rootItem.PSIsContainer) {
        throw "Refusing to continue: $DataRoot changed into a reparse point or a file while it was being secured."
    }

    # Stage the new key beside the live one. CreateNew fails outright if the path
    # already exists, so a pre-created file or link cannot be handed to us.
    $stagedKey = "$keyFile.new"
    if (Test-Path $stagedKey) { Remove-Item $stagedKey -Force }
    $stream = [System.IO.File]::Open(
        $stagedKey,
        [System.IO.FileMode]::CreateNew,
        [System.IO.FileAccess]::Write,
        [System.IO.FileShare]::None)
    $stream.Close()

    # Take ownership and lock the ACL down while the file is still empty.
    $acl = Get-Acl $stagedKey
    $acl.SetOwner((New-Object System.Security.Principal.NTAccount('BUILTIN', 'Administrators')))
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($existing in @($acl.Access)) { [void]$acl.RemoveAccessRule($existing) }
    foreach ($identity in $allowed) {
        $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
            $identity, 'FullControl', 'None', 'None', 'Allow')))
    }
    Set-Acl -Path $stagedKey -AclObject $acl

    # Verify the lockdown actually took effect BEFORE any key material is written.
    $verify = Get-Acl $stagedKey
    $unexpected = $verify.Access | Where-Object { $_.IdentityReference.Value -notin $allowed }
    if ($unexpected -or -not $verify.AreAccessRulesProtected) {
        Remove-Item $stagedKey -Force -ErrorAction SilentlyContinue
        throw "Refusing to write the key: $stagedKey did not lock down as expected ($($unexpected.IdentityReference -join ', '))."
    }

    # DPAPI LocalMachine, so the ciphertext is useless if copied off this server.
    # LocalMachine (not CurrentUser) is required because this script runs as an
    # administrator while the key is read back by the service account. That means
    # any process able to READ the file can also decrypt it, so the ACL above is
    # the real control. Optional entropy is deliberately omitted: it would have to
    # live in this script, which is in source control, so it would add no real
    # protection while implying more than it delivers.
    $plainBytes = [System.Text.Encoding]::UTF8.GetBytes($plainKey)
    $protected  = [System.Security.Cryptography.ProtectedData]::Protect(
        $plainBytes, $null, [System.Security.Cryptography.DataProtectionScope]::LocalMachine)
    [System.IO.File]::WriteAllText($stagedKey, [Convert]::ToBase64String($protected))
    [Array]::Clear($plainBytes, 0, $plainBytes.Length)

    # Prove the staged file decrypts back to the same key before it replaces a
    # working one. Losing this key makes every stored password unrecoverable, so
    # the live file is never deleted on the strength of an unverified write.
    $roundTrip = [System.Text.Encoding]::UTF8.GetString(
        [System.Security.Cryptography.ProtectedData]::Unprotect(
            [Convert]::FromBase64String([System.IO.File]::ReadAllText($stagedKey)),
            $null,
            [System.Security.Cryptography.DataProtectionScope]::LocalMachine))
    if ($roundTrip -ne $plainKey) {
        Remove-Item $stagedKey -Force -ErrorAction SilentlyContinue
        throw 'Refusing to install the key: the staged file did not decrypt back to the supplied key.'
    }

    # Keep the previous key until the new one is in place, then drop it.
    $backupKey = "$keyFile.bak"
    if (Test-Path $keyFile) {
        if (Test-Path $backupKey) { Remove-Item $backupKey -Force }
        Move-Item -Path $keyFile -Destination $backupKey -Force
    }
    Move-Item -Path $stagedKey -Destination $keyFile -Force
    if (Test-Path $backupKey) { Remove-Item $backupKey -Force }

    Write-Host "Stored RO_ENCRYPT_KEY DPAPI-protected at $keyFile (readable only by SYSTEM, Administrators and $ServiceAccount)."
    [Array]::Clear($plainBytes, 0, $plainBytes.Length)
    [Array]::Clear($keyBytes, 0, $keyBytes.Length)
    Remove-Variable plainKey -Force
}
elseif (-not (Test-Path $keyFile) -and -not [Environment]::GetEnvironmentVariable('RO_ENCRYPT_KEY', 'Machine')) {
    throw "No encryption key available. Re-run with -EncryptionKey to store one at $keyFile."
}

if ([Environment]::GetEnvironmentVariable('RO_ENCRYPT_KEY', 'Machine')) {
    Write-Warning 'RO_ENCRYPT_KEY is set as a machine-scoped environment variable. That registry location is readable by every authenticated user on this server. Move the key to the protected key file (re-run with -EncryptionKey) and clear the machine variable.'
}

# --- PSSQLite must be resolvable outside the calling user's profile ---
$machineModulePaths = @(
    "$env:ProgramFiles\WindowsPowerShell\Modules"
    "$env:SystemRoot\system32\WindowsPowerShell\v1.0\Modules"
)
$sqliteMachineWide = $machineModulePaths | Where-Object { Test-Path (Join-Path $_ 'PSSQLite') }
if (-not $sqliteMachineWide) {
    Write-Warning 'PSSQLite was not found in a machine-wide module path. The service account will not be able to load it. Install it with: Install-Module PSSQLite -Scope AllUsers'
}

$command = "Import-Module '$modulePath'; Start-ROCycle"

$actionSplat = @{
    Execute  = 'powershell.exe'
    Argument = "-ExecutionPolicy Bypass -NoProfile -NonInteractive -Command `"$command`""
}
$action = New-ScheduledTaskAction @actionSplat

$triggerSplat = @{
    Once               = $true
    At                 = (Get-Date).Date
    RepetitionInterval = (New-TimeSpan -Minutes $IntervalMinutes)
    RepetitionDuration = ([TimeSpan]::MaxValue)
}
$trigger = New-ScheduledTaskTrigger @triggerSplat

$settingsSplat = @{
    AllowStartIfOnBatteries    = $true
    DontStopIfGoingOnBatteries = $true
    StartWhenAvailable         = $true
    MultipleInstances          = 'IgnoreNew'
    ExecutionTimeLimit         = (New-TimeSpan -Minutes $ExecutionTimeLimitMinutes)
}
$settings = New-ScheduledTaskSettingsSet @settingsSplat

$registerSplat = @{
    TaskName    = $TaskName
    Action      = $action
    Trigger     = $trigger
    Settings    = $settings
    User        = $ServiceAccount
    Password    = [System.Net.NetworkCredential]::new('', $ServiceAccountPassword).Password
    RunLevel    = 'Highest'
    Description = 'Secret Server user activity simulator - runs on an interval'
    Force       = $true
}
Register-ScheduledTask @registerSplat | Out-Null

$registered = Get-ScheduledTask -TaskName $TaskName
Write-Host "Scheduled task '$TaskName' registered."
$registered | Format-List TaskName, State
$registered.Principal | Format-List UserId, LogonType, RunLevel

if ($registered.Principal.LogonType -ne 'Password') {
    Write-Warning "LogonType is '$($registered.Principal.LogonType)', expected 'Password'. The task will not run while the account is logged off."
}
