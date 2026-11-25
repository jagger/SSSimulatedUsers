BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\..\RobOtters.psd1'
    Import-Module $modulePath -Force
}

Describe 'Set-ROUser' {
    BeforeAll {
        Mock -ModuleName RobOtters Write-ROLog {}
        Mock -ModuleName RobOtters Invoke-ROQuery {
            if ($Query -like 'SELECT * FROM ROUser*') {
                return [PSCustomObject]@{
                    UserId = 1; Username = 'svc.sim01'; Password = 'enc'
                    Domain = 'LAB'; ActiveHourStart = '07:00'; ActiveHourEnd = '17:00'; IsEnabled = 1
                }
            }
        }
        Mock -ModuleName RobOtters Get-ROUser { [PSCustomObject]@{ Username = 'svc.sim01'; IsEnabled = 1 } }
    }

    Context 'Updating active hours' {
        It 'Should update the database' {
            Set-ROUser -Username 'svc.sim01' -ActiveHourEnd '19:00'
            Should -Invoke -CommandName Invoke-ROQuery -ModuleName RobOtters -Times 1 -Scope It -ParameterFilter {
                $Query -like 'UPDATE ROUser SET*ActiveHourEnd*'
            }
        }
    }

    Context 'Enabling/disabling user' {
        It 'Should set IsEnabled' {
            Set-ROUser -Username 'svc.sim01' -IsEnabled $false
            Should -Invoke -CommandName Invoke-ROQuery -ModuleName RobOtters -Times 1 -Scope It -ParameterFilter {
                $Query -like 'UPDATE ROUser SET*IsEnabled*'
            }
        }
    }

    Context 'When user does not exist' {
        BeforeAll {
            Mock -ModuleName RobOtters Invoke-ROQuery { $null } -ParameterFilter { $Query -like 'SELECT * FROM ROUser*' }
        }

        It 'Should write an error' {
            Set-ROUser -Username 'ghost' -ActiveHourEnd '19:00' -ErrorAction SilentlyContinue
        }
    }

    Context 'With -RandomPassword' {
        BeforeAll {
            # ConvertTo-SecureString requires Microsoft.PowerShell.Security which has
            # TypeData conflicts on some environments. Skip if unavailable.
            $securityModuleOk = $true
            try {
                $null = ConvertTo-SecureString 'test' -AsPlainText -Force -ErrorAction Stop
            }
            catch {
                $securityModuleOk = $false
            }

            if ($securityModuleOk) {
                Mock -ModuleName RobOtters Invoke-ROQuery {
                    if ($Query -like 'SELECT * FROM ROUser*') {
                        return [PSCustomObject]@{
                            UserId = 1; Username = 'svc.sim01'; Password = 'enc'
                            Domain = 'LAB'; ActiveHourStart = '07:00'; ActiveHourEnd = '17:00'; IsEnabled = 1
                        }
                    }
                }
                Mock -ModuleName RobOtters New-ROPassword { 'RandomPw123!' }
                Mock -ModuleName RobOtters Protect-ROPassword { 'encrypted-new' }
                Mock -ModuleName RobOtters Set-ADAccountPassword {}
                Mock -ModuleName RobOtters Get-ROUser { [PSCustomObject]@{ Username = 'svc.sim01' } }
            }
        }

        It 'Should generate and set a random password' -Skip:(-not $securityModuleOk) {
            Set-ROUser -Username 'svc.sim01' -RandomPassword
            Should -Invoke -CommandName New-ROPassword -ModuleName RobOtters -Times 1 -Scope It
            Should -Invoke -CommandName Set-ADAccountPassword -ModuleName RobOtters -Times 1 -Scope It
        }
    }
}
