Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"
$script:Lang = "es"

$script:I18n = @{
    es = @{
        MenuTitle = "GetOutTelemetries"
        By = "By Butti"
        Github = "GitHub: https://github.com/Buttiiii"
        OptApply = "[1] Aplicar optimizacion"
        OptGithub = "[2] Abrir GitHub de Butti"
        OptExit = "[0] Salir"
        OptLang = "[9] Cambiar idioma"
        Choose = "Elige una opcion"
        LangTitle = "Selecciona idioma / Select language"
        LangEs = "[1] Espanol"
        LangEn = "[2] English"
        LangDone = "Idioma aplicado: Espanol"
        NeedAdmin = "Este script necesita PowerShell como Administrador."
        OpenedGithub = "GitHub abierto. Saliendo..."
        Exiting = "Saliendo..."
        Step1 = "[1/9] Telemetria y privacidad..."
        Step2 = "[2/9] Servicios..."
        Step3 = "[3/9] Tareas programadas..."
        Step4 = "[4/9] Visual, tema oscuro y texto nitido..."
        Step5 = "[5/9] Fondo de bloqueo..."
        Step6 = "[6/9] Autoarranque (sin tocar OneDrive)..."
        Step7 = "[7/9] Wallpaper Engine..."
        Step8 = "[8/9] Cursor Vision Cursor White..."
        Step9 = "[9/9] Bateria + tareas autoreaplicacion..."
        Done = "Listo. Reinicia para consolidar todos los cambios."
    }
    en = @{
        MenuTitle = "GetOutTelemetries"
        By = "By Butti"
        Github = "GitHub: https://github.com/Buttiiii"
        OptApply = "[1] Apply optimization"
        OptGithub = "[2] Open Butti's GitHub"
        OptExit = "[0] Exit"
        OptLang = "[9] Change language"
        Choose = "Choose an option"
        LangTitle = "Select language / Selecciona idioma"
        LangEs = "[1] Espanol"
        LangEn = "[2] English"
        LangDone = "Language set: English"
        NeedAdmin = "This script needs PowerShell as Administrator."
        OpenedGithub = "GitHub opened. Exiting..."
        Exiting = "Exiting..."
        Step1 = "[1/9] Telemetry and privacy..."
        Step2 = "[2/9] Services..."
        Step3 = "[3/9] Scheduled tasks..."
        Step4 = "[4/9] Visuals, dark mode and sharp text..."
        Step5 = "[5/9] Lock screen..."
        Step6 = "[6/9] Startup cleanup (without touching OneDrive)..."
        Step7 = "[7/9] Wallpaper Engine..."
        Step8 = "[8/9] Vision Cursor White..."
        Step9 = "[9/9] Battery + auto reapply tasks..."
        Done = "Done. Restart to consolidate all changes."
    }
}

function T {
    param([Parameter(Mandatory = $true)][string]$Key)
    return $script:I18n[$script:Lang][$Key]
}

function Select-Language {
    Clear-Host
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "$(T 'LangTitle')" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "[1] Espanol"
    Write-Host "[2] English"
    Write-Host ""
    $langOption = Read-Host "Option / Opcion"
    if ($langOption -eq "2") {
        $script:Lang = "en"
    }
    else {
        $script:Lang = "es"
    }
    Write-Host (T 'LangDone')
    Start-Sleep -Milliseconds 600
}

function Set-RegDword {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][int]$Value
    )
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -PropertyType DWord -Value $Value -Force | Out-Null
}

function Set-RegString {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Value
    )
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -PropertyType String -Value $Value -Force | Out-Null
}

function Remove-RegValue {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name
    )
    if (Test-Path $Path) {
        Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
    }
}

function Disable-ServiceSafe {
    param([Parameter(Mandatory = $true)][string]$Name)
    Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue
    Set-Service -Name $Name -StartupType Disabled -ErrorAction SilentlyContinue
}

