@{
    RootModule        = 'RobOtters.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author            = 'jagger'
    Copyright         = '(c) 2026 jagger. All rights reserved.'
    Description       = 'Simulates realistic Secret Server user activity for lab environments. AD-authenticated users perform randomized actions (view, create, edit secrets and folders) against an on-prem Delinea Secret Server instance to generate audit trail data.'
    PowerShellVersion = '5.1'
    RequiredModules   = @('PSSQLite')
    FunctionsToExport = @(
        'Initialize-RODatabase'
        'Add-ROUser'
        'Remove-ROUser'
        'Get-ROUser'
        'Set-ROUser'
        'Start-ROCycle'
        'Get-ROActionLog'
        'Get-ROConfig'
        'Set-ROConfig'
        'Test-ROConnection'
        'Get-ROAccess'
        'Export-ROConfig'
        'Import-ROConfig'
        'Test-ROHealth'
    )
    CmdletsToExport   = @()
    VariablesToExport  = @()
    AliasesToExport    = @()
    PrivateData        = @{
        PSData = @{
            Tags         = @('SecretServer', 'Delinea', 'Simulation', 'ActiveDirectory', 'Audit')
            LicenseUri   = 'https://github.com/jagger/SSSimulatedUsers/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/jagger/SSSimulatedUsers'
            ReleaseNotes = 'v1.0.0: Pre-flight health checks (Test-ROHealth), cycle lock file, log retention enforcement, configurable action delays, token expiry validation, encryption key hardening, full Pester test coverage.'
        }
    }
}
