function Get-ROActionLog {
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
        $conditions += "Username = @Username"
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
