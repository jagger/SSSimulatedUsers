function Test-ROActiveHours {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ActiveHourStart,

        [Parameter(Mandatory)]
        [string]$ActiveHourEnd,

        [DateTime]$ReferenceTime = (Get-Date)
    )

    $now = $ReferenceTime.TimeOfDay
    $start = [TimeSpan]::Parse($ActiveHourStart)
    $end = [TimeSpan]::Parse($ActiveHourEnd)

    if ($start -le $end) {
        # Normal range (e.g., 07:00 - 17:00)
        return ($now -ge $start -and $now -lt $end)
    }
    else {
        # Midnight wraparound (e.g., 22:00 - 06:00)
        return ($now -ge $start -or $now -lt $end)
    }
}
