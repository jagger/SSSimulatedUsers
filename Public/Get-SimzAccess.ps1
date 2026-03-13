function Get-SimzAccess {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param(
        [Parameter(ParameterSetName = 'Query')]
        [string]$Username,

        [Parameter(ParameterSetName = 'Query')]
        [switch]$Refresh,

        [Parameter(ParameterSetName = 'Purge', Mandatory)]
        [switch]$Purge
    )

    # Handle purge — clear all cached access data
    if ($Purge) {
        Invoke-SimzQuery -Query "DELETE FROM UserAccess"
        Write-SimzLog -Message 'Purged all UserAccess data' -Component 'Access'
        return
    }

    # Determine which users to work with
    if ($Username) {
        $users = Invoke-SimzQuery -Query "SELECT * FROM SimUser WHERE Username = @Username AND IsEnabled = 1" `
            -SqlParameters @{ Username = $Username }
        if (-not $users) {
            Write-Error "User '$Username' not found or not enabled."
            return
        }
    }
    else {
        $users = Invoke-SimzQuery -Query "SELECT * FROM SimUser WHERE IsEnabled = 1 ORDER BY Username"
        if (-not $users) {
            Write-Error 'No enabled users found.'
            return
        }
    }

    # Staleness threshold from config (default 7 days)
    $maxAgeDays = Get-SimzConfig -Key 'AccessSnapshotMaxAgeDays'
    if (-not $maxAgeDays) { $maxAgeDays = 7 }

    # Refresh logic: -Refresh forces all, otherwise auto-refresh stale entries
    if ($Refresh) {
        foreach ($user in $users) {
            try {
                Update-SimzUserAccess -User $user
            }
            catch {
                Write-Warning "Failed to refresh access for '$($user.Username)': $_"
            }
        }
    }
    else {
        # Auto-refresh any user whose data is older than the configured threshold or missing
        foreach ($user in $users) {
            $cached = Invoke-SimzQuery -Query "SELECT CheckedAt FROM UserAccess WHERE UserId = @UserId" `
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
                    Update-SimzUserAccess -User $user
                }
                catch {
                    Write-Warning "Failed to refresh access for '$($user.Username)': $_"
                }
            }
        }
    }

    # Retrieve and display results (excluding internal AccessId column)
    if ($Username) {
        $results = Invoke-SimzQuery -Query "SELECT * FROM UserAccess WHERE Username = @Username" `
            -SqlParameters @{ Username = $Username }
    }
    else {
        $results = Invoke-SimzQuery -Query "SELECT * FROM UserAccess ORDER BY Username"
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
