function Update-SimzUserAccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$User
    )

    $baseUrl = Get-SimzConfig -Key 'SecretServerUrl'
    if (-not $baseUrl) {
        throw "SecretServerUrl not configured."
    }

    Write-SimzLog -Message "Refreshing access snapshot for '$($User.Username)'" -Component 'Access'

    # Authenticate as the specific user so API results reflect their permissions
    $session = Connect-SimzSecretServer -BaseUrl $baseUrl -Username $User.Username -Password $User.Password -Domain $User.Domain

    try {
        # Count folders visible to this user (take=1 to minimize payload; .total has the full count)
        $folders = Invoke-SimzApi -Session $session -Endpoint "folders?take=1"
        $folderCount = if ($folders.total) { $folders.total } else { 0 }

        # Count secrets visible to this user (take=1 to minimize payload; .total has the full count)
        $secrets = Invoke-SimzApi -Session $session -Endpoint "secrets?take=1"
        $secretCount = if ($secrets.total) { $secrets.total } else { 0 }

        # Get template names visible to this user (basic-user-accessible endpoint)
        $templates = Invoke-SimzApi -Session $session -Endpoint "secret-templates-list?take=500"
        $templateNames = ''
        $templateCount = if ($templates.records) { $templates.records.Count } else { 0 }
        if ($templates.records) {
            $templateNames = ($templates.records | Sort-Object -Property name | ForEach-Object { $_.name }) -join ', '
        }

        # Upsert into UserAccess
        $splat = @{
            Query         = @"
INSERT INTO UserAccess (UserId, Username, FolderCount, SecretCount, TemplateCount, TemplateNames, CheckedAt)
VALUES (@UserId, @Username, @FolderCount, @SecretCount, @TemplateCount, @TemplateNames, datetime('now'))
ON CONFLICT(UserId) DO UPDATE SET
    Username      = @Username,
    FolderCount   = @FolderCount,
    SecretCount   = @SecretCount,
    TemplateCount = @TemplateCount,
    TemplateNames = @TemplateNames,
    CheckedAt     = datetime('now')
"@
            SqlParameters = @{
                UserId        = $User.UserId
                Username      = $User.Username
                FolderCount   = $folderCount
                SecretCount   = $secretCount
                TemplateCount = $templateCount
                TemplateNames = $templateNames
            }
        }
        Invoke-SimzQuery @splat

        Write-SimzLog -Message "Access snapshot for '$($User.Username)': $folderCount folders, $secretCount secrets, $templateCount templates" -Component 'Access'
    }
    finally {
        Disconnect-SimzSecretServer -Session $session
    }
}
