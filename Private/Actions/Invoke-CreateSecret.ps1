function Invoke-CreateSecret {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        # Get available templates
        $templates = Invoke-SecretServerApi -Session $Session -Endpoint "secret-templates?take=20"
        if (-not $templates.records -or $templates.records.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'CreateSecret'; TargetType = 'Secret'; TargetId = $null
                TargetName = $null; Success = $false; ErrorMessage = 'No templates available'
            }
        }

        $template = $templates.records | Get-Random

        # Get a folder
        $folders = Invoke-SecretServerApi -Session $Session -Endpoint "folders?take=50"
        $folderId = -1
        if ($folders.records -and $folders.records.Count -gt 0) {
            $folderId = ($folders.records | Get-Random).id
        }

        # Generate a secret name
        $prefixes = @('svc', 'admin', 'app', 'db', 'web', 'api', 'backup', 'monitor')
        $suffixes = @('prod', 'dev', 'test', 'staging', 'lab', 'dr')
        $secretName = "sim-$(Get-Random -InputObject $prefixes)-$(Get-Random -InputObject $suffixes)-$(Get-Random -Minimum 1000 -Maximum 9999)"

        # Build items from template fields
        $templateDetail = Invoke-SecretServerApi -Session $Session -Endpoint "secret-templates/$($template.id)"
        $items = @()
        foreach ($field in $templateDetail.fields) {
            $value = switch -Wildcard ($field.name) {
                '*username*' { "simuser_$(Get-Random -Minimum 100 -Maximum 999)" }
                '*password*' { "P@ss$(Get-Random -Minimum 10000 -Maximum 99999)!" }
                '*url*'      { "https://server$(Get-Random -Minimum 1 -Maximum 50).lab.local" }
                '*server*'   { "server$(Get-Random -Minimum 1 -Maximum 50).lab.local" }
                '*notes*'    { "Created by TheSimz simulator" }
                default      { "simvalue_$(Get-Random -Minimum 100 -Maximum 999)" }
            }

            $items += @{
                fieldId           = $field.secretTemplateFieldId
                fieldName         = $field.name
                isFile            = $false
                itemValue         = $value
            }
        }

        $body = @{
            name               = $secretName
            secretTemplateId   = $template.id
            folderId           = $folderId
            siteId             = 1
            items              = $items
        }

        $result = Invoke-SecretServerApi -Session $Session -Endpoint 'secrets' -Method POST -Body $body

        [PSCustomObject]@{
            Action       = 'CreateSecret'
            TargetType   = 'Secret'
            TargetId     = $result.id
            TargetName   = "$secretName (template: $($template.name))"
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
