# Contributing

Thanks for your interest in contributing to SSSimulatedUsers!

## Reporting Issues

- Use [GitHub Issues](https://github.com/jagger/SSSimulatedUsers/issues) to report bugs or request features
- Include your PowerShell version (`$PSVersionTable`), Secret Server version, and steps to reproduce

## Submitting Changes

1. Fork the repo and create a branch from `main`
2. Make your changes following the conventions below
3. Test your changes against a Secret Server instance if possible
4. Open a pull request with a clear description of what you changed and why

## Coding Conventions

- **Verb-Noun** naming: public functions use the `RO` noun prefix
- All functions use `[CmdletBinding()]` and named parameters
- Use `Write-ROLog` for operational logging (not `Write-Host`)
- SQL queries must use parameterized queries via `-SqlParameters`
- No aliases in scripts; use full cmdlet names
- Prefer splatting for calls with 3+ parameters

## Adding a New Action

1. Create a function in `Private/Actions/` named `Invoke-YourAction.ps1`
2. Accept a `[PSCustomObject]$Session` parameter
3. Return the standard result object:
   ```powershell
   [PSCustomObject]@{
       Action       = 'YourAction'
       TargetType   = 'Secret'  # or Folder, Report, etc.
       TargetId     = $id
       TargetName   = $name
       Success      = $true
       ErrorMessage = $null
   }
   ```
4. Register it in `Private/Engine/Get-ROActionRegistry.ps1`
5. Add a default weight in `Data/SeedActionWeights.psd1`
