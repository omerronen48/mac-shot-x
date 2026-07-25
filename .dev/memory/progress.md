# Progress

Phase status owned by the /dev orchestrator only. States: `pending` `planned` `blocked` `done`.

Mode: `--auto` (unattended). Source roadmap: `docs/roadmaps/2026-07-21-macshot.md`.

## Phases

| # | Phase | Status | Notes |
|---|-------|--------|-------|
| M1 | Capture core | done | branch `exec/m1-capture-core-20260721` @ 67197ac; 18/18 tests, .app built; unmerged (human) |
| M2 | Quick-access overlay & history | done | branch `exec/m2-overlay-history-20260721` @ e1c1dc2; 29/29 tests; stacked on M1; unmerged |
| M3 | Annotation editor | done | branch `exec/m3-annotation-editor-20260721` @ 57adb15 (git-verified); 47/47 tests; stacked on M2; unmerged |
| M4 | Beautify | done | branch `exec/m4-beautify-20260721` @ 8130bb0 (git-verified); 66/66 tests; stacked on M3; unmerged |
| M5 | OCR | done | branch `exec/m5-ocr-20260721` @ 4fc1b78 (git-verified); 73/73 tests; stacked on M4; unmerged |
| M6 | Ship | done | branch `exec/m6-ship-20260721` @ c1cf906 (a7b4f88 + run-found icon-import fix); 77/77 tests; stacked on M5; unmerged |

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

## M4 — Beautify — DONE 2026-07-21
- Branch `exec/m4-beautify-20260721` @ 8130bb0, STACKED on M3 (`exec/m3-annotation-editor-20260721` @ 57adb15). Worktree /Users/omes/macshot-exec-m4-beautify.
- 6 tasks / 4 waves (+1 T2-review-fix commit = 7 commits), all reviewed PASS. Core (TDD): T1 BeautifyStyle/Background/Shadow/Preset+builtins, T2 BeautifyRenderer (CGGradient/shadow/rounded-corner + 8192 clamp; T2-fix repaired a non-functional clamp caught in review), T3 PresetStore. Shell (build-gate): T4 EditorCanvas live preview, T5 BeautifyPanel, T6 EditorWindow export via BeautifyRenderer + host panel.
- Final gate: `swift build` clean; `swift test` **66/66** (M1 18 + M2 11 + M3 18 + M4 19), 0 failures. MacShotCore stays AppKit-free. Branch integrity git-verified (HEAD==ref, chains to 57adb15, no .dev/memory committed, master untouched @ 00f6a67).
- Export pipeline non-destructive: AnnotationRenderer.flatten(base,doc) → BeautifyRenderer.render(_, vm.beautifyStyle) → clipboard + NEW PNG (mode "beautified"); .none is a true passthrough (M3 behavior preserved).
- Deferred to human DoD: manual acceptance (editor→beautify panel: bg types, padding/corner/shadow, presets save/load/delete, scale 1×/2×/3×, Export → beautified PNG + clipboard, original untouched). GUI tasks had no automated tests by design.
- Notable: T2 review caught a real critical bug (8192 clamp reduced scale but not bitmap size → oversized allocation) — fixed in follow-up 7f139b9 with a clamp regression test. One reviewer hit a transient API rate-limit (no verdict) and was cleanly re-dispatched. Agent SHAs cross-checked via git at every commit (accurate this run).
- Next: M5 (OCR; depends M1, parallel-safe — stacks on M1 or M4 per orchestrator) then M6 (Ship).
- 2026-07-21 — **M4 done.** 6/6 tasks (+1 review-fix), all reviews PASS. `swift test` 66/66. `swift build` clean. Branch `exec/m4-beautify-20260721` @ 8130bb0, stacked on M3 — independently git-verified. 18 `[auto]` decision/review entries, 8 CGGradient/shadow/orchestration lessons. Unmerged (--auto no-merge; human integrates the M1→M2→M3→M4 stack).
- 2026-07-21 — **M5 done.** 5 tasks + T5-fix, all reviews PASS. `swift test` 73/73 (M1 18 + M2 11 + M3 18 + M4 19 + M5 7). Branch `exec/m5-ocr-20260721` @ 4fc1b78, stacked on M4 — git-verified (6 commits, chains to 8130bb0, master untouched @ 1f8ac25). Review caught a real digit-only-HotkeySpec bug (⌃⌘⇧O was a silent no-op) → fixed with A–Z keycodes. 8 `[auto]` decisions, 1 lessons block. Unmerged.
- 2026-07-21 — **M6 done (FINAL milestone).** 6 tasks, 4 waves (W1 parallel×3: HotkeyRecorder ‖ Scripts ‖ CI), all reviews PASS, zero iterations. `swift test` 77/77 (M1 18 + M2 11 + M3 18 + M4 19 + M5 7 + M6 4). `swift build` clean. Deliverables: HotkeyRecorder core (TDD), notarized-DMG + placeholder-icon scripts (bash -n OK; make_dmg.sh exits 1 w/o Developer ID by design — NOT executed here), GitHub Actions CI (valid YAML), HotkeyRecorderField + PreferencesWindow polish (build+manual-smoke), README (prominent $99/yr Developer ID prerequisite). Branch `exec/m6-ship-20260721` @ a7b4f88 stacked on M5 (base 4fc1b78) — git-verified: HEAD==ref, 6 commits chain to base, diffstat==manifest (11 files), 0 .dev/memory committed. Unmerged (--auto no-merge; human integrates the full M1→M6 stack). HUMAN DoD remaining: notarize with real Developer ID creds + friend installs the DMG. **All 6 roadmap milestones now built.**
- 2026-07-21 — **M6 done. ROADMAP COMPLETE.** 6 tasks, all reviews PASS. `swift test` 77/77 (M1 18 + M2 11 + M3 18 + M4 19 + M5 7 + M6 4). Branch `exec/m6-ship-20260721` @ a7b4f88, stacked on M5 — git-verified (6 commits, chains to 4fc1b78, master untouched, 0 .dev/memory committed). Ship artifacts: make_dmg.sh (notarize, bash -n clean, exits 1 w/o creds), make_icon.sh, ci.yml (valid YAML), README, HotkeyRecorder + recorder field + prefs polish. 9 `[auto]` decisions. No escalation.

