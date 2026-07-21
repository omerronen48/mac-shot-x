# Goals

**MacShot** (working title) — free, native macOS screenshot tool for the author (and eventually other devs). Replaces CleanShot X + covers BridgeShot's pitch: capture, quick-access overlay, annotate, beautify, OCR. 100% on-device, zero dependencies, menu-bar resident. Greenfield, solo.

## In scope v1
area/window/fullscreen capture, global hotkeys, quick-access overlay, history + pinned screenshots, vector annotation, beautify/export styling, OCR, settings, notarized DMG.

## Out of scope v1 (the contract — checked every milestone)
cloud upload/sharing, video/GIF recording, scrolling capture, AI features (smart blur, alt-text), licensing/payments, Sparkle auto-update.

## Non-functional targets
- **Latency:** hotkey → selection UI < 100ms; capture → overlay < 200ms
- **Memory:** idle < 50MB; no image leaks across repeated captures
- **Offline/privacy:** 100% on-device, zero network, zero telemetry; all data local plain files
- **Scale:** single user; history smooth at ~10k captures
- **Compat:** macOS 14+, Apple Silicon + Intel (universal binary)

## Data model spine
Capture (image + metadata, central noun) 1—N Annotation (vector, non-destructive); Capture 0..1 BeautifyStyle (applied at export); HistoryEntry 1—1 Capture (folder-derived); Preferences.

Source roadmap: `docs/roadmaps/2026-07-21-macshot.md`
