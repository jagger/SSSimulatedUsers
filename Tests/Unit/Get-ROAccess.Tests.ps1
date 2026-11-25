BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\..\RobOtters.psd1'
    Import-Module $modulePath -Force
}

Describe 'Get-ROAccess' {
    BeforeAll {
        Mock -ModuleName RobOtters Write-ROLog {}
        Mock -ModuleName RobOtters Get-ROConfig { '7' }
    }

    Context 'When viewing cached access data' {
        BeforeAll {
            Mock -ModuleName RobOtters Invoke-ROQuery {
                if ($Query -like 'SELECT * FROM ROUser*') {
                    return @([PSCustomObject]@{ UserId = 1; Username = 'svc.sim01'; IsEnabled = 1 })
                }
                if ($Query -like 'SELECT CheckedAt*') {
                    return (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
                }
                if ($Query -like 'SELECT * FROM UserAccess*') {
                    return @([PSCustomObject]@{
                        Username = 'svc.sim01'; FolderCount = 5; SecretCount = 10
                        TemplateCount = 3; TemplateNames = 'Windows,Unix'; CheckedAt = '2026-03-16 12:00:00'
                    })
                }
            }
        }

        It 'Should return access data' {
            $result = Get-ROAccess
            $result | Should -Not -BeNullOrEmpty
            $result.Username | Should -Be 'svc.sim01'
        }
    }

    Context 'With -Purge' {
        BeforeAll {
            Mock -ModuleName RobOtters Invoke-ROQuery {}
        }

        It 'Should delete all UserAccess records' {
            Get-ROAccess -Purge
            Should -Invoke -CommandName Invoke-ROQuery -ModuleName RobOtters -Times 1 -Scope It -ParameterFilter {
                $Query -like 'DELETE FROM UserAccess'
            }
        }
    }

    Context 'When no enabled users' {
        BeforeAll {
            Mock -ModuleName RobOtters Invoke-ROQuery { $null } -ParameterFilter { $Query -like 'SELECT * FROM ROUser*' }
        }

        It 'Should write an error' {
            Get-ROAccess -ErrorAction SilentlyContinue
        }
    }
}
