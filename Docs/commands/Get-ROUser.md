# Get-ROUser

## Synopsis
List simulated users.

## Syntax
```powershell
Get-ROUser [-IncludeWeights] [-ShowPassword]

Get-ROUser [-Username] <String> [-IncludeWeights] [-ShowPassword]

Get-ROUser [-UserId] <Int32> [-IncludeWeights] [-ShowPassword]
```

## Description
Retrieves one or more simulated users from the RobOtters SQLite database. When called
without parameters it returns all users. Use -Username or -UserId to look up a single
user. The -IncludeWeights switch appends each user's action weight configuration, and
-ShowPassword decrypts and displays the stored password.

## Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| Username | String | No | -- | Filter by username (ByName parameter set) |
| UserId | Int32 | No | -- | Filter by database ID (ById parameter set) |
| IncludeWeights | Switch | No | -- | Include the ActionWeights property on each user |
| ShowPassword | Switch | No | -- | Decrypt and show the stored password in plain text |

## Examples

### Example 1: List all users
```powershell
Get-ROUser
```
Returns every registered simulated user.

### Example 2: Get a specific user with action weights
```powershell
Get-ROUser -Username 'svc-simuser01' -IncludeWeights
```
Returns the user record along with their weighted action probabilities.

### Example 3: Look up a user by ID and show password
```powershell
Get-ROUser -UserId 3 -ShowPassword
```
Returns the user with ID 3 and includes the decrypted password.

## Outputs

| Property | Type | Description |
|----------|------|-------------|
| Username | String | The registered username |
| Password | String | Encrypted password (or plain text if -ShowPassword) |
| Domain | String | The AD domain |
| ActiveHourStart | String | Start of active window |
| ActiveHourEnd | String | End of active window |
| IsEnabled | Boolean | Whether the user is enabled |
| UserId | Int32 | Database ID |
| ActionWeights | Hashtable | Action weight map (only with -IncludeWeights) |

## Related Commands
- [Add-ROUser](Add-ROUser.md)
- [Set-ROUser](Set-ROUser.md)
- [Remove-ROUser](Remove-ROUser.md)
