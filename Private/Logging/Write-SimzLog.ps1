function Write-SimzLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG')]
        [string]$Level = 'INFO',

        [string]$Component = 'General'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $logLine = "[$timestamp] [$Level] [$Component] $Message"

    $logPath = Get-SimzLogPath

    try {
        Add-Content -Path $logPath -Value $logLine -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed to write log: $_"
    }

    if ($Level -eq 'ERROR') {
        Write-Verbose $logLine
    }
    elseif ($Level -eq 'DEBUG') {
        Write-Debug $logLine
    }
    else {
        Write-Verbose $logLine
    }
}
