function Get-RODataRoot {
    [CmdletBinding()]
    param()

    if ($env:RO_DATA_PATH) {
        $root = $env:RO_DATA_PATH
    } else {
        $root = Join-Path $env:ProgramData 'RobOtters'
    }

    if (-not (Test-Path $root)) {
        New-Item -Path $root -ItemType Directory -Force | Out-Null
    }

    $root
}
