BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\..\RobOtters.psd1'
    Import-Module $modulePath -Force
}

Describe 'Set-ROConfig' {
    BeforeAll {
        Mock -ModuleName RobOtters Write-ROLog {}
        Mock -ModuleName RobOtters Invoke-ROQuery {}
    }

    It 'Should upsert the config key' {
        Set-ROConfig -Key 'SecretServerUrl' -Value 'https://new.url/SS'
        Should -Invoke -CommandName Invoke-ROQuery -ModuleName RobOtters -Times 1 -Scope It -ParameterFilter {
            $Query -like '*INSERT INTO Config*ON CONFLICT*' -and
            $SqlParameters.Key -eq 'SecretServerUrl' -and
            $SqlParameters.Value -eq 'https://new.url/SS'
        }
    }

    It 'Should log the change' {
        Set-ROConfig -Key 'MaxActionsPerCycle' -Value '20'
        Should -Invoke -CommandName Write-ROLog -ModuleName RobOtters -Times 1 -Scope It
    }

    It 'Should accept empty string values' {
        Set-ROConfig -Key 'DisabledActions' -Value ''
        Should -Invoke -CommandName Invoke-ROQuery -ModuleName RobOtters -Times 1 -Scope It -ParameterFilter {
            $SqlParameters.Value -eq ''
        }
    }
}
