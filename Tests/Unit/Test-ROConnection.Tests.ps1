BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\..\RobOtters.psd1'
    Import-Module $modulePath -Force
}

Describe 'Test-ROConnection' {
    BeforeAll {
        Mock -ModuleName RobOtters Write-ROLog {}
    }

    Context 'When connection succeeds' {
        BeforeAll {
            Mock -ModuleName RobOtters Get-ROUser {
                [PSCustomObject]@{ Username = 'svc.sim01'; Password = 'pw'; Domain = 'LAB' }
            }
            Mock -ModuleName RobOtters Get-ROConfig { 'https://ss.lab.local/SS' }
            Mock -ModuleName RobOtters Connect-ROSecretServer {
                [PSCustomObject]@{ Token = 'tok'; BaseUrl = 'https://ss.lab.local/SS'; Username = 'svc.sim01'; Expiry = (Get-Date).AddHours(1) }
            }
            Mock -ModuleName RobOtters Disconnect-ROSecretServer {}
        }

        It 'Should return Success status' {
            $result = Test-ROConnection -Username 'svc.sim01'
            $result.Status | Should -Be 'Success'
        }
    }

    Context 'When connection fails' {
        BeforeAll {
            Mock -ModuleName RobOtters Get-ROUser {
                [PSCustomObject]@{ Username = 'svc.sim01'; Password = 'pw'; Domain = 'LAB' }
            }
            Mock -ModuleName RobOtters Get-ROConfig { 'https://ss.lab.local/SS' }
            Mock -ModuleName RobOtters Connect-ROSecretServer { throw 'auth failed' }
        }

        It 'Should return Failed status' {
            $result = Test-ROConnection -Username 'svc.sim01'
            $result.Status | Should -Be 'Failed'
        }
    }

    Context 'When user not found' {
        BeforeAll {
            Mock -ModuleName RobOtters Get-ROUser { $null }
        }

        It 'Should write an error' {
            Test-ROConnection -Username 'ghost' -ErrorAction SilentlyContinue
            Should -Invoke -CommandName Get-ROUser -ModuleName RobOtters -Times 1 -Scope It
        }
    }
}
