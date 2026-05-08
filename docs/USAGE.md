# Usage Notes

## Profiles

Use `Lite` first. Move to `Recommended` only when you want stronger policy and service changes. Use `Hardcore` only when you accept possible Windows feature impact.

## Scheduled tasks

Scheduled tasks are disabled by default. Enable them only after installing the script to a protected directory such as:

- `C:\Program Files\GetOutTelemetries\`
- `C:\ProgramData\GetOutTelemetries\`

The script refuses risky user-writable locations for auto-reapply tasks.

## Cursor assets

Optional cursor files may be placed at:

```text
assets\cursors\VisionWhite\
```

Required files:

- `pointer.cur`
- `help.cur`
- `work.ani`
- `busy.ani`
- `text.cur`
- `link.cur`

If assets are missing, cursor installation is skipped and logged.

## Install

```powershell
.\GetOutTelemetries.ps1 -Install
```

Install copies the script and assets to a safe app location. It does not create scheduled tasks by itself.

## Uninstall

```powershell
.\GetOutTelemetries.ps1 -Uninstall
```

Uninstall removes GetOutTelemetries scheduled tasks and installed app files. Logs and backups are kept by default.

## Version

```powershell
.\GetOutTelemetries.ps1 -Version
```
