function Set-ROUser {
    <#
    .SYNOPSIS
        Update properties of a simulated user
    .DESCRIPTION
        Modifies one or more properties of an existing simulated user. When
        -Password or -RandomPassword is specified, the AD account password is
        updated first; the SQLite record is only changed if the AD update
        succeeds. -Password and -RandomPassword are mutually exclusive. Use
        -ActionWeights to update per-user action weights with a hashtable of
        ActionName=Weight pairs.
    .PARAMETER Username
        Username of the user to update.
    .PARAMETER Password
        New plain-text password (also updates AD account).
    .PARAMETER Domain
        New AD domain.
    .PARAMETER ActiveHourStart
        New active hour start (HH:mm).
    .PARAMETER ActiveHourEnd
        New active hour end (HH:mm).
    .PARAMETER IsEnabled
        Enable or disable the user.
    .PARAMETER ActionWeights
        Hashtable of ActionName=Weight pairs to upsert.
    .PARAMETER RandomPassword
        Generate a random password and set it in both AD and SQLite.
    .PARAMETER EnableCategory
        Enable all actions in a category (Core, Management, Advanced) by restoring default weights.
    .PARAMETER DisableCategory
        Disable all actions in a category by setting their weights to 0.
    .PARAMETER EnableAction
        Enable a specific action by restoring its default weight.
    .PARAMETER DisableAction
        Disable a specific action by setting its weight to 0.
    .EXAMPLE
        Set-ROUser -Username 'svc.sim01' -ActiveHourEnd '19:00'
    .EXAMPLE
        Set-ROUser -Username 'svc.sim01' -RandomPassword
        Generate and set a new random password.
    .EXAMPLE
        Set-ROUser -Username 'svc.sim01' -ActionWeights @{ ViewSecret = 50; CreateSecret = 10 }
    .EXAMPLE
        Set-ROUser -Username 'svc.sim01' -IsEnabled $false
        Disable the user.
    .EXAMPLE
        Set-ROUser -Username 'svc.sim01' -DisableCategory 'Management'
        Disable all Management actions for the user.
    .EXAMPLE
        Set-ROUser -Username 'svc.sim01' -EnableCategory 'Management'
        Restore default weights for all Management actions.
    .EXAMPLE
        Set-ROUser -Username 'svc.sim01' -DisableAction 'CreateSecret'
        Disable a single action for the user.
    .OUTPUTS
        PSCustomObject - the updated user record
    .LINK
        Docs/commands/Set-ROUser.md
    #>
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

        [switch]$RandomPassword,

        [ValidateSet('Core', 'Management', 'Advanced')]
        [string]$EnableCategory,

        [ValidateSet('Core', 'Management', 'Advanced')]
        [string]$DisableCategory,

        [string]$EnableAction,

        [string]$DisableAction
    )

    $user = Invoke-ROQuery -Query "SELECT * FROM ROUser WHERE Username = @Username COLLATE NOCASE" -SqlParameters @{ Username = $Username }
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
        $Password = New-ROPassword
        Write-ROLog -Message "Generated random password for '$Username'" -Component 'UserMgmt'
    }

    # Build dynamic UPDATE
    $sets = @()
    $params = @{ Username = $Username }

    if ($PSBoundParameters.ContainsKey('Password') -or $RandomPassword) {
        # Update AD password first (admin reset) - fail before touching SQLite
        $newSecure = ConvertTo-SecureString $Password -AsPlainText -Force
        $splatAD = @{
            Identity    = $Username
            Reset       = $true
            NewPassword = $newSecure
            ErrorAction = 'Stop'
        }
        try {
            Set-ADAccountPassword @splatAD
            Write-ROLog -Message "AD password updated for '$Username'" -Component 'UserMgmt'
        }
        catch {
            Write-Error "Failed to update AD password for '$Username': $_"
            return
        }

        $sets += "Password = @Password"
        $sets += "PasswordLastChanged = datetime('now')"
        $params['Password'] = Protect-ROPassword -PlainText $Password
    }
    if ($PSBoundParameters.ContainsKey('Domain'))          { $sets += "Domain = @Domain";                   $params['Domain'] = $Domain }
    if ($PSBoundParameters.ContainsKey('ActiveHourStart')) { $sets += "ActiveHourStart = @ActiveHourStart"; $params['ActiveHourStart'] = $ActiveHourStart }
    if ($PSBoundParameters.ContainsKey('ActiveHourEnd'))   { $sets += "ActiveHourEnd = @ActiveHourEnd";     $params['ActiveHourEnd'] = $ActiveHourEnd }
    if ($PSBoundParameters.ContainsKey('IsEnabled'))       { $sets += "IsEnabled = @IsEnabled";             $params['IsEnabled'] = [int]$IsEnabled }

    if ($sets.Count -gt 0) {
        $sets += "UpdatedAt = datetime('now')"
        $query = "UPDATE ROUser SET $($sets -join ', ') WHERE Username = @Username COLLATE NOCASE"
        Invoke-ROQuery -Query $query -SqlParameters $params
        Write-ROLog -Message "Updated user '$Username': $($sets -join ', ')" -Component 'UserMgmt'
    }

    # Update action weights if provided
    if ($ActionWeights) {
        foreach ($kv in $ActionWeights.GetEnumerator()) {
            Invoke-ROQuery -Query @"
INSERT INTO ActionWeight (UserId, ActionName, Weight) VALUES (@UserId, @ActionName, @Weight)
ON CONFLICT(UserId, ActionName) DO UPDATE SET Weight = @Weight
"@ -SqlParameters @{
                UserId     = $user.UserId
                ActionName = $kv.Key
                Weight     = $kv.Value
            }
        }
        Write-ROLog -Message "Updated action weights for '$Username'" -Component 'UserMgmt'
    }

    # Category-level enable/disable
    if ($EnableCategory -or $DisableCategory) {
        $registry = Get-ROActionRegistry
        $seedPath = Join-Path $PSScriptRoot '..\Data\SeedActionWeights.psd1'
        $seedPath = [System.IO.Path]::GetFullPath($seedPath)
        $seedWeights = if (Test-Path $seedPath) { Invoke-Expression (Get-Content -Path $seedPath -Raw) } else { @{} }

        $targetCategory = if ($EnableCategory) { $EnableCategory } else { $DisableCategory }
        $actionsInCategory = $registry.GetEnumerator() | Where-Object { $_.Value.Category -eq $targetCategory }

        foreach ($entry in $actionsInCategory) {
            $newWeight = if ($EnableCategory) {
                if ($seedWeights[$entry.Key]) { $seedWeights[$entry.Key] } else { 10 }
            } else { 0 }

            Invoke-ROQuery -Query @"
INSERT INTO ActionWeight (UserId, ActionName, Weight) VALUES (@UserId, @ActionName, @Weight)
ON CONFLICT(UserId, ActionName) DO UPDATE SET Weight = @Weight
"@ -SqlParameters @{
                UserId     = $user.UserId
                ActionName = $entry.Key
                Weight     = $newWeight
            }
        }

        $verb = if ($EnableCategory) { 'Enabled' } else { 'Disabled' }
        Write-ROLog -Message "$verb category '$targetCategory' for '$Username'" -Component 'UserMgmt'
    }

    # Granular action enable/disable
    if ($EnableAction -or $DisableAction) {
        $targetAction = if ($EnableAction) { $EnableAction } else { $DisableAction }
        $registry = Get-ROActionRegistry

        if (-not $registry.ContainsKey($targetAction)) {
            Write-Error "Unknown action '$targetAction'. Valid actions: $($registry.Keys -join ', ')"
            return
        }

        $newWeight = 0
        if ($EnableAction) {
            $seedPath = Join-Path $PSScriptRoot '..\Data\SeedActionWeights.psd1'
            $seedPath = [System.IO.Path]::GetFullPath($seedPath)
            if (Test-Path $seedPath) {
                $seedWeights = Invoke-Expression (Get-Content -Path $seedPath -Raw)
                $newWeight = if ($seedWeights[$targetAction]) { $seedWeights[$targetAction] } else { 10 }
            } else { $newWeight = 10 }
        }

        Invoke-ROQuery -Query @"
INSERT INTO ActionWeight (UserId, ActionName, Weight) VALUES (@UserId, @ActionName, @Weight)
ON CONFLICT(UserId, ActionName) DO UPDATE SET Weight = @Weight
"@ -SqlParameters @{
            UserId     = $user.UserId
            ActionName = $targetAction
            Weight     = $newWeight
        }

        $verb = if ($EnableAction) { 'Enabled' } else { 'Disabled' }
        Write-ROLog -Message "$verb action '$targetAction' for '$Username'" -Component 'UserMgmt'
    }

    Get-ROUser -Username $Username
}
