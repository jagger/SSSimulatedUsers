function Invoke-ROListFolderSecrets {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        # Get available folders
        $folders = Invoke-ROApi -Session $Session -Endpoint "folders?take=50"
        if (-not $folders.records -or $folders.records.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'ListFolderSecrets'; TargetType = 'Folder'; TargetId = $null
                TargetName = $null; Success = $false; ErrorMessage = 'No folders available'
            }
        }

        $folder = $folders.records | Get-Random
        $secrets = Invoke-ROApi -Session $Session -Endpoint "secrets?filter.folderId=$($folder.id)&take=50"
        $count = if ($secrets.records) { $secrets.records.Count } else { 0 }

        [PSCustomObject]@{
            Action       = 'ListFolderSecrets'
            TargetType   = 'Folder'
            TargetId     = $folder.id
            TargetName   = "$($folder.folderName) ($count secrets)"
            Success      = $true
            ErrorMessage = $null
        }
    }
    catch {
        [PSCustomObject]@{
            Action = 'ListFolderSecrets'; TargetType = 'Folder'; TargetId = $null
            TargetName = $null; Success = $false; ErrorMessage = $_.Exception.Message
        }
    }
}
