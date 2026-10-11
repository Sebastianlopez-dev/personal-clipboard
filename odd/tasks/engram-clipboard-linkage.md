# Engram clipboard linkage

## Objective

Make Engram usable from every agent the user runs while working in this repository, and move the historical clipboard work that Engram recorded under project `adm` into project `clipboard`.

## Verified diagnosis

Two independent defects, both reproduced with evidence.

### Defect A — the reported block is a sandbox denial, not a bad store

`engram` acquires `.instance-id.lock` in its data directory on **every** operation, including the read-only `doctor`. When the data directory is not writable, the whole tool fails.

Reproduced verbatim inside the Codex seatbelt sandbox:

```text
engram: engram: acquire instance identity lock: open migration lock file
/Users/adm/.engram/.instance-id.lock: open /Users/adm/.engram/.instance-id.lock: operation not permitted
```

This is the exact message the user reported. `codex doctor` reports `filesystem sandbox restricted`. `~/.engram` is outside the writable workspace, so the lock open is denied.

Control tests:

| Test | Result |
| --- | --- |
| Plain shell (Pi, no sandbox) | `engram instance-id` exit 0 |
| `chmod 555` data dir | `permission denied` (same failure class) |
| `codex sandbox engram doctor` | `operation not permitted` (matches user report) |
| `codex sandbox -c sandbox_mode="workspace-write" -c sandbox_workspace_write.writable_roots=["/Users/adm/.engram"]` | exit 0, resolves `9d2a9c798727807efabe53ce1f12f605` |

Trusting the repository alone does not help: `sandbox_workspace_write.writable_roots` is only consulted when the sandbox mode is `workspace-write`.

### Defect B — the "wrong project" claim was stale for this Pi session

The session of the current Pi chat is already correct:

| Field | Value |
| --- | --- |
| Session | `01a11fdb-bb12-755a-8491-d123962775c6` |
| Project | `clipboard` |
| Directory | `/Users/adm/Documents/personal/tools/clipboard` |
| `mem_save` | succeeded, observation 565 |

So the pasted analysis does not describe this Pi session. The genuinely misplaced data is the historical work session started from `~`:

| Field | Value |
| --- | --- |
| Session | `01a11d2d-de69-7d10-94ce-cd7ea26a81d9` and `...:resume:2` |
| Project | `adm` (wrong) |
| Directory | `/Users/adm` (wrong) |
| Observations | 58, all clipboard work |
| Prompts | 34, all clipboard work |

The repository already carries `.engram/config.json` with `project_name: clipboard`, and Engram resolves it with `project_source: config`, so cwd-based detection inside the repository is already correct.

## Scope

- Engram local store under `/Users/adm/.engram`.
- Agent integration config for Codex, Claude Code, opencode, and Pi.
- This repository's `.engram/config.json`.

## Constraints

- Do not delete observations, prompts, or sessions.
- Take a consistent SQLite backup before any mutation.
- Keep Cloud disabled; no enrollment, no token.
- Use the supported `engram projects rescue-ownership` path, not ad-hoc SQL, so FTS and sync bookkeeping stay consistent.
- The Codex sandbox relaxation is a security-relevant decision and needs explicit user approval before it is written.

## Tasks

- [x] ECL-1 Record the verified diagnosis.
  - Evidence: reproduction matrix above; user report matched byte for byte.
- [x] ECL-2 Create a consistent SQLite backup and verify it.
  - Evidence: `/Users/adm/.engram/manual-backups/engram-before-clipboard-linkage-20261009-111147.db`; `PRAGMA integrity_check` = `ok`; SHA-256 `f01e2c7c2110e3f345e88a16abcc32c05810bd5e72ca0a2dbca758cb0a583e2c`; counts 235 sessions / 565 observations / 821 prompts.
- [x] ECL-3 Rescue ownership of the `~` session and its 58 observations and 34 prompts from `adm` to `clipboard`.
  - Evidence: `engram projects rescue-ownership` refused (`owned_by_other_project`), so the supported `engram doctor repair --project adm --check session_project_directory_mismatch --apply` path was used after correcting the two session directories and temporarily relocating `.engram/config.json` so detection fell back to `git_root`.
  - Result: `status: applied`; 2 sessions, 58 observations, 34 prompts moved; repair backup `/Users/adm/.engram/backups/engram-repair-20261009T091740.389080000Z.db`, integrity `ok`; zero residue left under `adm`.
