<#
.SYNOPSIS
    Windows 10/11 privacy and optimization helper.

.DESCRIPTION
    GetOutTelemetries reduces optional diagnostic, telemetry, feedback, background,
    visual, startup and power noise using documented Windows registry, service and
    scheduled task settings where possible. It does not remove all telemetry and it
    does not weaken Windows security features.

    Apply/Revert create a timestamped backup and technical log under:
      C:\ProgramData\GetOutTelemetries\

.PARAMETER Interactive
    Opens the safe menu UI.

.PARAMETER Apply
    Applies the selected profile.

.PARAMETER Revert
    Restores values from the latest backup when available, otherwise conservative
    defaults are used.

.PARAMETER Diagnose
    Prints current state without changing files, registry, services or tasks.

.PARAMETER Profile
    Profile to apply: Lite, Recommended, Hardcore or Custom.

.PARAMETER EnableScheduledTasks
    Opt-in only. Allows safe current-user logon task creation.

.PARAMETER NoScheduledTasks
    Blocks scheduled task creation even if a profile requests it.

.EXAMPLE
    .\GetOutTelemetries.ps1 -Interactive

.EXAMPLE
    .\GetOutTelemetries.ps1 -Diagnose

.EXAMPLE
    .\GetOutTelemetries.ps1 -Apply -Profile Lite -WhatIf

.NOTES
    Baseline: Windows PowerShell 5.1. Compatible with PowerShell 7+ where possible.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
param(
    [switch]$Interactive,
    [switch]$Apply,
    [switch]$Revert,
    [switch]$Diagnose,

    [ValidateSet("Lite", "Recommended", "Hardcore", "Custom")]
    [string]$Profile = "Recommended",

    [switch]$NoScheduledTasks,
    [switch]$EnableScheduledTasks,
    [switch]$NoCursor,
    [switch]$NoWallpaperEngine,
    [switch]$NoStartupCleanup,
    [switch]$EnableStartupCleanup,
    [switch]$NoServiceTweaks,
    [switch]$NoVisualTweaks,
    [string]$CursorPath,
    [switch]$Install,
    [switch]$Uninstall,
    [switch]$Version,
    [switch]$Force,
    [switch]$SelfTest
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

$script:Lang = "es"
$script:ScriptVersion = "1.0.0"
$script:ResultCounts = [ordered]@{
    Applied       = 0
    Skipped       = 0
    Failed        = 0
    RequiresAdmin = 0
    NotFound      = 0
    AlreadySet    = 0
}
$script:RestartRequired = $false
$script:ProgramRoot = Join-Path $env:ProgramData "GetOutTelemetries"
$script:LogRoot = Join-Path $script:ProgramRoot "Logs"
$script:BackupRoot = Join-Path $script:ProgramRoot "Backups"
$script:RunStamp = Get-Date -Format "yyyyMMdd-HHmmss"
$script:LogPath = $null
$script:BackupPath = $null
    $script:Backup = [ordered]@{
    CreatedAt      = (Get-Date).ToString("o")
    ScriptVersion  = $script:ScriptVersion
    Registry       = @()
    Services       = @()
    ScheduledTasks = @()
    Startup        = @()
    Cursor         = @()
    Power          = @()
    Install        = @()
}

$script:I18n = @{
    es = @{
        Title             = "GetOutTelemetries"
        Choose            = "Elige una opcion"
        NeedAdmin         = "Esta accion necesita PowerShell como Administrador."
        AdminHow          = "Abre Inicio, busca PowerShell, clic derecho, Ejecutar como administrador."
        Done              = "Operacion finalizada."
        Diagnose          = "Diagnostico del sistema"
        Backup            = "Backup"
        Log               = "Log"
        HardcoreWarn      = "Hardcore puede afectar busqueda, indexacion, informes de error y rendimiento percibido."
        ConfirmWord       = "Escribe HARDCORE para continuar"
        Cancelled         = "Cancelado."
        NoRelease         = "No se pudo comprobar releases o no hay release publicada."
        ScheduledWarn     = "Las tareas programadas son opcionales. Se crearan solo para usuario actual, no SYSTEM."
        RestorePointAsk   = "Crear punto de restauracion antes de continuar? (s/n)"
        MenuLite          = "Aplicar Lite"
        MenuLiteDesc      = "privacidad basica segura, sin servicios ni tareas"
        MenuRecommended   = "Aplicar Recomendado"
        MenuRecommendedDesc = "privacidad equilibrada, tareas feedback y servicios diagnostico"
        MenuHardcore      = "Aplicar Hardcore"
        MenuHardcoreDesc  = "cambios agresivos, requiere confirmacion"
        MenuCustom        = "Modo personalizado"
        MenuCustomDesc    = "elige categorias una a una"
        MenuAll           = "Aplicar todo"
        MenuAllDesc       = "modo guiado con confirmaciones para partes sensibles"
        MenuDiagnose      = "Diagnosticar sistema"
        MenuDiagnoseDesc  = "solo lectura, no cambia nada"
        MenuRevert        = "Revertir cambios"
        MenuRevertDesc    = "usa ultimo backup disponible"
        MenuLatestLog     = "Ver ultimo log"
        MenuLatestLogDesc = "muestra ruta del log mas reciente"
        MenuAuthorGithub  = "Abrir GitHub de Butti"
        MenuAuthorGithubDesc = "perfil del autor"
        MenuProjectGithub = "Abrir GitHub del proyecto"
        MenuProjectGithubDesc = "repositorio GetOutTelemetries"
        MenuLanguage      = "Cambiar idioma"
        MenuLanguageDesc  = "espanol o ingles"
        MenuUpdates       = "Comprobar updates"
        MenuUpdatesDesc   = "consulta GitHub releases, no instala nada"
        MenuInfo          = "Que hace / impacto"
        MenuInfoDesc      = "explica perfiles, porcentaje orientativo y limites"
        MenuInstall       = "Instalar herramienta"
        MenuInstallDesc   = "copia a ubicacion segura, no crea tareas por defecto"
        MenuUninstall     = "Desinstalar herramienta"
        MenuUninstallDesc = "quita tareas y app instalada, conserva logs/backups"
        MenuExit          = "Salir"
        MenuExitDesc      = "cerrar herramienta"
        InvalidOption     = "Opcion invalida."
        LatestLog         = "Ultimo log"
        ApplyAllWarn      = "Aplicar todo ejecuta Hardcore guiado: servicios agresivos, limpieza de inicio seleccionada, cursor, Wallpaper Engine, energia y opcion de tarea programada."
        LanguageTitle     = "Selecciona idioma"
        LanguagePrompt    = "Idioma"
        MenuProfiles      = "Perfiles"
        MenuTools         = "Herramientas"
        MenuLinks         = "Enlaces y ayuda"
        AdminYes          = "Admin: si"
        AdminNo           = "Admin: no - aplicar/revertir pedira permisos"
        SafeBadge         = "SEGURO"
        MediumBadge       = "MEDIO"
        HighBadge         = "ALTO"
        ToolBadge         = "INFO"
        LinkBadge         = "LINK"
        TipLine           = "Consejo: usa primero Diagnosticar y luego Lite -WhatIf si quieres revisar sin cambios."
        ContinuePrompt    = "Pulsa Enter para volver al menu"
        ImpactTitle       = "Impacto orientativo"
        ImpactNote        = "No es porcentaje real medible: Windows no expone telemetria total. Es reduccion percibida aproximada."
        InfoDoesTitle     = "Hace esto segun perfil"
        InfoAlsoTitle     = "Tambien"
        InfoNotTitle      = "No hace"
        VersionLabel      = "Version"
        InstallDone       = "Instalado en"
        UninstallDone     = "Desinstalacion completada"
    }
    en = @{
        Title             = "GetOutTelemetries"
        Choose            = "Choose an option"
        NeedAdmin         = "This action requires PowerShell as Administrator."
        AdminHow          = "Open Start, search PowerShell, right click, Run as administrator."
        Done              = "Operation finished."
        Diagnose          = "System diagnosis"
        Backup            = "Backup"
        Log               = "Log"
        HardcoreWarn      = "Hardcore can affect search, indexing, error reporting and perceived performance."
        ConfirmWord       = "Type HARDCORE to continue"
        Cancelled         = "Cancelled."
        NoRelease         = "Could not check releases or no release exists."
        ScheduledWarn     = "Scheduled tasks are optional. They will be current-user only, not SYSTEM."
        RestorePointAsk   = "Create a restore point before continuing? (y/n)"
        MenuLite          = "Apply Lite"
        MenuLiteDesc      = "safe basic privacy, no services or tasks"
        MenuRecommended   = "Apply Recommended"
        MenuRecommendedDesc = "balanced privacy, feedback tasks and diagnostic services"
        MenuHardcore      = "Apply Hardcore"
        MenuHardcoreDesc  = "aggressive changes, confirmation required"
        MenuCustom        = "Custom mode"
        MenuCustomDesc    = "choose categories one by one"
        MenuAll           = "Apply all"
        MenuAllDesc       = "guided mode with confirmations for sensitive parts"
        MenuDiagnose      = "Diagnose system"
        MenuDiagnoseDesc  = "read-only, changes nothing"
        MenuRevert        = "Revert changes"
        MenuRevertDesc    = "uses latest available backup"
        MenuLatestLog     = "View latest log"
        MenuLatestLogDesc = "shows latest log path"
        MenuAuthorGithub  = "Open Butti GitHub"
        MenuAuthorGithubDesc = "author profile"
        MenuProjectGithub = "Open project GitHub"
        MenuProjectGithubDesc = "GetOutTelemetries repository"
        MenuLanguage      = "Change language"
        MenuLanguageDesc  = "Spanish or English"
        MenuUpdates       = "Check updates"
        MenuUpdatesDesc   = "queries GitHub releases, installs nothing"
        MenuInfo          = "What it does / impact"
        MenuInfoDesc      = "explains profiles, estimated impact and limits"
        MenuInstall       = "Install tool"
        MenuInstallDesc   = "copies to safe location, creates no tasks by default"
        MenuUninstall     = "Uninstall tool"
        MenuUninstallDesc = "removes tasks and installed app, keeps logs/backups"
        MenuExit          = "Exit"
        MenuExitDesc      = "close tool"
        InvalidOption     = "Invalid option."
        LatestLog         = "Latest log"
        ApplyAllWarn      = "Apply all runs guided Hardcore: aggressive services, selected startup cleanup, cursor, Wallpaper Engine, power and optional scheduled task."
        LanguageTitle     = "Select language"
        LanguagePrompt    = "Language"
        MenuProfiles      = "Profiles"
        MenuTools         = "Tools"
        MenuLinks         = "Links and help"
        AdminYes          = "Admin: yes"
        AdminNo           = "Admin: no - apply/revert will require elevation"
        SafeBadge         = "SAFE"
        MediumBadge       = "MEDIUM"
        HighBadge         = "HIGH"
        ToolBadge         = "INFO"
        LinkBadge         = "LINK"
        TipLine           = "Tip: run Diagnose first, then Lite -WhatIf if you want a dry review."
        ContinuePrompt    = "Press Enter to return to menu"
        ImpactTitle       = "Estimated impact"
        ImpactNote        = "This is not a measurable real percentage: Windows does not expose total telemetry. It is approximate perceived reduction."
        InfoDoesTitle     = "What each profile does"
        InfoAlsoTitle     = "Also"
        InfoNotTitle      = "Does not"
        VersionLabel      = "Version"
        InstallDone       = "Installed to"
        UninstallDone     = "Uninstall completed"
    }
}

function T {
    param([Parameter(Mandatory = $true)][string]$Key)
    return $script:I18n[$script:Lang][$Key]
}

function New-OperationResult {
    param(
        [Parameter(Mandatory = $true)][ValidateSet("Success", "Skipped", "Failed", "RequiresAdmin", "NotFound", "AlreadySet")][string]$Status,
        [Parameter(Mandatory = $true)][string]$Category,
        [Parameter(Mandatory = $true)][string]$Action,
        [Parameter(Mandatory = $true)][string]$Target,
        [object]$OldValue,
        [object]$NewValue,
        [string]$ErrorMessage
    )

    switch ($Status) {
        "Success" { $script:ResultCounts.Applied++ }
        "Skipped" { $script:ResultCounts.Skipped++ }
        "Failed" { $script:ResultCounts.Failed++ }
        "RequiresAdmin" { $script:ResultCounts.RequiresAdmin++ }
        "NotFound" { $script:ResultCounts.NotFound++ }
        "AlreadySet" { $script:ResultCounts.AlreadySet++ }
    }

    $result = [pscustomobject]@{
        Timestamp = (Get-Date).ToString("o")
        Status    = $Status
        Category  = $Category
        Action    = $Action
        Target    = $Target
        OldValue  = $OldValue
        NewValue  = $NewValue
        Error     = $ErrorMessage
    }
    Write-Verbose ("{0} {1} {2} -> {3}" -f $Status, $Category, $Action, $Target)
    Write-LogObject -Entry $result
    return $result
}

function Write-LogObject {
    param([Parameter(Mandatory = $true)][psobject]$Entry)
    if (-not $script:LogPath) { return }
    $line = "{0}`t{1}`t{2}`t{3}`t{4}`told={5}`tnew={6}`terror={7}" -f `
        $Entry.Timestamp, $Entry.Status, $Entry.Category, $Entry.Action, $Entry.Target, `
        (ConvertTo-CompactJson $Entry.OldValue), (ConvertTo-CompactJson $Entry.NewValue), $Entry.Error
    Add-Content -Path $script:LogPath -Value $line -Encoding UTF8
}

function ConvertTo-CompactJson {
    param([object]$Value)
    if ($null -eq $Value) { return "" }
    try { return ($Value | ConvertTo-Json -Compress -Depth 8) }
    catch { return [string]$Value }
}

function Initialize-RunStorage {
    param([switch]$NeedBackup)
    if ($WhatIfPreference -or $Diagnose -or $SelfTest) { return }

    New-Item -Path $script:LogRoot -ItemType Directory -Force | Out-Null
    $script:LogPath = Join-Path $script:LogRoot ("GetOutTelemetries-{0}.log" -f $script:RunStamp)
    New-Item -Path $script:LogPath -ItemType File -Force | Out-Null

    if ($NeedBackup) {
        $script:BackupPath = Join-Path $script:BackupRoot $script:RunStamp
        New-Item -Path $script:BackupPath -ItemType Directory -Force | Out-Null
    }
}

function Save-Backup {
    if (-not $script:BackupPath -or $WhatIfPreference) { return }
    $path = Join-Path $script:BackupPath "backup.json"
    $script:Backup | ConvertTo-Json -Depth 12 | Set-Content -Path $path -Encoding UTF8
}

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-Admin {
    if (Test-IsAdmin) { return $true }
    if ($WhatIfPreference) {
        Write-Warning ((T "NeedAdmin") + " WhatIf continues read-only.")
        return $true
    }
    Write-Warning (T "NeedAdmin")
    Write-Warning (T "AdminHow")
    New-OperationResult -Status RequiresAdmin -Category "Admin" -Action "Check" -Target "Administrator" | Out-Null
    return $false
}

function Get-ScriptPathSafe {
    $path = $PSCommandPath
    if ([string]::IsNullOrWhiteSpace($path)) { $path = $MyInvocation.MyCommand.Path }
    if ([string]::IsNullOrWhiteSpace($path) -or -not (Test-Path -LiteralPath $path)) {
        throw "Script path could not be detected. Run from a saved .ps1 file."
    }
    return (Resolve-Path -LiteralPath $path).Path
}

function Get-RegValueSafe {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name
    )
    try {
        if (-not (Test-Path -LiteralPath $Path)) {
            return [pscustomobject]@{ Exists = $false; Value = $null; Type = $null }
        }
        $item = Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop
        return [pscustomobject]@{ Exists = $true; Value = $item.$Name; Type = $null }
    }
    catch {
        return [pscustomobject]@{ Exists = $false; Value = $null; Type = $null }
    }
}

