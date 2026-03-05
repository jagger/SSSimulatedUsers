function Invoke-ChangePassword {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        $response = Invoke-SecretServerApi -Session $Session -Endpoint "secrets?take=50"
        if (-not $response.records -or $response.records.Count -eq 0) {
            return [PSCustomObject]@{
                Action = 'ChangePassword'; TargetType = 'Secret'; TargetId = $null
                TargetName = $null; Success = $false; ErrorMessage = 'No secrets available'
            }
        }

        # Check a few random secrets for RPC eligibility
        $candidates = $response.records | Get-Random -Count ([Math]::Min(10, $response.records.Count))
        $target = $null

        foreach ($s in $candidates) {
            $detail = Invoke-SecretServerApi -Session $Session -Endpoint "secrets/$($s.id)"
            if ($detail.autoChangeEnabled) {
                $target = $s
                break
            }
        }

        if (-not $target) {
            $target = $response.records | Get-Random
        }

        try {
            Invoke-SecretServerApi -Session $Session -Endpoint "secrets/$($target.id)/change-password" -Method POST -Body @{ secretId = $target.id } | Out-Null
        }
        catch {
            # Password change requires elevated SS role permission
            # The attempt itself generates audit activity, so treat as success
            Write-SimzLog -Message "ChangePassword on '$($target.name)' denied (expected if user lacks Force Password Change permission)" -Level WARN -Component 'Actions'
        }

        [PSCustomObject]@{
            Action       = 'ChangePassword'
            TargetType   = 'Secret'
            TargetId     = $target.id
            TargetName   = "$($target.name) (password change attempted)"
            Success      = $true
            ErrorMessage = $null
        }
    }
    catch {
        [PSCustomObject]@{
            Action = 'ChangePassword'; TargetType = 'Secret'; TargetId = $null
            TargetName = $null; Success = $false; ErrorMessage = $_.Exception.Message
        }
    }
}
