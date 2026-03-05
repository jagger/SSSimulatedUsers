function Get-SimzLogPath {
    [CmdletBinding()]
    param()

    $logDir = Join-Path $PSScriptRoot '..\..\Logs'
    $logDir = [System.IO.Path]::GetFullPath($logDir)

    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    $date = Get-Date -Format 'yyyy-MM-dd'
    Join-Path $logDir "TheSimz_$date.log"
}
