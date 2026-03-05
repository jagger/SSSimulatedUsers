function Invoke-PasswordRotation {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Username
    )

    if ($Username) {
        # One-off reset for a specific user
        $users = Invoke-SimzQuery -Query "SELECT * FROM SimUser WHERE Username = @Username" `
            -SqlParameters @{ Username = $Username }
        if (-not $users) {
            Write-Error "User '$Username' not found in SimUser table"
            return 0
        }
    }
    else {
        # Scheduled rotation: find users past their rotation window
        $rotationDays = [int](Get-SimzConfig -Key 'PasswordRotationDays')
        if ($rotationDays -le 0) { $rotationDays = 14 }

        $users = Invoke-SimzQuery -Query @"
SELECT * FROM SimUser
WHERE IsEnabled = 1
  AND (PasswordLastChanged IS NULL
       OR julianday('now') - julianday(PasswordLastChanged) >= @Days)
"@ -SqlParameters @{ Days = $rotationDays }

        if (-not $users) {
            Write-SimzLog -Message 'Password rotation: no users need rotation' -Level DEBUG -Component 'Engine'
            return 0
        }
    }

    $rotated = 0

    foreach ($user in @($users)) {
        try {
            $newPassword = New-SimzPassword
            $newSecure = ConvertTo-SecureString $newPassword -AsPlainText -Force

            $splatAD = @{
                Identity    = $user.Username
                Reset       = $true
                NewPassword = $newSecure
                ErrorAction = 'Stop'
            }
            Set-ADAccountPassword @splatAD

            Invoke-SimzQuery -Query @"
UPDATE SimUser
SET Password = @NewPw,
    PasswordLastChanged = datetime('now'),
    UpdatedAt = datetime('now')
WHERE Username = @Username
"@ -SqlParameters @{ NewPw = $newPassword; Username = $user.Username }

            Write-SimzLog -Message "Password rotated for '$($user.Username)'" -Component 'Engine'
            $rotated++
        }
        catch {
            Write-SimzLog -Message "Password rotation failed for '$($user.Username)': $_" -Level ERROR -Component 'Engine'
        }
    }

    Write-SimzLog -Message "Password rotation complete: $rotated of $(@($users).Count) users rotated" -Component 'Engine'
    return $rotated
}
