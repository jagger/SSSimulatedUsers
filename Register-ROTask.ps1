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
    # Test only the bits that actually permit creating entries in the directory.
    # Do NOT include Modify or FullControl here: those masks contain the read
    # bits too, so ReadAndExecute would match and we would silently strip read
    # access as well. CreateFiles/CreateDirectories are already set in Write,
    # Modify and FullControl, so matching on them alone catches every case.
    $writeish = [System.Security.AccessControl.FileSystemRights]::CreateFiles `
        -bor [System.Security.AccessControl.FileSystemRights]::CreateDirectories

    $rootAcl = Get-Acl $DataRoot
    $rootAcl.SetAccessRuleProtection($true, $true)
    Set-Acl -Path $DataRoot -AclObject $rootAcl

    $rootAcl = Get-Acl $DataRoot
    $removed = $false
    foreach ($ace in @($rootAcl.Access)) {
        if ($ace.IdentityReference.Value -eq $usersAccount -and
            $ace.AccessControlType -eq 'Allow' -and
            ($ace.FileSystemRights -band $writeish)) {
            [void]$rootAcl.RemoveAccessRuleSpecific($ace)
            $removed = $true
        }
    }
    if ($removed) {
        Set-Acl -Path $DataRoot -AclObject $rootAcl
        Write-Host "Removed write access for $usersAccount on $DataRoot."
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
