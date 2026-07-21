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
