# Security Policy

## Safe usage

GetOutTelemetries changes Windows settings. Use `-Diagnose` first, then `-WhatIf`, then apply the least aggressive profile that fits your needs.

Recommended flow:

```powershell
.\GetOutTelemetries.ps1 -Diagnose
.\GetOutTelemetries.ps1 -Apply -Profile Lite -WhatIf
.\GetOutTelemetries.ps1 -Apply -Profile Lite
```

Create a Windows restore point before aggressive changes. The tool also creates its own backups before modifications.

## What this project will not do

- No remote code execution.
- No auto-download or auto-update.
- No Defender, firewall, UAC, SmartScreen or security update weakening.
- No hidden persistence.
- No SYSTEM scheduled task pointing to user-writable scripts.
- No storage of sensitive personal data.

## Logs and backups

- Logs: `C:\ProgramData\GetOutTelemetries\Logs\`
- Backups: `C:\ProgramData\GetOutTelemetries\Backups\`

Logs may include Windows setting names, service names, task names and registry paths. Do not publish logs without reviewing them.

## Reporting a security issue

Open a private security advisory on GitHub if available, or contact the maintainer through the repository profile.

Include:

- Windows version and edition.
- PowerShell version.
- Exact command used.
- Relevant log excerpt.
- Why behavior seems unsafe.

Do not include secrets, account tokens or unrelated personal files.
