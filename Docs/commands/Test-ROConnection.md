# Test-ROConnection

## Synopsis
Test Secret Server authentication.

## Syntax
```powershell
Test-ROConnection [-Username] <String>
```

## Description
Attempts to authenticate the specified simulated user against the configured Secret
Server instance using OAuth2 password grant. Returns an object indicating whether
authentication succeeded or failed along with a descriptive message.

## Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| Username | String | Yes | -- | The username of the simulated user to test |

## Examples

### Example 1: Test a user's connection
```powershell
Test-ROConnection -Username 'svc-simuser01'
```
Authenticates the user against Secret Server and reports the result.

### Example 2: Test all users
```powershell
Get-ROUser | ForEach-Object { Test-ROConnection -Username $_.Username }
```
Iterates through every registered user and tests their Secret Server connectivity.

## Outputs

| Property | Type | Description |
|----------|------|-------------|
| Username | String | The tested username |
| BaseUrl | String | The Secret Server URL used for the test |
| Status | String | 'Success' or 'Failed' |
| Message | String | Details about the authentication result |

## Related Commands
- [Get-ROUser](Get-ROUser.md)
- [Set-ROConfig](Set-ROConfig.md)
