function Select-ROUserActions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$UserId,

        [int]$MinActions = 0,

        [int]$MaxActions = 15
    )

    # Get user's action weights (weight > 0 means enabled at user level)
    $weights = Invoke-ROQuery -Query "SELECT ActionName, Weight FROM ActionWeight WHERE UserId = @UserId AND Weight > 0" -SqlParameters @{ UserId = $UserId }

    if (-not $weights) {
        Write-ROLog -Message "No action weights found for UserId $UserId" -Level WARN -Component 'Engine'
        return @()
    }

    # Apply global disabled actions filter
    $disabledActions = Get-ROConfig -Key 'DisabledActions'
    if ($disabledActions) {
        $disabledList = $disabledActions -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        $weights = @($weights | Where-Object { $_.ActionName -notin $disabledList })
    }

    # Apply global disabled categories filter
    $disabledCategories = Get-ROConfig -Key 'DisabledCategories'
    if ($disabledCategories) {
        $disabledCatList = $disabledCategories -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        $registry = Get-ROActionRegistry
        $weights = @($weights | Where-Object {
            $entry = $registry[$_.ActionName]
            -not $entry -or $entry.Category -notin $disabledCatList
        })
    }

    if (-not $weights -or $weights.Count -eq 0) {
        Write-ROLog -Message "No eligible actions for UserId $UserId after global filters" -Level WARN -Component 'Engine'
        return @()
    }

    # Determine number of actions for this cycle
    $actionCount = Get-Random -Minimum $MinActions -Maximum ($MaxActions + 1)

    if ($actionCount -eq 0) {
        Write-ROLog -Message "UserId $UserId selected 0 actions this cycle (idle)" -Level DEBUG -Component 'Engine'
        return @()
    }

    # Build cumulative weight array for weighted random selection
    $totalWeight = ($weights | Measure-Object -Property Weight -Sum).Sum
    $selected = [System.Collections.Generic.List[string]]::new()

    for ($i = 0; $i -lt $actionCount; $i++) {
        $roll = Get-Random -Minimum 0 -Maximum $totalWeight
        $cumulative = 0

        foreach ($w in $weights) {
            $cumulative += $w.Weight
            if ($roll -lt $cumulative) {
                $selected.Add($w.ActionName)
                break
            }
        }
    }

    Write-ROLog -Message "UserId $UserId selected $actionCount actions: $($selected -join ', ')" -Level DEBUG -Component 'Engine'
    return $selected.ToArray()
}
