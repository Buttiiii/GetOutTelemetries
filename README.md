# GetOutTelemetries

Windows 10/11 privacy and optimization helper by Buttiiii.

GetOutTelemetries reduces optional diagnostic, telemetry, feedback and background noise. It also offers optional visual, power, startup, cursor and Wallpaper Engine tweaks. It does **not** promise full telemetry removal.

## Espanol

### Que hace

- Reduce telemetria opcional y ruido de diagnostico cuando Windows lo permite.
- Aplica cambios reversibles con backup previo.
- Registra cada intento de cambio en un log tecnico.
- Ofrece perfiles `Lite`, `Recommended`, `Hardcore` y `Custom`.
- Mantiene tareas programadas y limpieza de inicio como opt-in.
- No desactiva `SysMain` ni `WSearch` por defecto.
- No toca Defender, firewall, UAC, SmartScreen ni actualizaciones de seguridad.

### Que no hace

- No elimina el 100% de telemetria.
- No descarga ni ejecuta codigo remoto.
- No crea persistencia sin consentimiento.
- No borra apps.
- No convierte el script en EXE.

### Sistemas soportados

- Windows 10/11.
- Windows PowerShell 5.1 como base.
- PowerShell 7+ cuando sea posible.

### Uso recomendado

Abre PowerShell como Administrador en la carpeta del proyecto:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\GetOutTelemetries.ps1 -Interactive
```

Ejemplos no interactivos:

```powershell
.\GetOutTelemetries.ps1 -Diagnose
.\GetOutTelemetries.ps1 -Apply -Profile Lite
.\GetOutTelemetries.ps1 -Apply -Profile Recommended
.\GetOutTelemetries.ps1 -Apply -Profile Hardcore
.\GetOutTelemetries.ps1 -Revert
```

Vista previa sin cambios:

```powershell
.\GetOutTelemetries.ps1 -Apply -Profile Lite -WhatIf
```

### Perfiles

| Perfil | Descripcion |
| --- | --- |
| Lite | Cambios HKCU seguros de privacidad. Sin servicios, sin tareas, sin limpieza de inicio. |
| Recommended | Privacidad equilibrada, politicas razonables, tareas de feedback/telemetria, servicios de diagnostico obvios con backup. |
| Hardcore | Cambios agresivos opcionales con advertencia. Puede afectar busqueda, indexacion, error reporting y comportamiento de cache. |
| Custom | El usuario elige categorias manualmente. |
| Aplicar todo | Hardcore guiado con confirmaciones para partes sensibles. |

### Reduccion percibida orientativa

Windows no expone una metrica de "telemetria total", asi que estos porcentajes no son una garantia tecnica. Son una orientacion practica del ruido de telemetria/diagnostico opcional que suele reducir cada perfil.

| Perfil | Reduccion percibida |
| --- | ---: |
| Lite | 10-25% |
| Recommended | 35-60% |
| Hardcore | 60-80% |
| Aplicar todo | 65-85% |

### Resumen funcional

Hace esto, segun perfil:

- Lite: cambios suaves de privacidad en usuario actual. Desactiva advertising ID, experiencias personalizadas y sugerencias. No toca servicios ni tareas.
- Recommended: anade politicas de telemetria/busqueda web, desactiva tareas de feedback/CEIP y servicios de diagnostico como `DiagTrack`/`dmwappushservice`. No toca `SysMain` ni `WSearch`.
- Hardcore: anade cambios agresivos opcionales, como tocar `SysMain`, `WSearch`, `WerSvc`, limpieza de inicio, cursor, etc.
- Aplicar todo: Hardcore guiado con confirmaciones.

Tambien:

- Diagnose: mira estado actual sin cambiar nada.
- Revert: intenta restaurar desde ultimo backup.
- Crea logs en `C:\ProgramData\GetOutTelemetries\Logs\`.
- Crea backups en `C:\ProgramData\GetOutTelemetries\Backups\`.
- Detecta Wallpaper Engine por Steam, sin rutas hardcodeadas.
- Puede instalar cursor si hay assets en `assets\cursors\VisionWhite\`.
- Las tareas programadas son opcionales, no se crean por defecto.

No hace:

- No elimina 100% telemetria.
- No toca Defender, firewall, UAC, SmartScreen ni updates.
- No descarga ni ejecuta codigo remoto.
- No borra apps.
- No crea persistencia sin permiso.

### Menu interactivo

El menu usa secciones, colores y etiquetas de riesgo:

```text
[Perfiles]
  1   [SEGURO] Aplicar Lite
  2   [MEDIO ] Aplicar Recomendado
  3   [ALTO  ] Aplicar Hardcore
  4   [MEDIO ] Modo personalizado
  5   [ALTO  ] Aplicar todo

