function Remove-ROCycleLock {
    [CmdletBinding()]
    param()

    $lockPath = Join-Path (Get-RODataRoot) 'RobOtters.lock'

    if (Test-Path $lockPath) {
        Remove-Item -Path $lockPath -Force
        Write-ROLog -Message 'Released cycle lock' -Level DEBUG -Component 'Engine'
    }
}
