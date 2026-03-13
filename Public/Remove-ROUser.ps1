function Remove-ROUser {
    <#
    .SYNOPSIS
        Remove a simulated user from the RobOtters database
    .DESCRIPTION
        Deletes the specified user and their associated ActionWeight records.
        ActionLog entries are preserved for historical reporting. Supports
        -WhatIf and -Confirm via SupportsShouldProcess.
    .PARAMETER Username
        Username of the simulated user to remove.
    .EXAMPLE
        Remove-ROUser -Username 'svc.sim01'
    .EXAMPLE
        Remove-ROUser -Username 'svc.sim01' -WhatIf
        Preview without deleting.
    .EXAMPLE
        Remove-ROUser -Username 'svc.sim01' -Confirm:$false
        Skip confirmation prompt.
    .OUTPUTS
        None
    .LINK
        Docs/commands/Remove-ROUser.md
    #>
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
