# Set-ROUser

## Synopsis
Update user properties.

## Syntax
```powershell
Set-ROUser [-Username] <String> [-Password <String>] [-Domain <String>]
           [-ActiveHourStart <String>] [-ActiveHourEnd <String>]
           [-IsEnabled <Nullable[Boolean]>] [-ActionWeights <Hashtable>]

Set-ROUser [-Username] <String> [-RandomPassword] [-Domain <String>]
           [-ActiveHourStart <String>] [-ActiveHourEnd <String>]
           [-IsEnabled <Nullable[Boolean]>] [-ActionWeights <Hashtable>]
```

## Description
Updates one or more properties of an existing simulated user. When -Password or
-RandomPassword is specified the password is changed in Active Directory first and
then updated (DPAPI-encrypted) in the SQLite database. The -Password and
-RandomPassword parameters are mutually exclusive.

## Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| Username | String | Yes | -- | The username of the user to update |
| Password | String | No | -- | New plain-text password (mutually exclusive with RandomPassword) |
| Domain | String | No | -- | New AD domain value |
| ActiveHourStart | String | No | -- | New active window start (HH:mm) |
| ActiveHourEnd | String | No | -- | New active window end (HH:mm) |
| IsEnabled | Nullable[Boolean] | No | -- | Enable or disable the user |
| ActionWeights | Hashtable | No | -- | Updated action weight map |
| RandomPassword | Switch | No | -- | Generate and set a random password (mutually exclusive with Password) |
| EnableCategory | String | No | -- | Enable all actions in a category (Core, Management, Advanced) by restoring default weights |
| DisableCategory | String | No | -- | Disable all actions in a category by setting weights to 0 |
| EnableAction | String | No | -- | Enable a specific action by restoring its default weight |
| DisableAction | String | No | -- | Disable a specific action by setting its weight to 0 |

## Examples

### Example 1: Change a user's active hours
```powershell
Set-ROUser -Username 'svc-simuser01' -ActiveHourStart '08:00' -ActiveHourEnd '18:00'
```
Updates the active window for the specified user.

### Example 2: Disable a user
```powershell
Set-ROUser -Username 'svc-simuser01' -IsEnabled $false
```
Prevents the user from being selected in future simulation cycles.

### Example 3: Rotate to a random password
```powershell
Set-ROUser -Username 'svc-simuser01' -RandomPassword
```
Generates a random password, sets it in AD, and stores the encrypted value in the database.

### Example 4: Update action weights
```powershell
Set-ROUser -Username 'svc-simuser01' -ActionWeights @{ GetSecret = 10; CreateSecret = 5 }
```
Adjusts the probability weights for the user's actions during simulation cycles.

### Example 5: Disable all Management actions for a user
```powershell
Set-ROUser -Username 'svc-simuser01' -DisableCategory 'Management'
```
Sets all Management action weights to 0.

### Example 6: Re-enable a category
```powershell
Set-ROUser -Username 'svc-simuser01' -EnableCategory 'Management'
```
Restores default weights for all Management actions.

### Example 7: Disable a single action
```powershell
Set-ROUser -Username 'svc-simuser01' -DisableAction 'CreateSecret'
```

## Outputs

| Property | Type | Description |
|----------|------|-------------|
| Username | String | The updated username |
| Password | String | The encrypted password value |
| Domain | String | The AD domain |
| ActiveHourStart | String | Start of active window |
| ActiveHourEnd | String | End of active window |
| IsEnabled | Boolean | Whether the user is enabled |
| UserId | Int32 | Database ID |

## Related Commands
- [Get-ROUser](Get-ROUser.md)
- [Add-ROUser](Add-ROUser.md)
