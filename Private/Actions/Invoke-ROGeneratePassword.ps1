function Invoke-ROGeneratePassword {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        # Get available templates
        $templates = Invoke-ROApi -Session $Session -Endpoint "secret-templates?take=50"
        if (-not $templates.records -or $templates.records.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'GeneratePassword'; TargetType = 'Template'; TargetId = $null
                TargetName = $null; Success = $false; ErrorMessage = 'No templates available'
            }
        }

        $template = $templates.records | Get-Random

        # Get template details to find a password field slug
        $detail = Invoke-ROApi -Session $Session -Endpoint "secret-templates/$($template.id)"
        $passwordField = $detail.fields | Where-Object { $_.isPassword -eq $true } | Select-Object -First 1

        if (-not $passwordField) {
            return [PSCustomObject]@{
                Action = 'GeneratePassword'; TargetType = 'Template'; TargetId = $template.id
                TargetName = "$($template.name) (no password field)"; Success = $true; ErrorMessage = $null
            }
        }

        $slug = $passwordField.fieldSlugName
        Invoke-ROApi -Session $Session -Endpoint "secret-templates/$($template.id)/generate-password/$slug" | Out-Null

        [PSCustomObject]@{
            Action       = 'GeneratePassword'
            TargetType   = 'Template'
            TargetId     = $template.id
            TargetName   = "$($template.name) (password generated)"
            Success      = $true
            ErrorMessage = $null
        }
    }
    catch {
        [PSCustomObject]@{
            Action = 'GeneratePassword'; TargetType = 'Template'; TargetId = $null
            TargetName = $null; Success = $false; ErrorMessage = $_.Exception.Message
        }
    }
}
