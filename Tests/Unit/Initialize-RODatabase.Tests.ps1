BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\..\RobOtters.psd1'
    Import-Module $modulePath -Force
}

Describe 'Initialize-RODatabase' {
    BeforeAll {
        Mock -ModuleName RobOtters Get-RODbPath { 'TestDrive:\RobOtters.sqlite' }
        Mock -ModuleName RobOtters Get-RODataRoot { 'TestDrive:\' }
        Mock -ModuleName RobOtters Write-ROLog {}
        Mock -ModuleName RobOtters Invoke-ROQuery {}
        Mock -ModuleName RobOtters Invoke-Expression {}
    }

    Context 'When schema file exists' {
        BeforeAll {
            # Only return true for the schema path; false for seed weights to avoid Invoke-Expression issues
            Mock -ModuleName RobOtters Test-Path {
                if ($Path -like '*Schema.sql') { return $true }
                if ($Path -like '*SeedActionWeights*') { return $false }
                if ($Path -like '*RobOtters.sqlite') { return $false }
                return $false
            }
            Mock -ModuleName RobOtters Get-Content { "CREATE TABLE IF NOT EXISTS Config (Key TEXT PRIMARY KEY, Value TEXT);" }
        }

        It 'Should execute schema statements' {
            Initialize-RODatabase | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName Invoke-ROQuery -ModuleName RobOtters -Scope It -ParameterFilter {
                $Query -like '*CREATE TABLE*'
            }
        }

        It 'Should seed default config when empty' {
            Mock -ModuleName RobOtters Invoke-ROQuery {
                if ($Query -like 'SELECT COUNT*') { return 0 }
                if ($Query -like 'PRAGMA*') { return @() }
                if ($Query -like 'SELECT name FROM sqlite_master*') { return $null }
                if ($Query -like 'SELECT Value*') { return $null }
                if ($Query -like 'SELECT UserId*') { return $null }
            } -ParameterFilter { $Query -and $Query -notlike '*CREATE*' -and $Query -notlike '*INSERT INTO Config*' }

            Initialize-RODatabase | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When schema file is missing' {
        It 'Should throw an error' {
            Mock -ModuleName RobOtters Test-Path {
                if ($Path -like '*Schema.sql') { return $false }
                if ($Path -like '*RobOtters.sqlite') { return $false }
                return $false
            }
            { Initialize-RODatabase } | Should -Throw '*Schema file not found*'
        }
    }
}
