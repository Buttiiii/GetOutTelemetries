# Safety Guide

## Recommended Flow

1. Run `.\GetOutTelemetries.ps1 -Diagnose`.
2. Run `.\GetOutTelemetries.ps1 -Apply -Profile Lite -WhatIf`.
3. Apply `Lite` first.
4. Move to `Recommended` only if you want stronger policy/service changes.
5. Use `Hardcore` only if you accept Windows feature impact.

## Profiles

- `Lite`: safest. Per-user privacy values only.
- `Recommended`: balanced. Adds policy, feedback tasks and diagnostic services.
- `Hardcore`: aggressive. May affect Windows Search, indexing, error reporting, caching/performance behavior and startup entries.
- `Custom`: choose categories manually.

## Restore Points

Interactive mode asks about restore points before stronger profiles. Restore points are helpful but not the only rollback mechanism.

## Backups

The tool writes structured backups before modifications where possible:

- Registry values.
- Service startup state.
- Scheduled task state.
- Startup entries.
- Cursor values.
- Power plan export/query where available.

## Scheduled Tasks

Scheduled tasks are opt-in only. The tool refuses risky user-writable script locations for auto-reapply.

## Security Boundaries

The tool must not weaken Defender, firewall, UAC, SmartScreen or security updates. It must not download or execute remote code.
