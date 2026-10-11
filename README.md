# Tahoe Clip

Tahoe Clip is a development scaffold for a planned privacy-first clipboard manager for macOS Tahoe on Intel x86_64, not a working MVP.

The target MVP combines an AppKit menu bar app, text-first clipboard history, local SQLite storage, a global hotkey, and a CLI for shell tools such as Pi and Gentleman.Dots.

## Current status

| Area | Scaffold status |
| --- | --- |
| Capture/core | H1 adds centralized text item construction, idempotent watcher start/stop, approximate source metadata, and content-free capture errors with at most three attempts per change. Runtime verification is pending. |
| CLI | Help and command dispatch exist. Help exits `0`; all seven operational commands report unsupported behavior on stderr and exit `1`; unknown commands report an error and usage on stderr and exit `2`. |
| Storage | A database URL holder exists. `migrate()` throws `SQLiteDatabase.Error.notImplemented`; SQLite persistence and migrations are planned. |
| History/hotkey | History rendering, selection/copy, and global-hotkey registration are planned. The menu history action is a placeholder, not usable history recall. |

Tests have been added, but none have executed. With project-local module caches, the build gets past manifest compilation; runtime test verification is blocked by missing test-framework modules. Previous attempts reported `no such module 'Testing'` and `no such module 'XCTest'`. All tests now follow the existing `Testing` convention; no second framework, substitute framework, or dependency has been added. No test retry was made after restoring this convention. Both production executables compiled and linked with project-local module caches. All 10 CLI checks passed (help, seven unsupported operations, and an unknown command). Automated tests and GUI/real-clipboard runtime verification remain pending.

## Quick path

1. Build the Swift package.
2. Run the menu bar app during development.
3. View `clipctl` help. Operational shell workflows are not available yet.

```bash
swift build
swift run TahoeClip
swift run clipctl --help
```

Production build and direct CLI checks passed using project-local module caches and SwiftPM sandboxing disabled for this restricted environment. The plain development commands above and GUI launch were not exercised. Unsupported CLI commands intentionally fail until implemented.

## Planned MVP decisions

| Area | Decision |
| --- | --- |
| UI | AppKit, not SwiftUI, to keep the app native and predictable on Intel Macs. |
| Storage | SQLite through the system `sqlite3` library first; no third-party dependency until the schema stabilizes. |
| Clipboard | Poll `NSPasteboard.general.changeCount`; capture text first, then add richer types later. |
| Hotkey | Carbon `RegisterEventHotKey` wrapper behind a small adapter. |
| CLI | Separate executable sharing `ClipCore` with the app. |
| Privacy | Local-only database, no network, optional sensitive-content filters, explicit clear/prune commands. |

## Development memory (Engram)

Engram binds each agent session to a project from the session's own directory, not from the files it edits. The chain is: `.engram/config.json` (`project_name: clipboard`) for the Engram core, then the Git root basename as fallback for the Claude Code and opencode plugins. All four agents resolve to `clipboard` while their session directory is inside this repository.

That gives one rule:

- Launch the agent with its working directory inside this repository so the session binds to `clipboard`.
- Launching from `~` binds the session to the unrelated `adm` project instead, even when every edited file belongs to this repository. Override explicitly with `ENGRAM_PROJECT=clipboard`, or `engram mcp --project clipboard` for a per-agent MCP registration.

Codex runs its shell and hooks inside a macOS seatbelt sandbox, and the Engram store lives outside the writable workspace. Without a writable root pointing at that store, every Engram call dies on `acquire instance identity lock: ... .instance-id.lock: operation not permitted`, so the session hooks cannot register the session and the agent cannot save. Codex needs both a workspace-write sandbox mode and the Engram data directory declared as an extra writable root in its user config.

Pi, Claude Code, and opencode are not sandboxed this way and need no extra configuration.

## Repository layout

See [`docs/architecture.md`](docs/architecture.md) for the full MVP design and implementation plan.
