# Tweaks Reference

GetOutTelemetries reduces optional diagnostic, telemetry and background noise. It does not remove all telemetry.

| Category | Target | Type | Profile | Reversible | Risk | Restart/sign-out |
| --- | --- | --- | --- | --- | --- | --- |
| Privacy | `HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo\Enabled` | Registry | Lite | Yes | Low | Sign-out may help |
| Privacy | `HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy\TailoredExperiencesWithDiagnosticDataEnabled` | Registry | Lite | Yes | Low | Sign-out may help |
| Privacy | ContentDelivery suggested content values | Registry | Lite | Yes | Low | Sign-out may help |
| Telemetry | `HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection\AllowTelemetry` | Registry policy | Recommended | Yes | Medium | Restart may help |
| Search | Web/Bing search policy values | Registry policy | Recommended | Yes | Medium | Restart Explorer/sign-out |
| Feedback | Feedback notification policy | Registry | Recommended | Yes | Low | Sign-out may help |
| Scheduled tasks | CEIP and feedback tasks | Scheduled task | Recommended | Yes | Medium | No |
| Services | `DiagTrack`, `dmwappushservice` | Service startup | Recommended | Yes | Medium | Restart recommended |
| Services | `SysMain`, `WSearch`, `WerSvc` | Service startup | Hardcore/Custom | Yes | High | Restart recommended |
| Startup | Selected `Run` entries | Registry | Hardcore/Custom | Yes, if backed up | High | Next logon |
| Visual | Dark theme, transparency, taskbar animations | Registry | Recommended | Yes | Low | Sign-out may help |
| Cursor | Cursor registry values | Registry/files | Hardcore/Custom | Yes, if backed up | Medium | Sign-out may help |
| Wallpaper Engine | `HKCU:\Software\Microsoft\Windows\CurrentVersion\Run\WallpaperEngine` | Registry | Recommended | Yes | Low | Next logon |
| Power | Display and sleep tuning | Power plan | Recommended | Partial/full export when possible | Medium | No |
| Auto reapply | `\GetOutTelemetries\ApplyRecommendedAtLogon` | Scheduled task | Opt-in only | Yes | High | Next logon |

Backups are stored under `C:\ProgramData\GetOutTelemetries\Backups\`.
