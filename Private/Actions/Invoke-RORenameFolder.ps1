function Invoke-RORenameFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        $folders = Invoke-ROApi -Session $Session -Endpoint "folders?take=100"
        if (-not $folders.records -or $folders.records.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'RenameFolder'; TargetType = 'Folder'; TargetId = $null
                TargetName = $null; Success = $false; ErrorMessage = 'No folders available'
            }
        }

        # Prefer personal folders where the user has write access
        $candidates = $folders.records | Where-Object {
            $_.folderPath -match '\\Personal Folders\\'
        }
        if (-not $candidates -or $candidates.Count -eq 0) {
            $candidates = $folders.records
        }

        $folder = $candidates | Get-Random
        $originalName = $folder.folderName

        # Rename: append -renamed
        $renameBody = @{
            folderName = "$originalName-renamed"
            folderTypeId = $folder.folderTypeId
            parentFolderId = $folder.parentFolderId
            inheritPermissions = $folder.inheritPermissions
            inheritSecretPolicy = $folder.inheritSecretPolicy
        }
        Invoke-ROApi -Session $Session -Endpoint "folders/$($folder.id)" -Method PUT -Body $renameBody | Out-Null

        # Restore original name
        try {
            $restoreBody = @{
                folderName = $originalName
                folderTypeId = $folder.folderTypeId
                parentFolderId = $folder.parentFolderId
                inheritPermissions = $folder.inheritPermissions
                inheritSecretPolicy = $folder.inheritSecretPolicy
            }
            Invoke-ROApi -Session $Session -Endpoint "folders/$($folder.id)" -Method PUT -Body $restoreBody | Out-Null
        }
        catch {
            Write-ROLog -Message "RenameFolder: failed to restore original name for folder $($folder.id): $_" -Level WARN -Component 'Actions'
        }

        [PSCustomObject]@{
            Action       = 'RenameFolder'
            TargetType   = 'Folder'
            TargetId     = $folder.id
            TargetName   = "$originalName (renamed and restored)"
            Success      = $true
            ErrorMessage = $null
        }
    }
    catch {
        [PSCustomObject]@{
            Action = 'RenameFolder'; TargetType = 'Folder'; TargetId = $null
            TargetName = $null; Success = $false; ErrorMessage = $_.Exception.Message
        }
    }
}
