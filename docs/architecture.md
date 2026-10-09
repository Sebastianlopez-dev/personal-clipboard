# Tahoe Clip planned MVP architecture

Target design: a menu bar AppKit app will watch the macOS pasteboard, store text history locally in SQLite, expose a global hotkey for recall, and ship a CLI for Pi and Gentleman.Dots automation. This is a development scaffold, not a working MVP.

## Current implementation status

H1 adds centralized text item construction, idempotent watcher start/stop, approximate source metadata, and content-free capture errors with at most three attempts per change. These changes and their tests remain runtime-unverified because the current compiler and SDK are incompatible.

CLI help and command dispatch exist: no arguments, `help`, `--help`, and `-h` print help on stdout and exit `0`. The seven operational commands below report unsupported behavior on stderr and exit `1`; unknown commands report an error and usage on stderr and exit `2`.

`SQLiteDatabase` holds a URL, but `migrate()` throws `SQLiteDatabase.Error.notImplemented`. SQLite persistence, history rendering/selection/copy, and global-hotkey registration are planned. The menu history action is only a placeholder. Build and runtime verification are pending.

## Planned decisions

| Topic | MVP decision | Tradeoff |
| --- | --- | --- |
| Runtime | Swift 6 + AppKit on macOS Tahoe, Intel x86_64 target. | Native and fast; less portable than Electron/Tauri. |
| UI shell | Menu bar app with compact history window. | Lower scope than a full preferences-heavy app. |
| Clipboard source | `NSPasteboard.general` with `changeCount` polling. | Simple and stable; polling is less elegant than nonexistent pasteboard events. |
| Storage | SQLite database in Application Support. | Durable and queryable; requires careful schema/migration discipline. |
| SQLite access | Start with a tiny `sqlite3` adapter over system SQLite. | No dependency churn; more boilerplate until a wrapper is justified. |
| Hotkey | Carbon hotkey registration wrapped behind `HotKeyRegistrar`. | Old API, but still the pragmatic macOS global-hotkey path. |
| Paste behavior | Selecting an item writes it back to the pasteboard. | Avoids Accessibility permission for MVP; user presses paste manually. |
| CLI | `clipctl` talks to the same SQLite store. | Perfect for shell/agent workflows; must guard against concurrent access. |
| Privacy | Local-only, no network, no sync, configurable redaction/exclusion. | Less magical; much safer by default. |

Apple documents `NSPasteboard` as the AppKit pasteboard API for macOS apps, and macOS includes SQLite as a system library/CLI, so the MVP can avoid extra runtime services early on ([Apple NSPasteboard](https://developer.apple.com/documentation/appkit/nspasteboard?changes=_3_3), [Apple Core Services overview](https://developer-rno.apple.com/library/archive/documentation/MacOSX/Conceptual/OSX_Technology_Overview/CoreServicesLayer/CoreServicesLayer.html)).

## Planned components

```text
TahoeClip.app
  AppDelegate
  StatusItemController
  ClipboardWatcher
  HistoryPanelController
  HotKeyRegistrar

clipctl
  list | search | copy | clear | prune | pause | resume

ClipCore
  ClipboardItem
  ClipboardStore
  SQLiteDatabase
  PrivacyFilter
  AppPaths
```

### Planned boundaries

- `TahoeClip` owns AppKit lifecycle, menu bar UI, hotkey handling, and user interaction.
- `clipctl` owns terminal-facing commands and stable output formats.
- `ClipCore` owns storage, data models, privacy filters, and shared business rules.

## Planned data flow

```text
NSPasteboard.general
  -> ClipboardWatcher sees changeCount change
  -> PrivacyFilter rejects sensitive or oversized content
  -> ClipboardStore deduplicates and writes SQLite row
  -> HistoryPanel reads latest rows
  -> User selects row
  -> App or clipctl writes selected value back to NSPasteboard.general
```

## Planned database sketch

```sql
CREATE TABLE clipboard_items (
  id TEXT PRIMARY KEY,
  kind TEXT NOT NULL,
  preview TEXT NOT NULL,
  content TEXT NOT NULL,
  content_hash TEXT NOT NULL UNIQUE,
  source_app_bundle_id TEXT,
  created_at INTEGER NOT NULL,
  last_used_at INTEGER,
  use_count INTEGER NOT NULL DEFAULT 0,
  is_pinned INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_clipboard_items_created_at ON clipboard_items(created_at DESC);
CREATE INDEX idx_clipboard_items_preview ON clipboard_items(preview);
```

The planned MVP will store text content directly. No SQLite schema or persistence is implemented yet. Later versions may move large/binary payloads to blob files and keep metadata in SQLite.

## Planned privacy requirements

These are target requirements, not a statement that every safeguard is implemented or verified.

- Keep default storage local to Application Support only.
- Do not add network capability to the MVP.
- Do not capture from ignored apps, configurable by bundle identifier.
- Skip likely secrets: long tokens, private keys, password-field markers when detectable, and oversized payloads.
- Provide `clipctl clear`, `clipctl prune --older-than`, and app menu clear actions.
- Never auto-paste into other apps in MVP; that would require Accessibility trust and a bigger consent story.

## Planned CLI contract

The following operational examples are unavailable in the scaffold. Each command reports unsupported behavior on stderr and exits `1`; arguments are not parsed yet. Use `clipctl --help` for the implemented help path.

```bash
clipctl list --limit 20
clipctl search "token"
clipctl copy <id>
clipctl clear
clipctl prune --older-than 30d
clipctl pause
clipctl resume
```

For Pi and Gentleman.Dots, prefer machine-readable output later:

```bash
clipctl list --json --limit 10
```

## Project tree

```text
TahoeClip/
  Package.swift
  README.md
  docs/
    architecture.md
  Sources/
    ClipCore/
      AppPaths.swift
      ClipboardItem.swift
      ClipboardStore.swift
      PrivacyFilter.swift
      SQLiteDatabase.swift
    TahoeClip/
      main.swift
      AppDelegate.swift
      ClipboardWatcher.swift
      HistoryPanelController.swift
      HotKeyRegistrar.swift
      StatusItemController.swift
    clipctl/
      main.swift
  Tests/
    ClipCoreTests/
      PrivacyFilterTests.swift
  odd/
    tasks/
      tahoe-clip-mvp.md
```

## Remaining MVP implementation roadmap

This roadmap describes the target MVP, not completed or verified milestones. H2 only makes unfinished operations fail explicitly; it does not implement these features.

1. Create compiling skeleton with app, CLI, and shared core.
2. Add SQLite schema creation and text insert/list operations.
3. Add pasteboard watcher with deduplication by content hash.
4. Add status item and history panel showing recent text entries.
5. Add hotkey registration and panel toggle.
6. Add CLI commands for list/search/copy/clear/prune.
7. Add preferences for ignored apps, retention, and pause/resume.
8. Package as a `.app` later; keep SwiftPM fast during MVP.

## Intended checks (not verified)

The current compiler/SDK mismatch prevents running the tests. These commands are for use after the environment is repaired; no successful build or test result is claimed.

```bash
swift package describe
swift test
swift run clipctl --help
```
