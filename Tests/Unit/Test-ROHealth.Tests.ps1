BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\..\RobOtters.psd1'
    Import-Module $modulePath -Force
}

Describe 'Test-ROHealth' {
    BeforeAll {
        Mock -ModuleName RobOtters Get-RODbPath { 'TestDrive:\RobOtters.sqlite' }
        Mock -ModuleName RobOtters Get-RODataRoot { 'TestDrive:\' }
        Mock -ModuleName RobOtters Write-ROLog {}
    }

    Context 'When all checks pass' {
        BeforeAll {
            Mock -ModuleName RobOtters Get-Module { [PSCustomObject]@{ Version = '1.7.0' } }
            Mock -ModuleName RobOtters Test-Path { $true }
            Mock -ModuleName RobOtters Get-ROConfig {
                switch ($Key) {
                    'SecretServerUrl' { 'https://ss.lab.local/SS' }
                    'DefaultDomain'   { 'MYLAB' }
                }
            }
            Mock -ModuleName RobOtters Invoke-RestMethod { [PSCustomObject]@{ version = '11.5' } }
            Mock -ModuleName RobOtters Invoke-ROQuery { 3 }
        }

        It 'Should return all-pass results' {
            $results = Test-ROHealth
            $overall = $results | Where-Object { $_.Check -eq 'Overall' }
            $overall.Passed | Should -Be $true
        }

        It 'Should return 7 check results' {
            $results = Test-ROHealth
            $results.Count | Should -Be 7
        }
    }

    Context 'When database is missing' {
        BeforeAll {
            Mock -ModuleName RobOtters Get-Module { [PSCustomObject]@{ Version = '1.7.0' } }
            Mock -ModuleName RobOtters Test-Path { $false }
        }

        It 'Should fail the Database File check' {
            $results = Test-ROHealth
            $dbCheck = $results | Where-Object { $_.Check -eq 'Database File' }
            $dbCheck.Passed | Should -Be $false
        }

        It 'Should have Overall as failed' {
            $results = Test-ROHealth
            $overall = $results | Where-Object { $_.Check -eq 'Overall' }
            $overall.Passed | Should -Be $false
        }
    }

    Context 'When PSSQLite is not installed' {
        BeforeAll {
            Mock -ModuleName RobOtters Get-Module { $null }
            Mock -ModuleName RobOtters Test-Path { $false }
        }

        It 'Should fail the PSSQLite check' {
            $results = Test-ROHealth
            $check = $results | Where-Object { $_.Check -eq 'PSSQLite Module' }
            $check.Passed | Should -Be $false
        }
    }

    Context 'When encryption key is invalid' {
        BeforeAll {
            $env:RO_ENCRYPT_KEY = 'not-valid-base64!!!'
            Mock -ModuleName RobOtters Get-Module { [PSCustomObject]@{ Version = '1.7.0' } }
            Mock -ModuleName RobOtters Test-Path { $true }
            Mock -ModuleName RobOtters Get-ROConfig { 'https://ss.lab.local/SS' }
            Mock -ModuleName RobOtters Invoke-RestMethod { [PSCustomObject]@{ version = '11.5' } }
            Mock -ModuleName RobOtters Invoke-ROQuery { 1 }
        }

        AfterAll {
            Remove-Item Env:\RO_ENCRYPT_KEY -ErrorAction SilentlyContinue
        }

        It 'Should fail the Encryption Key check' {
            $results = Test-ROHealth
            $check = $results | Where-Object { $_.Check -eq 'Encryption Key' }
            $check.Passed | Should -Be $false
        }
    }
}
