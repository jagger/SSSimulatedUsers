function Invoke-ROCreateSecret {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        # Query templates the user is actually allowed to create
        $templates = Invoke-ROApi -Session $Session -Endpoint "secret-templates-list?take=500"
        if (-not $templates.records -or $templates.records.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'CreateSecret'; TargetType = 'Secret'; TargetId = $null
                TargetName = $null; Success = $false; ErrorMessage = 'No secret templates available to this user'
            }
        }

        # Get a folder - prefer personal folder for write access
        $folders = Invoke-ROApi -Session $Session -Endpoint "folders?take=50"
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

        # Try up to 2 templates in case the first one has validation issues
        $templateCandidates = $templates.records | Get-Random -Count ([Math]::Min(2, $templates.records.Count))
        foreach ($template in $templateCandidates) {
            $templateId = $template.id

            try {
                # Get a secret stub from the API and set siteId (stub defaults to -1 which is rejected)
                $stub = Invoke-ROApi -Session $Session -Endpoint "secrets/stub?secretTemplateId=$templateId&folderId=$folderId"
                $stub.siteId = 1

                # Generate a secret name
                $prefixes = @('svc', 'admin', 'app', 'db', 'web', 'api', 'backup', 'monitor')
                $suffixes = @('prod', 'dev', 'test', 'staging', 'lab', 'dr')
                $secretName = "sim-$(Get-Random -InputObject $prefixes)-$(Get-Random -InputObject $suffixes)-$(Get-Random -Minimum 1000 -Maximum 9999)"
                $stub.name = $secretName

                # Fill in stub fields - only set fields that exist in the stub
                foreach ($item in $stub.items) {
                    if ($null -eq $item.slug) { continue }
                    $item.itemValue = switch ($item.slug) {
                        'resource'  { "server$(Get-Random -Minimum 1 -Maximum 50).lab.local" }
                        'url'       { "https://app$(Get-Random -Minimum 1 -Maximum 50).lab.local" }
                        'username'  { "simuser_$(Get-Random -Minimum 100 -Maximum 999)" }
                        'password'  { "P@ss$(Get-Random -Minimum 10000 -Maximum 99999)!" }
                        'notes'     { "Created by RobOtters simulator at $(Get-Date -Format 'yyyy-MM-dd HH:mm')" }
                        default     {
                            if ($item.isRequired) {
                                "simvalue_$(Get-Random -Minimum 100 -Maximum 999)"
                            }
                            else {
                                $item.itemValue
                            }
                        }
                    }
                }

                # Create the secret
                $result = Invoke-ROApi -Session $Session -Endpoint 'secrets' -Method POST -Body $stub

                return [PSCustomObject]@{
                    Action       = 'CreateSecret'
                    TargetType   = 'Secret'
                    TargetId     = $result.id
                    TargetName   = "$secretName (template: $($template.name))"
                    Success      = $true
                    ErrorMessage = $null
                }
            }
            catch {
                Write-ROLog -Message "CreateSecret: template '$($template.name)' failed, trying next: $_" -Level WARN -Component 'Actions'
                continue
            }
        }

        # All template attempts failed
        [PSCustomObject]@{
            Action       = 'CreateSecret'
            TargetType   = 'Secret'
            TargetId     = $null
            TargetName   = 'All template attempts failed'
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
