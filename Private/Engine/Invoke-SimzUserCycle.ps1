function Invoke-SimzUserCycle {
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

    Write-SimzLog -Message "Starting cycle for '$username'" -Component 'Engine'

    # Authenticate
    $session = $null
    try {
        $session = Connect-SimzSecretServer -BaseUrl $BaseUrl -Username $username -Password $User.Password -Domain $User.Domain
    }
    catch {
        Write-SimzLog -Message "Auth failed for '$username', skipping cycle: $_" -Level ERROR -Component 'Engine'
        Write-SimzActionLog -UserId $userId -Username $username -ActionName 'Authenticate' -Result 'Failure' -ErrorMessage $_.Exception.Message
        $results.Errors++
        return $results
    }

    # Select actions
    $actions = Select-SimzUserActions -UserId $userId -MinActions $MinActions -MaxActions $MaxActions
    $registry = Get-SimzActionRegistry

    foreach ($actionName in $actions) {
        $regEntry = $registry[$actionName]
        if (-not $regEntry) {
            Write-SimzLog -Message "Unknown action '$actionName' for '$username'" -Level WARN -Component 'Engine'
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

            Write-SimzActionLog @logParams
            $results.Actions++
        }
        catch {
            $sw.Stop()
            Write-SimzLog -Message "Action '$actionName' threw for '$username': $_" -Level ERROR -Component 'Engine'
            Write-SimzActionLog -UserId $userId -Username $username -ActionName $actionName -Result 'Failure' -ErrorMessage $_.Exception.Message -DurationMs $sw.ElapsedMilliseconds
            $results.Actions++
            $results.Errors++
        }

        # Random delay between actions (1-5 seconds) to simulate human pace
        $delay = Get-Random -Minimum 1 -Maximum 6
        Start-Sleep -Seconds $delay
    }

    # Disconnect
    try {
        Disconnect-SimzSecretServer -Session $session
    }
    catch {
        Write-SimzLog -Message "Disconnect failed for '$username' (non-fatal)" -Level WARN -Component 'Engine'
    }

    Write-SimzLog -Message "Completed cycle for '$username': $($results.Actions) actions, $($results.Errors) errors" -Component 'Engine'
    return $results
}
