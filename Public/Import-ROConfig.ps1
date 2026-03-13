function Import-ROConfig {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [switch]$ConfigOnly,

        [switch]$UsersOnly
    )

    if (-not (Test-Path $Path)) {
        Write-Error "File not found: $Path"
        return
    }

    $data = Get-Content -Path $Path -Raw | ConvertFrom-Json

    # Import Config
    if (-not $UsersOnly -and $data.Config) {
        $configHash = @{}
        $data.Config.PSObject.Properties | ForEach-Object { $configHash[$_.Name] = $_.Value }

        foreach ($kv in $configHash.GetEnumerator()) {
            if ($PSCmdlet.ShouldProcess("Config key '$($kv.Key)'", "Set to '$($kv.Value)'")) {
                Set-ROConfig -Key $kv.Key -Value $kv.Value
                Write-ROLog -Message "Imported config key '$($kv.Key)'" -Component 'Config'
            }
        }
    }

    # Import Users
    if (-not $ConfigOnly -and $data.Users) {
        foreach ($u in $data.Users) {
            $username = $u.Username

            if ($PSCmdlet.ShouldProcess("User '$username'", 'Import/update')) {
                $existing = Get-ROUser -Username $username 2>$null

                if ($existing) {
                    # Update existing user
                    $splatSet = @{ Username = $username }
                    if ($u.Domain)          { $splatSet['Domain'] = $u.Domain }
                    if ($u.ActiveHourStart) { $splatSet['ActiveHourStart'] = $u.ActiveHourStart }
                    if ($u.ActiveHourEnd)   { $splatSet['ActiveHourEnd'] = $u.ActiveHourEnd }
                    if ($null -ne $u.IsEnabled) { $splatSet['IsEnabled'] = [bool]$u.IsEnabled }

                    if ($u.Password) {
                        $splatSet['Password'] = $u.Password
                    }

                    Set-ROUser @splatSet

                    # Rotate password if not provided
                    if (-not $u.Password) {
                        Invoke-ROPasswordRotation -Username $username
                        Write-ROLog -Message "Rotated password for existing user '$username' (no password in import)" -Component 'Config'
                    }
                }
                else {
                    # New user
                    $password = $u.Password
                    if (-not $password) {
                        $password = New-ROPassword
                        $newSecure = ConvertTo-SecureString $password -AsPlainText -Force
                        $splatAD = @{
                            Identity    = $username
                            Reset       = $true
                            NewPassword = $newSecure
                            ErrorAction = 'Stop'
                        }
                        try {
                            Set-ADAccountPassword @splatAD
                            Write-ROLog -Message "Set AD password for new user '$username'" -Component 'Config'
                        }
                        catch {
                            Write-Error "Failed to set AD password for new user '$username': $_"
                            continue
                        }
                    }

                    $splatAdd = @{
                        Username = $username
                        Password = $password
                        Domain   = $u.Domain
                    }
                    if ($u.ActiveHourStart) { $splatAdd['ActiveHourStart'] = $u.ActiveHourStart }
                    if ($u.ActiveHourEnd)   { $splatAdd['ActiveHourEnd'] = $u.ActiveHourEnd }

                    Add-ROUser @splatAdd
                    Write-ROLog -Message "Added new user '$username' from import" -Component 'Config'
                }

                # Update action weights if present
                if ($u.ActionWeights) {
                    $weightHash = @{}
                    $u.ActionWeights.PSObject.Properties | ForEach-Object { $weightHash[$_.Name] = [int]$_.Value }
                    Set-ROUser -Username $username -ActionWeights $weightHash
                }
            }
        }
    }

    Write-ROLog -Message "Import from '$Path' complete" -Component 'Config'
    Write-Output "Import from $Path complete."
}
