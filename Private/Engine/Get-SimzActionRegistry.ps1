function Get-SimzActionRegistry {
    [CmdletBinding()]
    param()

    @{
        SearchSecrets     = @{ Function = 'Invoke-SimzSearchSecrets';     Category = 'Core' }
        ViewSecret        = @{ Function = 'Invoke-SimzViewSecret';        Category = 'Core' }
        CheckoutPassword  = @{ Function = 'Invoke-SimzCheckoutPassword';  Category = 'Core' }
        ListFolderSecrets = @{ Function = 'Invoke-SimzListFolderSecrets'; Category = 'Core' }
        BrowseFolders     = @{ Function = 'Invoke-SimzBrowseFolders';     Category = 'Core' }
        CreateFolder      = @{ Function = 'Invoke-SimzCreateFolder';      Category = 'Management' }
        CreateSecret      = @{ Function = 'Invoke-SimzCreateSecret';      Category = 'Management' }
        EditSecret        = @{ Function = 'Invoke-SimzEditSecret';        Category = 'Management' }
        MoveSecret        = @{ Function = 'Invoke-SimzMoveSecret';        Category = 'Management' }
        CheckinSecret     = @{ Function = 'Invoke-SimzCheckinSecret';     Category = 'Advanced' }
        RunReport         = @{ Function = 'Invoke-SimzRunReport';         Category = 'Advanced' }
        AddFavorite       = @{ Function = 'Invoke-SimzAddFavorite';       Category = 'Advanced' }
        TriggerHeartbeat  = @{ Function = 'Invoke-SimzTriggerHeartbeat';  Category = 'Advanced' }
        ViewSecretPolicy  = @{ Function = 'Invoke-SimzViewSecretPolicy';  Category = 'Advanced' }
        ToggleComment     = @{ Function = 'Invoke-SimzToggleComment';     Category = 'Management' }
        ToggleCheckout    = @{ Function = 'Invoke-SimzToggleCheckout';    Category = 'Management' }
        ExpireSecret      = @{ Function = 'Invoke-SimzExpireSecret';      Category = 'Management' }
        ChangePassword    = @{ Function = 'Invoke-SimzChangePassword';    Category = 'Advanced' }
        LaunchSecret      = @{ Function = 'Invoke-SimzLaunchSecret';     Category = 'Advanced' }
    }
}
