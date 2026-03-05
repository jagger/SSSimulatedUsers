function Invoke-SimzRunReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        # List available reports
        $reports = Invoke-SimzApi -Session $Session -Endpoint "reports?take=20"
        if (-not $reports.records -or $reports.records.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'RunReport'; TargetType = 'Report'; TargetId = $null
                TargetName = $null; Success = $false; ErrorMessage = 'No reports available'
            }
        }

        $report = $reports.records | Get-Random

        # Execute the report
        $body = @{ id = $report.id }
        $result = Invoke-SimzApi -Session $Session -Endpoint "reports/execute" -Method POST -Body $body

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
