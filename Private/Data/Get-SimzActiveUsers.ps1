function Get-SimzActiveUsers {
    [CmdletBinding()]
    param()

    $allUsers = Invoke-SimzQuery -Query "SELECT * FROM SimUser WHERE IsEnabled = 1"

    if (-not $allUsers) {
        Write-SimzLog -Message 'No enabled users found' -Level WARN -Component 'Engine'
        return @()
    }

    $activeUsers = foreach ($user in $allUsers) {
        if (Test-SimzActiveHours -ActiveHourStart $user.ActiveHourStart -ActiveHourEnd $user.ActiveHourEnd) {
            $dow = (Get-Date).DayOfWeek
            if ($dow -eq 'Saturday' -or $dow -eq 'Sunday') {
                if ((Get-Random -Minimum 0 -Maximum 100) -lt 5) {
                    Write-SimzLog -Message "Weekend: '$($user.Username)' included (5% roll)" -Level DEBUG -Component 'Engine'
                    $user
                }
            }
            else {
                $user
            }
        }
    }

    Write-SimzLog -Message "Found $(@($activeUsers).Count) active users out of $(@($allUsers).Count) enabled" -Component 'Engine'
    @($activeUsers)
}
