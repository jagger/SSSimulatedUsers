function Invoke-ROLogCleanup {
    [CmdletBinding()]
    param()

    $retentionDays = Get-ROConfig -Key 'LogRetentionDays'
    if (-not $retentionDays) { $retentionDays = 30 }
    $retentionDays = [int]$retentionDays

    $logDir = Join-Path (Get-RODataRoot) 'Logs'
    if (-not (Test-Path $logDir)) { return }

    $cutoff = (Get-Date).AddDays(-$retentionDays)
    $oldFiles = Get-ChildItem -Path $logDir -Filter '*.log' | Where-Object { $_.LastWriteTime -lt $cutoff }

    if ($oldFiles) {
        $count = @($oldFiles).Count
        $oldFiles | Remove-Item -Force
        Write-ROLog -Message "Log cleanup: removed $count file(s) older than $retentionDays days" -Component 'Logging'
    }
}
