# Tahoe Clip MVP tasks

Build a privacy-first clipboard manager for macOS Tahoe on Intel x86_64 using Swift, AppKit, SQLite, a global hotkey, and a small CLI compatible with Pi and Gentleman.Dots workflows.

## Scope

In scope:
- Menu bar AppKit app that watches the general pasteboard.
- SQLite-backed local history for text-first clipboard items.
- Global hotkey to open a lightweight history panel.
- CLI for listing, searching, copying, pruning, and clearing history.
- Privacy defaults: local-only storage, sensitive-content filters, no network, no cloud sync.

Out of scope for MVP:
- iCloud sync, screenshots/OCR, rich editor UI, cross-device history, background AI processing.
- Accessibility-driven auto-paste into the previous app. MVP copies selected history back to the pasteboard only.

## Route

- T1: Architecture and initial repository scaffold — direct inline. Evidence: empty workspace, Swift 6.3.3 available for x86_64 macOS 26.0, and no existing app code to map.

## Checklist

- [x] T1 — Create architecture document, project tree, SwiftPM manifest, starter modules, privacy policy notes, and initial checks.

## Acceptance criteria

- Architecture explains boundaries, data flow, privacy decisions, and implementation sequence.
- Project tree separates app shell, CLI, and shared core.
- Initial package is intentionally minimal and can evolve without pulling third-party dependencies first.

## Verification

- Attempted: `swift package describe` from the project root. Blocked by the current sandbox/toolchain environment (`sandbox-exec: sandbox_apply: Operation not permitted`) after SwiftPM cache permission warnings.
- Observed: `git status --short` shows the initial scaffold staged and `.build/` ignored.
