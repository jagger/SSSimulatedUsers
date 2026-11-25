function Test-ROHealth {
    <#
    .SYNOPSIS
        Run pre-flight validation checks for RobOtters
    .DESCRIPTION
        Checks that all prerequisites are met before running a cycle:
        PSSQLite module loaded, database exists, required config keys present,
        encryption key valid (if AES passwords exist), Secret Server reachable,
        and at least one enabled user exists. Returns a summary object with
        per-check pass/fail and overall status.
    .EXAMPLE
        Test-ROHealth
        Run all health checks.
    .EXAMPLE
        Test-ROHealth | Where-Object { -not $_.Passed }
        Show only failing checks.
    .OUTPUTS
        PSCustomObject[] with Check, Passed, Detail properties, plus an OverallStatus property on the last object.
    .LINK
        Docs/commands/Test-ROHealth.md
    #>
    [CmdletBinding()]
    param()

    $checks = @()

    # 1. PSSQLite module loaded
    $psSqlite = Get-Module -Name PSSQLite -ListAvailable
    $checks += [PSCustomObject]@{
        Check  = 'PSSQLite Module'
        Passed = [bool]$psSqlite
        Detail = if ($psSqlite) { "Version $($psSqlite.Version)" } else { 'PSSQLite module not found' }
    }

    # 2. Database file exists and is readable
    $dbPath = Get-RODbPath
    $dbExists = Test-Path $dbPath
    $checks += [PSCustomObject]@{
        Check  = 'Database File'
        Passed = $dbExists
        Detail = if ($dbExists) { $dbPath } else { "Not found: $dbPath" }
    }

    # 3. Required config keys
    $configOk = $true
    $configDetail = @()
    if ($dbExists) {
        $ssUrl = Get-ROConfig -Key 'SecretServerUrl'
        $domain = Get-ROConfig -Key 'DefaultDomain'

        if (-not $ssUrl -or $ssUrl -eq 'https://yoursecretserver/SecretServer') {
            $configOk = $false
            $configDetail += 'SecretServerUrl not configured'
        }
        if (-not $domain -or $domain -eq 'LAB') {
            $configDetail += 'DefaultDomain may need updating'
        }
    }
    else {
        $configOk = $false
        $configDetail += 'Cannot check config (no database)'
    }
    $checks += [PSCustomObject]@{
        Check  = 'Required Config'
        Passed = $configOk
        Detail = if ($configDetail) { $configDetail -join '; ' } else { 'SecretServerUrl and DefaultDomain set' }
    }

    # 4. Encryption key validity
    $encKeyOk = $true
    $encKeyDetail = 'DPAPI mode (no RO_ENCRYPT_KEY set)'
    if ($env:RO_ENCRYPT_KEY) {
        try {
            [byte[]]$testKey = [Convert]::FromBase64String($env:RO_ENCRYPT_KEY)
            if ($testKey.Length -ne 32) {
                $encKeyOk = $false
                $encKeyDetail = "Key decodes to $($testKey.Length) bytes (expected 32)"
            }
            else {
                $encKeyDetail = 'AES-256 key valid (32 bytes)'
            }
        }
        catch {
            $encKeyOk = $false
            $encKeyDetail = "Invalid base64: $_"
        }
    }
    $checks += [PSCustomObject]@{
        Check  = 'Encryption Key'
        Passed = $encKeyOk
        Detail = $encKeyDetail
    }

    # 5. Secret Server reachable
    $ssReachable = $false
    $ssDetail = 'Skipped (no URL configured)'
    if ($dbExists) {
        $ssUrl = Get-ROConfig -Key 'SecretServerUrl'
        if ($ssUrl -and $ssUrl -ne 'https://yoursecretserver/SecretServer') {
            try {
                $versionUrl = "$ssUrl/api/v1/version"
                $null = Invoke-RestMethod -Uri $versionUrl -Method GET -ErrorAction Stop -TimeoutSec 10
                $ssReachable = $true
                $ssDetail = "Reachable at $ssUrl"
            }
            catch {
                $ssDetail = "Cannot reach $ssUrl/api/v1/version: $($_.Exception.Message)"
            }
        }
    }
    $checks += [PSCustomObject]@{
        Check  = 'Secret Server'
        Passed = $ssReachable
        Detail = $ssDetail
    }

    # 6. At least 1 enabled user
    $userOk = $false
    $userDetail = 'Skipped (no database)'
    if ($dbExists) {
        $enabledCount = Invoke-ROQuery -Query "SELECT COUNT(*) AS Cnt FROM ROUser WHERE IsEnabled = 1" -Scalar
        $userOk = $enabledCount -gt 0
        $userDetail = if ($userOk) { "$enabledCount enabled user(s)" } else { 'No enabled users found' }
    }
    $checks += [PSCustomObject]@{
        Check  = 'Enabled Users'
        Passed = $userOk
        Detail = $userDetail
    }

    # Overall status
    $allPassed = ($checks | Where-Object { -not $_.Passed }).Count -eq 0

    # Add overall status to output
    $checks += [PSCustomObject]@{
        Check  = 'Overall'
        Passed = $allPassed
        Detail = if ($allPassed) { 'All checks passed' } else { 'One or more checks failed' }
    }

    $checks
}
