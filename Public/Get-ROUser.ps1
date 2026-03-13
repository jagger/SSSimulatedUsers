function Get-ROUser {
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
        $users = Invoke-ROQuery -Query "SELECT * FROM ROUser WHERE Username = @Username" -SqlParameters @{ Username = $Username }
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
