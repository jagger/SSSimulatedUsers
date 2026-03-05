function Invoke-CreateSecret {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        # Use Password (2) or Web Password (9) templates
        $templateId = Get-Random -InputObject @(2, 9)

        # Get a folder — prefer personal folder for write access
        $folders = Invoke-SecretServerApi -Session $Session -Endpoint "folders?take=50"
        $folderId = -1

        if ($folders.records -and $folders.records.Count -gt 0) {
            $personalFolder = $folders.records | Where-Object {
                $_.folderPath -match '\\Personal Folders\\'
            } | Get-Random

            if ($personalFolder) {
                $folderId = $personalFolder.id
            }
            else {
                $folderId = ($folders.records | Get-Random).id
            }
        }

        # Get a secret stub from the API and set siteId (stub defaults to -1 which is rejected)
        $stub = Invoke-SecretServerApi -Session $Session -Endpoint "secrets/stub?secretTemplateId=$templateId&folderId=$folderId"
        $stub.siteId = 1

        # Generate a secret name
        $prefixes = @('svc', 'admin', 'app', 'db', 'web', 'api', 'backup', 'monitor')
        $suffixes = @('prod', 'dev', 'test', 'staging', 'lab', 'dr')
        $secretName = "sim-$(Get-Random -InputObject $prefixes)-$(Get-Random -InputObject $suffixes)-$(Get-Random -Minimum 1000 -Maximum 9999)"
        $stub.name = $secretName

        # Fill in the stub fields
        foreach ($item in $stub.items) {
            $item.itemValue = switch ($item.slug) {
                'resource'  { "server$(Get-Random -Minimum 1 -Maximum 50).lab.local" }
                'url'       { "https://app$(Get-Random -Minimum 1 -Maximum 50).lab.local" }
                'username'  { "simuser_$(Get-Random -Minimum 100 -Maximum 999)" }
                'password'  { "P@ss$(Get-Random -Minimum 10000 -Maximum 99999)!" }
                'notes'     { "Created by TheSimz simulator at $(Get-Date -Format 'yyyy-MM-dd HH:mm')" }
                default     { "simvalue_$(Get-Random -Minimum 100 -Maximum 999)" }
            }
        }

        # Create the secret
        $result = Invoke-SecretServerApi -Session $Session -Endpoint 'secrets' -Method POST -Body $stub

        [PSCustomObject]@{
            Action       = 'CreateSecret'
            TargetType   = 'Secret'
            TargetId     = $result.id
            TargetName   = "$secretName (template: $($stub.secretTemplateName))"
            Success      = $true
            ErrorMessage = $null
        }
    }
    catch {
        [PSCustomObject]@{
            Action = 'CreateSecret'; TargetType = 'Secret'; TargetId = $null
            TargetName = $null; Success = $false; ErrorMessage = $_.Exception.Message
        }
    }
}