[Herramientas]
  6   [INFO  ] Diagnosticar sistema
  7   [INFO  ] Revertir cambios
  8   [INFO  ] Ver ultimo log

[Enlaces y ayuda]
  9   [LINK  ] Abrir GitHub de Butti
  p   [LINK  ] Abrir GitHub del proyecto
  i   [INFO  ] Que hace / impacto
  l   [INFO  ] Cambiar idioma
  u   [INFO  ] Comprobar updates
  0   [INFO  ] Salir
```

| Opcion | Accion |
| --- | --- |
| 1 | Aplicar Lite - privacidad basica segura. |
| 2 | Aplicar Recomendado - equilibrio entre privacidad y compatibilidad. |
| 3 | Aplicar Hardcore - cambios agresivos con confirmacion. |
| 4 | Modo personalizado - elegir categorias. |
| 5 | Aplicar todo - Hardcore guiado con confirmaciones para partes sensibles. |
| 6 | Diagnosticar sistema - solo lectura. |
| 7 | Revertir cambios - usa ultimo backup. |
| 8 | Ver ultimo log. |
| 9 | Abrir GitHub de Butti. |
| p | Abrir GitHub del proyecto. |
| i | Ver que hace el script e impacto orientativo. |
| l | Cambiar idioma. |
| u | Comprobar updates. |
| 0 | Salir. |

### Tabla de ajustes

| Categoria | Ajuste | Perfil por defecto | Reversible | Riesgo |
| --- | --- | --- | --- | --- |
| Privacy | Advertising ID off | Lite | Si | Bajo |
| Privacy | Tailored experiences off | Lite | Si | Bajo |
| Privacy | Suggested content off | Lite | Si | Bajo |
| Telemetry | AllowTelemetry policy reduced | Recommended | Si | Medio |
| Search | Disable web/Bing search suggestions | Recommended | Si | Medio |
| Feedback | Feedback notifications off | Recommended | Si | Bajo |
| Scheduled Tasks | CEIP/feedback task disable | Recommended | Si | Medio |
| Services | Disable DiagTrack/dmwappushservice | Recommended | Si | Medio |
| Services | SysMain/WSearch changes | Hardcore/Custom only | Si | Alto |
| Startup | Disable selected Run entries | Custom/Hardcore only | Si, con backup | Alto |
| Visual | Dark theme/transparency/animations | Recommended | Si | Bajo |
| Cursor | VisionWhite assets if provided | Hardcore/Custom only | Si, con backup | Medio |
| Wallpaper Engine | Detect Steam and set startup | Recommended | Si | Bajo |
| Power | Display/sleep tuning | Recommended | Parcial | Medio |
| Auto reapply | Scheduled task | Opt-in only | Si | Alto |

### Parametros

| Parametro | Uso |
| --- | --- |
| `-Interactive` | Abre menu seguro. |
| `-Apply` | Aplica perfil seleccionado. |
| `-Revert` | Revierte usando backup cuando existe. |
| `-Diagnose` | Muestra estado actual sin cambiar nada. |
| `-Profile Lite\|Recommended\|Hardcore\|Custom` | Selecciona perfil. |
| `-NoScheduledTasks` | Bloquea tareas programadas. |
| `-EnableScheduledTasks` | Permite tarea programada opt-in con reglas seguras. |
| `-NoCursor` | Omite cursor. |
| `-NoWallpaperEngine` | Omite Wallpaper Engine. |
| `-NoStartupCleanup` | Omite limpieza de inicio. |
| `-NoServiceTweaks` | Omite servicios. |
| `-NoVisualTweaks` | Omite tema/visual. |
| `-WhatIf` | Simula sin cambiar sistema. |
| `-Verbose` | Muestra operaciones detalladas. |
| `-Force` | Reduce prompts no criticos, sin saltar checks de seguridad. |
| `-SelfTest` | Valida strings locales prohibidas y perfiles. |

### Backups y logs

- Logs: `C:\ProgramData\GetOutTelemetries\Logs\`
- Backups: `C:\ProgramData\GetOutTelemetries\Backups\<timestamp>\backup.json`

Cada cambio guarda categoria, accion, destino, valor anterior, valor nuevo, resultado y error si existe.

### Revertir

```powershell
.\GetOutTelemetries.ps1 -Revert
```

Revert usa el ultimo backup disponible. Si no hay backup, aplica valores conservadores y avisa.

### Diagnostico

```powershell
.\GetOutTelemetries.ps1 -Diagnose
```

No modifica nada. Muestra version de Windows, PowerShell, admin, claves relevantes, servicios, tareas, Wallpaper Engine, assets de cursor, ultimo backup y ultimo log.

### Seguridad

Crea un punto de restauracion antes de cambios agresivos. El script pregunta por ello en modo interactivo antes de `Recommended` y `Hardcore`.

Reglas importantes:

- No crea tareas programadas por defecto.
- No crea tareas `SYSTEM` apuntando a rutas escribibles por usuario.
- No usa rutas personales del autor.
- No descarga ni ejecuta codigo remoto.
- No debilita seguridad de Windows.

Reporta bugs con:

- Version de Windows.
- Comando usado.
- Log mas reciente.
- Backup mas reciente si afecta revert.

### Limitaciones conocidas

- Algunas politicas pueden no aplicarse igual en Windows Home/Pro/Enterprise.
- Algunos ajustes requieren cerrar sesion o reiniciar.
- Backup de energia es parcial.
- Limpieza de inicio solo restaura entradas `Run` guardadas en backup.
- El check de updates consulta GitHub solo cuando se pide y no instala nada.

### Validacion

```powershell
.\GetOutTelemetries.ps1 -SelfTest
```

## English

### What it does

- Reduces optional diagnostic and telemetry background noise where Windows supports it.
- Applies reversible changes with backup first.
- Logs every attempted change in a technical log.
- Provides `Lite`, `Recommended`, `Hardcore` and `Custom` profiles.
- Keeps scheduled tasks and startup cleanup opt-in.
- Does not disable `SysMain` or `WSearch` by default.
- Does not weaken Defender, firewall, UAC, SmartScreen or security updates.

### What it does not do

- It does not remove 100% of telemetry.
- It does not download or execute remote code.
- It does not create persistence without consent.
- It does not remove applications.
- It is not packaged as an EXE.

### Supported systems

- Windows 10/11.
- Windows PowerShell 5.1 baseline.
- PowerShell 7+ where possible.

### Recommended usage

Run PowerShell as Administrator in the project folder:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\GetOutTelemetries.ps1 -Interactive
```

