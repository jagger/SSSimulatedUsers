function Invoke-RORunReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        # List available reports
        $reports = Invoke-ROApi -Session $Session -Endpoint "reports?take=20"
        if (-not $reports.records -or $reports.records.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'RunReport'; TargetType = 'Report'; TargetId = $null
                TargetName = 'No reports available (searched)'; Success = $true; ErrorMessage = $null
            }
        }

        $report = $reports.records | Get-Random

        # Execute the report
        $body = @{ id = $report.id }
        try {
            $result = Invoke-ROApi -Session $Session -Endpoint "reports/execute" -Method POST -Body $body
        }
        catch {
            Write-ROLog -Message "RunReport: execution of '$($report.name)' failed (permission or parameter issue): $_" -Level WARN -Component 'Actions'
            return [PSCustomObject]@{
                Action       = 'RunReport'
                TargetType   = 'Report'
                TargetId     = $report.id
                TargetName   = "$($report.name) (execution denied)"
                Success      = $true
                ErrorMessage = $null
            }
        }

        [PSCustomObject]@{
            Action       = 'RunReport'
            TargetType   = 'Report'
            TargetId     = $report.id
            TargetName   = $report.name
            Success      = $true
            ErrorMessage = $null
        }
    }
    catch {
        [PSCustomObject]@{
            Action = 'RunReport'; TargetType = 'Report'; TargetId = $null
            TargetName = $null; Success = $false; ErrorMessage = $_.Exception.Message
        }
    }
}
