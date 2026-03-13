function Write-ROActionLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$UserId,

        [Parameter(Mandatory)]
        [string]$Username,

        [Parameter(Mandatory)]
        [string]$ActionName,

        [string]$TargetType,

        [int]$TargetId,

        [string]$TargetName,

        [Parameter(Mandatory)]
        [ValidateSet('Success', 'Failure', 'Skipped')]
        [string]$Result,

        [string]$ErrorMessage,

        [int]$DurationMs
    )

    $query = @"
INSERT INTO ActionLog (UserId, Username, ActionName, TargetType, TargetId, TargetName, Result, ErrorMessage, DurationMs)
VALUES (@UserId, @Username, @ActionName, @TargetType, @TargetId, @TargetName, @Result, @ErrorMessage, @DurationMs)
"@

    $params = @{
        UserId       = $UserId
        Username     = $Username
        ActionName   = $ActionName
        TargetType   = $TargetType
        TargetId     = $TargetId
        TargetName   = $TargetName
        Result       = $Result
        ErrorMessage = $ErrorMessage
        DurationMs   = $DurationMs
    }

    Invoke-ROQuery -Query $query -SqlParameters $params
}