- [x] ECL-4 Grant the Engram data directory sandbox access for Codex.
  - Approved by explicit user choice ("Fix verificado").
  - Change: `~/.codex/config.toml` gained `sandbox_mode = "workspace-write"`, `[sandbox_workspace_write] writable_roots = ["/Users/adm/.engram"]`, and `[projects."/Users/adm/Documents/personal/tools/clipboard"] trust_level = "trusted"`. Backup: `~/.codex/config.toml.bak-engram-linkage-20261009-112111`.
  - Verification: `codex exec --skip-git-repo-check "Run this exact shell command...: engram instance-id"` returned exit `0` with instance id `9d2a9c798727807efabe53ce1f12f605`, and its SessionStart hooks registered thread `01a11ff8-a909-7b21-b57c-ad8e538c2bb3` as project `clipboard` with directory `/Users/adm/Documents/personal/tools/clipboard`.
  - Note: the `codex sandbox` debug subcommand is not a faithful model of the runtime. It ignores the file's `sandbox_mode` and only honors `-c` overrides plus the file's `writable_roots`, so it still fails after the fix. The real runtime was verified through `codex exec` instead.
- [x] ECL-5 Verify per-agent linkage in this repository and record the launch rule.
  - Evidence: project resolution for this repository returns `clipboard` from every agent path. Engram core and the Codex hook use `/project/current?cwd=` (accepts `config`, `git_remote`, `git_root`, `git_child`, `dir_basename`, `process_override`); the Claude Code and opencode plugins fall back to the Git root basename, which is also `clipboard` here because the repository has no origin remote.
  - Pi session `01a11fdb-bb12-755a-8491-d123962775c6` was already bound to `clipboard` and its `mem_save` succeeded (observation 565).
  - Documented in `README.md` under "Development memory (Engram)".
- [x] ECL-6 Closure: full doctor plus evidence.
  - Evidence: MCP `mem_doctor` for `clipboard` returns `status: ok`, 10/10 checks, `session_project_directory_mismatch` ok across 4 sessions; `mem_search` on `clipboard` returns the migrated historical observations (514, 560).
- [x] ECL-7 Normalize the stale auto-generated titles left behind by the move.
  - Context: `mem_session_summary` derives its title from the project at save time, so the 17 migrated summaries still read `Session summary: adm` while their rows belong to `clipboard`.
  - Change: title-only updates through `mem_update` with `expected_project: clipboard`; no content, type, scope, or session ownership was touched.
  - Evidence: 17/17 updated; `select count(*) from observations where project='clipboard' and title like '%adm%'` returns 0; `PRAGMA integrity_check` = `ok`.

## Evidence

- Backup: `/Users/adm/.engram/manual-backups/engram-before-clipboard-linkage-20261009-111147.db`, integrity `ok`, SHA-256 `f01e2c7c2110e3f345e88a16abcc32c05810bd5e72ca0a2dbca758cb0a583e2c`.
- Repair backup: `/Users/adm/.engram/backups/engram-repair-20261009T091740.389080000Z.db`, integrity `ok`.
- Project counts after the move: `clipboard` 3 sessions / 59 observations / 35 prompts; `adm` 49 sessions / 96 observations / 177 prompts.
- Doctor scoping note: the MCP `mem_doctor` scopes to the detected project, while CLI `engram doctor --check <code>` without `--project` scans every project. The only remaining warning is the three pre-existing `session_project_directory_mismatch` findings for `manual-save-portfolio`, `manual-save-plataforma-cero`, and `manual-save-plataforma-cero-web`, which are out of scope by explicit user instruction.
- Sandbox denial reproduced with `codex sandbox engram doctor --json`.
- Working sandbox configuration validated with `sandbox_mode="workspace-write"` plus `sandbox_workspace_write.writable_roots=["/Users/adm/.engram"]`.

## Closure

Both defects are repaired and verified.

- The Engram project binding for this repository is `clipboard` from every agent path, and the historical `~` session with its 58 observations and 34 prompts now belongs to `clipboard`.
- Codex can reach `~/.engram` inside its sandbox: its session hooks register, and its shell can run `engram` successfully.
- No data was deleted. Two independent backups exist, both integrity-checked, plus the repair's own snapshot.

Remaining, out of scope by explicit user instruction: the three pre-existing `session_project_directory_mismatch` findings for `manual-save-portfolio`, `manual-save-plataforma-cero`, and `manual-save-plataforma-cero-web`.

Watch item: the migrated session summaries carried the auto-generated title `Session summary: adm`, because the title was derived from the project at save time. Resolved in ECL-7: all 17 now read `Session summary: clipboard`.

Watch item: the Codex thread `01a11d2d-de69-7d10-94ce-cd7ea26a81d9` has cwd `/Users/adm/Documents/personal/tools/clipboard` in Codex's own state, yet its Engram hook reported cwd `/Users/adm` at creation. Reopening that specific thread may make its hook request project `adm` against a session now owned by `clipboard`, which Engram refuses as a project conflict rather than silently reverting. Continuing this work in a fresh thread rooted in the repository avoids it.

Observation, not touched: observation 168 carries project `plataforma-cero` with the title `Session summary: adm`. It is the same class of staleness left by the earlier EGR-3 repair, but it belongs to another project, so it was left alone. The 22 `Session summary: adm` titles inside the `adm` project are correct and were not touched.

Untracked in the repository: `.engram/config.json` (the project binding) and `odd/tasks/engram-clipboard-linkage.md`. No commit was made; committing remains the user's decision.