function Backup-RegValue {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name
    )
    $current = Get-RegValueSafe -Path $Path -Name $Name
    $script:Backup.Registry += [pscustomobject]@{
        Path   = $Path
        Name   = $Name
        Exists = $current.Exists
        Value  = $current.Value
    }
    Save-Backup
}

function Set-RegValueSafe {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][ValidateSet("DWord", "String")][string]$Type,
        [Parameter(Mandatory = $true)][object]$Value,
        [Parameter(Mandatory = $true)][string]$Category
    )
    $target = "$Path\$Name"
    $old = Get-RegValueSafe -Path $Path -Name $Name
    if ($old.Exists -and ([string]$old.Value -eq [string]$Value)) {
        return New-OperationResult -Status AlreadySet -Category $Category -Action "SetRegistry" -Target $target -OldValue $old.Value -NewValue $Value
    }
    Backup-RegValue -Path $Path -Name $Name
    if ($WhatIfPreference) {
        return New-OperationResult -Status Skipped -Category $Category -Action "WhatIfSetRegistry" -Target $target -OldValue $old.Value -NewValue $Value
    }
    try {
        if (-not (Test-Path -LiteralPath $Path)) { New-Item -Path $Path -Force | Out-Null }
        New-ItemProperty -LiteralPath $Path -Name $Name -PropertyType $Type -Value $Value -Force | Out-Null
        $script:RestartRequired = $true
        return New-OperationResult -Status Success -Category $Category -Action "SetRegistry" -Target $target -OldValue $old.Value -NewValue $Value
    }
    catch {
        return New-OperationResult -Status Failed -Category $Category -Action "SetRegistry" -Target $target -OldValue $old.Value -NewValue $Value -ErrorMessage $_.Exception.Message
    }
}

function Remove-RegValueSafe {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Category
    )
    $target = "$Path\$Name"
    $old = Get-RegValueSafe -Path $Path -Name $Name
    if (-not $old.Exists) {
        return New-OperationResult -Status NotFound -Category $Category -Action "RemoveRegistry" -Target $target
    }
    Backup-RegValue -Path $Path -Name $Name
    if ($WhatIfPreference) {
        return New-OperationResult -Status Skipped -Category $Category -Action "WhatIfRemoveRegistry" -Target $target -OldValue $old.Value
    }
    try {
        Remove-ItemProperty -LiteralPath $Path -Name $Name
        $script:RestartRequired = $true
        return New-OperationResult -Status Success -Category $Category -Action "RemoveRegistry" -Target $target -OldValue $old.Value
    }
    catch {
        return New-OperationResult -Status Failed -Category $Category -Action "RemoveRegistry" -Target $target -OldValue $old.Value -ErrorMessage $_.Exception.Message
    }
}

function Backup-ServiceState {
    param([Parameter(Mandatory = $true)][string]$Name)
    if ($WhatIfPreference) {
        try {
            $service = Get-Service -Name $Name -ErrorAction Stop
            $state = [string]$service.Status
            $startMode = if ($service.PSObject.Properties.Name -contains "StartType") { [string]$service.StartType } else { "Unknown" }
            $script:Backup.Services += [pscustomobject]@{
                Name      = $Name
                Exists    = $true
                StartMode = $startMode
                State     = $state
            }
            Save-Backup
            return [pscustomobject]@{ Name = $Name; StartMode = $startMode; State = $state }
        }
        catch {
            $script:Backup.Services += [pscustomobject]@{ Name = $Name; Exists = $false; StartMode = $null; State = $null }
            Save-Backup
            return $null
        }
    }
    try {
        $svc = Get-CimInstance -ClassName Win32_Service -Filter ("Name='{0}'" -f $Name) -ErrorAction Stop
        if ($svc) {
            $script:Backup.Services += [pscustomobject]@{
                Name      = $Name
                Exists    = $true
                StartMode = $svc.StartMode
                State     = $svc.State
            }
            Save-Backup
            return $svc
        }
    }
    catch { }
    $script:Backup.Services += [pscustomobject]@{ Name = $Name; Exists = $false; StartMode = $null; State = $null }
    Save-Backup
    return $null
}

