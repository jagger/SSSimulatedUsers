function Invoke-ViewSecretPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session
    )

    try {
        $policies = Invoke-SecretServerApi -Session $Session -Endpoint "secret-policy/search?take=20"

        $policyCount = 0
        $policyName = 'N/A'

        if ($policies.records -and $policies.records.Count -gt 0) {
            $policyCount = $policies.records.Count
            $policy = $policies.records | Get-Random
            $policyName = $policy.secretPolicyName

            # View detail
            Invoke-SecretServerApi -Session $Session -Endpoint "secret-policy/search?filter.secretPolicyName=$($policy.secretPolicyName)" | Out-Null
        }

        [PSCustomObject]@{
            Action       = 'ViewSecretPolicy'
            TargetType   = 'Policy'
            TargetId     = $null
            TargetName   = "$policyName ($policyCount policies)"
            Success      = $true
            ErrorMessage = $null
        }
    }
    catch {
        [PSCustomObject]@{
            Action = 'ViewSecretPolicy'; TargetType = 'Policy'; TargetId = $null
            TargetName = $null; Success = $false; ErrorMessage = $_.Exception.Message
        }
    }
}