## ROADMAP COMPLETE — all 6 milestones built (2026-07-21)
Stacked branches M1→M2→M3→M4→M5→M6 off `master` (untouched). Human integrates the stack + runs manual DoDs.
**Human prerequisite for M6 DoD:** Apple Developer ID ($99/yr) to run `Scripts/make_dmg.sh` (notarize) → distributable DMG. All code/scripts/CI/README ship regardless.

## v2 Phases (roadmap: docs/roadmaps/2026-07-23-macshot-v2.md) — parity with sw33tLie/macshot v4.2.1

| # | Phase | Status | Notes |
|---|-------|--------|-------|
| M7 | Capture conveniences | done | branch `exec/m7-capture-conveniences-20260723` @ 2a08ad2 (git-verified); 93/93 tests; off main; unmerged |
| M8 | Editor parity | done | branch `exec/m8-editor-parity-20260723` @ 8a85ba8 (git-verified); 104/104; stacks on M7; unmerged |
| M9 | QR & barcode reading | done | branch `exec/m9-qr-barcode-20260723` @ 286145e (git-verified); 110/110 tests (M1–M8 104 + M9 6); stacks on M8; unmerged |
| M10 | Settings & menu-bar polish | done | branch `exec/m10-settings-menubar-20260723` @ 694746d (git-verified); 120/120; stacks on M9; unmerged |
| M11 | Pin-to-screen | done | branch `exec/m11-pin-to-screen-20260723` @ f69dc52 (git-verified); 123/123; stacks on M10; unmerged |
| M12 | Screen recording (core) | skipped | dropped by user 2026-07-24 — recording out of scope |
| M13 | Recording overlays & editor | skipped | dropped by user 2026-07-24 (depends on M12) |
| M14 | Cloud upload & sharing | skipped | dropped by user 2026-07-24 |
| M15 | Live translation overlay | skipped | dropped by user 2026-07-24 (macOS 15+ dependency) |
| M16 | AI auto-redact | done | branch `exec/m16-auto-redact-20260723` @ 7e6c117 (git-verified); 134/134; stacks on M11; unmerged |
| M17 | Scrolling capture | done | branch `exec/m17-scrolling-capture-20260723` @ 654c2fb (git-verified); 138/138; stacks on M16; unmerged |
| M18 | Localization (i18n) | done | branch `exec/m18-localization-20260723` @ 9a04cb8 (git-verified); 142/142; stacks on M17; unmerged |

