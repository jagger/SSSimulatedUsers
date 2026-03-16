function Start-ROCycle {
    <#
    .SYNOPSIS
        Run a simulation cycle against Secret Server
    .DESCRIPTION
        Executes a simulation cycle. In full mode (no -User), rotates passwords
        for users due for rotation, then iterates through all enabled users
        within their active hours, selecting a random number of actions
        (MinActionsPerCycle to MaxActionsPerCycle) per user. In single-user mode
        (-User), runs only for the specified user. Use -Force to override active
        hour restrictions. Returns a cycle summary object. Supports -WhatIf.
    .PARAMETER User
        Run cycle for a single user only.
    .PARAMETER Force
        Override active hour restrictions.
    .EXAMPLE
        Start-ROCycle
        Full cycle for all active users.
    .EXAMPLE
        Start-ROCycle -User 'svc.sim01'
        Single-user cycle.
    .EXAMPLE
        Start-ROCycle -User 'svc.sim01' -Force
        Ignore active hours for the specified user.
    .EXAMPLE
        Start-ROCycle -WhatIf
        Preview what would run without executing.
    .OUTPUTS
        PSCustomObject with StartTime, EndTime, TotalUsers, ActiveUsers, TotalActions, Errors
    .LINK
        Docs/commands/Start-ROCycle.md
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [string]$User,

        [Parameter()]
        [switch]$Force
    )

    $cycleStart = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-ROLog -Message "=== Cycle starting at $cycleStart ===" -Component 'Cycle'

    # Load config
    $baseUrl = Get-ROConfig -Key 'SecretServerUrl'
    if (-not $baseUrl) {
        throw "SecretServerUrl not configured. Run: Set-ROConfig -Key SecretServerUrl -Value 'https://...'"
    }

    $minActions = [int](Get-ROConfig -Key 'MinActionsPerCycle')
    $maxActions = [int](Get-ROConfig -Key 'MaxActionsPerCycle')
    if ($maxActions -eq 0) { $maxActions = 15 }

    $totalActions = 0
    $totalErrors = 0

    if ($User) {
        # Single-user mode
        $roUser = Get-ROUser -Username $User -ShowPassword
        if (-not $roUser) {
            throw "User '$User' not found"
        }
        if (-not $roUser.IsEnabled) {
            throw "User '$User' is not enabled"
        }

        # Check active hours
        $isActive = Test-ROActiveHours -ActiveHourStart $roUser.ActiveHourStart -ActiveHourEnd $roUser.ActiveHourEnd
        if (-not $isActive -and -not $Force) {
            Write-Warning "User '$User' is outside active hours ($($roUser.ActiveHourStart) - $($roUser.ActiveHourEnd)). Use -Force to override."
            return
        }
        if (-not $isActive -and $Force) {
            Write-ROLog -Message "User '$User' is outside active hours - running anyway (-Force)" -Level WARN -Component 'Cycle'
        }

        $allUsers = 1
        $activeUsers = @($roUser)

        if (-not $PSCmdlet.ShouldProcess("user '$User'", 'Run simulation cycle')) {
            return
        }

        try {
            $result = Invoke-ROUserCycle -User $roUser -BaseUrl $baseUrl -MinActions $minActions -MaxActions $maxActions
            $totalActions += $result.Actions
            $totalErrors += $result.Errors
        }
        catch {
            Write-ROLog -Message "User cycle failed for '$User': $_" -Level ERROR -Component 'Cycle'
            $totalErrors++
        }
    }
    else {
        # Full cycle mode - existing behavior

        # Rotate AD passwords for users due for rotation
        try {
            $rotated = Invoke-ROPasswordRotation
            if ($rotated -gt 0) {
                Write-ROLog -Message "Rotated passwords for $rotated user(s)" -Component 'Cycle'
            }
        }
        catch {
            Write-ROLog -Message "Password rotation error: $_" -Level ERROR -Component 'Cycle'
        }

        # Get active users
        $activeUsers = Get-ROActiveUsers
        $allUsers = Invoke-ROQuery -Query "SELECT COUNT(*) AS Cnt FROM ROUser WHERE IsEnabled = 1" -Scalar

        if (-not $activeUsers -or $activeUsers.Count -eq 0) {
            Write-ROLog -Message 'No active users for this cycle' -Level WARN -Component 'Cycle'
            Invoke-ROQuery -Query @"
INSERT INTO CycleLog (StartTime, EndTime, TotalUsers, ActiveUsers, TotalActions, Errors)
VALUES (@Start, @End, @Total, 0, 0, 0)
"@ -SqlParameters @{ Start = $cycleStart; End = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'); Total = $allUsers }
            return
        }

        if (-not $PSCmdlet.ShouldProcess("$($activeUsers.Count) active users", 'Run simulation cycle')) {
            return
        }

        foreach ($roUser in $activeUsers) {
            try {
                $result = Invoke-ROUserCycle -User $roUser -BaseUrl $baseUrl -MinActions $minActions -MaxActions $maxActions
                $totalActions += $result.Actions
                $totalErrors += $result.Errors
            }
            catch {
                Write-ROLog -Message "User cycle failed for '$($roUser.Username)': $_" -Level ERROR -Component 'Cycle'
                $totalErrors++
            }
        }
    }

    $cycleEnd = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

    # Record cycle summary
    Invoke-ROQuery -Query @"
INSERT INTO CycleLog (StartTime, EndTime, TotalUsers, ActiveUsers, TotalActions, Errors)
VALUES (@Start, @End, @Total, @Active, @Actions, @Errors)
"@ -SqlParameters @{
        Start   = $cycleStart
        End     = $cycleEnd
        Total   = $allUsers
        Active  = $activeUsers.Count
        Actions = $totalActions
        Errors  = $totalErrors
    }

    Write-ROLog -Message "=== Cycle complete: $($activeUsers.Count) users, $totalActions actions, $totalErrors errors ===" -Component 'Cycle'

    [PSCustomObject]@{
        StartTime    = $cycleStart
        EndTime      = $cycleEnd
        TotalUsers   = $allUsers
        ActiveUsers  = $activeUsers.Count
        TotalActions = $totalActions
        Errors       = $totalErrors
    }
}
