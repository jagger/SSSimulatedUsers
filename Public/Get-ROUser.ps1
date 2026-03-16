function Get-ROUser {
    <#
    .SYNOPSIS
        List simulated users from the RobOtters database
    .DESCRIPTION
        Retrieves one or more simulated users. By default, passwords are masked.
        Use -ShowPassword to decrypt and display actual passwords. Use
        -IncludeWeights to attach each user's ActionWeight records.
    .PARAMETER Username
        Filter by username (ParameterSetName ByName).
    .PARAMETER UserId
        Filter by user ID (ParameterSetName ById).
    .PARAMETER IncludeWeights
        Attach ActionWeight records to each user object.
    .PARAMETER ShowPassword
        Decrypt and display actual passwords instead of masked values.
    .EXAMPLE
        Get-ROUser
        List all users.
    .EXAMPLE
        Get-ROUser -Username 'svc.sim01' -ShowPassword
        Show the actual password for a specific user.
    .EXAMPLE
        Get-ROUser -IncludeWeights
        Include action weights for all users.
    .OUTPUTS
        PSCustomObject[] - user records with Username, Domain, ActiveHourStart, ActiveHourEnd, IsEnabled, Password properties
    .LINK
        Docs/commands/Get-ROUser.md
    #>
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param(
        [Parameter(ParameterSetName = 'ByName')]
        [string]$Username,

        [Parameter(ParameterSetName = 'ById')]
        [int]$UserId,

        [switch]$IncludeWeights,

        [switch]$ShowPassword
    )

    if ($Username) {
        $users = Invoke-ROQuery -Query "SELECT * FROM ROUser WHERE Username = @Username COLLATE NOCASE" -SqlParameters @{ Username = $Username }
    }
    elseif ($UserId) {
        $users = Invoke-ROQuery -Query "SELECT * FROM ROUser WHERE UserId = @UserId" -SqlParameters @{ UserId = $UserId }
    }
    else {
        $users = Invoke-ROQuery -Query "SELECT * FROM ROUser ORDER BY Username"
    }

    if ($IncludeWeights -and $users) {
        foreach ($user in $users) {
            $weights = Invoke-ROQuery -Query "SELECT ActionName, Weight FROM ActionWeight WHERE UserId = @UserId" -SqlParameters @{ UserId = $user.UserId }
            $user | Add-Member -NotePropertyName 'ActionWeights' -NotePropertyValue $weights -Force
        }
    }

    if (-not $ShowPassword -and $users) {
        foreach ($u in $users) {
            $u.Password = '********'
        }
    } elseif ($ShowPassword -and $users) {
        foreach ($u in $users) {
            $u.Password = Unprotect-ROPassword -EncryptedText $u.Password
        }
    }

    $users
}