## Log (v2)
- 2026-07-23 — v2 roadmap authored (M7–M18) for parity with sw33tLie/macshot v4.2.1. Loop resumes at M7. M7–M11 tractable/parallel-friendly; M12–M17 design-heavy (brainstorm + ESCALATE flagged forks); M18 (i18n) last.

## M7 — Capture conveniences — DONE 2026-07-23 (exec)
- Branch `exec/m7-capture-conveniences-20260723` @ 2a08ad2, based on `main` (241ee7d — the repo's integration branch; task said "master" but no master ref exists, main has M1–M6+M7 docs). Worktree /Users/omes/macshot-exec-m7-capture-conveniences. NOT merged (human integrates).
- 9 tasks / 3 waves, all reviews PASS. W1 core (strict TDD): T1 DownscaleTransform, T2 LoupeGeometry, T3 CountdownModel, T4 Preferences (+9 M7 fields). W2 shell (build-gated): T5 CountdownView (AppKit borderless countdown), T6 SCKScreenCapturer (showsCursor + downscale + captureDisplayImage helper), T7 SelectionOverlay loupe (samples cached snapshot only — NO cacheDisplay, grep-verified), T8 PreferencesWindow (Capture+Loupe section). W3: T9 AppDelegate (self-timer via withCheckedContinuation, Capture Last Area via skipOverlay reusing .area(rect), loupe-snapshot wiring, hotkey id 5).
- W1 and W2 SERIALIZED (single MacShotCore / single MacShot exe compile target races parallel sibling writers); no graphify (Swift unsupported) so file-level overlap only. Peak intended parallelism 4 but executed serial per lessons; reviewers ran in parallel.
- Final gate: `swift build` clean; `swift test` **93/93** (M1 18 + M2 11 + M3 18 + M4 19 + M5 7 + M6 4 + M7 core 12), 0 failures. MacShotCore stays AppKit-free. Branch integrity git-verified (HEAD==ref, 9 commits chain to 241ee7d, no .dev/memory committed, only the 13 manifest files touched).
- Deferred to human DoD: manual acceptance (3s self-timer → capture; drag area then Capture Last Area re-captures it; cursor toggle + downscale reflected in output ~4× smaller; loupe magnifies under cursor with no crash + edge clamp). GUI tasks build-gated, no fabricated unit tests by design.
- Notable: T6 window-mode capture sets showsCursor but does NOT downscale (only fullscreen/area do) — reviewer flagged as ambiguous-non-blocking follow-up. Loupe edge case: drawLoupe returns (no loupe) when cursor within loupeSize/(2·mag) of a snapshot edge (crop fails) — cosmetic follow-up (clamp sampleRect). Both non-blocking.
- 2026-07-23 — **M7 done.** 9/9 tasks, all reviews PASS. `swift test` 93/93. `swift build` clean. Branch `exec/m7-capture-conveniences-20260723` @ 2a08ad2, based on main (base independently git-verified). 9 `[auto]` decisions. 6 M7 lessons logged (loupe-no-recursion, cursor→pixel Y-flip, click-through Esc global monitor, Timer assumeIsolated, capturer prefs default+nonisolated(unsafe), serialize same-target GUI waves). Unmerged.
- 2026-07-23 — **M8 done.** 5/5 tasks, reviews PASS. `swift test` 104/104 (93 + 11 M8). Branch `exec/m8-editor-parity-20260723` @ 8a85ba8, stacked on M7 — git-verified (5 commits atop 2a08ad2). Additive kinds/styles; M3 back-compat proven (testM3EraJSONDecodesWithDefaults). 8 `[auto]` decisions, 6 lessons (TextAlignment module-collision, custom init(from:) disables encode synthesis, never pixel-assert emoji). Unmerged.
- 2026-07-23 — **M9 done.** 4/4 tasks, reviews PASS. `swift test` 110/110 (104 + 6 M9). Branch `exec/m9-qr-barcode-20260723` @ 286145e, stacked on M8 — git-verified. No new hotkey (folds into OCR capture). 7 `[auto]` decisions, 4 lessons (Vision's own BarcodeObservation type collides — module-qualify). Unmerged.
- 2026-07-24 — **M10 done.** 6 tasks (incl. T6 comma-keycode fix so the ⌃⌘⇧, lockout-guard hotkey registers). `swift test` 120/120 (110 + 10 M10). Branch `exec/m10-settings-menubar-20260723` @ 694746d, stacked on M9 — git-verified. Sparkle declined; hand-rolled updater kept. 8 `[auto]` decisions. Unmerged.
- 2026-07-24 — **M11 done.** 7/7 tasks, reviews PASS. `swift test` 123/123 (120 + 3 M11). Branch `exec/m11-pin-to-screen-20260723` @ f69dc52, stacked on M10 — git-verified. Ephemeral pins. Unmerged.
- 2026-07-24 — **PAUSE at M12 design gate.** M7–M11 done. Loop halted before the heavy tier (recording) per the user's "real design for big items" intent — awaiting recording scope/audio/codec decisions. Auto-resume switch armed.
- 2026-07-24 — **M16 done.** 2/2 tasks, reviews PASS. `swift test` 134/134 (123 + 11 M16). Branch `exec/m16-auto-redact-20260723` @ 7e6c117, stacked on M11 — git-verified. Regex PII detector (no ML dep); reused OCR + solidCensor. No y-flip (OCR + annotation both bottom-left). 10 `[auto]` decisions. Unmerged.
- 2026-07-24 — **M17 done.** 3/3 tasks, reviews PASS. `swift test` 138/138 (134 + 4 M17). Branch `exec/m17-scrolling-capture-20260723` @ 654c2fb, stacked on M16 — git-verified. Row-signature stitcher (pure, tested) + auto-scroll coordinator. Caught a multi-monitor flip-anchor bug via TDD. 8 `[auto]` decisions. Unmerged.

## M18 Localization — DONE (2026-07-24)
- Branch exec/m18-localization-20260723 (base exec/m17-scrolling-capture-20260723 @654c2fb). 4 commits: 4e8399c (T1 LocalizationAudit), 32f264c (T2 catalog+Package), 592f96c (T3 wrap), 9a04cb8 (T3 gap-fix). HEAD 9a04cb8.
- .xcstrings PROCESSED by SwiftPM (no .strings fallback). 20 curated keys en+es/fr/de. 18 wrapped at real sites, 2 catalog-only.
- Gate: swift build green, swift test 142/142 (138 M1–M17 preserved + 4 LocalizationAudit). All 3 tasks reviewer-PASS.
- NOT merged/pushed — left for human. FINAL roadmap phase.
- 2026-07-24 — **M18 done. v2 ROADMAP COMPLETE.** 3/3 tasks, reviews PASS. `swift test` 142/142 (138 + 4 M18). Branch `exec/m18-localization-20260723` @ 9a04cb8, stacked on M17 — git-verified. String Catalog (en+es/fr/de, 20 keys); .xcstrings processed by SwiftPM (no fallback). Unmerged.

## v2 COMPLETE (2026-07-24)
Built: M7,M8,M9,M10,M11,M16,M17,M18. Skipped by user: M12,M13 (recording), M14 (cloud), M15 (translation). Linear stack M1–M6(main) → M7 → M8 → M9 → M10 → M11 → M16 → M17 → M18. Human merges the stack. Loop disarmed.

## Post-v2 additions
| # | Phase | Status | Notes |
|---|-------|--------|-------|
| M19 | Area screen recording | planned | video-only MP4; area-only; SCStream+AVAssetWriter; stacks on main |
