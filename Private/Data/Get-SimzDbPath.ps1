function Get-SimzDbPath {
    [CmdletBinding()]
    param()

    $dataDir = Join-Path $PSScriptRoot '..\..\Data'
    $dataDir = [System.IO.Path]::GetFullPath($dataDir)
    Join-Path $dataDir 'TheSimz.sqlite'
}
