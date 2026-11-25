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

        Beyond MaxDepth the node is replaced outright rather than returned. This
        matters: ConvertTo-Json renders anything past its own -Depth by calling
        ToString(), which for a PSCustomObject emits "@{password=secret}" with
        values intact. The walker's limit must therefore stay below the
        serializer's, and must fail closed when it is reached.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        $Node,

        [Parameter(Mandatory)]
        [string]$Pattern,

        [int]$Depth = 0,

        [int]$MaxDepth = 10
    )

    if ($null -eq $Node) { return $null }

    if ($Depth -ge $MaxDepth) { return '[redacted: too deep]' }

    if ($Node -is [string] -or $Node -is [datetime] -or $Node.GetType().IsPrimitive) {
        return $Node
    }

    if ($Node -is [System.Collections.IEnumerable]) {
        # Unary comma keeps a single-element array an array, so the logged shape
        # still matches what the API actually returned.
        return , @(foreach ($item in $Node) {
            Convert-ROLogNode -Node $item -Pattern $Pattern -Depth ($Depth + 1) -MaxDepth $MaxDepth
        })
    }

    if ($Node.PSObject -and $Node.PSObject.Properties) {
        $out = [ordered]@{}
        foreach ($prop in $Node.PSObject.Properties) {
            if ($prop.Name -match $Pattern) {
                $out[$prop.Name] = '[redacted]'
            }
            else {
                $out[$prop.Name] = Convert-ROLogNode -Node $prop.Value -Pattern $Pattern -Depth ($Depth + 1) -MaxDepth $MaxDepth
            }
        }
        return [PSCustomObject]$out
    }

    # Unknown shape: do not guess at it.
    '[redacted: unrecognised node]'
}

function Get-ROSafeLogBody {
    <#
    .SYNOPSIS
        Render an API response body safe to write to the log file
    .DESCRIPTION
        Secret Server error bodies can echo secret field values. Write-ROLog
        persists DEBUG lines to disk, so anything returned here lands in a file
        other accounts can read.

        The body is parsed as JSON and every property whose name looks sensitive
        is redacted regardless of value type, then re-serialised. Anything that
        is not a structured object - an unparseable body, a bare string, a
        number, or an array of bare scalars - is suppressed rather than logged,
        because there are no key names to reason about and the whole value could
        be a token.

        Known limitation: this redacts by key name. A secret embedded in the free
        text of a descriptive field (for example a "message" that quotes a
        credential) is not detected. Whitelisting the few keys worth logging
        would close that, at the cost of the diagnostic detail this logging
        exists to provide.
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

    if ($null -eq $parsed) { return $null }

    # A bare scalar, or an array of bare scalars, carries no key names to judge
    # it by - the value itself could be the secret. Suppress it.
    $isScalar = {
        param($v)
        $null -eq $v -or $v -is [string] -or $v -is [datetime] -or $v.GetType().IsPrimitive
    }
    if (& $isScalar $parsed) {
        return "[scalar body suppressed, $($Body.Length) chars]"
    }
    if ($parsed -is [System.Collections.IEnumerable] -and $parsed -isnot [string]) {
        $items = @($parsed)
        if ($items.Count -gt 0) {
            $allScalar = $true
            foreach ($item in $items) { if (-not (& $isScalar $item)) { $allScalar = $false; break } }
            if ($allScalar) { return "[scalar body suppressed, $($Body.Length) chars]" }
        }
    }

    try {
        # Walker depth (10) stays below the serializer depth (12) so nothing can
        # reach ConvertTo-Json's ToString() fallback unredacted.
        $safe = Convert-ROLogNode -Node $parsed -Pattern $pattern -MaxDepth 10 |
            ConvertTo-Json -Depth 12 -Compress
    }
    catch {
        return '[body suppressed: could not be safely redacted]'
    }

    if ($safe.Length -gt $MaxLength) {
        $safe = $safe.Substring(0, $MaxLength) + '...[truncated]'
    }

    $safe
}
