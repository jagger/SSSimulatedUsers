@{
    RootModule        = 'TheSimz.psm1'
    ModuleVersion     = '0.2.0'
    GUID              = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author            = 'jagger'
    Description       = 'Secret Server user activity simulator for lab environments'
    PowerShellVersion = '5.1'
    RequiredModules   = @('PSSQLite')
    FunctionsToExport = @(
        'Initialize-SimzDatabase'
        'Add-SimzUser'
        'Remove-SimzUser'
        'Get-SimzUser'
        'Set-SimzUser'
        'Start-SimzCycle'
        'Get-SimzActionLog'
        'Get-SimzConfig'
        'Set-SimzConfig'
        'Test-SimzConnection'
    )
    CmdletsToExport   = @()
    VariablesToExport  = @()
    AliasesToExport    = @()
    PrivateData        = @{ PSData = @{ LicenseUri = 'https://github.com/jagger/SSSimulatedUsers/blob/main/LICENSE'; ProjectUri = 'https://github.com/jagger/SSSimulatedUsers' } }
}
