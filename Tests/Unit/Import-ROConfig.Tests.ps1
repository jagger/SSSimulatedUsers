BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\..\RobOtters.psd1'
    Import-Module $modulePath -Force
}

Describe 'Import-ROConfig' {
    BeforeAll {
        Mock -ModuleName RobOtters Write-ROLog {}
        Mock -ModuleName RobOtters Set-ROConfig {}
        Mock -ModuleName RobOtters Get-ROUser { $null }
        Mock -ModuleName RobOtters Add-ROUser {}
        Mock -ModuleName RobOtters Set-ROUser {}
    }

    Context 'With valid import file' {
        BeforeAll {
            $importData = [PSCustomObject]@{
                ExportedAt = '2026-03-16 12:00:00'
                Config = [PSCustomObject]@{
                    SecretServerUrl    = 'https://ss.lab.local/SS'
                    MinActionsPerCycle = '2'
                }
                Users = @()
            }
            $importPath = Join-Path $TestDrive 'import.json'
            $importData | ConvertTo-Json -Depth 3 | Set-Content $importPath
        }

        It 'Should import config keys' {
            Import-ROConfig -Path $importPath -ConfigOnly -Confirm:$false
            Should -Invoke -CommandName Set-ROConfig -ModuleName RobOtters -Times 2 -Scope It
        }
    }

    Context 'When file does not exist' {
        It 'Should write an error' {
            Import-ROConfig -Path 'C:\nonexistent.json' -ErrorAction SilentlyContinue -Confirm:$false
        }
    }

    Context 'With users in import' {
        BeforeAll {
            $importData = [PSCustomObject]@{
                ExportedAt = '2026-03-16 12:00:00'
                Config = [PSCustomObject]@{}
                Users = @(
                    [PSCustomObject]@{
                        Username = 'svc.sim01'; Password = 'P@ss'; Domain = 'LAB'
                        ActiveHourStart = '07:00'; ActiveHourEnd = '17:00'; IsEnabled = 1
                        ActionWeights = [PSCustomObject]@{}
                    }
                )
            }
            $importPath = Join-Path $TestDrive 'import-users.json'
            $importData | ConvertTo-Json -Depth 3 | Set-Content $importPath
        }

        It 'Should add new users' {
            Import-ROConfig -Path $importPath -UsersOnly -Confirm:$false
            Should -Invoke -CommandName Add-ROUser -ModuleName RobOtters -Times 1 -Scope It
        }
    }
}
