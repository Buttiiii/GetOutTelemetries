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
