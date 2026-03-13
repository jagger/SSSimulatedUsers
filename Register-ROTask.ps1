$modulePath = Join-Path $PSScriptRoot 'RobOtters.psd1'
Import-Module $modulePath -Force

$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-ExecutionPolicy Bypass -NoProfile -Command `"Import-Module '$modulePath'; Start-ROCycle`""

$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Minutes 30) -RepetitionDuration (New-TimeSpan -Days 9999)

$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 25)

Register-ScheduledTask -TaskName 'RobOtters' -Action $action -Trigger $trigger -Settings $settings -Description 'Secret Server user activity simulator - runs every 30 minutes' -RunLevel Highest -Force

Write-Host 'Scheduled task "RobOtters" registered successfully.'
Get-ScheduledTask -TaskName 'RobOtters' | Format-List TaskName, State, Description
