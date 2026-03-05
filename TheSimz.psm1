$ModuleRoot = $PSScriptRoot

# Dot-source all private functions (recurse into subdirectories)
Get-ChildItem -Path "$ModuleRoot\Private" -Recurse -Filter '*.ps1' | ForEach-Object {
    . $_.FullName
}

# Dot-source all public functions
Get-ChildItem -Path "$ModuleRoot\Public" -Filter '*.ps1' | ForEach-Object {
    . $_.FullName
}
