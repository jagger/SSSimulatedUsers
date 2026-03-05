function Set-SimzUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Username,

        [string]$Password,

        [string]$Domain,

        [string]$ActiveHourStart,

        [string]$ActiveHourEnd,

        [Nullable[bool]]$IsEnabled,

        [hashtable]$ActionWeights,

        [switch]$RandomPassword
    )

    $user = Invoke-SimzQuery -Query "SELECT * FROM SimUser WHERE Username = @Username" -SqlParameters @{ Username = $Username }
    if (-not $user) {
        Write-Error "User '$Username' not found."
        return
    }

    if ($PSBoundParameters.ContainsKey('Password') -and $RandomPassword) {
        Write-Error "-Password and -RandomPassword cannot be used together."
        return
    }

    # Generate random password if requested
    if ($RandomPassword) {
        $Password = New-SimzPassword
        Write-SimzLog -Message "Generated random password for '$Username'" -Component 'UserMgmt'
    }

    # Build dynamic UPDATE
    $sets = @()
    $params = @{ Username = $Username }

    if ($PSBoundParameters.ContainsKey('Password') -or $RandomPassword) {
        # Update AD password first — fail before touching SQLite
        $oldSecure = ConvertTo-SecureString $user.Password -AsPlainText -Force
        $newSecure = ConvertTo-SecureString $Password -AsPlainText -Force
        $splatAD = @{
            Identity    = $Username
            OldPassword = $oldSecure
            NewPassword = $newSecure
            ErrorAction = 'Stop'
        }
        try {
            Set-ADAccountPassword @splatAD
            Write-SimzLog -Message "AD password updated for '$Username'" -Component 'UserMgmt'
        }
        catch {
            Write-Error "Failed to update AD password for '$Username': $_"
            return
        }

        $sets += "Password = @Password"
        $sets += "PasswordLastChanged = datetime('now')"
        $params['Password'] = $Password
    }
    if ($PSBoundParameters.ContainsKey('Domain'))          { $sets += "Domain = @Domain";                   $params['Domain'] = $Domain }
    if ($PSBoundParameters.ContainsKey('ActiveHourStart')) { $sets += "ActiveHourStart = @ActiveHourStart"; $params['ActiveHourStart'] = $ActiveHourStart }
    if ($PSBoundParameters.ContainsKey('ActiveHourEnd'))   { $sets += "ActiveHourEnd = @ActiveHourEnd";     $params['ActiveHourEnd'] = $ActiveHourEnd }
    if ($PSBoundParameters.ContainsKey('IsEnabled'))       { $sets += "IsEnabled = @IsEnabled";             $params['IsEnabled'] = [int]$IsEnabled }

    if ($sets.Count -gt 0) {
        $sets += "UpdatedAt = datetime('now')"
        $query = "UPDATE SimUser SET $($sets -join ', ') WHERE Username = @Username"
        Invoke-SimzQuery -Query $query -SqlParameters $params
        Write-SimzLog -Message "Updated user '$Username': $($sets -join ', ')" -Component 'UserMgmt'
    }

    # Update action weights if provided
    if ($ActionWeights) {
        foreach ($kv in $ActionWeights.GetEnumerator()) {
            Invoke-SimzQuery -Query @"
INSERT INTO ActionWeight (UserId, ActionName, Weight) VALUES (@UserId, @ActionName, @Weight)
ON CONFLICT(UserId, ActionName) DO UPDATE SET Weight = @Weight
"@ -SqlParameters @{
                UserId     = $user.UserId
                ActionName = $kv.Key
                Weight     = $kv.Value
            }
        }
        Write-SimzLog -Message "Updated action weights for '$Username'" -Component 'UserMgmt'
    }

    Get-SimzUser -Username $Username
}
