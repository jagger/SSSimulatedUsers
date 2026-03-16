@{
    RootModule        = 'RobOtters.psm1'
    ModuleVersion     = '0.5.0'
    GUID              = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author            = 'jagger'
    Description       = 'Secret Server user activity simulator for lab environments'
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
    )
    CmdletsToExport   = @()
    VariablesToExport  = @()
    AliasesToExport    = @()
    PrivateData        = @{ PSData = @{ LicenseUri = 'https://github.com/jagger/SSSimulatedUsers/blob/main/LICENSE'; ProjectUri = 'https://github.com/jagger/SSSimulatedUsers' } }
}
