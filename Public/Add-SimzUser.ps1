function Add-SimzUser {
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
    $existing = Invoke-SimzQuery -Query "SELECT UserId FROM SimUser WHERE Username = @Username" -SqlParameters @{ Username = $Username }
    if ($existing) {
        Write-Error "User '$Username' already exists."
        return
    }

    $query = @"
INSERT INTO SimUser (Username, Password, Domain, ActiveHourStart, ActiveHourEnd)
VALUES (@Username, @Password, @Domain, @ActiveHourStart, @ActiveHourEnd)
"@

    Invoke-SimzQuery -Query $query -SqlParameters @{
        Username        = $Username
        Password        = $Password
        Domain          = $Domain
        ActiveHourStart = $ActiveHourStart
        ActiveHourEnd   = $ActiveHourEnd
    }

    # Get the new UserId
    $userId = Invoke-SimzQuery -Query "SELECT UserId FROM SimUser WHERE Username = @Username" -SqlParameters @{ Username = $Username } -Scalar

    # Seed action weights from defaults
    $seedPath = Join-Path $PSScriptRoot '..\Data\SeedActionWeights.psd1'
    $seedPath = [System.IO.Path]::GetFullPath($seedPath)

    if (Test-Path $seedPath) {
        $weights = Invoke-Expression (Get-Content -Path $seedPath -Raw)

        foreach ($kv in $weights.GetEnumerator()) {
            Invoke-SimzQuery -Query @"
INSERT INTO ActionWeight (UserId, ActionName, Weight)
VALUES (@UserId, @ActionName, @Weight)
"@ -SqlParameters @{
                UserId     = $userId
                ActionName = $kv.Key
                Weight     = $kv.Value
            }
        }
    }

    Write-SimzLog -Message "Added user '$Username' (ID: $userId) with default action weights" -Component 'UserMgmt'
    Get-SimzUser -Username $Username
}
