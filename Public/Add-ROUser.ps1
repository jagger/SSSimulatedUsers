function Add-ROUser {
    <#
    .SYNOPSIS
        Register a simulated AD user in the RobOtters database
    .DESCRIPTION
        Adds a new simulated user. The password is encrypted via DPAPI before
        storage. Action weights are automatically seeded from
        Data/SeedActionWeights.psd1. Returns the new user object.
    .PARAMETER Username
        AD username for the simulated user.
    .PARAMETER Password
        Plain-text password (encrypted at rest via DPAPI).
    .PARAMETER Domain
        AD domain name.
    .PARAMETER ActiveHourStart
        Earliest time the user will be active (HH:mm). Defaults to '07:00'.
    .PARAMETER ActiveHourEnd
        Latest time the user will be active (HH:mm). Defaults to '17:00'.
    .EXAMPLE
        Add-ROUser -Username 'svc.sim01' -Password 'P@ssw0rd!' -Domain 'LAB'
    .EXAMPLE
        Add-ROUser -Username 'svc.sim02' -Password 'S3cret!' -Domain 'LAB' -ActiveHourStart '09:00' -ActiveHourEnd '21:00'
    .OUTPUTS
        PSCustomObject - the newly created user record
    .LINK
        Docs/commands/Add-ROUser.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Username,

        [Parameter(Mandatory)]
        [string]$Password,

        [Parameter(Mandatory)]
        [string]$Domain,

        [string]$ActiveHourStart = '07:00',

        [string]$ActiveHourEnd = '17:00'
    )

    # Validate user exists in AD
    try {
        $adUser = Get-ADUser -Identity $Username -ErrorAction Stop
    }
    catch {
        Write-Error "AD account '$Username' not found. The user must exist in Active Directory before adding to RobOtters."
        return
    }

    # Check for duplicate
    $existing = Invoke-ROQuery -Query "SELECT UserId FROM ROUser WHERE Username = @Username COLLATE NOCASE" -SqlParameters @{ Username = $Username }
    if ($existing) {
        Write-Error "User '$Username' already exists."
        return
    }

    $query = @"
INSERT INTO ROUser (Username, Password, Domain, ActiveHourStart, ActiveHourEnd)
VALUES (@Username, @Password, @Domain, @ActiveHourStart, @ActiveHourEnd)
"@

    $Password = Protect-ROPassword -PlainText $Password

    Invoke-ROQuery -Query $query -SqlParameters @{
        Username        = $Username
        Password        = $Password
        Domain          = $Domain
        ActiveHourStart = $ActiveHourStart
        ActiveHourEnd   = $ActiveHourEnd
    }

    # Get the new UserId
    $userId = Invoke-ROQuery -Query "SELECT UserId FROM ROUser WHERE Username = @Username COLLATE NOCASE" -SqlParameters @{ Username = $Username } -Scalar

    # Seed action weights from defaults
    $seedPath = Join-Path $PSScriptRoot '..\Data\SeedActionWeights.psd1'
    $seedPath = [System.IO.Path]::GetFullPath($seedPath)

    if (Test-Path $seedPath) {
        $weights = Invoke-Expression (Get-Content -Path $seedPath -Raw)

        foreach ($kv in $weights.GetEnumerator()) {
            Invoke-ROQuery -Query @"
INSERT INTO ActionWeight (UserId, ActionName, Weight)
VALUES (@UserId, @ActionName, @Weight)
"@ -SqlParameters @{
                UserId     = $userId
                ActionName = $kv.Key
                Weight     = $kv.Value
            }
        }
    }

    Write-ROLog -Message "Added user '$Username' (ID: $userId) with default action weights" -Component 'UserMgmt'
    Get-ROUser -Username $Username
}
