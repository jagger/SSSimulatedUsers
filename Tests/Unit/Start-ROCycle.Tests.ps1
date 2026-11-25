BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\..\RobOtters.psd1'
    Import-Module $modulePath -Force
}

Describe 'Start-ROCycle' {
    BeforeAll {
        Mock -ModuleName RobOtters Write-ROLog {}
        Mock -ModuleName RobOtters New-ROCycleLock { 'TestDrive:\RobOtters.lock' }
        Mock -ModuleName RobOtters Remove-ROCycleLock {}
        Mock -ModuleName RobOtters Invoke-ROLogCleanup {}
        Mock -ModuleName RobOtters Invoke-ROQuery {}
        Mock -ModuleName RobOtters Get-ROConfig {
            switch ($Key) {
                'SecretServerUrl'    { 'https://ss.lab.local/SS' }
                'MinActionsPerCycle' { '0' }
                'MaxActionsPerCycle' { '5' }
            }
        }
    }

    Context 'Full cycle with no active users' {
        BeforeAll {
            Mock -ModuleName RobOtters Get-ROActiveUsers { @() }
            Mock -ModuleName RobOtters Invoke-ROPasswordRotation { 0 }
            Mock -ModuleName RobOtters Invoke-ROQuery {
                if ($Query -like 'SELECT COUNT*') { return 0 }
            }
        }

        It 'Should log warning and return early' {
            Start-ROCycle
            Should -Invoke -CommandName Write-ROLog -ModuleName RobOtters -Times 1 -Scope It -ParameterFilter {
                $Message -like '*No active users*'
            }
        }
    }

    Context 'Lock file prevents overlapping runs' {
        BeforeAll {
            Mock -ModuleName RobOtters New-ROCycleLock { throw 'Cycle already running' }
        }

        It 'Should write error when lock cannot be acquired' {
            Start-ROCycle -ErrorAction SilentlyContinue 2>$null
            Should -Invoke -CommandName New-ROCycleLock -ModuleName RobOtters -Times 1 -Scope It
        }
    }

    Context 'Single-user mode' {
        BeforeAll {
            Mock -ModuleName RobOtters New-ROCycleLock { 'TestDrive:\RobOtters.lock' }
            Mock -ModuleName RobOtters Get-ROUser {
                [PSCustomObject]@{
                    UserId = 1; Username = 'svc.sim01'; Password = 'decrypted'
                    Domain = 'LAB'; ActiveHourStart = '00:00'; ActiveHourEnd = '23:59'; IsEnabled = 1
                }
            }
            Mock -ModuleName RobOtters Test-ROActiveHours { $true }
            Mock -ModuleName RobOtters Invoke-ROUserCycle { @{ Actions = 3; Errors = 0 } }
        }

        It 'Should run for the specified user and return summary' {
            $result = Start-ROCycle -User 'svc.sim01'
            $result.TotalActions | Should -Be 3
            $result.Errors | Should -Be 0
        }
    }

    Context 'Log cleanup runs after cycle' {
        BeforeAll {
            Mock -ModuleName RobOtters New-ROCycleLock { 'TestDrive:\RobOtters.lock' }
            Mock -ModuleName RobOtters Get-ROUser {
                [PSCustomObject]@{
                    UserId = 1; Username = 'svc.sim01'; Password = 'pw'
                    Domain = 'LAB'; ActiveHourStart = '00:00'; ActiveHourEnd = '23:59'; IsEnabled = 1
                }
            }
            Mock -ModuleName RobOtters Test-ROActiveHours { $true }
            Mock -ModuleName RobOtters Invoke-ROUserCycle { @{ Actions = 1; Errors = 0 } }
        }

        It 'Should invoke log cleanup' {
            Start-ROCycle -User 'svc.sim01'
            Should -Invoke -CommandName Invoke-ROLogCleanup -ModuleName RobOtters -Times 1 -Scope It
        }
    }

    Context 'Lock is always released' {
        BeforeAll {
            Mock -ModuleName RobOtters New-ROCycleLock { 'TestDrive:\RobOtters.lock' }
            Mock -ModuleName RobOtters Get-ROConfig { throw 'config error' } -ParameterFilter { $Key -eq 'SecretServerUrl' }
        }

        It 'Should release lock even on error' {
            { Start-ROCycle } | Should -Throw
            Should -Invoke -CommandName Remove-ROCycleLock -ModuleName RobOtters -Times 1 -Scope It
        }
    }
}
