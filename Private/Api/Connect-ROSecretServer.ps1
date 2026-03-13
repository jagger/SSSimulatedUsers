function Connect-ROSecretServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BaseUrl,

        [Parameter(Mandatory)]
        [string]$Username,

        [Parameter(Mandatory)]
        [string]$Password,

        [Parameter(Mandatory)]
        [string]$Domain
    )

    $tokenUrl = "$BaseUrl/oauth2/token"

    $body = @{
        grant_type = 'password'
        username   = $Username
        password   = $Password
        domain     = $Domain
    }

    Write-ROLog -Message "Authenticating '$Username' against $BaseUrl" -Level DEBUG -Component 'API'

    try {
        $response = Invoke-RestMethod -Uri $tokenUrl -Method POST -Body $body -ContentType 'application/x-www-form-urlencoded' -ErrorAction Stop

        $session = [PSCustomObject]@{
            Token    = $response.access_token
            BaseUrl  = $BaseUrl
            Username = $Username
            Expiry   = (Get-Date).AddSeconds($response.expires_in)
            SSUserId = $null
        }

        # Cache Secret Server user ID for checkin filtering
        try {
            $me = Invoke-RestMethod -Uri "$BaseUrl/api/v1/users/current" `
                -Headers @{ Authorization = "Bearer $($response.access_token)" } `
                -ContentType 'application/json'
            $session.SSUserId = $me.id
        }
        catch {
            Write-ROLog -Message "Could not fetch current user ID for '$Username': $_" -Level WARN -Component 'API'
        }

        Write-ROLog -Message "Authenticated '$Username' successfully (expires in $($response.expires_in)s)" -Component 'API'
        return $session
    }
    catch {
        Write-ROLog -Message "Authentication failed for '$Username': $_" -Level ERROR -Component 'API'
        throw
    }
}
