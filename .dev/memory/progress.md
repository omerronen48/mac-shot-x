# Progress

Phase status owned by the /dev orchestrator only. States: `pending` `planned` `blocked` `done`.

Mode: `--auto` (unattended). Source roadmap: `docs/roadmaps/2026-07-21-macshot.md`.

## Phases

| # | Phase | Status | Notes |
|---|-------|--------|-------|
| M1 | Capture core | done | branch `exec/m1-capture-core-20260721` @ 67197ac; 18/18 tests, .app built; unmerged (human) |
| M2 | Quick-access overlay & history | done | branch `exec/m2-overlay-history-20260721` @ e1c1dc2; 29/29 tests; stacked on M1; unmerged |
| M3 | Annotation editor | done | branch `exec/m3-annotation-editor-20260721` @ 57adb15 (git-verified); 47/47 tests; stacked on M2; unmerged |
| M4 | Beautify | planned | plan: docs/plans/2026-07-21-m4-beautify.md (6 tasks); stacks on M3 branch |
| M5 | OCR | pending | depends M1 (parallel-safe with M3/M4) |
| M6 | Ship | pending | depends M1–M5 |

## Log
- 2026-07-21 — imported 6 milestones from roadmap, all pending. Loop starts at M1.
- 2026-07-21 — **M1 done.** 15/15 tasks, 16 commits, all task-reviews PASS. `swift test` 18/18, `swift build` clean, universal ad-hoc-signed `MacShot.app` produced. Branch `exec/m1-capture-core-20260721` @ 67197ac in worktree `/Users/omes/macshot-exec-m1-capture-core`; master untouched, unmerged (--auto no-merge; human integrates). 6 `[auto]` decisions, 4 Swift/SCK lessons logged. Orphan `Sources/MacShotCore/Placeholder.swift` (T1 scaffold) — remove opportunistically in M2.

## Integration note (--auto stacking)
Phases don't merge to master (no-merge rule). Dependent phases stack: M2 branches off M1's branch, M3 off M2, etc. Human merges the stack after review. M5 (depends M1 only) also stacks on M1's branch.

## M2 — Quick-access overlay & history — DONE 2026-07-21
- Branch `exec/m2-overlay-history-20260721` at e1c1dc2, STACKED on M1 (`exec/m1-capture-core-20260721` @ 67197ac). Worktree /Users/omes/macshot-exec-m2-overlay-history.
- 8 tasks / 5 waves, all reviewed PASS. Core: T1 PinStore, T2 OverlayStack, T3 CaptureResult+image (Placeholder.swift deleted), T4 HistoryStore/HistoryEntry. Shell: T5 QuickAccessPanel, T6 HistoryWindow, T7 OverlayController, T8 AppDelegate wiring.
- Final gate: `swift build` clean; `swift test` 29/29 XCTest (M1 18 + M2 11). No merge to master (--auto no-merge; M1+M2 stack awaits human review/merge).
- Deferred to human DoD: manual acceptance (real capture→panel, drag-out to Slack/mail, History grid pin/delete, rapid-capture stacking + ~8s auto-dismiss). GUI tasks had no automated tests by design.
- Next: M3 (editor/annotations) per roadmap; stacks on M2.
- 2026-07-21 — **M2 done.** 8/8 tasks, all reviews PASS. `swift test` 29/29 (M1 18 + M2 11). `swift build` clean. Branch `exec/m2-overlay-history-20260721` @ e1c1dc2, stacked on M1 (base verified). 11 `[auto]` decisions, 3 lessons. Notable: T4 added `resolvingSymlinksInPath()` for pin-path comparison (macOS temp symlink). Unmerged (human integrates M1→M2 stack).
- 2026-07-21 — **M3 execution done (exec).** 9/9 tasks, all task-reviews PASS. Branch `exec/m3-annotation-editor-20260721` @ 57adb15, stacked on M2 (`exec/m2-overlay-history-20260721` @ e1c1dc2). `swift build` clean; `swift test` **47/47** (M1 18 + M2 11 + M3 18). Core (T1-T5) strict TDD incl. real CoreImage/CoreGraphics pixel+blur assertions; GUI shell (T6-T9) build-gated. MacShotCore stays AppKit-free (CoreText CFString keys, RGBAColor→CGColor). T9 expanded manifest by 1 file (OverlayController — panel-action router needs the .edit case); non-destructive editor export writes a NEW annotated PNG + clipboard via M1 SystemSink. Unmerged (--auto no-merge; human integrates M1→M2→M3 stack). Notable execution hazard: agent-reported commit SHAs were unreliable (mis-transcribed for T5-T8; T9 write-then-commit timing races) — orchestrator verified every commit via git cat-file/reflog; a stray memory commit was soft-reset off the code branch. See lessons.md "Agent report trust".
- 2026-07-21 — **M3 done.** 9/9 tasks, all reviews PASS. `swift test` 47/47 (M1 18 + M2 11 + M3 18). `swift build` clean. Branch `exec/m3-annotation-editor-20260721` @ 57adb15, stacked on M2 — **independently git-verified** (9 commits, chains to e1c1dc2, master untouched). 13 `[auto]` decisions. T9 expanded manifest by 1 (OverlayController.swift = panel-action router for `.edit`). Unmerged.
