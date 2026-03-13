function Get-ROActionRegistry {
    [CmdletBinding()]
    param()

    @{
        SearchSecrets     = @{ Function = 'Invoke-ROSearchSecrets';     Category = 'Core' }
        ViewSecret        = @{ Function = 'Invoke-ROViewSecret';        Category = 'Core' }
        CheckoutPassword  = @{ Function = 'Invoke-ROCheckoutPassword';  Category = 'Core' }
        ListFolderSecrets = @{ Function = 'Invoke-ROListFolderSecrets'; Category = 'Core' }
        BrowseFolders     = @{ Function = 'Invoke-ROBrowseFolders';     Category = 'Core' }
        CreateFolder      = @{ Function = 'Invoke-ROCreateFolder';      Category = 'Management' }
        CreateSecret      = @{ Function = 'Invoke-ROCreateSecret';      Category = 'Management' }
        EditSecret        = @{ Function = 'Invoke-ROEditSecret';        Category = 'Management' }
        MoveSecret        = @{ Function = 'Invoke-ROMoveSecret';        Category = 'Management' }
        CheckinSecret     = @{ Function = 'Invoke-ROCheckinSecret';     Category = 'Advanced' }
        RunReport         = @{ Function = 'Invoke-RORunReport';         Category = 'Advanced' }
        AddFavorite       = @{ Function = 'Invoke-ROAddFavorite';       Category = 'Advanced' }
        TriggerHeartbeat  = @{ Function = 'Invoke-ROTriggerHeartbeat';  Category = 'Advanced' }
        ViewSecretPolicy  = @{ Function = 'Invoke-ROViewSecretPolicy';  Category = 'Advanced' }
        ToggleComment     = @{ Function = 'Invoke-ROToggleComment';     Category = 'Management' }
        ToggleCheckout    = @{ Function = 'Invoke-ROToggleCheckout';    Category = 'Management' }
        ExpireSecret      = @{ Function = 'Invoke-ROExpireSecret';      Category = 'Management' }
        ChangePassword    = @{ Function = 'Invoke-ROChangePassword';    Category = 'Advanced' }
        LaunchSecret      = @{ Function = 'Invoke-ROLaunchSecret';     Category = 'Advanced' }
    }
}
