# Clipboard hardening

## Objective
Resolve the six static review findings without implementing the full MVP or adding speculative abstractions.

## Authorized scope
Watcher lifecycle, capture errors and source metadata, text item invariants, unused menu dependency, honest scaffold behavior and documentation, focused regression tests.

## Constraints
English artifacts. Single writer at a time; independent read-only analysis may run concurrently. No remote operations. No dependency downloads or installations are required; if Python tooling becomes necessary, use a project-isolated uv environment with versions pinned in requirements. Preserve staged scaffold; repository has no baseline commit. Delivery strategy: ask-on-risk. Forecast: approximately 300 authored changed lines excluding the existing scaffold.

## Tasks
- [ ] H1 — Harden capture lifecycle and item construction; remove unused menu dependency; add regression tests. Route: delegated direct (multi-file logic and tests).
- [ ] H2 — Make unfinished CLI/storage behavior explicit and document implemented vs planned features. Route: delegated direct (multiple code/documentation files).
- [ ] H3 — Independently verify integration and record outcomes. Route: delegated verification.

## Acceptance criteria
Repeated start produces one timer; stop invalidates it. Capture failures are reported without logging clipboard content. Filtered items are not retried. Source identifier is reused and described as approximate. Current text identity rules have one construction path. Stubs do not masquerade as successful operations. No new plugin/event framework.

## Verification
Test-first where runnable deterministic tests exist; otherwise record runner failure, never claim RED/GREEN. Runner: swift test --disable-sandbox --cache-path .build/cache --config-path .build/config --security-path .build/security. Structural check: git diff --check. Native review mode: on; assessment initially unavailable due to index permission, permission subsequently granted. Commit/review boundary pending: unborn repository and pre-existing staged scaffold must not be silently absorbed into a fix commit.

## Progress
H1 source changes applied: one timer, explicit stop and lifetime cleanup, generation-guarded ticks, source reuse, three capture attempts per change, content-free errors, centralized text item construction, unused menu dependency removed. H2 applied: explicit CLI failures, throwing migration placeholder, planned/implemented documentation distinction. Fourteen new cases with 53 checks were added; 17 cases total including the existing privacy suite. Tests remain unexecuted: stable-source testing fails because Testing is unavailable. An XCTest compatibility trial also failed; tests were restored to the existing Testing convention to avoid mixed frameworks.

## Observed checks
- Independent verifier found no concrete H1 defect statically.
- Initial concurrent package verification failed because H2 modified SQLiteDatabase.swift during the build. Final builds ran only after writers finished.
- Production build with local module caches succeeded (exit 0); TahoeClip and clipctl linked.
- All 10 CLI checks passed: no args/help -> 0 stdout, seven unsupported operations -> 1 stderr, unknown -> 2 stderr.
- Changed Swift syntax parse and git diff --check passed.
- Automated tests, GUI launch, real clipboard capture, and off-main cleanup runtime remain unverified.
- Native review preflight performed; no START or approval. It requires intended-untracked selection for the new tests/task document; no bound transaction was created.
- No commits/staging/push/PR. Existing staged scaffold preserved, corrections remain unstaged/untracked. The repository has no baseline commit. Observed hardening source/document diff is 278 authored changes plus 238 new test lines, excluding task tracking; this exceeds the advisory 400-line delivery budget. Resolve baseline and delivery strategy before any commit.
- Task boxes remain open because functional test proof and work-unit commits are pending; applied source changes are not represented as verified task closure.

## Next step
Restore access to the Swift testing modules without adding another framework, then execute the 17 tests. Verify GUI/clipboard behavior where supported. Resolve initial baseline, delivery slicing and intended-untracked review selection before committing; no remote work is authorized.
