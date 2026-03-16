function Get-ROActionLog {
    <#
    .SYNOPSIS
        Query the action history log
    .DESCRIPTION
        Retrieves action log entries from the ActionLog table. Supports filtering
        by username, action name, and date range. Results are ordered by
        timestamp descending.
    .PARAMETER Last
        Return only the N most recent entries.
    .PARAMETER Username
        Filter by username.
    .PARAMETER ActionName
        Filter by action name (e.g., ViewSecret, CreateSecret).
    .PARAMETER Since
        Return entries on or after this date/time.
    .PARAMETER Until
        Return entries on or before this date/time.
    .EXAMPLE
        Get-ROActionLog -Last 20
        Last 20 actions.
    .EXAMPLE
        Get-ROActionLog -Username 'svc.sim01' -Since (Get-Date).AddDays(-1)
    .EXAMPLE
        Get-ROActionLog -ActionName 'ViewSecret' -Last 50
    .OUTPUTS
        PSCustomObject[] - ActionLog records with LogId, Username, ActionName, TargetType, TargetId, TargetName, Success, ErrorMessage, Timestamp
    .LINK
        Docs/commands/Get-ROActionLog.md
    #>
    [CmdletBinding()]
    param(
        [int]$Last,

        [string]$Username,

        [string]$ActionName,

        [DateTime]$Since,

        [DateTime]$Until
    )

    $conditions = @()
    $params = @{}

    if ($Username) {
        $conditions += "Username = @Username COLLATE NOCASE"
        $params['Username'] = $Username
    }
    if ($ActionName) {
        $conditions += "ActionName = @ActionName"
        $params['ActionName'] = $ActionName
    }
    if ($Since) {
        $conditions += "Timestamp >= @Since"
        $params['Since'] = $Since.ToString('yyyy-MM-dd HH:mm:ss')
    }
    if ($Until) {
        $conditions += "Timestamp <= @Until"
        $params['Until'] = $Until.ToString('yyyy-MM-dd HH:mm:ss')
    }

    $where = if ($conditions.Count -gt 0) { "WHERE $($conditions -join ' AND ')" } else { '' }
    $limit = if ($Last -gt 0) { "LIMIT $Last" } else { '' }

    $query = "SELECT * FROM ActionLog $where ORDER BY Timestamp DESC $limit"

    if ($params.Count -gt 0) {
        Invoke-ROQuery -Query $query -SqlParameters $params
    }
    else {
        Invoke-ROQuery -Query $query
    }
}
