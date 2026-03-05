function Start-SimzCycle {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $cycleStart = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-SimzLog -Message "=== Cycle starting at $cycleStart ===" -Component 'Cycle'

    # Load config
    $baseUrl = Get-SimzConfig -Key 'SecretServerUrl'
    if (-not $baseUrl) {
        throw "SecretServerUrl not configured. Run: Set-SimzConfig -Key SecretServerUrl -Value 'https://...'"
    }

    $minActions = [int](Get-SimzConfig -Key 'MinActionsPerCycle')
    $maxActions = [int](Get-SimzConfig -Key 'MaxActionsPerCycle')
    if ($maxActions -eq 0) { $maxActions = 15 }

    # Rotate AD passwords for users due for rotation
    try {
        $rotated = Invoke-PasswordRotation
        if ($rotated -gt 0) {
            Write-SimzLog -Message "Rotated passwords for $rotated user(s)" -Component 'Cycle'
        }
    }
    catch {
        Write-SimzLog -Message "Password rotation error: $_" -Level ERROR -Component 'Cycle'
    }

    # Get active users
    $activeUsers = Get-SimzActiveUsers
    $allUsers = Invoke-SimzQuery -Query "SELECT COUNT(*) AS Cnt FROM SimUser WHERE IsEnabled = 1" -Scalar

    if (-not $activeUsers -or $activeUsers.Count -eq 0) {
        Write-SimzLog -Message 'No active users for this cycle' -Level WARN -Component 'Cycle'
        Invoke-SimzQuery -Query @"
INSERT INTO CycleLog (StartTime, EndTime, TotalUsers, ActiveUsers, TotalActions, Errors)
VALUES (@Start, @End, @Total, 0, 0, 0)
"@ -SqlParameters @{ Start = $cycleStart; End = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'); Total = $allUsers }
        return
    }

    if (-not $PSCmdlet.ShouldProcess("$($activeUsers.Count) active users", 'Run simulation cycle')) {
        return
    }

    $totalActions = 0
    $totalErrors = 0

    foreach ($user in $activeUsers) {
        try {
            $result = Invoke-UserCycle -User $user -BaseUrl $baseUrl -MinActions $minActions -MaxActions $maxActions
            $totalActions += $result.Actions
            $totalErrors += $result.Errors
        }
        catch {
            Write-SimzLog -Message "User cycle failed for '$($user.Username)': $_" -Level ERROR -Component 'Cycle'
            $totalErrors++
        }
    }

    $cycleEnd = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

    # Record cycle summary
    Invoke-SimzQuery -Query @"
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

    Write-SimzLog -Message "=== Cycle complete: $($activeUsers.Count) users, $totalActions actions, $totalErrors errors ===" -Component 'Cycle'

    [PSCustomObject]@{
        StartTime    = $cycleStart
        EndTime      = $cycleEnd
        TotalUsers   = $allUsers
        ActiveUsers  = $activeUsers.Count
        TotalActions = $totalActions
        Errors       = $totalErrors
    }
}