function Disable-TaskSafe {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$TaskName
    )
    Disable-ScheduledTask -TaskPath $Path -TaskName $TaskName -ErrorAction SilentlyContinue | Out-Null
}

function Ensure-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host (T 'NeedAdmin') -ForegroundColor Yellow
        exit 1
    }
}

function Set-LockScreen {
    $lockSource = "C:\Users\$env:USERNAME\AppData\Roaming\Microsoft\Windows\Themes\TranscodedWallpaper"
    $lockDir = "C:\ProgramData\OpenCode"
    $lockFile = Join-Path $lockDir "lockscreen.jpg"

    if (Test-Path $lockSource) {
        New-Item -Path $lockDir -ItemType Directory -Force | Out-Null
        Copy-Item -Path $lockSource -Destination $lockFile -Force

        Set-RegString -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "LockScreenImage" -Value $lockFile
        Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen" -Value 0

        Set-RegString -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP" -Name "LockScreenImagePath" -Value $lockFile
        Set-RegString -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP" -Name "LockScreenImageUrl" -Value $lockFile
        Set-RegDword -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP" -Name "LockScreenImageStatus" -Value 1
    }

    Set-RegDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "RotatingLockScreenEnabled" -Value 0
    Set-RegDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "RotatingLockScreenOverlayEnabled" -Value 0
}

function Set-CursorVisionWhite {
    $src = "C:\Users\$env:USERNAME\OneDrive\Datos adjuntos\Cursor Raton\Vision Cursor White"
    $dst = "C:\Windows\Cursors\vision cursor white"

    if (-not (Test-Path $src)) { return }

    New-Item -Path $dst -ItemType Directory -Force | Out-Null
    Copy-Item -Path (Join-Path $src "*.cur") -Destination $dst -Force -ErrorAction SilentlyContinue
    Copy-Item -Path (Join-Path $src "*.ani") -Destination $dst -Force -ErrorAction SilentlyContinue

    reg.exe add "HKCU\Control Panel\Cursors" /ve /t REG_SZ /d "Vision Cursor White" /f | Out-Null
    Set-RegString -Path "HKCU:\Control Panel\Cursors" -Name "Arrow" -Value (Join-Path $dst "pointer.cur")
    Set-RegString -Path "HKCU:\Control Panel\Cursors" -Name "Help" -Value (Join-Path $dst "help.cur")
    Set-RegString -Path "HKCU:\Control Panel\Cursors" -Name "AppStarting" -Value (Join-Path $dst "work.ani")
    Set-RegString -Path "HKCU:\Control Panel\Cursors" -Name "Wait" -Value (Join-Path $dst "busy.ani")
    Set-RegString -Path "HKCU:\Control Panel\Cursors" -Name "Crosshair" -Value (Join-Path $dst "cross.cur")
    Set-RegString -Path "HKCU:\Control Panel\Cursors" -Name "IBeam" -Value (Join-Path $dst "text.cur")
    Set-RegString -Path "HKCU:\Control Panel\Cursors" -Name "NWPen" -Value (Join-Path $dst "handwriting.cur")
    Set-RegString -Path "HKCU:\Control Panel\Cursors" -Name "No" -Value (Join-Path $dst "unavailiable.cur")
    Set-RegString -Path "HKCU:\Control Panel\Cursors" -Name "SizeNS" -Value (Join-Path $dst "vert.cur")
    Set-RegString -Path "HKCU:\Control Panel\Cursors" -Name "SizeWE" -Value (Join-Path $dst "horz.cur")
    Set-RegString -Path "HKCU:\Control Panel\Cursors" -Name "SizeNWSE" -Value (Join-Path $dst "dgn1.cur")
    Set-RegString -Path "HKCU:\Control Panel\Cursors" -Name "SizeNESW" -Value (Join-Path $dst "dgn2.cur")
    Set-RegString -Path "HKCU:\Control Panel\Cursors" -Name "SizeAll" -Value (Join-Path $dst "move.cur")
    Set-RegString -Path "HKCU:\Control Panel\Cursors" -Name "UpArrow" -Value (Join-Path $dst "alternate.cur")
    Set-RegString -Path "HKCU:\Control Panel\Cursors" -Name "Hand" -Value (Join-Path $dst "link.cur")
    Set-RegString -Path "HKCU:\Control Panel\Cursors" -Name "Person" -Value (Join-Path $dst "person.cur")
    Set-RegString -Path "HKCU:\Control Panel\Cursors" -Name "Pin" -Value (Join-Path $dst "pin.cur")
}

