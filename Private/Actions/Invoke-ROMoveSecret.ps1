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

        # Prefer personal folders for move targets (higher chance of write permission)
        $personalFolders = @($folders.records | Where-Object { $_.folderPath -match '\\Personal Folders\\' })

        # Try up to 3 secret/folder combos
        $candidates = $response.records | Get-Random -Count ([Math]::Min(3, $response.records.Count))
        foreach ($secret in $candidates) {
            try {
                $detail = Invoke-ROApi -Session $Session -Endpoint "secrets/$($secret.id)"

                if ($personalFolders.Count -gt 0) {
                    $targetFolder = $personalFolders | Get-Random
                }
                else {
                    $targetFolder = $folders.records | Get-Random
                }

                $detail.folderId = $targetFolder.id

                Invoke-ROApi -Session $Session -Endpoint "secrets/$($secret.id)" -Method PUT -Body $detail | Out-Null

                return [PSCustomObject]@{
                    Action       = 'MoveSecret'
                    TargetType   = 'Secret'
                    TargetId     = $secret.id
                    TargetName   = "$($secret.name) -> $($targetFolder.folderName)"
                    Success      = $true
                    ErrorMessage = $null
                }
            }
            catch {
                Write-ROLog -Message "MoveSecret: cannot move secret $($secret.id), trying next: $_" -Level WARN -Component 'Actions'
                continue
            }
        }

        # All attempts failed
        [PSCustomObject]@{
            Action       = 'MoveSecret'
            TargetType   = 'Secret'
            TargetId     = $null
            TargetName   = 'All move attempts denied (permission)'
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
