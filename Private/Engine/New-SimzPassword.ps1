function New-SimzPassword {
    [CmdletBinding()]
    param(
        [int]$Length = 16
    )

    $lower   = 'abcdefghijklmnopqrstuvwxyz'
    $upper   = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    $digits  = '0123456789'
    $symbols = '!@#$%^&*()-_=+'
    $all     = $lower + $upper + $digits + $symbols

    # Guarantee one from each class, fill the rest randomly, then shuffle
    $mandatory = @(
        $lower[(Get-Random -Maximum $lower.Length)]
        $upper[(Get-Random -Maximum $upper.Length)]
        $digits[(Get-Random -Maximum $digits.Length)]
        $symbols[(Get-Random -Maximum $symbols.Length)]
    )
    $rest = 1..($Length - 4) | ForEach-Object { $all[(Get-Random -Maximum $all.Length)] }
    -join (($mandatory + $rest) | Sort-Object { Get-Random })
}
