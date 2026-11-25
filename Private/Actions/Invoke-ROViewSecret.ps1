function Invoke-ROViewSecret {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        # Find a secret to view by searching
        $response = Invoke-ROApi -Session $Session -Endpoint "secrets?take=50"
        if (-not $response.records -or $response.records.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'ViewSecret'; TargetType = 'Secret'; TargetId = $null
                TargetName = $null; Success = $false; ErrorMessage = 'No secrets available'
            }
        }

        # Try up to 3 random secrets in case some require checkout/comment to view
        $candidates = $response.records | Get-Random -Count ([Math]::Min(3, $response.records.Count))
        foreach ($secret in $candidates) {
            try {
                $detail = Invoke-ROApi -Session $Session -Endpoint "secrets/$($secret.id)"

                return [PSCustomObject]@{
                    Action       = 'ViewSecret'
                    TargetType   = 'Secret'
                    TargetId     = $detail.id
                    TargetName   = $detail.name
                    Success      = $true
                    ErrorMessage = $null
                }
            }
            catch {
                Write-ROLog -Message "ViewSecret: cannot access secret $($secret.id), trying next: $_" -Level WARN -Component 'Actions'
                continue
            }
        }

        # All candidates inaccessible - the search itself generated audit activity
        [PSCustomObject]@{
            Action       = 'ViewSecret'
            TargetType   = 'Secret'
            TargetId     = $null
            TargetName   = 'All candidates inaccessible (checkout/comment required)'
            Success      = $true
            ErrorMessage = $null
        }
    }
    catch {
        [PSCustomObject]@{
            Action = 'ViewSecret'; TargetType = 'Secret'; TargetId = $null
            TargetName = $null; Success = $false; ErrorMessage = $_.Exception.Message
        }
    }
}
