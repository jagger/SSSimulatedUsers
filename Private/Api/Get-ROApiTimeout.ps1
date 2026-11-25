function Get-ROApiTimeout {
    <#
    .SYNOPSIS
        Resolve the HTTP timeout (seconds) for Secret Server REST calls
    .DESCRIPTION
        Reads the ApiTimeoutSeconds config key, falling back to 60 seconds when
        the key is missing, non-numeric, or non-positive. Without a timeout a
        single unresponsive request can stall an entire cycle until Task
        Scheduler kills the process. The resolved value is cached for the life
        of the module (each cycle runs in a fresh process, so config changes
        still take effect on the next cycle).
    .OUTPUTS
        Int32 timeout in seconds.
    #>
    [CmdletBinding()]
    param()

    if ($script:ROApiTimeoutCache) {
        return $script:ROApiTimeoutCache
    }

    $timeout = 0
    $configured = Get-ROConfig -Key 'ApiTimeoutSeconds'
    if ($configured) {
        [int]$parsed = 0
        if ([int]::TryParse([string]$configured, [ref]$parsed)) {
            $timeout = $parsed
        }
        else {
            Write-ROLog -Message "ApiTimeoutSeconds value '$configured' is not numeric - using 60s" -Level WARN -Component 'API'
        }
    }

    if ($timeout -le 0) { $timeout = 60 }

    $script:ROApiTimeoutCache = $timeout
    $timeout
}
