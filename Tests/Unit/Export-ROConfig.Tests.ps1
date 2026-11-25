BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\..\RobOtters.psd1'
    Import-Module $modulePath -Force
}

Describe 'Export-ROConfig' {
    BeforeAll {
        Mock -ModuleName RobOtters Write-ROLog {}
        Mock -ModuleName RobOtters Invoke-ROQuery {
            if ($Query -like 'SELECT Key, Value*') {
                return @(
                    [PSCustomObject]@{ Key = 'SecretServerUrl'; Value = 'https://ss.lab.local/SS' }
                    [PSCustomObject]@{ Key = 'MinActionsPerCycle'; Value = '0' }
                )
            }
            if ($Query -like 'SELECT * FROM ROUser*') {
                return @([PSCustomObject]@{
                    UserId = 1; Username = 'svc.sim01'; Password = 'encrypted'
                    Domain = 'LAB'; ActiveHourStart = '07:00'; ActiveHourEnd = '17:00'; IsEnabled = 1
                })
            }
            if ($Query -like 'SELECT ActionName*') {
                return @([PSCustomObject]@{ ActionName = 'ViewSecret'; Weight = 30 })
            }
        }
    }

    It 'Should write JSON to the specified path' {
        $outPath = Join-Path $TestDrive 'export.json'
        Export-ROConfig -Path $outPath
        $outPath | Should -Exist
    }

    It 'Should exclude passwords by default' {
        $outPath = Join-Path $TestDrive 'export-nopw.json'
        Export-ROConfig -Path $outPath
        $json = Get-Content $outPath -Raw | ConvertFrom-Json
        $json.Users[0].Password | Should -BeNullOrEmpty
    }

    Context 'With -IncludePasswords' {
        BeforeAll {
            Mock -ModuleName RobOtters Unprotect-ROPassword { 'plaintext-pw' }
        }

        It 'Should include decrypted passwords' {
            $outPath = Join-Path $TestDrive 'export-pw.json'
            Export-ROConfig -Path $outPath -IncludePasswords
            $json = Get-Content $outPath -Raw | ConvertFrom-Json
            $json.Users[0].Password | Should -Be 'plaintext-pw'
        }
    }
}
