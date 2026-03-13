function Invoke-ROApi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Session,

        [Parameter(Mandatory)]
        [string]$Endpoint,

        [ValidateSet('GET', 'POST', 'PUT', 'DELETE', 'PATCH')]
        [string]$Method = 'GET',

        [object]$Body,

        [int]$MaxRetries = 2,

        [switch]$Paginate
    )

    $url = "$($Session.BaseUrl)/api/v1/$($Endpoint.TrimStart('/'))"
    $headers = @{
        Authorization = "Bearer $($Session.Token)"
    }

    $attempt = 0
    while ($true) {
        $attempt++
        try {
            $splat = @{
                Uri         = $url
                Method      = $Method
                Headers     = $headers
                ContentType = 'application/json'
                ErrorAction = 'Stop'
            }

            if ($Body) {
                if ($Body -is [string]) {
                    $splat['Body'] = $Body
                }
                else {
                    $splat['Body'] = $Body | ConvertTo-Json -Depth 10
                }
            }

            $response = Invoke-RestMethod @splat

            # Handle pagination if requested
            if ($Paginate -and $response.records) {
                $allRecords = [System.Collections.Generic.List[object]]::new()
                $allRecords.AddRange($response.records)

                while ($response.hasNext) {
                    $skip = $allRecords.Count
                    $pageUrl = if ($url -match '\?') { "$url&skip=$skip&take=100" } else { "$url`?skip=$skip&take=100" }
                    $splat['Uri'] = $pageUrl
                    $response = Invoke-RestMethod @splat
                    if ($response.records) {
                        $allRecords.AddRange($response.records)
                    }
                }

                return $allRecords
            }

            return $response
        }
        catch {
            $statusCode = $null
            if ($_.Exception.Response) {
                $statusCode = [int]$_.Exception.Response.StatusCode
            }

            # Retry on 429 (throttled) or 5xx (server error)
            if ($attempt -le $MaxRetries -and ($statusCode -eq 429 -or ($statusCode -ge 500 -and $statusCode -lt 600))) {
                $waitSec = $attempt * 2
                Write-ROLog -Message "API $Method $Endpoint returned $statusCode, retrying in ${waitSec}s (attempt $attempt/$MaxRetries)" -Level WARN -Component 'API'
                Start-Sleep -Seconds $waitSec
                continue
            }

            Write-ROLog -Message "API $Method $Endpoint failed: $_" -Level ERROR -Component 'API'
            throw
        }
    }
}
