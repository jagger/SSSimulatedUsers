BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\..\RobOtters.psd1'
    Import-Module $modulePath -Force
}

Describe 'Get-ROConfig' {
    BeforeAll {
        Mock -ModuleName RobOtters Invoke-ROQuery {
            if ($Query -like '*WHERE Key*') {
                return 'https://ss.lab.local/SecretServer'
            }
            return @(
                [PSCustomObject]@{ Key = 'SecretServerUrl'; Value = 'https://ss.lab.local/SecretServer' }
                [PSCustomObject]@{ Key = 'MinActionsPerCycle'; Value = '0' }
            )
        }
    }

    Context 'With -Key parameter' {
        It 'Should return a single value' {
            $result = Get-ROConfig -Key 'SecretServerUrl'
            $result | Should -Be 'https://ss.lab.local/SecretServer'
        }

        It 'Should query with the correct parameter' {
            Get-ROConfig -Key 'SecretServerUrl'
            Should -Invoke -CommandName Invoke-ROQuery -ModuleName RobOtters -ParameterFilter {
                $SqlParameters.Key -eq 'SecretServerUrl'
            }
        }
    }

    Context 'Without -Key parameter' {
        It 'Should return all config entries' {
            $result = Get-ROConfig
            $result.Count | Should -Be 2
        }
    }
}
