function Unprotect-ROPassword {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EncryptedText
    )

    $key = Get-ROEncryptionKey
    $secure = ConvertTo-SecureString $EncryptedText -Key $key
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    } finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}
