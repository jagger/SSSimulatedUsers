function Remove-SimzUser {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Username
    )

    $user = Invoke-SimzQuery -Query "SELECT UserId FROM SimUser WHERE Username = @Username" -SqlParameters @{ Username = $Username }
    if (-not $user) {
        Write-Error "User '$Username' not found."
        return
    }

    if ($PSCmdlet.ShouldProcess($Username, 'Remove simulated user')) {
        # ActionWeight rows cascade-delete via FK; ActionLog rows kept for history
        Invoke-SimzQuery -Query "DELETE FROM ActionWeight WHERE UserId = @UserId" -SqlParameters @{ UserId = $user.UserId }
        Invoke-SimzQuery -Query "DELETE FROM SimUser WHERE UserId = @UserId" -SqlParameters @{ UserId = $user.UserId }
        Write-SimzLog -Message "Removed user '$Username' (ID: $($user.UserId))" -Component 'UserMgmt'
    }
}
