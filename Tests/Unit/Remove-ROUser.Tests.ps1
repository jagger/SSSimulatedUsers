BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\..\RobOtters.psd1'
    Import-Module $modulePath -Force
}

Describe 'Remove-ROUser' {
    BeforeAll {
        Mock -ModuleName RobOtters Write-ROLog {}
    }

    Context 'When user exists' {
        BeforeAll {
            Mock -ModuleName RobOtters Invoke-ROQuery {
                if ($Query -like 'SELECT UserId*') { return [PSCustomObject]@{ UserId = 1 } }
            }
        }

        It 'Should delete user and action weights' {
            Remove-ROUser -Username 'svc.sim01' -Confirm:$false
            Should -Invoke -CommandName Invoke-ROQuery -ModuleName RobOtters -Times 1 -Scope It -ParameterFilter { $Query -like 'DELETE FROM ActionWeight*' }
            Should -Invoke -CommandName Invoke-ROQuery -ModuleName RobOtters -Times 1 -Scope It -ParameterFilter { $Query -like 'DELETE FROM ROUser*' }
        }
    }

    Context 'When user does not exist' {
        BeforeAll {
            Mock -ModuleName RobOtters Invoke-ROQuery { $null } -ParameterFilter { $Query -like 'SELECT UserId*' }
        }

        It 'Should write an error' {
            Remove-ROUser -Username 'ghost' -ErrorAction SilentlyContinue -Confirm:$false
            Should -Invoke -CommandName Invoke-ROQuery -ModuleName RobOtters -Times 1 -Scope It
        }
    }
}