Non-interactive examples:

```powershell
.\GetOutTelemetries.ps1 -Diagnose
.\GetOutTelemetries.ps1 -Apply -Profile Lite
.\GetOutTelemetries.ps1 -Apply -Profile Recommended
.\GetOutTelemetries.ps1 -Apply -Profile Hardcore
.\GetOutTelemetries.ps1 -Revert
```

Dry run:

```powershell
.\GetOutTelemetries.ps1 -Apply -Profile Recommended -WhatIf
```

### Profiles

| Profile | Description |
| --- | --- |
| Lite | Safe HKCU privacy tweaks. No services, no tasks, no startup cleanup. |
| Recommended | Balanced privacy, reasonable policies, feedback/telemetry tasks and diagnostic services with backup. |
| Hardcore | Optional aggressive changes. May affect search, indexing, error reporting and perceived performance. |
| Custom | User chooses categories manually. |
| Apply all | Guided Hardcore with confirmations for sensitive parts. |

### Estimated perceived reduction

Windows does not expose a "total telemetry" metric, so these percentages are not a technical guarantee. They are practical guidance for optional telemetry/diagnostic noise commonly reduced by each profile.

| Profile | Perceived reduction |
| --- | ---: |
| Lite | 10-25% |
| Recommended | 35-60% |
| Hardcore | 60-80% |
| Apply all | 65-85% |

### Functional summary

What each profile does:

- Lite: safe per-user privacy tweaks. Disables advertising ID, tailored experiences and suggestions. No services or tasks.
- Recommended: adds telemetry/web search policies, disables feedback/CEIP tasks and diagnostic services such as `DiagTrack`/`dmwappushservice`. Does not touch `SysMain` or `WSearch`.
- Hardcore: adds optional aggressive changes such as `SysMain`, `WSearch`, `WerSvc`, startup cleanup, cursor, etc.
- Apply all: guided Hardcore with confirmations.

Also:

- Diagnose: checks current state without changing anything.
- Revert: restores from latest backup when available.
- Creates logs in `C:\ProgramData\GetOutTelemetries\Logs\`.
- Creates backups in `C:\ProgramData\GetOutTelemetries\Backups\`.
- Detects Wallpaper Engine through Steam, with no hardcoded local paths.
- Can install cursor assets from `assets\cursors\VisionWhite\`.
- Scheduled tasks are optional and are not created by default.

Does not:

- Does not remove 100% of telemetry.
- Does not touch Defender, firewall, UAC, SmartScreen or updates.
- Does not download or execute remote code.
- Does not delete apps.
- Does not create persistence without permission.

### Interactive menu

The menu uses sections, colors and risk labels:

```text
[Profiles]
  1   [SAFE  ] Apply Lite
  2   [MEDIUM] Apply Recommended
  3   [HIGH  ] Apply Hardcore
  4   [MEDIUM] Custom mode
  5   [HIGH  ] Apply all

[Tools]
  6   [INFO  ] Diagnose system
  7   [INFO  ] Revert changes
  8   [INFO  ] View latest log

