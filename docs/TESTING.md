# Testing

Run from the repository root.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "$errors = $null; [System.Management.Automation.PSParser]::Tokenize((Get-Content .\GetOutTelemetries.ps1 -Raw), [ref]$errors) | Out-Null; if ($errors) { $errors; exit 1 }; 'Parse OK'"
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\GetOutTelemetries.ps1 -SelfTest
powershell -NoProfile -ExecutionPolicy Bypass -File .\GetOutTelemetries.ps1 -Diagnose
powershell -NoProfile -ExecutionPolicy Bypass -File .\GetOutTelemetries.ps1 -Apply -Profile Lite -WhatIf
powershell -NoProfile -ExecutionPolicy Bypass -File .\GetOutTelemetries.ps1 -Apply -Profile Recommended -WhatIf
powershell -NoProfile -ExecutionPolicy Bypass -File .\GetOutTelemetries.ps1 -Apply -Profile Hardcore -WhatIf
```

Hardcore safety check:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\GetOutTelemetries.ps1 -Apply -Profile Hardcore
```

Expected: non-interactive run aborts unless `-Force` is supplied. `-WhatIf` remains read-only.
