function New-ROCycleLock {
    [CmdletBinding()]
    param()

    $lockPath = Join-Path (Get-RODataRoot) 'RobOtters.lock'

    if (Test-Path $lockPath) {
        $lockContent = Get-Content -Path $lockPath -Raw
        $lockPid = ($lockContent -split "`n" | Select-Object -First 1).Trim()

        # Check if the PID is still running
        $process = $null
        try { $process = Get-Process -Id ([int]$lockPid) -ErrorAction SilentlyContinue } catch {}

        if ($process) {
            throw "Cycle already running (PID $lockPid, lock file: $lockPath). If this is stale, delete the lock file manually."
        }
        else {
            Write-ROLog -Message "Stale lock file found (PID $lockPid no longer running), overwriting" -Level WARN -Component 'Engine'
        }
    }

    $pid = $PID
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Set-Content -Path $lockPath -Value "$pid`n$timestamp" -Force

    Write-ROLog -Message "Acquired cycle lock (PID $pid)" -Level DEBUG -Component 'Engine'
    $lockPath
}
