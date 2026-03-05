function Select-SimzUserActions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$UserId,

        [int]$MinActions = 0,

        [int]$MaxActions = 15
    )

    # Get user's action weights
    $weights = Invoke-SimzQuery -Query "SELECT ActionName, Weight FROM ActionWeight WHERE UserId = @UserId AND Weight > 0" -SqlParameters @{ UserId = $UserId }

    if (-not $weights) {
        Write-SimzLog -Message "No action weights found for UserId $UserId" -Level WARN -Component 'Engine'
        return @()
    }

    # Determine number of actions for this cycle
    $actionCount = Get-Random -Minimum $MinActions -Maximum ($MaxActions + 1)

    if ($actionCount -eq 0) {
        Write-SimzLog -Message "UserId $UserId selected 0 actions this cycle (idle)" -Level DEBUG -Component 'Engine'
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

    Write-SimzLog -Message "UserId $UserId selected $actionCount actions: $($selected -join ', ')" -Level DEBUG -Component 'Engine'
    return $selected.ToArray()
}
