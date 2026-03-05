function Invoke-SimzCreateFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        # Get folders, preferring user's personal folder for write access
        $folders = Invoke-SimzApi -Session $Session -Endpoint "folders?take=50"
        $parentId = -1
        $parentName = 'Root'

        if ($folders.records -and $folders.records.Count -gt 0) {
            # Try to find a personal folder first (typically named after user or under Personal Folders)
            $personalFolder = $folders.records | Where-Object {
                $_.folderPath -match '\\Personal Folders\\'
            } | Get-Random

            if ($personalFolder) {
                $parentId = $personalFolder.id
                $parentName = $personalFolder.folderName
            }
            else {
                return [PSCustomObject]@{
                    Action = 'CreateFolder'; TargetType = 'Folder'; TargetId = $null
                    TargetName = 'No personal folder found'; Success = $true; ErrorMessage = $null
                }
            }
        }

        $adjectives = @('Test', 'Lab', 'Dev', 'Staging', 'Temp', 'Shared', 'Team', 'Project')
        $nouns = @('Servers', 'Services', 'Accounts', 'Credentials', 'Keys', 'Certs', 'Access', 'Resources')
        $folderName = "$(Get-Random -InputObject $adjectives)-$(Get-Random -InputObject $nouns)-$(Get-Random -Minimum 100 -Maximum 999)"

        $body = @{
            folderName     = $folderName
            folderTypeId   = 1
            parentFolderId = $parentId
            inheritPermissions = $true
            inheritSecretPolicy = $true
        }

        $result = Invoke-SimzApi -Session $Session -Endpoint 'folders' -Method POST -Body $body

        [PSCustomObject]@{
            Action       = 'CreateFolder'
            TargetType   = 'Folder'
            TargetId     = $result.id
            TargetName   = "$folderName (in $parentName)"
            Success      = $true
            ErrorMessage = $null
        }
    }
    catch {
        [PSCustomObject]@{
            Action = 'CreateFolder'; TargetType = 'Folder'; TargetId = $null
            TargetName = $null; Success = $false; ErrorMessage = $_.Exception.Message
        }
    }
}
