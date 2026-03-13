function Get-ROActiveUsers {
    [CmdletBinding()]
    param()

    $allUsers = Invoke-ROQuery -Query "SELECT * FROM ROUser WHERE IsEnabled = 1"

    if (-not $allUsers) {
        Write-ROLog -Message 'No enabled users found' -Level WARN -Component 'Engine'
        return @()
    }

    $activeUsers = foreach ($user in $allUsers) {
        if (Test-ROActiveHours -ActiveHourStart $user.ActiveHourStart -ActiveHourEnd $user.ActiveHourEnd) {
            $dow = (Get-Date).DayOfWeek
            if ($dow -eq 'Saturday' -or $dow -eq 'Sunday') {
                if ((Get-Random -Minimum 0 -Maximum 100) -lt 5) {
                    Write-ROLog -Message "Weekend: '$($user.Username)' included (5% roll)" -Level DEBUG -Component 'Engine'
                    $user
                }
            }
            else {
                $user
            }
        }
    }

    # Strip passwords - engine fetches them on-demand from DB when needed
    foreach ($u in @($activeUsers)) {
        $u.PSObject.Properties.Remove('Password')
    }

    Write-ROLog -Message "Found $(@($activeUsers).Count) active users out of $(@($allUsers).Count) enabled" -Component 'Engine'
    @($activeUsers)
}
