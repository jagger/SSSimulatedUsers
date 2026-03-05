function Invoke-SimzQuery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Query,

        [hashtable]$SqlParameters,

        [switch]$Scalar
    )

    $dbPath = Get-SimzDbPath

    $splat = @{
        DataSource = $dbPath
        Query      = $Query
    }

    if ($SqlParameters) {
        $splat['SqlParameters'] = $SqlParameters
    }

    $result = Invoke-SqliteQuery @splat

    if ($Scalar) {
        if ($null -ne $result) {
            $props = $result | Get-Member -MemberType NoteProperty | Select-Object -First 1
            if ($props) {
                return $result.($props.Name)
            }
        }
        return $null
    }

    $result
}
