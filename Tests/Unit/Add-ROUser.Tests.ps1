BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\..\RobOtters.psd1'
    Import-Module $modulePath -Force
}

Describe 'Add-ROUser' {
    BeforeAll {
        Mock -ModuleName RobOtters Write-ROLog {}
        Mock -ModuleName RobOtters Protect-ROPassword { 'encrypted-pw' }
        Mock -ModuleName RobOtters Get-ADUser { [PSCustomObject]@{ SamAccountName = 'svc.sim01' } }
    }

    Context 'When adding a new user' {
        BeforeAll {
            Mock -ModuleName RobOtters Invoke-ROQuery {
                if ($Query -like 'SELECT UserId FROM ROUser WHERE Username*' -and $SqlParameters.Username -eq 'svc.sim01' -and $Query -notlike '*INSERT*') { return $null }
                if ($Query -like 'INSERT INTO ROUser*') { return $null }
                if ($Query -like 'SELECT UserId FROM ROUser WHERE Username*') { return 42 }
                if ($Query -like 'INSERT*ActionWeight*') { return $null }
            }
            Mock -ModuleName RobOtters Get-ROUser { [PSCustomObject]@{ Username = 'svc.sim01'; UserId = 42; Domain = 'LAB' } }
            Mock -ModuleName RobOtters Test-Path { $false } -ParameterFilter { $Path -like '*SeedActionWeights*' }
        }

        It 'Should validate AD account exists' {
            Add-ROUser -Username 'svc.sim01' -Password 'P@ss' -Domain 'LAB'
            Should -Invoke -CommandName Get-ADUser -ModuleName RobOtters -Times 1 -Scope It
        }

        It 'Should encrypt the password before storage' {
            Add-ROUser -Username 'svc.sim01' -Password 'P@ss' -Domain 'LAB'
            Should -Invoke -CommandName Protect-ROPassword -ModuleName RobOtters -Times 1 -Scope It
        }

        It 'Should return the new user object' {
            $result = Add-ROUser -Username 'svc.sim01' -Password 'P@ss' -Domain 'LAB'
            $result.Username | Should -Be 'svc.sim01'
        }
    }

    Context 'When AD account does not exist' {
        BeforeAll {
            Mock -ModuleName RobOtters Get-ADUser { throw 'not found' }
        }

        It 'Should write an error and return nothing' {
            $result = Add-ROUser -Username 'baduser' -Password 'P@ss' -Domain 'LAB' -ErrorAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When user already exists' {
        BeforeAll {
            Mock -ModuleName RobOtters Get-ADUser { [PSCustomObject]@{ SamAccountName = 'svc.sim01' } }
            Mock -ModuleName RobOtters Invoke-ROQuery { [PSCustomObject]@{ UserId = 1 } } -ParameterFilter { $Query -like 'SELECT UserId FROM ROUser*' }
        }

        It 'Should write an error for duplicate user' {
            $result = Add-ROUser -Username 'svc.sim01' -Password 'P@ss' -Domain 'LAB' -ErrorAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }
    }
}
