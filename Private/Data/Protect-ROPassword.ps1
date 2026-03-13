function Protect-ROPassword {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PlainText
    )

    $key = Get-ROEncryptionKey
    $secure = ConvertTo-SecureString $PlainText -AsPlainText -Force
    ConvertFrom-SecureString $secure -Key $key
}
