function Export-ROConfig {
    <#
    .SYNOPSIS
        Export configuration and users to a JSON file
    .DESCRIPTION
        Exports all Config key-value pairs, user records, and per-user
        ActionWeights to a JSON file. By default passwords are excluded
        (null in output). Use -IncludePasswords to decrypt and include
        passwords in the export. WARNING: exported passwords are in
        plain text.
    .PARAMETER Path
        File path for the JSON export.
    .PARAMETER IncludePasswords
        Decrypt and include passwords in the export (security risk).
    .EXAMPLE
        Export-ROConfig -Path 'C:\backup\robotters-config.json'
    .EXAMPLE
        Export-ROConfig -Path '.\config-with-pw.json' -IncludePasswords
    .OUTPUTS
        System.String
            Confirmation message with export path.
    .LINK
        Docs/commands/Export-ROConfig.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [switch]$IncludePasswords
    )

    # Build Config hashtable
    $configRows = Invoke-ROQuery -Query "SELECT Key, Value FROM Config ORDER BY Key"
    $configHash = @{}
    foreach ($row in @($configRows)) {
        $configHash[$row.Key] = $row.Value
    }

    # Build Users array with action weights
    $users = Invoke-ROQuery -Query "SELECT * FROM ROUser ORDER BY Username"
    $userList = @()

    foreach ($user in @($users)) {
        # Password handling
        $password = $null
        if ($IncludePasswords) {
            $password = Unprotect-ROPassword -EncryptedText $user.Password
        }

        # Action weights
        $weightRows = Invoke-ROQuery -Query "SELECT ActionName, Weight FROM ActionWeight WHERE UserId = @UserId" -SqlParameters @{ UserId = $user.UserId }
        $weightHash = @{}
        foreach ($w in @($weightRows)) {
            $weightHash[$w.ActionName] = [int]$w.Weight
        }

        $userList += [PSCustomObject]@{
            Username        = $user.Username
            Password        = $password
            Domain          = $user.Domain
            ActiveHourStart = $user.ActiveHourStart
            ActiveHourEnd   = $user.ActiveHourEnd
            IsEnabled       = [int]$user.IsEnabled
            ActionWeights   = $weightHash
        }
    }

    $export = [PSCustomObject]@{
        ExportedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Config     = $configHash
        Users      = $userList
    }

    $json = $export | ConvertTo-Json -Depth 3
    Set-Content -Path $Path -Value $json -Encoding UTF8

    $msg = "Exported config to '$Path' ($(@($users).Count) users"
    if ($IncludePasswords) { $msg += ', passwords included' }
    $msg += ')'
    Write-ROLog -Message $msg -Component 'Config'

    Write-Output "Export saved to $Path"
}
