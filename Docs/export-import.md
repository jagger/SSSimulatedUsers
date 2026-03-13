# Export and Import

## Exporting
```powershell
# Export config + users (passwords excluded)
Export-ROConfig -Path '.\robotters-backup.json'

# Export with passwords (plain text -- handle with care)
Export-ROConfig -Path '.\robotters-full.json' -IncludePasswords
```

### JSON Format
```json
{
  "ExportedAt": "2024-01-15 09:00:00",
  "Config": {
    "SecretServerUrl": "https://ss.lab.local/SecretServer",
    "DefaultDomain": "LAB"
  },
  "Users": [
    {
      "Username": "svc.sim01",
      "Password": null,
      "Domain": "LAB",
      "ActiveHourStart": "07:00",
      "ActiveHourEnd": "17:00",
      "IsEnabled": 1,
      "ActionWeights": { "ViewSecret": 25, "SearchSecrets": 20 }
    }
  ]
}
```

## Importing
```powershell
# Import everything
Import-ROConfig -Path '.\robotters-backup.json'

# Config only
Import-ROConfig -Path '.\config.json' -ConfigOnly

# Users only
Import-ROConfig -Path '.\config.json' -UsersOnly

# Preview first
Import-ROConfig -Path '.\config.json' -WhatIf
```

### How Import Works
- **Existing users**: properties are updated (domain, active hours, enabled status, passwords, action weights)
- **New users with password**: created as-is
- **New users without password**: a random password is generated and set in AD
- **Config keys**: upserted (insert or update)

## Use Case: Migrating Between Lab Environments
1. On the source machine: `Export-ROConfig -Path .\export.json -IncludePasswords`
2. Copy export.json to the target machine
3. On the target: `Initialize-RODatabase` then `Import-ROConfig -Path .\export.json`
4. Update SecretServerUrl: `Set-ROConfig -Key 'SecretServerUrl' -Value 'https://new-server/SecretServer'`
5. Test: `Test-ROConnection -Username 'svc.sim01'`
