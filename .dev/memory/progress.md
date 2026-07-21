# Progress

Phase status owned by the /dev orchestrator only. States: `pending` `planned` `blocked` `done`.

Mode: `--auto` (unattended). Source roadmap: `docs/roadmaps/2026-07-21-macshot.md`.

## Phases

| # | Phase | Status | Notes |
|---|-------|--------|-------|
| M1 | Capture core | done | branch `exec/m1-capture-core-20260721` @ 67197ac; 18/18 tests, .app built; unmerged (human) |
| M2 | Quick-access overlay & history | pending | depends M1 |
| M3 | Annotation editor | pending | depends M2 |
| M4 | Beautify | pending | depends M3 |
| M5 | OCR | pending | depends M1 (parallel-safe with M3/M4) |
| M6 | Ship | pending | depends M1–M5 |

## Log
- 2026-07-21 — imported 6 milestones from roadmap, all pending. Loop starts at M1.
- 2026-07-21 — **M1 done.** 15/15 tasks, 16 commits, all task-reviews PASS. `swift test` 18/18, `swift build` clean, universal ad-hoc-signed `MacShot.app` produced. Branch `exec/m1-capture-core-20260721` @ 67197ac in worktree `/Users/omes/macshot-exec-m1-capture-core`; master untouched, unmerged (--auto no-merge; human integrates). 6 `[auto]` decisions, 4 Swift/SCK lessons logged. Orphan `Sources/MacShotCore/Placeholder.swift` (T1 scaffold) — remove opportunistically in M2.

## Integration note (--auto stacking)
Phases don't merge to master (no-merge rule). Dependent phases stack: M2 branches off M1's branch, M3 off M2, etc. Human merges the stack after review. M5 (depends M1 only) also stacks on M1's branch.
