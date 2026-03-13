function Get-ROEncryptionKey {
    [CmdletBinding()]
    param()

    if (-not $env:RO_ENCRYPT_KEY) {
        throw 'Environment variable RO_ENCRYPT_KEY is not set. Set it to a base64-encoded 256-bit (32-byte) key. Generate one with: [Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))'
    }

    [byte[]]$key = [Convert]::FromBase64String($env:RO_ENCRYPT_KEY)

    if ($key.Length -ne 32) {
        throw "RO_ENCRYPT_KEY must decode to exactly 32 bytes (AES-256). Got $($key.Length) bytes."
    }

    $key
}
