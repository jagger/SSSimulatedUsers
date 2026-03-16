function Invoke-ROUserCycle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$User,

        [Parameter(Mandatory)]
        [string]$BaseUrl,

        [int]$MinActions = 0,

        [int]$MaxActions = 15
    )

    $username = $User.Username
    $userId = $User.UserId
    $results = @{ Actions = 0; Errors = 0 }

    Write-ROLog -Message "Starting cycle for '$username'" -Component 'Engine'

    # Authenticate - fetch password on-demand so user objects never carry it
    $session = $null
    $password = Invoke-ROQuery -Query "SELECT Password FROM ROUser WHERE UserId = @UserId" `
        -SqlParameters @{ UserId = $userId } -Scalar
    $password = Unprotect-ROPassword -EncryptedText $password
    try {
        $session = Connect-ROSecretServer -BaseUrl $BaseUrl -Username $username -Password $password -Domain $User.Domain
    }
    catch {
        $authError = $_.Exception.Message
        $authFailureAction = Get-ROConfig -Key 'AuthFailureAction'

        if ($authFailureAction -eq 'RotateAndAlert') {
            Write-ROLog -Message "Auth failed for '$username', attempting password rotation..." -Level WARN -Component 'Engine'
            Write-ROActionLog -UserId $userId -Username $username -ActionName 'Authenticate' -Result 'Failure' -ErrorMessage $authError

            $rotationCount = Invoke-ROPasswordRotation -Username $username

            if ($rotationCount -gt 0) {
                # Re-read updated password from SQLite
                $newPassword = Invoke-ROQuery -Query "SELECT Password FROM ROUser WHERE Username = @Username COLLATE NOCASE" `
                    -SqlParameters @{ Username = $username } -Scalar
                $newPassword = Unprotect-ROPassword -EncryptedText $newPassword

                try {
                    $session = Connect-ROSecretServer -BaseUrl $BaseUrl -Username $username -Password $newPassword -Domain $User.Domain
                    Write-ROLog -Message "Password rotated and auth recovered for '$username'" -Level WARN -Component 'Engine'
                }
                catch {
                    Write-ROLog -Message "AUTH ALERT: rotation did not fix auth for '$username': $($_.Exception.Message)" -Level ERROR -Component 'Engine'
                    $results.Errors++
                    return $results
                }
            }
            else {
                Write-ROLog -Message "AUTH ALERT: rotation failed for '$username', cannot retry" -Level ERROR -Component 'Engine'
                $results.Errors++
                return $results
            }
        }
        else {
            # AlertOnly (default) - log and skip
            Write-ROLog -Message "Auth failed for '$username', skipping cycle: $authError" -Level ERROR -Component 'Engine'
            Write-ROActionLog -UserId $userId -Username $username -ActionName 'Authenticate' -Result 'Failure' -ErrorMessage $authError
            $results.Errors++
            return $results
        }
    }

    # Select actions
    $actions = Select-ROUserActions -UserId $userId -MinActions $MinActions -MaxActions $MaxActions
    $registry = Get-ROActionRegistry

    foreach ($actionName in $actions) {
        $regEntry = $registry[$actionName]
        if (-not $regEntry) {
            Write-ROLog -Message "Unknown action '$actionName' for '$username'" -Level WARN -Component 'Engine'
            continue
        }

        $functionName = $regEntry.Function
        $sw = [System.Diagnostics.Stopwatch]::StartNew()

        try {
            $actionResult = & $functionName -Session $session
            $sw.Stop()

            $logParams = @{
                UserId     = $userId
                Username   = $username
                ActionName = $actionName
                TargetType = $actionResult.TargetType
                TargetId   = if ($actionResult.TargetId) { $actionResult.TargetId } else { 0 }
                TargetName = $actionResult.TargetName
                Result     = if ($actionResult.Success) { 'Success' } else { 'Failure' }
                DurationMs = $sw.ElapsedMilliseconds
            }

            if (-not $actionResult.Success) {
                $logParams['ErrorMessage'] = $actionResult.ErrorMessage
                $results.Errors++
            }

            Write-ROActionLog @logParams
            $results.Actions++
        }
        catch {
            $sw.Stop()
            Write-ROLog -Message "Action '$actionName' threw for '$username': $_" -Level ERROR -Component 'Engine'
            Write-ROActionLog -UserId $userId -Username $username -ActionName $actionName -Result 'Failure' -ErrorMessage $_.Exception.Message -DurationMs $sw.ElapsedMilliseconds
            $results.Actions++
            $results.Errors++
        }

        # Random delay between actions (1-5 seconds) to simulate human pace
        $delay = Get-Random -Minimum 1 -Maximum 6
        Start-Sleep -Seconds $delay
    }

    # Disconnect
    try {
        Disconnect-ROSecretServer -Session $session
    }
    catch {
        Write-ROLog -Message "Disconnect failed for '$username' (non-fatal)" -Level WARN -Component 'Engine'
    }

    Write-ROLog -Message "Completed cycle for '$username': $($results.Actions) actions, $($results.Errors) errors" -Component 'Engine'
    return $results
}
