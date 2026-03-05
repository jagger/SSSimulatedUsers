function Invoke-BrowseFolders {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        $folders = Invoke-SecretServerApi -Session $Session -Endpoint "folders?take=100"
        if (-not $folders.records -or $folders.records.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'BrowseFolders'; TargetType = 'Folder'; TargetId = $null
                TargetName = $null; Success = $false; ErrorMessage = 'No folders available'
            }
        }

        # Pick a random folder and browse its children
        $folder = $folders.records | Get-Random
        $children = Invoke-SecretServerApi -Session $Session -Endpoint "folders?filter.parentFolderId=$($folder.id)&take=50"
        $childCount = if ($children.records) { $children.records.Count } else { 0 }

        [PSCustomObject]@{
            Action       = 'BrowseFolders'
            TargetType   = 'Folder'
            TargetId     = $folder.id
            TargetName   = "$($folder.folderName) ($childCount children)"
            Success      = $true
            ErrorMessage = $null
        }
    }
    catch {
        [PSCustomObject]@{
            Action = 'BrowseFolders'; TargetType = 'Folder'; TargetId = $null
            TargetName = $null; Success = $false; ErrorMessage = $_.Exception.Message
        }
    }
}
