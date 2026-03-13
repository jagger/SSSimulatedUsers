function Add-ROUser {
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

    # Check for duplicate
    $existing = Invoke-ROQuery -Query "SELECT UserId FROM ROUser WHERE Username = @Username" -SqlParameters @{ Username = $Username }
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
    $userId = Invoke-ROQuery -Query "SELECT UserId FROM ROUser WHERE Username = @Username" -SqlParameters @{ Username = $Username } -Scalar

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
