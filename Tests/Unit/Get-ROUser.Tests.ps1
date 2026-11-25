BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\..\RobOtters.psd1'
    Import-Module $modulePath -Force
}

Describe 'Get-ROUser' {
    BeforeAll {
        Mock -ModuleName RobOtters Invoke-ROQuery {
            @([PSCustomObject]@{
                UserId          = 1
                Username        = 'svc.sim01'
                Password        = 'encrypted-data'
                Domain          = 'LAB'
                ActiveHourStart = '07:00'
                ActiveHourEnd   = '17:00'
                IsEnabled       = 1
            })
        }
        Mock -ModuleName RobOtters Unprotect-ROPassword { 'plaintext-pw' }
    }

    Context 'Without -ShowPassword' {
        It 'Should mask passwords' {
            $result = Get-ROUser
            $result.Password | Should -Be '********'
        }
    }

    Context 'With -ShowPassword' {
        It 'Should decrypt and show passwords' {
            $result = Get-ROUser -ShowPassword
            $result.Password | Should -Be 'plaintext-pw'
        }
    }

    Context 'With -Username filter' {
        It 'Should query by username' {
            Get-ROUser -Username 'svc.sim01'
            Should -Invoke -CommandName Invoke-ROQuery -ModuleName RobOtters -Times 1 -Scope It -ParameterFilter {
                $Query -like '*WHERE Username*' -and $SqlParameters.Username -eq 'svc.sim01'
            }
        }
    }

    Context 'With -IncludeWeights' {
        BeforeAll {
            Mock -ModuleName RobOtters Invoke-ROQuery {
                if ($Query -like 'SELECT ActionName*') {
                    return @([PSCustomObject]@{ ActionName = 'ViewSecret'; Weight = 30 })
                }
                return @([PSCustomObject]@{
                    UserId = 1; Username = 'svc.sim01'; Password = 'enc'; Domain = 'LAB'
                    ActiveHourStart = '07:00'; ActiveHourEnd = '17:00'; IsEnabled = 1
                })
            }
        }

        It 'Should attach action weights' {
            $result = Get-ROUser -IncludeWeights
            $result.ActionWeights | Should -Not -BeNullOrEmpty
        }
    }
}
