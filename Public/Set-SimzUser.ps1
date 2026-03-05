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
        $sets += "Password = @Password"
        $params['Password'] = $Password
    }
    if ($RandomPassword) { $sets += "PasswordLastChanged = datetime('now')" }
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
