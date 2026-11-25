BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\..\RobOtters.psd1'
    Import-Module $modulePath -Force
}

Describe 'Get-ROActionLog' {
    BeforeAll {
        Mock -ModuleName RobOtters Invoke-ROQuery {
            @(
                [PSCustomObject]@{ LogId = 1; Username = 'svc.sim01'; ActionName = 'ViewSecret'; Result = 'Success' }
                [PSCustomObject]@{ LogId = 2; Username = 'svc.sim02'; ActionName = 'CreateSecret'; Result = 'Success' }
            )
        }
    }

    It 'Should return all log entries when no filters' {
        $result = Get-ROActionLog
        $result.Count | Should -Be 2
    }

    Context 'With -Last parameter' {
        It 'Should include LIMIT in query' {
            Get-ROActionLog -Last 10
            Should -Invoke -CommandName Invoke-ROQuery -ModuleName RobOtters -Times 1 -Scope It -ParameterFilter {
                $Query -like '*LIMIT 10*'
            }
        }
    }

    Context 'With -Username filter' {
        It 'Should filter by username' {
            Get-ROActionLog -Username 'svc.sim01'
            Should -Invoke -CommandName Invoke-ROQuery -ModuleName RobOtters -Times 1 -Scope It -ParameterFilter {
                $Query -like '*WHERE*Username*' -and $SqlParameters.Username -eq 'svc.sim01'
            }
        }
    }

    Context 'With -Since and -Until' {
        It 'Should filter by date range' {
            Get-ROActionLog -Since ([datetime]'2026-01-01') -Until ([datetime]'2026-12-31')
            Should -Invoke -CommandName Invoke-ROQuery -ModuleName RobOtters -Times 1 -Scope It -ParameterFilter {
                $Query -like '*Timestamp >= @Since*' -and $Query -like '*Timestamp <= @Until*'
            }
        }
    }
}
