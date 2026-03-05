Import-Module C:\projects\TheSimz\TheSimz.psd1 -Force

$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-ExecutionPolicy Bypass -NoProfile -Command "Import-Module C:\projects\TheSimz\TheSimz.psd1; Start-SimzCycle"'

$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Minutes 30) -RepetitionDuration (New-TimeSpan -Days 9999)

$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 25)

Register-ScheduledTask -TaskName 'TheSimz' -Action $action -Trigger $trigger -Settings $settings -Description 'Secret Server user activity simulator - runs every 30 minutes' -RunLevel Highest -Force

Write-Host 'Scheduled task "TheSimz" registered successfully.'
Get-ScheduledTask -TaskName 'TheSimz' | Format-List TaskName, State, Description
