# Decisions

Chronological log. Tags: `[interactive]` `[auto]` `[escalated]`.

## Roadmap-level (pre-seeded from docs/roadmaps/2026-07-21-macshot.md)
- Swift 6 + SwiftUI with AppKit interop (not Electron/Tauri) — native capture APIs, TCC, floating panels.
- ScreenCaptureKit for capture (not CGWindowListCreateImage, deprecated).
- Vision framework for OCR (not Tesseract) — free, on-device, zero-dep.
- SwiftUI Canvas for editor first; documented AppKit/CALayer fallback if perf fails (risk R2).
- Carbon `RegisterEventHotKey` hand-rolled (~50 LOC) instead of KeyboardShortcuts SPM lib; add lib only if hotkey-recording UI hurts.
- History = folder of PNG files + UserDefaults; no SQLite/Core Data.
- macOS 14+, universal binary; no back-compat code.
- No App Sandbox; Developer ID direct distribution (not App Store).
- Single Capture Engine entry point; every capture mode is a mode flag, not a separate path.
- Quick-Access Overlay is the hub; every capture lands there.

## /dev loop
- `[auto]` 2026-07-21 — greenfield, all 6 milestones seeded `pending`, none marked done; loop starts at M1. Rationale: empty repo (only `.claude/`, `docs/`), nothing built yet.
- `[auto]` 2026-07-21 — `git init` + baseline commit on `master`. Rationale: executing-plan-time worktree flow needs an existing repo with ≥1 commit; greenfield had none.
- `[auto]` 2026-07-21 — cron resume-guard install **denied** by auto-mode classifier (unauthorized persistence). Consequence: loop runs this session but will NOT auto-relaunch after a usage-limit/crash. User must re-run `/dev --auto` manually to resume, or grant the crontab permission. Auto-resume switch (`.dev/auto-resume`) still armed.
- `[auto]` 2026-07-21 — toolchain verified: Swift 6.3.3, Xcode 26.6, Apple Silicon. M1 build+test viable; ScreenCaptureKit/TCC boundary to be mocked for unit tests (real capture is human acceptance, not an automated gate).

### phase1/brainstorm (M1 — Capture core) — all `[auto]`, reversible
- App name: keep working title **MacShot**; bundle id `com.omerronen.macshot`, module `MacShot`. Rationale: roadmap working title; final name deferred to M6.
- Build system: **SwiftPM package**, not an Xcode `.xcodeproj`. Layout: `MacShotCore` library (all testable logic) + `MacShot` executable (thin GUI/AppKit/SCK shell) + `MacShotCoreTests`. `Scripts/make_app.sh` assembles `MacShot.app` (Info.plist `LSUIElement=true`) around the built binary. Rationale: `swift test` runs the core headless for TDD; zero runtime deps; CI-friendly. M6 may migrate to xcodebuild or keep SwiftPM. Reversible.
- Test boundary: `CaptureEngine` depends on a `ScreenCapturer` protocol; real impl = ScreenCaptureKit, tests = fake returning a canned `CGImage`. GUI shell (status item, Carbon hotkeys, overlay window, TCC prompt) is manually verified, not unit-tested. Rationale: keeps the untestable GUI/TCC surface thin; logic is 100% testable.
- Selection UI: full-screen dimmed overlay (semi-transparent dark) across all displays, crosshair cursor, live dimension readout by cursor, magnifier loupe for pixel precision, drag rectangle, Space to reposition mid-drag, Esc cancels, release confirms. Mirrors macOS ⌘⇧4. Reversible.
- Window-highlight UX: window mode highlights the window under the cursor (tinted border), click captures it; window list + frames from `SCShareableContent`. Reversible.
- Hotkey defaults (avoid system ⌘⇧3/4/5/6 range; user rebinds in M6): Area `⌘⇧2`, Window `⌃⌘⇧2`, Fullscreen `⌃⌘⇧3`. Placeholders. Reversible.
- After-capture behavior default: copy to clipboard AND save file to save dir, then post a `UserNotifications` banner. No overlay/editor (out of scope M1). Reversible.
- Prefs storage: `UserDefaults` (save dir bookmark, filename format string, capture hotkeys, after-capture toggle). Rationale: matches roadmap "PNG files + UserDefaults, no DB".

### phase1/plan (M1 — Capture core) — all `[auto]`
- Extracted `SelectionGeometry` (drag→rect/clamp/min-size) into `MacShotCore` so overlay math is unit-tested and the AppKit overlay stays a renderer. Testable core vs manually-verified GUI shell is the plan's verification split.
- GUI-shell tasks (T8–T14) gate on `swift build` + a manual-smoke checklist item, not fabricated unit tests — AppKit/ScreenCaptureKit/Carbon/TCC can't run in headless `swift test`. TDD-before-commit is strict for `MacShotCore` (T2–T7).
- 15 tasks, 6 waves; peak parallelism 6 (W4 GUI shell). Plan: `docs/plans/2026-07-21-m1-capture-core.md`.
- Universal binary via `swift build -c release --arch arm64 --arch x86_64`; ad-hoc codesign for local dev (Developer ID signing deferred to M6).
