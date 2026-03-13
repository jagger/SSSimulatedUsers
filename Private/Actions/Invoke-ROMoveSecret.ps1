function Invoke-ROMoveSecret {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        $response = Invoke-ROApi -Session $Session -Endpoint "secrets?take=50"
        if (-not $response.records -or $response.records.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'MoveSecret'; TargetType = 'Secret'; TargetId = $null
                TargetName = $null; Success = $false; ErrorMessage = 'No secrets available'
            }
        }

        $folders = Invoke-ROApi -Session $Session -Endpoint "folders?take=50"
        if (-not $folders.records -or $folders.records.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'MoveSecret'; TargetType = 'Secret'; TargetId = $null
                TargetName = $null; Success = $false; ErrorMessage = 'No folders available'
            }
        }

        $secret = $response.records | Get-Random
        $targetFolder = $folders.records | Get-Random

        # Get full secret detail, change folderId, PUT back
        $detail = Invoke-ROApi -Session $Session -Endpoint "secrets/$($secret.id)"
        $detail.folderId = $targetFolder.id

        Invoke-ROApi -Session $Session -Endpoint "secrets/$($secret.id)" -Method PUT -Body $detail | Out-Null

        [PSCustomObject]@{
            Action       = 'MoveSecret'
            TargetType   = 'Secret'
            TargetId     = $secret.id
            TargetName   = "$($secret.name) -> $($targetFolder.folderName)"
            Success      = $true
            ErrorMessage = $null
        }
    }
    catch {
        [PSCustomObject]@{
            Action = 'MoveSecret'; TargetType = 'Secret'; TargetId = $null
            TargetName = $null; Success = $false; ErrorMessage = $_.Exception.Message
        }
    }
}
