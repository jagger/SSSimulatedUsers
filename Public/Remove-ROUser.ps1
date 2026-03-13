function Remove-ROUser {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Username
    )

    $user = Invoke-ROQuery -Query "SELECT UserId FROM ROUser WHERE Username = @Username" -SqlParameters @{ Username = $Username }
    if (-not $user) {
        Write-Error "User '$Username' not found."
        return
    }

    if ($PSCmdlet.ShouldProcess($Username, 'Remove simulated user')) {
        # ActionWeight rows cascade-delete via FK; ActionLog rows kept for history
        Invoke-ROQuery -Query "DELETE FROM ActionWeight WHERE UserId = @UserId" -SqlParameters @{ UserId = $user.UserId }
        Invoke-ROQuery -Query "DELETE FROM ROUser WHERE UserId = @UserId" -SqlParameters @{ UserId = $user.UserId }
        Write-ROLog -Message "Removed user '$Username' (ID: $($user.UserId))" -Component 'UserMgmt'
    }
}
