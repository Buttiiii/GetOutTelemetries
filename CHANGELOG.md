# Changelog

## 1.0.0 - Unreleased

- Refactored personal tweak script into public Windows privacy/optimization utility.
- Added parameter modes: `-Interactive`, `-Apply`, `-Revert`, `-Diagnose`, `-Profile`, `-WhatIf`, `-Force`.
- Added safe profiles: Lite, Recommended, Hardcore and Custom.
- Added structured logging under `C:\ProgramData\GetOutTelemetries\Logs\`.
- Added structured backups under `C:\ProgramData\GetOutTelemetries\Backups\`.
- Removed author-specific hardcoded paths.
- Made scheduled tasks opt-in only.
- Prevented default disabling of `SysMain` and `WSearch`.
- Added diagnostic read-only mode.
- Added self-test validation mode.
- Added bilingual README, MIT license and security policy.
- Added fully localized interactive menu with short descriptions, author GitHub link and guided "Apply all" option.
- Added portable cursor support with `-CursorPath` and assets placeholder.
- Added `-Install`, `-Uninstall`, `-Version` and `-EnableStartupCleanup`.
- Added stronger Hardcore safety for non-interactive runs.
- Added improved power plan backup/export and restore attempt.
- Added CI and release packaging workflows.
- Added `.gitignore` and expanded docs.