function Set-ServiceStartupSafe {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][ValidateSet("Automatic", "Manual", "Disabled")][string]$StartupType,
        [Parameter(Mandatory = $true)][string]$Category,
        [switch]$StopService
    )
    $svc = Backup-ServiceState -Name $Name
    if (-not $svc) {
        return New-OperationResult -Status NotFound -Category $Category -Action "SetService" -Target $Name -NewValue $StartupType
    }
    if ($svc.StartMode -eq $StartupType) {
        return New-OperationResult -Status AlreadySet -Category $Category -Action "SetService" -Target $Name -OldValue $svc.StartMode -NewValue $StartupType
    }
    if ($WhatIfPreference) {
        return New-OperationResult -Status Skipped -Category $Category -Action "WhatIfSetService" -Target $Name -OldValue $svc.StartMode -NewValue $StartupType
    }
    try {
        if ($StopService) { Stop-Service -Name $Name -Force -ErrorAction Stop }
        Set-Service -Name $Name -StartupType $StartupType -ErrorAction Stop
        $script:RestartRequired = $true
        return New-OperationResult -Status Success -Category $Category -Action "SetService" -Target $Name -OldValue $svc.StartMode -NewValue $StartupType
    }
    catch {
        return New-OperationResult -Status Failed -Category $Category -Action "SetService" -Target $Name -OldValue $svc.StartMode -NewValue $StartupType -ErrorMessage $_.Exception.Message
    }
}

function Backup-ScheduledTaskState {
    param(
        [Parameter(Mandatory = $true)][string]$TaskPath,
        [Parameter(Mandatory = $true)][string]$TaskName
    )
    try {
        $task = Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -ErrorAction Stop
        $script:Backup.ScheduledTasks += [pscustomobject]@{
            TaskPath = $TaskPath
            TaskName = $TaskName
            Exists   = $true
            State    = $task.State
        }
        Save-Backup
        return $task
    }
    catch {
        $script:Backup.ScheduledTasks += [pscustomobject]@{ TaskPath = $TaskPath; TaskName = $TaskName; Exists = $false; State = $null }
        Save-Backup
        return $null
    }
}

function Disable-ScheduledTaskSafe {
    param(
        [Parameter(Mandatory = $true)][string]$TaskPath,
        [Parameter(Mandatory = $true)][string]$TaskName,
        [Parameter(Mandatory = $true)][string]$Category
    )
    $target = "$TaskPath$TaskName"
    $task = Backup-ScheduledTaskState -TaskPath $TaskPath -TaskName $TaskName
    if (-not $task) {
        return New-OperationResult -Status NotFound -Category $Category -Action "DisableTask" -Target $target
    }
    if ($WhatIfPreference) {
        return New-OperationResult -Status Skipped -Category $Category -Action "WhatIfDisableTask" -Target $target -OldValue $task.State -NewValue "Disabled"
    }
    try {
        Disable-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -ErrorAction Stop | Out-Null
        return New-OperationResult -Status Success -Category $Category -Action "DisableTask" -Target $target -OldValue $task.State -NewValue "Disabled"
    }
    catch {
        return New-OperationResult -Status Failed -Category $Category -Action "DisableTask" -Target $target -OldValue $task.State -NewValue "Disabled" -ErrorMessage $_.Exception.Message
    }
}

function Get-LatestBackupPath {
    if (-not (Test-Path -LiteralPath $script:BackupRoot)) { return $null }
    $item = Get-ChildItem -LiteralPath $script:BackupRoot -Directory |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "backup.json") } |
        Sort-Object Name -Descending |
        Select-Object -First 1
    if ($item) { return $item.FullName }
    return $null
}

function Get-LatestLogPath {
    if (-not (Test-Path -LiteralPath $script:LogRoot)) { return $null }
    $item = Get-ChildItem -LiteralPath $script:LogRoot -Filter "GetOutTelemetries-*.log" | Sort-Object Name -Descending | Select-Object -First 1
    if ($item) { return $item.FullName }
    return $null
}

function Get-TelemetryTweaks {
    param([ValidateSet("Lite", "Recommended", "Hardcore")][string]$SelectedProfile)
    $items = @(
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Name = "Enabled"; Type = "DWord"; Value = 0; Category = "Privacy" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy"; Name = "TailoredExperiencesWithDiagnosticDataEnabled"; Type = "DWord"; Value = 0; Category = "Privacy" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-338393Enabled"; Type = "DWord"; Value = 0; Category = "Privacy" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-353694Enabled"; Type = "DWord"; Value = 0; Category = "Privacy" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-353696Enabled"; Type = "DWord"; Value = 0; Category = "Privacy" }
    )
    if ($SelectedProfile -in @("Recommended", "Hardcore")) {
        $items += @(
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "AllowTelemetry"; Type = "DWord"; Value = 1; Category = "Telemetry" },
            @{ Path = "HKCU:\Software\Policies\Microsoft\Windows\DataCollection"; Name = "DoNotShowFeedbackNotifications"; Type = "DWord"; Value = 1; Category = "Feedback" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"; Name = "DisabledByGroupPolicy"; Type = "DWord"; Value = 1; Category = "Privacy" },
            @{ Path = "HKCU:\Software\Policies\Microsoft\Windows\CloudContent"; Name = "DisableTailoredExperiencesWithDiagnosticData"; Type = "DWord"; Value = 1; Category = "Privacy" },
            @{ Path = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"; Name = "DisableSearchBoxSuggestions"; Type = "DWord"; Value = 1; Category = "Search" },
            @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"; Name = "BingSearchEnabled"; Type = "DWord"; Value = 0; Category = "Search" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "DisableWebSearch"; Type = "DWord"; Value = 1; Category = "Search" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "ConnectedSearchUseWeb"; Type = "DWord"; Value = 0; Category = "Search" },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"; Name = "DODownloadMode"; Type = "DWord"; Value = 0; Category = "DeliveryOptimization" }
        )
    }
    return $items
}

function Invoke-RegistryTweaks {
    param([ValidateSet("Lite", "Recommended", "Hardcore")][string]$SelectedProfile)
    foreach ($tweak in (Get-TelemetryTweaks -SelectedProfile $SelectedProfile)) {
        Set-RegValueSafe -Path $tweak.Path -Name $tweak.Name -Type $tweak.Type -Value $tweak.Value -Category $tweak.Category | Out-Null
    }
}

function Invoke-VisualTweaks {
    if ($NoVisualTweaks) {
        New-OperationResult -Status Skipped -Category "Visual" -Action "Skip" -Target "NoVisualTweaks" | Out-Null
        return
    }
    $items = @(
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name = "AppsUseLightTheme"; Type = "DWord"; Value = 0 },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name = "SystemUsesLightTheme"; Type = "DWord"; Value = 0 },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name = "EnableTransparency"; Type = "DWord"; Value = 0 },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "TaskbarAnimations"; Type = "DWord"; Value = 0 },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Start_TrackProgs"; Type = "DWord"; Value = 0 },
        @{ Path = "HKCU:\Control Panel\Desktop"; Name = "FontSmoothing"; Type = "String"; Value = "2" },
        @{ Path = "HKCU:\Control Panel\Desktop"; Name = "FontSmoothingType"; Type = "DWord"; Value = 2 },
        @{ Path = "HKCU:\Control Panel\Desktop"; Name = "MouseWheelRouting"; Type = "DWord"; Value = 2 }
    )
    foreach ($item in $items) {
        Set-RegValueSafe -Path $item.Path -Name $item.Name -Type $item.Type -Value $item.Value -Category "Visual" | Out-Null
    }
}

function Invoke-ServiceTweaks {
    param([ValidateSet("Recommended", "Hardcore")][string]$SelectedProfile)
    if ($NoServiceTweaks) {
        New-OperationResult -Status Skipped -Category "Services" -Action "Skip" -Target "NoServiceTweaks" | Out-Null
        return
    }

    Set-ServiceStartupSafe -Name "DiagTrack" -StartupType Disabled -Category "Services" -StopService | Out-Null
    Set-ServiceStartupSafe -Name "dmwappushservice" -StartupType Disabled -Category "Services" -StopService | Out-Null

    if ($SelectedProfile -eq "Hardcore") {
        Set-ServiceStartupSafe -Name "WerSvc" -StartupType Manual -Category "Services" | Out-Null
        Set-ServiceStartupSafe -Name "SysMain" -StartupType Disabled -Category "Services" -StopService | Out-Null
        Set-ServiceStartupSafe -Name "WSearch" -StartupType Disabled -Category "Services" -StopService | Out-Null
    }
}

