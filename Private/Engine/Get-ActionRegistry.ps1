function Get-ActionRegistry {
    [CmdletBinding()]
    param()

    @{
        SearchSecrets     = @{ Function = 'Invoke-SearchSecrets';     Category = 'Core' }
        ViewSecret        = @{ Function = 'Invoke-ViewSecret';        Category = 'Core' }
        CheckoutPassword  = @{ Function = 'Invoke-CheckoutPassword';  Category = 'Core' }
        ListFolderSecrets = @{ Function = 'Invoke-ListFolderSecrets'; Category = 'Core' }
        BrowseFolders     = @{ Function = 'Invoke-BrowseFolders';     Category = 'Core' }
        CreateFolder      = @{ Function = 'Invoke-CreateFolder';      Category = 'Management' }
        CreateSecret      = @{ Function = 'Invoke-CreateSecret';      Category = 'Management' }
        EditSecret        = @{ Function = 'Invoke-EditSecret';        Category = 'Management' }
        MoveSecret        = @{ Function = 'Invoke-MoveSecret';        Category = 'Management' }
        CheckinSecret     = @{ Function = 'Invoke-CheckinSecret';     Category = 'Advanced' }
        RunReport         = @{ Function = 'Invoke-RunReport';         Category = 'Advanced' }
        AddFavorite       = @{ Function = 'Invoke-AddFavorite';       Category = 'Advanced' }
        TriggerHeartbeat  = @{ Function = 'Invoke-TriggerHeartbeat';  Category = 'Advanced' }
        ViewSecretPolicy  = @{ Function = 'Invoke-ViewSecretPolicy';  Category = 'Advanced' }
    }
}
