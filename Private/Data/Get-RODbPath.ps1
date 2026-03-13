function Get-RODbPath {
    [CmdletBinding()]
    param()

    $dataDir = Get-RODataRoot
    Join-Path $dataDir 'RobOtters.sqlite'
}