function Set-BatteryTuning {
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 5 | Out-Null
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100 | Out-Null
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_VIDEO VIDEOIDLE 300 | Out-Null
    powercfg /setacvalueindex SCHEME_CURRENT SUB_VIDEO VIDEOIDLE 1200 | Out-Null
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_DISK DISKIDLE 300 | Out-Null
    powercfg /setacvalueindex SCHEME_CURRENT SUB_DISK DISKIDLE 0 | Out-Null
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 1200 | Out-Null
    powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 0 | Out-Null
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP HIBERNATEIDLE 2700 | Out-Null
    powercfg /setactive SCHEME_CURRENT | Out-Null
}

function Set-StartupTasks {
    param([Parameter(Mandatory = $true)][string]$ScriptPath)

    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ("-NoProfile -ExecutionPolicy Bypass -File `"" + $ScriptPath + "`"")
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew

    $triggerStartup = New-ScheduledTaskTrigger -AtStartup
    $principalStartup = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    Register-ScheduledTask -TaskPath "\OpenCode\" -TaskName "ReaplicarOptimizacion_Startup" -Action $action -Trigger $triggerStartup -Principal $principalStartup -Settings $settings -Force | Out-Null

    $user = ($env:USERDOMAIN + "\" + $env:USERNAME)
    $triggerLogon = New-ScheduledTaskTrigger -AtLogOn -User $user
    $principalLogon = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Highest
    Register-ScheduledTask -TaskPath "\OpenCode\" -TaskName "ReaplicarOptimizacion_Logon" -Action $action -Trigger $triggerLogon -Principal $principalLogon -Settings $settings -Force | Out-Null
}

function Show-MiniMenu {
    Clear-Host
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "          $(T 'MenuTitle')" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host (T 'By')
    Write-Host (T 'Github')
    Write-Host ""
    Write-Host (T 'OptApply')
    Write-Host (T 'OptGithub')
    Write-Host (T 'OptExit')
    Write-Host (T 'OptLang')
    Write-Host ""
    return (Read-Host (T 'Choose'))
}

Select-Language
while ($true) {
    $menuOption = Show-MiniMenu
    switch ($menuOption) {
        "2" {
            Start-Process "https://github.com/Buttiiii"
            Write-Host (T 'OpenedGithub')
            exit 0
        }
        "0" {
            Write-Host (T 'Exiting')
            exit 0
        }
        "9" {
            Select-Language
            continue
        }
        "1" {
            Ensure-Admin
            break
        }
        default {
            continue
        }
    }
}

Write-Host (T 'Step1')
Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0
Set-RegDword -Path "HKCU:\Software\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -Value 1
Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -Value 1
Set-RegDword -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -Value 1
Set-RegDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0
Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -Value 1
Set-RegDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value 0
Set-RegDword -Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" -Name "DisableTailoredExperiencesWithDiagnosticData" -Value 1

# No bloquear lock screen / spotlight por politica.
Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures"
Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableSoftLanding"
Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsSpotlightFeatures"

Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0
Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0
Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Value 0
Set-RegDword -Path "HKCU:\Software\Microsoft\InputPersonalization" -Name "RestrictImplicitTextCollection" -Value 1
Set-RegDword -Path "HKCU:\Software\Microsoft\InputPersonalization" -Name "RestrictImplicitInkCollection" -Value 1
Set-RegDword -Path "HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore" -Name "HarvestContacts" -Value 0
Set-RegDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Value 0
Set-RegDword -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Value 1
Set-RegDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0
Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableWebSearch" -Value 1
Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "ConnectedSearchUseWeb" -Value 0
Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCloudSearch" -Value 0
Set-RegDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1
Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value 0

Write-Host (T 'Step2')
Disable-ServiceSafe -Name "DiagTrack"
Disable-ServiceSafe -Name "dmwappushservice"
Disable-ServiceSafe -Name "WerSvc"
Disable-ServiceSafe -Name "SysMain"
Disable-ServiceSafe -Name "WSearch"

Write-Host (T 'Step3')
Disable-TaskSafe -Path "\Microsoft\Windows\Customer Experience Improvement Program\" -TaskName "Consolidator"
Disable-TaskSafe -Path "\Microsoft\Windows\Customer Experience Improvement Program\" -TaskName "UsbCeip"
Disable-TaskSafe -Path "\Microsoft\Windows\DiskDiagnostic\" -TaskName "Microsoft-Windows-DiskDiagnosticDataCollector"
Disable-TaskSafe -Path "\Microsoft\Windows\Feedback\Siuf\" -TaskName "DmClient"
Disable-TaskSafe -Path "\Microsoft\Windows\Feedback\Siuf\" -TaskName "DmClientOnScenarioDownload"
Disable-TaskSafe -Path "\Microsoft\Windows\Application Experience\" -TaskName "Microsoft Compatibility Appraiser Exp"
Disable-TaskSafe -Path "\Microsoft\Windows\Application Experience\" -TaskName "PcaPatchDbTask"

Write-Host (T 'Step4')
Set-RegDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 0
Set-RegDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Value 0
Set-RegDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewAlphaSelect" -Value 1
Set-RegDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewShadow" -Value 1
Set-RegDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_IrisRecommendations" -Value 0
Set-RegDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0
Set-RegDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0
Set-RegDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0
Set-RegString -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "400"
Set-RegString -Path "HKCU:\Control Panel\Desktop" -Name "FontSmoothing" -Value "2"
Set-RegDword -Path "HKCU:\Control Panel\Desktop" -Name "FontSmoothingType" -Value 2
Set-RegDword -Path "HKCU:\Control Panel\Desktop" -Name "FontSmoothingGamma" -Value 1500
Set-RegDword -Path "HKCU:\Control Panel\Desktop" -Name "FontSmoothingOrientation" -Value 1

Write-Host (T 'Step5')
Set-LockScreen

Write-Host (T 'Step6')
$hkcuRun = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$hklmRun = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$disableHKCURun = @("Adobe Acrobat Synchronizer", "Discord", "EADM", "EpicGamesLauncher", "Parsec.App.0", "Proton VPN", "RiotClient", "Steam", "WallpaperEngine")
$disableHKLMRun = @("Logitech Download Assistant", "Riot Vanguard")
foreach ($n in $disableHKCURun) { Remove-ItemProperty -Path $hkcuRun -Name $n -ErrorAction SilentlyContinue }
foreach ($n in $disableHKLMRun) { Remove-ItemProperty -Path $hklmRun -Name $n -ErrorAction SilentlyContinue }

Write-Host (T 'Step7')
$we = "D:\Archivos de Progama (x86)\Steam\steamapps\common\wallpaper_engine\wallpaper64.exe"
if (Test-Path $we) {
    Set-ItemProperty -Path $hkcuRun -Name "WallpaperEngine" -Type String -Value ("`"$we`" -silent")
}

Write-Host (T 'Step8')
Set-CursorVisionWhite

Write-Host (T 'Step9')
Set-BatteryTuning

$scriptPath = $PSCommandPath
if ([string]::IsNullOrWhiteSpace($scriptPath)) {
    $scriptPath = "C:\Users\$env:USERNAME\OneDrive\Proyectos\GetOutTelemetries.ps1"
}
Set-StartupTasks -ScriptPath $scriptPath

rundll32.exe user32.dll,UpdatePerUserSystemParameters
Write-Host (T 'Done') -ForegroundColor Green