[Links and help]
  9   [LINK  ] Open Butti GitHub
  p   [LINK  ] Open project GitHub
  i   [INFO  ] What it does / impact
  l   [INFO  ] Change language
  u   [INFO  ] Check updates
  0   [INFO  ] Exit
```

| Option | Action |
| --- | --- |
| 1 | Apply Lite - safe basic privacy. |
| 2 | Apply Recommended - balance between privacy and compatibility. |
| 3 | Apply Hardcore - aggressive changes with confirmation. |
| 4 | Custom mode - choose categories. |
| 5 | Apply all - guided Hardcore with confirmations for sensitive parts. |
| 6 | Diagnose system - read-only. |
| 7 | Revert changes - uses latest backup. |
| 8 | View latest log. |
| 9 | Open Butti GitHub. |
| p | Open project GitHub. |
| i | Show what the script does and estimated impact. |
| l | Change language. |
| u | Check updates. |
| 0 | Exit. |

### Tweaks table

| Category | Tweak | Default profile | Reversible | Risk |
| --- | --- | --- | --- | --- |
| Privacy | Advertising ID off | Lite | Yes | Low |
| Privacy | Tailored experiences off | Lite | Yes | Low |
| Privacy | Suggested content off | Lite | Yes | Low |
| Telemetry | AllowTelemetry policy reduced | Recommended | Yes | Medium |
| Search | Disable web/Bing search suggestions | Recommended | Yes | Medium |
| Feedback | Feedback notifications off | Recommended | Yes | Low |
| Scheduled Tasks | CEIP/feedback task disable | Recommended | Yes | Medium |
| Services | Disable DiagTrack/dmwappushservice | Recommended | Yes | Medium |
| Services | SysMain/WSearch changes | Hardcore/Custom only | Yes | High |
| Startup | Disable selected Run entries | Custom/Hardcore only | Yes, with backup | High |
| Visual | Dark theme/transparency/animations | Recommended | Yes | Low |
| Cursor | VisionWhite assets if provided | Hardcore/Custom only | Yes, with backup | Medium |
| Wallpaper Engine | Detect Steam and set startup | Recommended | Yes | Low |
| Power | Display/sleep tuning | Recommended | Partial | Medium |
| Auto reapply | Scheduled task | Opt-in only | Yes | High |

### Parameters

| Parameter | Use |
| --- | --- |
| `-Interactive` | Opens safe menu UI. |
| `-Apply` | Applies selected profile. |
| `-Revert` | Reverts using backup when available. |
| `-Diagnose` | Shows current state without changing anything. |
| `-Profile Lite\|Recommended\|Hardcore\|Custom` | Selects profile. |
| `-NoScheduledTasks` | Blocks scheduled tasks. |
| `-EnableScheduledTasks` | Allows opt-in scheduled task using safe rules. |
| `-NoCursor` | Skips cursor. |
| `-NoWallpaperEngine` | Skips Wallpaper Engine. |
| `-NoStartupCleanup` | Skips startup cleanup. |
| `-NoServiceTweaks` | Skips service changes. |
| `-NoVisualTweaks` | Skips visual/theme changes. |
| `-WhatIf` | Simulates without changing system state. |
| `-Verbose` | Shows detailed operations. |
| `-Force` | Reduces non-critical prompts without bypassing safety checks. |
| `-SelfTest` | Validates forbidden local strings and profiles. |

### Backups and logs

- Logs: `C:\ProgramData\GetOutTelemetries\Logs\`
- Backups: `C:\ProgramData\GetOutTelemetries\Backups\<timestamp>\backup.json`

Each change logs category, action, target, old value, new value, result and error when present.

### Revert

```powershell
.\GetOutTelemetries.ps1 -Revert
```

Revert uses the latest available backup. If no backup exists, it applies conservative defaults and warns clearly.

### Diagnose

```powershell
.\GetOutTelemetries.ps1 -Diagnose
```

Read-only. Shows Windows version, PowerShell version, admin status, relevant registry values, services, tasks, Wallpaper Engine detection, cursor assets, latest backup and latest log.

### Security

Create a Windows restore point before aggressive changes. Interactive mode asks before `Recommended` and `Hardcore`.

Important rules:

- Scheduled tasks are not created by default.
- No `SYSTEM` scheduled task points to user-writable scripts.
- No author-specific personal paths.
- No remote code download or execution.
- No Windows security weakening.

Report bugs with:

- Windows version.
- Command used.
- Latest log.
- Latest backup if revert is affected.

### Known limitations

- Windows editions differ. Some policy values may be ignored by Home editions.
- Some settings require sign-out or restart.
- Power plan backup is partial.
- Startup cleanup can only restore registry `Run` entries that were backed up.
- Update checks query GitHub only when requested and never auto-install code.

### Validation

```powershell
.\GetOutTelemetries.ps1 -SelfTest
```

Self-test checks forbidden author-local strings and basic profile validity.
