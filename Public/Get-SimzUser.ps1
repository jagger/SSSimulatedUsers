function Get-SimzUser {
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
        $users = Invoke-SimzQuery -Query "SELECT * FROM SimUser WHERE Username = @Username" -SqlParameters @{ Username = $Username }
    }
    elseif ($UserId) {
        $users = Invoke-SimzQuery -Query "SELECT * FROM SimUser WHERE UserId = @UserId" -SqlParameters @{ UserId = $UserId }
    }
    else {
        $users = Invoke-SimzQuery -Query "SELECT * FROM SimUser ORDER BY Username"
    }

    if ($IncludeWeights -and $users) {
        foreach ($user in $users) {
            $weights = Invoke-SimzQuery -Query "SELECT ActionName, Weight FROM ActionWeight WHERE UserId = @UserId" -SqlParameters @{ UserId = $user.UserId }
            $user | Add-Member -NotePropertyName 'ActionWeights' -NotePropertyValue $weights -Force
        }
    }

    if (-not $ShowPassword -and $users) {
        foreach ($u in $users) {
            $u.Password = '********'
        }
    }

    $users
}
