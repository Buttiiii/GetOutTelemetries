# GetOutTelemetries

By Butti  
GitHub: https://github.com/Buttiiii

## ES

Script para aplicar optimizaciones de Windows orientadas a reducir telemetria, procesos de fondo y mantener una configuracion rapida con tema oscuro.

### Requisitos
- Windows 10/11
- PowerShell ejecutado como Administrador

### Ejecutar
```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\alexc\OneDrive\Proyectos\GetOutTelemetries.ps1"
```

### Menu
- `[1]` Aplicar optimizacion
- `[2]` Abrir GitHub de Butti
- `[0]` Salir
- `[9]` Cambiar idioma

## EN

Script to apply Windows optimizations focused on reducing telemetry/background noise while keeping a fast dark-mode setup.

### Requirements
- Windows 10/11
- PowerShell running as Administrator

### Run
```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\alexc\OneDrive\Proyectos\GetOutTelemetries.ps1"
```

### Menu
- `[1]` Apply optimization
- `[2]` Open Butti's GitHub
- `[0]` Exit
- `[9]` Change language

## Notes
- The script creates/reuses scheduled tasks under `\OpenCode\` for automatic re-apply.
- After running, restart Windows to fully apply all changes.
