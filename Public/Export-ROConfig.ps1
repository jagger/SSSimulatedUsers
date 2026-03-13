function Export-ROConfig {
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
