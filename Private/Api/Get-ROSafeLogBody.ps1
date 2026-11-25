function Convert-ROLogNode {
    <#
    .SYNOPSIS
        Recursively redact sensitive leaves from a parsed JSON node
    .DESCRIPTION
        Internal helper for Get-ROSafeLogBody. Walks arrays and objects and
        replaces the value of any property whose NAME looks sensitive, whatever
        the value's type. Matching on the key rather than the value is what makes
        this robust against numbers, arrays and nested objects, which a regex
        over raw text silently misses.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        $Node,

        [Parameter(Mandatory)]
        [string]$Pattern,

        [int]$Depth = 0
    )

    if ($null -eq $Node -or $Depth -gt 20) { return $Node }

    if ($Node -is [string] -or $Node.GetType().IsPrimitive -or $Node -is [datetime]) {
        return $Node
    }

    if ($Node -is [System.Collections.IEnumerable]) {
        # Unary comma keeps a single-element array an array, so the logged shape
        # still matches what the API actually returned.
        return , @(foreach ($item in $Node) { Convert-ROLogNode -Node $item -Pattern $Pattern -Depth ($Depth + 1) })
    }

    if ($Node.PSObject -and $Node.PSObject.Properties) {
        $out = [ordered]@{}
        foreach ($prop in $Node.PSObject.Properties) {
            if ($prop.Name -match $Pattern) {
                $out[$prop.Name] = '[redacted]'
            }
            else {
                $out[$prop.Name] = Convert-ROLogNode -Node $prop.Value -Pattern $Pattern -Depth ($Depth + 1)
            }
        }
        return [PSCustomObject]$out
    }

    $Node
}

function Get-ROSafeLogBody {
    <#
    .SYNOPSIS
        Render an API response body safe to write to the log file
    .DESCRIPTION
        Secret Server error bodies can echo secret field values. Write-ROLog
        persists DEBUG lines to disk, so anything returned here lands in a file
        that is readable by BUILTIN\Users.

        The body is parsed as JSON and every property whose name looks sensitive
        is redacted regardless of value type, then re-serialised. If the body
        cannot be parsed we cannot reason about its structure, so it is
        suppressed entirely rather than scrubbed with a regex that may not match
        the same thing the real parser would - failing closed, not open.
    .PARAMETER Body
        Raw response body.
    .PARAMETER MaxLength
        Truncate the redacted result to this many characters.
    .OUTPUTS
        String safe for logging, or $null when there is nothing to log.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Body,

        [int]$MaxLength = 512
    )

    if ([string]::IsNullOrWhiteSpace($Body)) { return $null }

    # Key-name patterns. Deliberately broad: a false redaction costs a little
    # diagnostic detail, a missed one writes a credential to disk.
    $pattern = '(?i)(password|passphrase|secret|token|credential|privatekey|apikey|itemvalue|^key$|^value$)'

    try {
        $parsed = $Body | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        return "[non-JSON body suppressed, $($Body.Length) chars]"
    }

    try {
        $safe = Convert-ROLogNode -Node $parsed -Pattern $pattern | ConvertTo-Json -Depth 12 -Compress
    }
    catch {
        return "[body suppressed: could not be safely redacted]"
    }

    if ($safe.Length -gt $MaxLength) {
        $safe = $safe.Substring(0, $MaxLength) + '...[truncated]'
    }

    $safe
}