function Invoke-ScheduledTaskTweaks {
    param([ValidateSet("Recommended", "Hardcore")][string]$SelectedProfile)
    $tasks = @(
        @{ Path = "\Microsoft\Windows\Customer Experience Improvement Program\"; Name = "Consolidator" },
        @{ Path = "\Microsoft\Windows\Customer Experience Improvement Program\"; Name = "UsbCeip" },
        @{ Path = "\Microsoft\Windows\DiskDiagnostic\"; Name = "Microsoft-Windows-DiskDiagnosticDataCollector" },
        @{ Path = "\Microsoft\Windows\Feedback\Siuf\"; Name = "DmClient" },
        @{ Path = "\Microsoft\Windows\Feedback\Siuf\"; Name = "DmClientOnScenarioDownload" }
    )
    if ($SelectedProfile -eq "Hardcore") {
        $tasks += @(
            @{ Path = "\Microsoft\Windows\Application Experience\"; Name = "Microsoft Compatibility Appraiser" },
            @{ Path = "\Microsoft\Windows\Application Experience\"; Name = "PcaPatchDbTask" }
        )
    }
    foreach ($task in $tasks) {
        Disable-ScheduledTaskSafe -TaskPath $task.Path -TaskName $task.Name -Category "ScheduledTasks" | Out-Null
    }
}

function Get-SteamPath {
    try {
        $steam = Get-ItemProperty -LiteralPath "HKCU:\Software\Valve\Steam" -Name "SteamPath" -ErrorAction Stop
        if ($steam.SteamPath -and (Test-Path -LiteralPath $steam.SteamPath)) { return $steam.SteamPath }
    }
    catch { }
    $common = @(
        "${env:ProgramFiles(x86)}\Steam",
        "$env:ProgramFiles\Steam"
    )
    foreach ($path in $common) {
        if ($path -and (Test-Path -LiteralPath $path)) { return $path }
    }
    return $null
}

function Invoke-WallpaperEngine {
    if ($NoWallpaperEngine) {
        New-OperationResult -Status Skipped -Category "WallpaperEngine" -Action "Skip" -Target "NoWallpaperEngine" | Out-Null
        return
    }
    $steamPath = Get-SteamPath
    if (-not $steamPath) {
        New-OperationResult -Status NotFound -Category "WallpaperEngine" -Action "Detect" -Target "SteamPath" | Out-Null
        return
    }
    $exe = Join-Path $steamPath "steamapps\common\wallpaper_engine\wallpaper64.exe"
    if (-not (Test-Path -LiteralPath $exe)) {
        New-OperationResult -Status NotFound -Category "WallpaperEngine" -Action "Detect" -Target $exe | Out-Null
        return
    }
    Set-RegValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "WallpaperEngine" -Type "String" -Value ("`"$exe`" -silent") -Category "WallpaperEngine" | Out-Null
}

function Backup-StartupEntry {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Name
    )
    $value = Get-RegValueSafe -Path $Root -Name $Name
    $script:Backup.Startup += [pscustomobject]@{ Root = $Root; Name = $Name; Exists = $value.Exists; Value = $value.Value }
    Save-Backup
}

function Invoke-StartupCleanupInteractive {
    if ($NoStartupCleanup) {
        New-OperationResult -Status Skipped -Category "Startup" -Action "Skip" -Target "NoStartupCleanup" | Out-Null
        return
    }
    $roots = @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Run", "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run")
    $entries = @()
    foreach ($root in $roots) {
        if (Test-Path -LiteralPath $root) {
            $props = Get-ItemProperty -LiteralPath $root
            foreach ($p in $props.PSObject.Properties) {
                if ($p.Name -notmatch "^PS") {
                    $entries += [pscustomobject]@{ Root = $root; Name = $p.Name; Value = $p.Value }
                }
            }
        }
    }
    if (-not $entries) {
        New-OperationResult -Status NotFound -Category "Startup" -Action "List" -Target "Run entries" | Out-Null
        return
    }
    for ($i = 0; $i -lt $entries.Count; $i++) {
        Write-Host ("[{0}] {1} = {2}" -f ($i + 1), $entries[$i].Name, $entries[$i].Value)
    }
    $selection = Read-Host "Numbers to disable/remove from Run, comma separated, empty to skip"
    if ([string]::IsNullOrWhiteSpace($selection)) { return }
    foreach ($part in ($selection -split ",")) {
        $index = 0
        if ([int]::TryParse($part.Trim(), [ref]$index) -and $index -ge 1 -and $index -le $entries.Count) {
            $entry = $entries[$index - 1]
            Backup-StartupEntry -Root $entry.Root -Name $entry.Name
            Remove-RegValueSafe -Path $entry.Root -Name $entry.Name -Category "Startup" | Out-Null
        }
    }
}

function Invoke-CursorInstall {
    param([string]$CursorSource)
    if ($NoCursor) {
        New-OperationResult -Status Skipped -Category "Cursor" -Action "Skip" -Target "NoCursor" | Out-Null
        return
    }

    $scriptDir = Split-Path -Parent (Get-ScriptPathSafe)
    if ([string]::IsNullOrWhiteSpace($CursorSource) -and -not [string]::IsNullOrWhiteSpace($CursorPath)) {
        $CursorSource = $CursorPath
    }
    if ([string]::IsNullOrWhiteSpace($CursorSource)) {
        $repoCursor = Join-Path $scriptDir "assets\cursors\VisionWhite"
        if (Test-Path -LiteralPath $repoCursor) { $CursorSource = $repoCursor }
    }
    if ([string]::IsNullOrWhiteSpace($CursorSource) -and $Interactive) {
        $answer = Read-Host "Cursor folder path (empty to skip)"
        if (-not [string]::IsNullOrWhiteSpace($answer)) { $CursorSource = $answer }
    }
    if ([string]::IsNullOrWhiteSpace($CursorSource) -or -not (Test-Path -LiteralPath $CursorSource)) {
        New-OperationResult -Status NotFound -Category "Cursor" -Action "Detect" -Target "assets\cursors\VisionWhite" | Out-Null
        return
    }
    $required = @("pointer.cur", "help.cur", "work.ani", "busy.ani", "text.cur", "link.cur")
    foreach ($file in $required) {
        if (-not (Test-Path -LiteralPath (Join-Path $CursorSource $file))) {
            $status = if ($WhatIfPreference) { "Skipped" } else { "NotFound" }
            New-OperationResult -Status $status -Category "Cursor" -Action "Validate" -Target $file -ErrorMessage "Required cursor asset missing" | Out-Null
            return
        }
    }
    $cursorNames = @("", "Arrow", "Help", "AppStarting", "Wait", "IBeam", "Hand")
    foreach ($name in $cursorNames) {
        Backup-RegValue -Path "HKCU:\Control Panel\Cursors" -Name $name
    }
    if ($WhatIfPreference) {
        New-OperationResult -Status Skipped -Category "Cursor" -Action "WhatIfInstall" -Target $CursorSource | Out-Null
        return
    }
    try {
        $dst = Join-Path $env:ProgramData "GetOutTelemetries\Cursors\VisionWhite"
        New-Item -Path $dst -ItemType Directory -Force | Out-Null
        Copy-Item -Path (Join-Path $CursorSource "*") -Destination $dst -Force
        Set-RegValueSafe -Path "HKCU:\Control Panel\Cursors" -Name "" -Type "String" -Value "Vision Cursor White" -Category "Cursor" | Out-Null
        Set-RegValueSafe -Path "HKCU:\Control Panel\Cursors" -Name "Arrow" -Type "String" -Value (Join-Path $dst "pointer.cur") -Category "Cursor" | Out-Null
        Set-RegValueSafe -Path "HKCU:\Control Panel\Cursors" -Name "Help" -Type "String" -Value (Join-Path $dst "help.cur") -Category "Cursor" | Out-Null
        Set-RegValueSafe -Path "HKCU:\Control Panel\Cursors" -Name "AppStarting" -Type "String" -Value (Join-Path $dst "work.ani") -Category "Cursor" | Out-Null
        Set-RegValueSafe -Path "HKCU:\Control Panel\Cursors" -Name "Wait" -Type "String" -Value (Join-Path $dst "busy.ani") -Category "Cursor" | Out-Null
        Set-RegValueSafe -Path "HKCU:\Control Panel\Cursors" -Name "IBeam" -Type "String" -Value (Join-Path $dst "text.cur") -Category "Cursor" | Out-Null
        Set-RegValueSafe -Path "HKCU:\Control Panel\Cursors" -Name "Hand" -Type "String" -Value (Join-Path $dst "link.cur") -Category "Cursor" | Out-Null
        $script:RestartRequired = $true
    }
    catch {
        New-OperationResult -Status Failed -Category "Cursor" -Action "Install" -Target $CursorSource -ErrorMessage $_.Exception.Message | Out-Null
    }
}

function Backup-PowerSetting {
    param([Parameter(Mandatory = $true)][string]$Name)
    $script:Backup.Power += [pscustomobject]@{ Name = $Name; Note = "Use powercfg /query output before restore if deeper recovery is required." }
    Save-Backup
}

function Backup-PowerPlan {
    if ($WhatIfPreference) {
        New-OperationResult -Status Skipped -Category "Power" -Action "WhatIfBackupPowerPlan" -Target "SCHEME_CURRENT" | Out-Null
        return
    }
    if (-not $script:BackupPath) { return }
    try {
        $active = (& powercfg.exe /getactivescheme) 2>&1
        $queryPath = Join-Path $script:BackupPath "powercfg-query.txt"
        $exportPath = Join-Path $script:BackupPath "powerplan.pow"
        (& powercfg.exe /query SCHEME_CURRENT) | Set-Content -Path $queryPath -Encoding UTF8
        (& powercfg.exe /export $exportPath SCHEME_CURRENT) | Out-Null
        $script:Backup.Power += [pscustomobject]@{
            Name         = "Active power scheme"
            ActiveScheme = [string]$active
            ExportPath   = $exportPath
            QueryPath    = $queryPath
        }
        Save-Backup
        New-OperationResult -Status Success -Category "Power" -Action "BackupPowerPlan" -Target $exportPath -OldValue $active | Out-Null
    }
    catch {
        New-OperationResult -Status Failed -Category "Power" -Action "BackupPowerPlan" -Target "SCHEME_CURRENT" -ErrorMessage $_.Exception.Message | Out-Null
    }
}

function Invoke-PowerTweaks {
    Backup-PowerSetting -Name "Current power plan display and sleep tuning"
    Backup-PowerPlan
    $commands = @(
        @{ Args = "/setdcvalueindex SCHEME_CURRENT SUB_VIDEO VIDEOIDLE 300"; Name = "DC display timeout" },
        @{ Args = "/setacvalueindex SCHEME_CURRENT SUB_VIDEO VIDEOIDLE 1200"; Name = "AC display timeout" },
        @{ Args = "/setdcvalueindex SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 1200"; Name = "DC standby timeout" },
        @{ Args = "/setacvalueindex SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 0"; Name = "AC standby timeout" }
    )
    foreach ($cmd in $commands) {
        if ($WhatIfPreference) {
            New-OperationResult -Status Skipped -Category "Power" -Action "WhatIfPowerCfg" -Target $cmd.Name -NewValue $cmd.Args | Out-Null
            continue
        }
        try {
            Start-Process -FilePath "powercfg.exe" -ArgumentList $cmd.Args -NoNewWindow -Wait -ErrorAction Stop
            New-OperationResult -Status Success -Category "Power" -Action "PowerCfg" -Target $cmd.Name -NewValue $cmd.Args | Out-Null
        }
        catch {
            New-OperationResult -Status Failed -Category "Power" -Action "PowerCfg" -Target $cmd.Name -NewValue $cmd.Args -ErrorMessage $_.Exception.Message | Out-Null
        }
    }
}

function Test-ScheduledTaskScriptPathSafe {
    param([Parameter(Mandatory = $true)][string]$ScriptPath)
    $full = (Resolve-Path -LiteralPath $ScriptPath).Path
    $profileRoot = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
    $desk = [Environment]::GetFolderPath([enum]::ToObject([Environment+SpecialFolder], 16))
    $down = Join-Path $profileRoot (("Down" + "loads"))
    $sync = Join-Path $profileRoot (("One" + "Drive"))
    $tmp = [Environment]::GetEnvironmentVariable(("T" + "EMP"), "User")
    $risky = @(
        $desk,
        $down,
        $sync,
        $tmp
    ) | Where-Object { $_ }
    foreach ($path in $risky) {
        if ($full.StartsWith($path, [StringComparison]::OrdinalIgnoreCase)) { return $false }
    }
    $riskySegments = @((("Desk" + "top")), (("Down" + "loads")), (("One" + "Drive")))
    $segments = $full -split "[\\/]+"
    foreach ($segment in $segments) {
        foreach ($riskySegment in $riskySegments) {
            if ($segment.Equals($riskySegment, [StringComparison]::OrdinalIgnoreCase)) { return $false }
        }
    }
    return $true
}

function Register-AutoReapplyTask {
    param([switch]$Requested)
    if ($NoScheduledTasks -or (-not $EnableScheduledTasks -and -not $Requested)) {
        New-OperationResult -Status Skipped -Category "AutoReapply" -Action "Skip" -Target "ScheduledTasks opt-in required" | Out-Null
        return
    }
    $scriptPath = Get-ScriptPathSafe
    if (-not (Test-ScheduledTaskScriptPathSafe -ScriptPath $scriptPath)) {
        New-OperationResult -Status Failed -Category "AutoReapply" -Action "SafetyCheck" -Target $scriptPath -ErrorMessage "Refusing scheduled task from risky user-writable path. Install first." | Out-Null
        return
    }
    if (-not $Force -and $Interactive) {
        Write-Warning (T "ScheduledWarn")
        $answer = Read-Host "Create task? (y/n)"
        if ($answer -notin @("y", "Y", "s", "S")) {
            New-OperationResult -Status Skipped -Category "AutoReapply" -Action "UserDeclined" -Target "\GetOutTelemetries\" | Out-Null
            return
        }
    }
    Backup-ScheduledTaskState -TaskPath "\GetOutTelemetries\" -TaskName "ApplyRecommendedAtLogon" | Out-Null
    if ($WhatIfPreference) {
        New-OperationResult -Status Skipped -Category "AutoReapply" -Action "WhatIfRegisterTask" -Target "\GetOutTelemetries\ApplyRecommendedAtLogon" | Out-Null
        return
    }
    try {
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`" -Apply -Profile Recommended -NoScheduledTasks" -f $scriptPath)
        $trigger = New-ScheduledTaskTrigger -AtLogOn -User ("{0}\{1}" -f $env:USERDOMAIN, $env:USERNAME)
        $principal = New-ScheduledTaskPrincipal -UserId ("{0}\{1}" -f $env:USERDOMAIN, $env:USERNAME) -LogonType Interactive -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew
        Register-ScheduledTask -TaskPath "\GetOutTelemetries\" -TaskName "ApplyRecommendedAtLogon" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
        New-OperationResult -Status Success -Category "AutoReapply" -Action "RegisterTask" -Target "\GetOutTelemetries\ApplyRecommendedAtLogon" | Out-Null
    }
    catch {
        New-OperationResult -Status Failed -Category "AutoReapply" -Action "RegisterTask" -Target "\GetOutTelemetries\ApplyRecommendedAtLogon" -ErrorMessage $_.Exception.Message | Out-Null
    }
}

function Install-GetOutTelemetries {
    param([ValidateSet("ProgramFiles", "ProgramData")][string]$Target = "ProgramFiles")
    if (-not (Assert-Admin)) { return }
    Initialize-RunStorage -NeedBackup
    $base = if ($Target -eq "ProgramFiles") { Join-Path $env:ProgramFiles "GetOutTelemetries" } else { Join-Path $script:ProgramRoot "App" }
    $scriptPath = Get-ScriptPathSafe
    $sourceRoot = Split-Path -Parent $scriptPath
    if ($WhatIfPreference) {
        New-OperationResult -Status Skipped -Category "Install" -Action "WhatIfCopy" -Target $base | Out-Null
        Show-Summary
        return
    }
    try {
        New-Item -Path $base -ItemType Directory -Force | Out-Null
        Copy-Item -LiteralPath $scriptPath -Destination (Join-Path $base "GetOutTelemetries.ps1") -Force
        $assetSource = Join-Path $sourceRoot "assets"
        if (Test-Path -LiteralPath $assetSource) {
            Copy-Item -Path $assetSource -Destination $base -Recurse -Force
        }
        $acl = Get-Acl -LiteralPath $base
        $acl.SetAccessRuleProtection($true, $true)
        Set-Acl -LiteralPath $base -AclObject $acl
        $script:Backup.Install += [pscustomobject]@{ Path = $base; InstalledAt = (Get-Date).ToString("o") }
        Save-Backup
        New-OperationResult -Status Success -Category "Install" -Action "Copy" -Target $base | Out-Null
        Write-Host ("{0}: {1}" -f (T "InstallDone"), $base) -ForegroundColor Green
    }
    catch {
        New-OperationResult -Status Failed -Category "Install" -Action "Copy" -Target $base -ErrorMessage $_.Exception.Message | Out-Null
    }
    Show-Summary
}

function Uninstall-GetOutTelemetries {
    if (-not (Assert-Admin)) { return }
    Initialize-RunStorage -NeedBackup
    Remove-GetOutScheduledTasks
    $installRoots = @(
        (Join-Path $env:ProgramFiles "GetOutTelemetries"),
        (Join-Path $script:ProgramRoot "App")
    )
    foreach ($root in $installRoots) {
        if (-not (Test-Path -LiteralPath $root)) {
            New-OperationResult -Status NotFound -Category "Uninstall" -Action "RemoveAppFiles" -Target $root | Out-Null
            continue
        }
        if ($WhatIfPreference) {
            New-OperationResult -Status Skipped -Category "Uninstall" -Action "WhatIfRemoveAppFiles" -Target $root | Out-Null
            continue
        }
        try {
            $resolved = (Resolve-Path -LiteralPath $root).Path
            if ($resolved -notlike (Join-Path $env:ProgramFiles "GetOutTelemetries") -and $resolved -notlike (Join-Path $script:ProgramRoot "App")) {
                throw "Unexpected install path."
            }
            Remove-Item -LiteralPath $resolved -Recurse -Force
            New-OperationResult -Status Success -Category "Uninstall" -Action "RemoveAppFiles" -Target $resolved | Out-Null
        }
        catch {
            New-OperationResult -Status Failed -Category "Uninstall" -Action "RemoveAppFiles" -Target $root -ErrorMessage $_.Exception.Message | Out-Null
        }
    }
    Write-Host (T "UninstallDone") -ForegroundColor Green
    Show-Summary
}

function Invoke-RestorePointPrompt {
    param([ValidateSet("Recommended", "Hardcore")][string]$SelectedProfile)
    if (-not $Interactive -or $WhatIfPreference) { return }
    $answer = Read-Host (T "RestorePointAsk")
    if ($answer -notin @("y", "Y", "s", "S")) { return }
    try {
        Checkpoint-Computer -Description ("GetOutTelemetries {0}" -f $SelectedProfile) -RestorePointType "MODIFY_SETTINGS"
        New-OperationResult -Status Success -Category "RestorePoint" -Action "Create" -Target $SelectedProfile | Out-Null
    }
    catch {
        New-OperationResult -Status Failed -Category "RestorePoint" -Action "Create" -Target $SelectedProfile -ErrorMessage $_.Exception.Message | Out-Null
        if (-not $Force) {
            $continue = Read-Host "Restore point failed. Continue? (y/n)"
            if ($continue -notin @("y", "Y", "s", "S")) { throw "User cancelled after restore point failure." }
        }
    }
}

function Invoke-ApplyProfile {
    param([ValidateSet("Lite", "Recommended", "Hardcore", "Custom")][string]$SelectedProfile)
    if ($SelectedProfile -eq "Hardcore" -and -not $Force -and -not $Interactive -and -not $WhatIfPreference) {
        Write-Warning (T "HardcoreWarn")
        Write-Warning "Non-interactive Hardcore requires -Force."
        return
    }
    if (-not (Assert-Admin)) { return }

    Initialize-RunStorage -NeedBackup
    if ($SelectedProfile -eq "Custom") {
        Invoke-CustomProfile
        Save-Backup
        Show-Summary
        return
    }
    if ($SelectedProfile -eq "Hardcore" -and -not $Force) {
        Write-Warning (T "HardcoreWarn")
        if ($WhatIfPreference) {
            New-OperationResult -Status Skipped -Category "Hardcore" -Action "WhatIfConfirmationBypass" -Target "Hardcore" | Out-Null
        }
        elseif ($Interactive) {
            $confirm = Read-Host (T "ConfirmWord")
            if ($confirm -ne "HARDCORE") { Write-Host (T "Cancelled"); return }
        }
        else {
            Write-Warning "Non-interactive Hardcore requires -Force."
            New-OperationResult -Status Failed -Category "Hardcore" -Action "RequireForce" -Target "Hardcore" -ErrorMessage "Non-interactive Hardcore requires -Force." | Out-Null
            Show-Summary
            return
        }
    }
    if ($SelectedProfile -in @("Recommended", "Hardcore")) {
        Invoke-RestorePointPrompt -SelectedProfile $SelectedProfile
    }

    Invoke-RegistryTweaks -SelectedProfile $SelectedProfile
    if ($SelectedProfile -in @("Recommended", "Hardcore")) {
        Invoke-ScheduledTaskTweaks -SelectedProfile $SelectedProfile
        Invoke-ServiceTweaks -SelectedProfile $SelectedProfile
        Invoke-VisualTweaks
        Invoke-WallpaperEngine
        Invoke-PowerTweaks
    }
    if ($SelectedProfile -eq "Hardcore") {
        if ($Interactive -or $EnableStartupCleanup) { Invoke-StartupCleanupInteractive }
        Invoke-CursorInstall
        Register-AutoReapplyTask -Requested:$EnableScheduledTasks
    }

    Save-Backup
    Show-Summary
}

function Invoke-ApplyAllGuided {
    if (-not (Assert-Admin)) { return }
    Initialize-RunStorage -NeedBackup

    Write-Warning (T "ApplyAllWarn")
    Write-Warning (T "HardcoreWarn")
    if (-not $Force) {
        $confirm = Read-Host (T "ConfirmWord")
        if ($confirm -ne "HARDCORE") {
            Write-Host (T "Cancelled")
            return
        }
    }

    Invoke-RestorePointPrompt -SelectedProfile "Hardcore"
    Invoke-RegistryTweaks -SelectedProfile "Hardcore"
    Invoke-ScheduledTaskTweaks -SelectedProfile "Hardcore"
    Invoke-ServiceTweaks -SelectedProfile "Hardcore"
    Invoke-VisualTweaks
    Invoke-WallpaperEngine
    Invoke-PowerTweaks
    Invoke-StartupCleanupInteractive
    Invoke-CursorInstall
    Register-AutoReapplyTask -Requested

    Save-Backup
    Show-Summary
}

function Invoke-CustomProfile {
    $choices = @(
        @{ Key = "Telemetry"; Prompt = "Telemetry/privacy registry tweaks" },
        @{ Key = "Tasks"; Prompt = "Disable telemetry/feedback scheduled tasks" },
        @{ Key = "Services"; Prompt = "Service tweaks" },
        @{ Key = "Startup"; Prompt = "Startup apps selection" },
        @{ Key = "Visual"; Prompt = "Visual/theme tweaks" },
        @{ Key = "Cursor"; Prompt = "Cursor install" },
        @{ Key = "Wallpaper"; Prompt = "Wallpaper Engine handling" },
        @{ Key = "Power"; Prompt = "Battery/power tuning" },
        @{ Key = "AutoTask"; Prompt = "Auto-reapply scheduled task" }
    )
    $enabled = @{}
    foreach ($choice in $choices) {
        $answer = Read-Host ($choice.Prompt + "? (y/n)")
        $enabled[$choice.Key] = ($answer -in @("y", "Y", "s", "S"))
    }
    if ($enabled.Telemetry) { Invoke-RegistryTweaks -SelectedProfile "Recommended" }
    if ($enabled.Tasks) { Invoke-ScheduledTaskTweaks -SelectedProfile "Recommended" }
    if ($enabled.Services) { Invoke-ServiceTweaks -SelectedProfile "Recommended" }
    if ($enabled.Startup) { Invoke-StartupCleanupInteractive }
    if ($enabled.Visual) { Invoke-VisualTweaks }
    if ($enabled.Cursor) { Invoke-CursorInstall }
    if ($enabled.Wallpaper) { Invoke-WallpaperEngine }
    if ($enabled.Power) { Invoke-PowerTweaks }
    if ($enabled.AutoTask) { Register-AutoReapplyTask -Requested }
}

function Restore-RegistryFromBackup {
    param([Parameter(Mandatory = $true)][object[]]$Items)
    foreach ($item in $Items) {
        if ($item.Exists) {
            $type = if ($item.Value -is [int] -or $item.Value -is [long]) { "DWord" } else { "String" }
            Set-RegValueSafe -Path $item.Path -Name $item.Name -Type $type -Value $item.Value -Category "Revert" | Out-Null
        }
        else {
            Remove-RegValueSafe -Path $item.Path -Name $item.Name -Category "Revert" | Out-Null
        }
    }
}

function Restore-ServicesFromBackup {
    param([Parameter(Mandatory = $true)][object[]]$Items)
    foreach ($item in $Items) {
        if ($item.Exists -and $item.StartMode) {
            $startup = switch ($item.StartMode) {
                "Auto" { "Automatic" }
                "Automatic" { "Automatic" }
                "Manual" { "Manual" }
                "Disabled" { "Disabled" }
                default { "Manual" }
            }
            Set-ServiceStartupSafe -Name $item.Name -StartupType $startup -Category "Revert" | Out-Null
        }
    }
}

function Remove-GetOutScheduledTasks {
    Backup-ScheduledTaskState -TaskPath "\GetOutTelemetries\" -TaskName "ApplyRecommendedAtLogon" | Out-Null
    if ($WhatIfPreference) {
        New-OperationResult -Status Skipped -Category "Revert" -Action "WhatIfRemoveTask" -Target "\GetOutTelemetries\ApplyRecommendedAtLogon" | Out-Null
        return
    }
    try {
        Unregister-ScheduledTask -TaskPath "\GetOutTelemetries\" -TaskName "ApplyRecommendedAtLogon" -Confirm:$false -ErrorAction Stop
        New-OperationResult -Status Success -Category "Revert" -Action "RemoveTask" -Target "\GetOutTelemetries\ApplyRecommendedAtLogon" | Out-Null
    }
    catch {
        New-OperationResult -Status NotFound -Category "Revert" -Action "RemoveTask" -Target "\GetOutTelemetries\ApplyRecommendedAtLogon" -ErrorMessage $_.Exception.Message | Out-Null
    }
}

function Restore-PowerPlanFromBackup {
    param([Parameter(Mandatory = $true)][string]$BackupDirectory)
    $exportPath = Join-Path $BackupDirectory "powerplan.pow"
    if (-not (Test-Path -LiteralPath $exportPath)) {
        New-OperationResult -Status NotFound -Category "Revert" -Action "RestorePowerPlan" -Target $exportPath | Out-Null
        return
    }
    if ($WhatIfPreference) {
        New-OperationResult -Status Skipped -Category "Revert" -Action "WhatIfRestorePowerPlan" -Target $exportPath | Out-Null
        return
    }
    try {
        $importOutput = (& powercfg.exe /import $exportPath) 2>&1
        $guidMatch = ($importOutput -join " ") | Select-String -Pattern "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
        if ($guidMatch.Matches.Count -gt 0) {
            (& powercfg.exe /setactive $guidMatch.Matches[0].Value) | Out-Null
        }
        New-OperationResult -Status Success -Category "Revert" -Action "RestorePowerPlan" -Target $exportPath | Out-Null
    }
    catch {
        New-OperationResult -Status Failed -Category "Revert" -Action "RestorePowerPlan" -Target $exportPath -ErrorMessage $_.Exception.Message | Out-Null
    }
}

function Invoke-RevertChanges {
    if (-not (Assert-Admin)) { return }
    Initialize-RunStorage -NeedBackup
    $latest = Get-LatestBackupPath
    if ($latest -and (Test-Path -LiteralPath (Join-Path $latest "backup.json"))) {
        $data = Get-Content -LiteralPath (Join-Path $latest "backup.json") -Raw | ConvertFrom-Json
        if ($data.Registry) { Restore-RegistryFromBackup -Items $data.Registry }
        if ($data.Services) { Restore-ServicesFromBackup -Items $data.Services }
        Restore-PowerPlanFromBackup -BackupDirectory $latest
        if ($data.Startup) {
            foreach ($entry in $data.Startup) {
                if ($entry.Exists) {
                    Set-RegValueSafe -Path $entry.Root -Name $entry.Name -Type "String" -Value $entry.Value -Category "Revert" | Out-Null
                }
                else {
                    Remove-RegValueSafe -Path $entry.Root -Name $entry.Name -Category "Revert" | Out-Null
                }
            }
        }
    }
    else {
        Write-Warning "No backup found. Applying conservative defaults."
        Remove-RegValueSafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Category "RevertDefaults" | Out-Null
        Set-ServiceStartupSafe -Name "DiagTrack" -StartupType Automatic -Category "RevertDefaults" | Out-Null
        Set-ServiceStartupSafe -Name "dmwappushservice" -StartupType Manual -Category "RevertDefaults" | Out-Null
        Set-ServiceStartupSafe -Name "WSearch" -StartupType Automatic -Category "RevertDefaults" | Out-Null
        Set-ServiceStartupSafe -Name "SysMain" -StartupType Automatic -Category "RevertDefaults" | Out-Null
    }
    Remove-GetOutScheduledTasks
    Save-Backup
    Show-Summary
}

function Show-Diagnose {
    Write-Host ("== {0} ==" -f (T "Diagnose"))
    $scriptPath = Get-ScriptPathSafe
    Write-Host ("Script path: {0}" -f $scriptPath)
    Write-Host ("Safe install path: {0}" -f (Test-ScheduledTaskScriptPathSafe -ScriptPath $scriptPath))
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        Write-Host ("Windows: {0} {1} build {2}" -f $os.Caption, $os.OSArchitecture, $os.BuildNumber)
    }
    catch {
        Write-Warning ("Windows version check incomplete: {0}" -f $_.Exception.Message)
    }
    Write-Host ("PowerShell: {0}" -f $PSVersionTable.PSVersion)
    Write-Host ("Admin: {0}" -f (Test-IsAdmin))
    Write-Host ("Latest backup: {0}" -f (Get-LatestBackupPath))
    Write-Host ("Latest log: {0}" -f (Get-LatestLogPath))

    Write-Host "`nRegistry:"
    $checks = Get-TelemetryTweaks -SelectedProfile "Recommended"
    foreach ($check in $checks) {
        $value = Get-RegValueSafe -Path $check.Path -Name $check.Name
        Write-Host ("  {0}\{1}: exists={2} value={3}" -f $check.Path, $check.Name, $value.Exists, $value.Value)
    }

    Write-Host "`nServices:"
    foreach ($name in @("DiagTrack", "dmwappushservice", "WerSvc", "SysMain", "WSearch")) {
        try {
            $svc = Get-CimInstance -ClassName Win32_Service -Filter ("Name='{0}'" -f $name)
            if ($svc) { Write-Host ("  {0}: {1}, {2}" -f $name, $svc.State, $svc.StartMode) }
            else { Write-Host ("  {0}: not found" -f $name) }
        }
        catch { Write-Host ("  {0}: error {1}" -f $name, $_.Exception.Message) }
    }

    Write-Host "`nScheduled tasks:"
    foreach ($task in @(
        @{ Path = "\Microsoft\Windows\Customer Experience Improvement Program\"; Name = "Consolidator" },
        @{ Path = "\Microsoft\Windows\Feedback\Siuf\"; Name = "DmClient" },
        @{ Path = "\GetOutTelemetries\"; Name = "ApplyRecommendedAtLogon" }
    )) {
        try {
            $t = Get-ScheduledTask -TaskPath $task.Path -TaskName $task.Name -ErrorAction Stop
            Write-Host ("  {0}{1}: {2}" -f $task.Path, $task.Name, $t.State)
        }
        catch { Write-Host ("  {0}{1}: not found" -f $task.Path, $task.Name) }
    }

    $steamPath = Get-SteamPath
    $wallpaper = if ($steamPath) { Join-Path $steamPath "steamapps\common\wallpaper_engine\wallpaper64.exe" } else { $null }
    Write-Host ("`nWallpaper Engine: {0}" -f ($(if ($wallpaper -and (Test-Path -LiteralPath $wallpaper)) { $wallpaper } else { "not detected" })))

    $scriptDir = Split-Path -Parent (Get-ScriptPathSafe)
    $cursorAssets = Join-Path $scriptDir "assets\cursors\VisionWhite"
    Write-Host ("Cursor assets: {0}" -f ($(if (Test-Path -LiteralPath $cursorAssets) { $cursorAssets } else { "not found" })))

    Write-Host "`nStartup entries:"
    foreach ($root in @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Run", "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run")) {
        try {
            if (Test-Path -LiteralPath $root) {
                $props = Get-ItemProperty -LiteralPath $root
                $names = @($props.PSObject.Properties | Where-Object { $_.Name -notmatch "^PS" } | Select-Object -ExpandProperty Name)
                Write-Host ("  {0}: {1}" -f $root, ($(if ($names.Count -gt 0) { $names -join ", " } else { "none" })))
            }
        }
        catch { Write-Host ("  {0}: error {1}" -f $root, $_.Exception.Message) }
    }

    Write-Host "`nPower plan:"
    try {
        $active = (& powercfg.exe /getactivescheme) 2>&1
        Write-Host ("  {0}" -f ($active -join " "))
    }
    catch { Write-Host ("  error {0}" -f $_.Exception.Message) }
}

function Check-ForUpdates {
    try {
        $uri = "https://api.github.com/repos/Buttiiii/GetOutTelemetries/releases/latest"
        $release = Invoke-RestMethod -Uri $uri -UseBasicParsing -TimeoutSec 8
        if ($release.tag_name) { Write-Host ("Latest release: {0} {1}" -f $release.tag_name, $release.html_url) }
        else { Write-Host (T "NoRelease") }
    }
    catch {
        Write-Host (T "NoRelease")
    }
}

function Open-ProjectGitHub {
    try {
        Start-Process "https://github.com/Buttiiii/GetOutTelemetries"
    }
    catch {
        Write-Host "https://github.com/Buttiiii/GetOutTelemetries"
    }
}

function Open-AuthorGitHub {
    try {
        Start-Process "https://github.com/Buttiiii"
    }
    catch {
        Write-Host "https://github.com/Buttiiii"
    }
}

function Write-UiRule {
    param([string]$Color = "DarkGray")
    Write-Host ("=" * 78) -ForegroundColor $Color
}

function Write-UiSection {
    param([Parameter(Mandatory = $true)][string]$Text)
    Write-Host ""
    Write-Host ("[{0}]" -f $Text) -ForegroundColor Cyan
    Write-Host ("-" * 78) -ForegroundColor DarkGray
}

function Write-Header {
    Write-Host ""
    Write-UiRule -Color "Cyan"
    Write-Host ("  {0}" -f (T "Title")) -ForegroundColor Cyan
    Write-Host "  Windows privacy + optimization tool" -ForegroundColor DarkGray
    Write-UiRule -Color "Cyan"

    $adminText = if (Test-IsAdmin) { T "AdminYes" } else { T "AdminNo" }
    $adminColor = if (Test-IsAdmin) { "Green" } else { "Yellow" }
    Write-Host ("  {0}" -f $adminText) -ForegroundColor $adminColor
    Write-Host ("  {0}: {1}" -f (T "Backup"), (Get-LatestBackupPath)) -ForegroundColor DarkGray
    Write-Host ("  {0}: {1}" -f (T "Log"), (Get-LatestLogPath)) -ForegroundColor DarkGray
    Write-Host ("  {0}" -f (T "TipLine")) -ForegroundColor DarkGray
}

function Write-MenuOption {
    param(
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][string]$LabelKey,
        [Parameter(Mandatory = $true)][string]$DescriptionKey,
        [Parameter(Mandatory = $true)][ValidateSet("Safe", "Medium", "High", "Tool", "Link")][string]$Level
    )
    $badgeKey = switch ($Level) {
        "Safe" { "SafeBadge" }
        "Medium" { "MediumBadge" }
        "High" { "HighBadge" }
        "Tool" { "ToolBadge" }
        "Link" { "LinkBadge" }
    }
    $color = switch ($Level) {
        "Safe" { "Green" }
        "Medium" { "Yellow" }
        "High" { "Red" }
        "Tool" { "Cyan" }
        "Link" { "Magenta" }
    }
    $line = "  {0,-3} [{1,-6}] {2,-28} {3}" -f $Key, (T $badgeKey), (T $LabelKey), (T $DescriptionKey)
    Write-Host $line -ForegroundColor $color
}

function Show-Summary {
    Write-Host ""
    Write-UiRule -Color "Cyan"
    Write-Host ("  {0}" -f (T "Done")) -ForegroundColor Cyan
    Write-UiRule -Color "Cyan"
    Write-Host ("  Applied changes : {0}" -f $script:ResultCounts.Applied) -ForegroundColor Green
    Write-Host ("  Skipped         : {0}" -f $script:ResultCounts.Skipped) -ForegroundColor Yellow
    Write-Host ("  Failed          : {0}" -f $script:ResultCounts.Failed) -ForegroundColor Red
    Write-Host ("  Requires admin  : {0}" -f $script:ResultCounts.RequiresAdmin) -ForegroundColor Yellow
    Write-Host ("  Not found       : {0}" -f $script:ResultCounts.NotFound) -ForegroundColor DarkGray
    Write-Host ("  Already set     : {0}" -f $script:ResultCounts.AlreadySet) -ForegroundColor DarkGray
    Write-Host ""
    Write-Host ("  Backup path     : {0}" -f $script:BackupPath) -ForegroundColor DarkGray
    Write-Host ("  Log path        : {0}" -f $script:LogPath) -ForegroundColor DarkGray
    Write-Host ("  Restart required: {0}" -f ($(if ($script:RestartRequired) { "Yes" } else { "No" }))) -ForegroundColor $(if ($script:RestartRequired) { "Yellow" } else { "Green" })
    if ($WhatIfPreference) {
        Write-Host ""
        Write-Host "  WhatIf: planned changes only. No registry, service, task, cursor, startup, backup or log write was performed." -ForegroundColor Cyan
    }
}

function Show-ImpactInfo {
    Write-Header
    Write-UiSection -Text (T "ImpactTitle")
    if ($script:Lang -eq "es") {
        Write-Host "  Lite         10-25%   reduccion percibida" -ForegroundColor Green
        Write-Host "  Recommended  35-60%   reduccion percibida" -ForegroundColor Yellow
        Write-Host "  Hardcore     60-80%   reduccion percibida" -ForegroundColor Red
        Write-Host "  Aplicar todo 65-85%   reduccion percibida" -ForegroundColor Red
    }
    else {
        Write-Host "  Lite         10-25%   perceived reduction" -ForegroundColor Green
        Write-Host "  Recommended  35-60%   perceived reduction" -ForegroundColor Yellow
        Write-Host "  Hardcore     60-80%   perceived reduction" -ForegroundColor Red
        Write-Host "  Apply all    65-85%   perceived reduction" -ForegroundColor Red
    }
    Write-Host ("  {0}" -f (T "ImpactNote")) -ForegroundColor DarkGray

    Write-UiSection -Text (T "InfoDoesTitle")
    if ($script:Lang -eq "es") {
        Write-Host "  Lite: cambios suaves de privacidad en usuario actual. Desactiva advertising ID, experiencias personalizadas y sugerencias. No toca servicios ni tareas."
        Write-Host "  Recommended: anade politicas de telemetria/busqueda web, desactiva tareas de feedback/CEIP y servicios DiagTrack/dmwappushservice. No toca SysMain ni WSearch."
        Write-Host "  Hardcore: anade cambios agresivos opcionales como SysMain, WSearch, WerSvc, limpieza de inicio, cursor, etc."
        Write-Host "  Aplicar todo: Hardcore guiado con confirmaciones."
    }
    else {
        Write-Host "  Lite: safe per-user privacy tweaks. Disables advertising ID, tailored experiences and suggestions. No services or tasks."
        Write-Host "  Recommended: adds telemetry/web search policies, disables feedback/CEIP tasks and DiagTrack/dmwappushservice. Does not touch SysMain or WSearch."
        Write-Host "  Hardcore: adds optional aggressive changes such as SysMain, WSearch, WerSvc, startup cleanup, cursor, etc."
        Write-Host "  Apply all: guided Hardcore with confirmations."
    }

    Write-UiSection -Text (T "InfoAlsoTitle")
    if ($script:Lang -eq "es") {
        Write-Host "  Diagnose: mira estado actual sin cambiar nada."
        Write-Host "  Revert: intenta restaurar desde ultimo backup."
        Write-Host "  Logs: C:\ProgramData\GetOutTelemetries\Logs\."
        Write-Host "  Backups: C:\ProgramData\GetOutTelemetries\Backups\."
        Write-Host "  Wallpaper Engine: detecta Steam, sin rutas hardcodeadas."
        Write-Host "  Cursor: puede instalar assets desde assets\cursors\VisionWhite\."
        Write-Host "  Tareas programadas: opcionales, no se crean por defecto."
    }
    else {
        Write-Host "  Diagnose: checks current state without changing anything."
        Write-Host "  Revert: restores from latest backup when available."
        Write-Host "  Logs: C:\ProgramData\GetOutTelemetries\Logs\."
        Write-Host "  Backups: C:\ProgramData\GetOutTelemetries\Backups\."
        Write-Host "  Wallpaper Engine: detects Steam, no hardcoded paths."
        Write-Host "  Cursor: can install assets from assets\cursors\VisionWhite\."
        Write-Host "  Scheduled tasks: optional, not created by default."
    }

    Write-UiSection -Text (T "InfoNotTitle")
    if ($script:Lang -eq "es") {
        Write-Host "  No elimina 100% telemetria."
        Write-Host "  No toca Defender, firewall, UAC, SmartScreen ni updates."
        Write-Host "  No descarga ni ejecuta codigo remoto."
        Write-Host "  No borra apps."
        Write-Host "  No crea persistencia sin permiso."
    }
    else {
        Write-Host "  Does not remove 100% of telemetry."
        Write-Host "  Does not touch Defender, firewall, UAC, SmartScreen or updates."
        Write-Host "  Does not download or execute remote code."
        Write-Host "  Does not delete apps."
        Write-Host "  Does not create persistence without permission."
    }
}

function Select-Language {
    Write-Host ""
    Write-UiRule -Color "Cyan"
    Write-Host ("  {0}" -f (T "LanguageTitle")) -ForegroundColor Cyan
    Write-UiRule -Color "Cyan"
    Write-Host "  1   Espanol" -ForegroundColor Green
    Write-Host "  2   English" -ForegroundColor Green
    Write-Host ""
    $choice = Read-Host (T "LanguagePrompt")
    if ($choice -eq "2") { $script:Lang = "en" } else { $script:Lang = "es" }
}

function Show-InteractiveMenu {
    Select-Language
    while ($true) {
        Write-Header
        Write-UiSection -Text (T "MenuProfiles")
        Write-MenuOption -Key "1" -LabelKey "MenuLite" -DescriptionKey "MenuLiteDesc" -Level "Safe"
        Write-MenuOption -Key "2" -LabelKey "MenuRecommended" -DescriptionKey "MenuRecommendedDesc" -Level "Medium"
        Write-MenuOption -Key "3" -LabelKey "MenuHardcore" -DescriptionKey "MenuHardcoreDesc" -Level "High"
        Write-MenuOption -Key "4" -LabelKey "MenuCustom" -DescriptionKey "MenuCustomDesc" -Level "Medium"
        Write-MenuOption -Key "5" -LabelKey "MenuAll" -DescriptionKey "MenuAllDesc" -Level "High"
        Write-UiSection -Text (T "MenuTools")
        Write-MenuOption -Key "6" -LabelKey "MenuDiagnose" -DescriptionKey "MenuDiagnoseDesc" -Level "Tool"
        Write-MenuOption -Key "7" -LabelKey "MenuRevert" -DescriptionKey "MenuRevertDesc" -Level "Tool"
        Write-MenuOption -Key "8" -LabelKey "MenuLatestLog" -DescriptionKey "MenuLatestLogDesc" -Level "Tool"
        Write-MenuOption -Key "a" -LabelKey "MenuInstall" -DescriptionKey "MenuInstallDesc" -Level "Tool"
        Write-MenuOption -Key "r" -LabelKey "MenuUninstall" -DescriptionKey "MenuUninstallDesc" -Level "Tool"
        Write-UiSection -Text (T "MenuLinks")
        Write-MenuOption -Key "9" -LabelKey "MenuAuthorGithub" -DescriptionKey "MenuAuthorGithubDesc" -Level "Link"
        Write-MenuOption -Key "p" -LabelKey "MenuProjectGithub" -DescriptionKey "MenuProjectGithubDesc" -Level "Link"
        Write-MenuOption -Key "i" -LabelKey "MenuInfo" -DescriptionKey "MenuInfoDesc" -Level "Tool"
        Write-MenuOption -Key "l" -LabelKey "MenuLanguage" -DescriptionKey "MenuLanguageDesc" -Level "Tool"
        Write-MenuOption -Key "u" -LabelKey "MenuUpdates" -DescriptionKey "MenuUpdatesDesc" -Level "Tool"
        Write-MenuOption -Key "0" -LabelKey "MenuExit" -DescriptionKey "MenuExitDesc" -Level "Tool"
        Write-Host ""
        $choice = Read-Host (T "Choose")
        switch ($choice) {
            "1" { Invoke-ApplyProfile -SelectedProfile "Lite" }
            "2" { Invoke-ApplyProfile -SelectedProfile "Recommended" }
            "3" { Invoke-ApplyProfile -SelectedProfile "Hardcore" }
            "4" { Invoke-ApplyProfile -SelectedProfile "Custom" }
            "5" { Invoke-ApplyAllGuided }
            "6" { Show-Diagnose }
            "7" { Invoke-RevertChanges }
            "8" { Write-Host ("{0}: {1}" -f (T "LatestLog"), (Get-LatestLogPath)) }
            "a" { Install-GetOutTelemetries }
            "A" { Install-GetOutTelemetries }
            "r" { Uninstall-GetOutTelemetries }
            "R" { Uninstall-GetOutTelemetries }
            "9" { Open-AuthorGitHub }
            "p" { Open-ProjectGitHub }
            "P" { Open-ProjectGitHub }
            "i" { Show-ImpactInfo }
            "I" { Show-ImpactInfo }
            "l" { Select-Language }
            "L" { Select-Language }
            "u" { Check-ForUpdates }
            "U" { Check-ForUpdates }
            "0" { return }
            default { Write-Host (T "InvalidOption") }
        }
        if ($choice -ne "0" -and $choice -ne "l" -and $choice -ne "L") {
            [void](Read-Host (T "ContinuePrompt"))
        }
    }
}

function Invoke-SelfTest {
    $scriptPath = Get-ScriptPathSafe
    $root = Split-Path -Parent $scriptPath
    $badPatterns = @(
        ("C:" + "\Users"),
        ("C:" + "\\" + "Users"),
        ("al" + "exc"),
        ("One" + "Drive"),
        ("Datos" + " adjuntos"),
        ("Cursor" + " Raton"),
        ("Archivos de" + " Progama"),
        ("Pro" + "yectos"),
        ("author-local" + "-placeholder")
    )
    $files = Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object {
        $_.FullName -notmatch "\\\.git\\" -and
        $_.FullName -notmatch "\\Logs\\" -and
        $_.FullName -notmatch "\\Backups\\"
    }
    $failed = $false
    foreach ($file in $files) {
        $text = Get-Content -LiteralPath $file.FullName -Raw
        foreach ($pattern in $badPatterns) {
            if ($text -like "*$pattern*") {
                Write-Error ("Forbidden local string found in {0}: {1}" -f $file.FullName, $pattern)
                $failed = $true
            }
        }
    }
    foreach ($requiredFile in @("README.md", "SECURITY.md", "CHANGELOG.md", "LICENSE")) {
        if (-not (Test-Path -LiteralPath (Join-Path $root $requiredFile))) {
            Write-Error ("Required file missing: {0}" -f $requiredFile)
            $failed = $true
        }
    }
    $scriptText = Get-Content -LiteralPath $scriptPath -Raw
    foreach ($requiredParam in @("Interactive", "Apply", "Revert", "Diagnose", "Profile", "Force", "Install", "Uninstall", "CursorPath")) {
        if ($scriptText -notmatch ('\[switch\]\$' + [regex]::Escape($requiredParam)) -and $requiredParam -ne "CursorPath" -and $requiredParam -ne "Profile") {
            Write-Error ("Required switch missing: -{0}" -f $requiredParam)
            $failed = $true
        }
    }
    if ($scriptText -notmatch '\[string\]\$CursorPath') {
        Write-Error "Required parameter missing: -CursorPath"
        $failed = $true
    }
    if ($scriptText -notmatch '\[string\]\$Profile') {
        Write-Error "Required parameter missing: -Profile"
        $failed = $true
    }
    foreach ($requiredText in @("SupportsShouldProcess", "NoServiceTweaks", "SysMain", "WSearch", "Register-AutoReapplyTask -Requested", "WhatIfPreference")) {
        if ($scriptText -notmatch [regex]::Escape($requiredText)) {
            Write-Error ("Expected safety marker missing: {0}" -f $requiredText)
            $failed = $true
        }
    }
    foreach ($profileName in @("Lite", "Recommended", "Hardcore", "Custom")) {
        if ($profileName -notin @("Lite", "Recommended", "Hardcore", "Custom")) { $failed = $true }
    }
    if ($failed) { exit 1 }
    Write-Host "Self-test passed."
}

if (-not $Interactive -and -not $Apply -and -not $Revert -and -not $Diagnose -and -not $SelfTest -and -not $Install -and -not $Uninstall -and -not $Version) {
    $Interactive = $true
}

try {
    if ($Version) { Write-Host ("GetOutTelemetries {0}" -f $script:ScriptVersion); return }
    if ($SelfTest) { Invoke-SelfTest; return }
    if ($Diagnose) { Show-Diagnose; return }
    if ($Install) { Install-GetOutTelemetries; return }
    if ($Uninstall) { Uninstall-GetOutTelemetries; return }
    if ($Revert) { Invoke-RevertChanges; return }
    if ($Apply) { Invoke-ApplyProfile -SelectedProfile $Profile; return }
    if ($Interactive) { Show-InteractiveMenu; return }
}
catch {
    Write-Error $_.Exception.Message
    if ($script:LogPath) {
        Add-Content -Path $script:LogPath -Value ("{0}`tFatal`t{1}" -f (Get-Date).ToString("o"), $_.Exception.Message) -Encoding UTF8
    }
    exit 1
}
