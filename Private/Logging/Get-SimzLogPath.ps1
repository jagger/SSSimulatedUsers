function Get-SimzLogPath {
    [CmdletBinding()]
    param()

    $logDir = Join-Path $PSScriptRoot '..\..\Logs'
    $logDir = [System.IO.Path]::GetFullPath($logDir)

    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    $date = Get-Date -Format 'yyyy-MM-dd'
    $logFile = Join-Path $logDir "TheSimz_$date.log"

    # Create today's log file if it doesn't exist and grant shared write access
    # so multiple accounts (scheduled task + interactive) can both append to it
    if (-not (Test-Path $logFile)) {
        New-Item -Path $logFile -ItemType File -Force | Out-Null
        icacls $logFile /grant 'Users:M' /Q 2>$null | Out-Null
    }

    $logFile
}
