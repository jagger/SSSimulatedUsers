function Get-ROEncryptionKey {
    <#
    .SYNOPSIS
        Resolve the AES-256 key used to encrypt stored user passwords
    .DESCRIPTION
        Looks for the key in two places, in order:

          1. $env:RO_ENCRYPT_KEY - base64 AES-256 key.
          2. <data root>\encryption.key - the same key, DPAPI-protected
             (LocalMachine scope) and ACL'd to SYSTEM, Administrators and the
             service account. This is the preferred location: unlike a
             machine-scoped environment variable, which every authenticated
             user on the server can read, access here is controlled by the
             file ACL, and the ciphertext is useless if copied off the box.

        Register-ROTask.ps1 -EncryptionKey writes the protected file.
    .OUTPUTS
        Byte[] - 32-byte AES-256 key.
    #>
    [CmdletBinding()]
    param()

    $keyText = $null
    $source  = $null

    if ($env:RO_ENCRYPT_KEY) {
        $keyText = $env:RO_ENCRYPT_KEY
        $source  = 'RO_ENCRYPT_KEY environment variable'
    }
    else {
        $keyFile = Join-Path (Get-RODataRoot) 'encryption.key'
        if (Test-Path $keyFile) {
            try {
                Add-Type -AssemblyName System.Security -ErrorAction Stop
                $protected = [Convert]::FromBase64String([System.IO.File]::ReadAllText($keyFile).Trim())
                $plain     = [System.Security.Cryptography.ProtectedData]::Unprotect(
                    $protected, $null, [System.Security.Cryptography.DataProtectionScope]::LocalMachine)
                $keyText   = [System.Text.Encoding]::UTF8.GetString($plain)
                $source    = $keyFile
                [Array]::Clear($plain, 0, $plain.Length)
            }
            catch {
                throw "Could not read the encryption key at '$keyFile': $_"
            }
        }
    }

    if (-not $keyText) {
        throw 'No encryption key available. Set RO_ENCRYPT_KEY to a base64-encoded 256-bit (32-byte) key, or store one with Register-ROTask.ps1 -EncryptionKey. Generate one with: [Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))'
    }

    try { [byte[]]$key = [Convert]::FromBase64String($keyText) }
    catch { throw "Encryption key from $source is not valid base64." }

    if ($key.Length -ne 32) {
        throw "Encryption key from $source must decode to exactly 32 bytes (AES-256). Got $($key.Length) bytes."
    }

    $key
}
