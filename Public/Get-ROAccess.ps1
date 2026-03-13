function Get-ROAccess {
    <#
    .SYNOPSIS
        View user access snapshots showing folders, secrets, and templates per user
    .DESCRIPTION
        Queries cached access data from the UserAccess table. Data is
        automatically refreshed when older than AccessSnapshotMaxAgeDays
        (default 7). Use -Refresh to force an update from Secret Server.
        Use -Purge to clear all cached access data. Without -Username,
        returns data for all enabled users.
    .PARAMETER Username
        Filter to a specific user. Part of the Query parameter set.
    .PARAMETER Refresh
        Force refresh from Secret Server for all queried users.
        Part of the Query parameter set.
    .PARAMETER Purge
        Clear all cached UserAccess data. Part of the Purge parameter set.
    .EXAMPLE
        Get-ROAccess
        View access for all users (auto-refreshes stale data).
    .EXAMPLE
        Get-ROAccess -Username 'svc.sim01' -Refresh
        Force refresh for one user.
    .EXAMPLE
        Get-ROAccess -Purge
        Clear all cached access data.
    .OUTPUTS
        PSCustomObject[] with Username, FolderCount, SecretCount, TemplateCount, TemplateNames, CheckedAt properties.
    .LINK
        Docs/commands/Get-ROAccess.md
    #>
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param(
        [Parameter(ParameterSetName = 'Query')]
        [string]$Username,

        [Parameter(ParameterSetName = 'Query')]
        [switch]$Refresh,

        [Parameter(ParameterSetName = 'Purge', Mandatory)]
        [switch]$Purge
    )

    # Handle purge - clear all cached access data
    if ($Purge) {
        Invoke-ROQuery -Query "DELETE FROM UserAccess"
        Write-ROLog -Message 'Purged all UserAccess data' -Component 'Access'
        return
    }

    # Determine which users to work with
    if ($Username) {
        $users = Invoke-ROQuery -Query "SELECT * FROM ROUser WHERE Username = @Username AND IsEnabled = 1" `
            -SqlParameters @{ Username = $Username }
        if (-not $users) {
            Write-Error "User '$Username' not found or not enabled."
            return
        }
    }
    else {
        $users = Invoke-ROQuery -Query "SELECT * FROM ROUser WHERE IsEnabled = 1 ORDER BY Username"
        if (-not $users) {
            Write-Error 'No enabled users found.'
            return
        }
    }

    # Staleness threshold from config (default 7 days)
    $maxAgeDays = Get-ROConfig -Key 'AccessSnapshotMaxAgeDays'
    if (-not $maxAgeDays) { $maxAgeDays = 7 }

    # Refresh logic: -Refresh forces all, otherwise auto-refresh stale entries
    if ($Refresh) {
        foreach ($user in $users) {
            try {
                Update-ROUserAccess -User $user
            }
            catch {
                Write-Warning "Failed to refresh access for '$($user.Username)': $_"
            }
        }
    }
    else {
        # Auto-refresh any user whose data is older than the configured threshold or missing
        foreach ($user in $users) {
            $cached = Invoke-ROQuery -Query "SELECT CheckedAt FROM UserAccess WHERE UserId = @UserId" `
                -SqlParameters @{ UserId = $user.UserId } -Scalar

            $needsRefresh = $true
            if ($cached) {
                $checkedDate = [datetime]::ParseExact($cached, 'yyyy-MM-dd HH:mm:ss', [System.Globalization.CultureInfo]::InvariantCulture)
                if (((Get-Date) - $checkedDate).TotalDays -lt [int]$maxAgeDays) {
                    $needsRefresh = $false
                }
            }

            if ($needsRefresh) {
                try {
                    Update-ROUserAccess -User $user
                }
                catch {
                    Write-Warning "Failed to refresh access for '$($user.Username)': $_"
                }
            }
        }
    }

    # Retrieve and display results (excluding internal AccessId column)
    if ($Username) {
        $results = Invoke-ROQuery -Query "SELECT * FROM UserAccess WHERE Username = @Username" `
            -SqlParameters @{ Username = $Username }
    }
    else {
        $results = Invoke-ROQuery -Query "SELECT * FROM UserAccess ORDER BY Username"
    }

    if (-not $results) {
        Write-Warning 'No access data available. Run with -Refresh to populate.'
        return
    }

    $results | ForEach-Object {
        [PSCustomObject]@{
            Username      = $_.Username
            FolderCount   = $_.FolderCount
            SecretCount   = $_.SecretCount
            TemplateCount = $_.TemplateCount
            TemplateNames = $_.TemplateNames
            CheckedAt     = $_.CheckedAt
        }
    }
}
