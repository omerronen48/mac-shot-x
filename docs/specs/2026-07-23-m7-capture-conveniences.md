# Spec — M7: Capture Conveniences

> Milestone M7 of `docs/roadmaps/2026-07-23-macshot-v2.md`. Autonomous under the v2 loop; open questions resolved with reversible `[auto]` defaults (see `.dev/memory/decisions.md` → phase7). Builds on shipped M1–M6 (on `master`). No graphify graph — M1–M6 API known from building them.

## Mind map

```mermaid
mindmap
  root((M7 Capture Conveniences))
    Components
      MacShotCore
        Preferences +fields
        DownscaleTransform
        LoupeGeometry
        CountdownModel
      MacShot shell
        CountdownView window
        SelectionOverlay loupe
        SCKScreenCapturer cursor/downscale
        AppDelegate delay + last-area
        PreferencesWindow controls
    Data flow
      hotkey -> delay countdown -> capture
      area select -> save lastAreaRect
      Capture Last Area -> capture(.area(lastRect))
      overlay present -> screen snapshot -> loupe samples it
      capture -> showsCursor + downscale -> save
    Interfaces
      SCStreamConfiguration.showsCursor
      display snapshot (SCScreenshotManager)
      UserDefaults prefs
    Risks
      loupe recursion (avoided: cached snapshot)
      snapshot latency before selection
      retina scale detection
    Tests
      Unit DownscaleTransform target size
      Unit LoupeGeometry sample+clamp
      Unit CountdownModel ticks
      Unit Preferences roundtrip (lastRect, delay, toggles, loupe)
      Manual countdown + loupe + cursor + downscale
```

## Purpose

Add the small capture-flow niceties from the reference app: a self-timer with countdown, one-key repeat of the last area, a cursor-in-shot toggle, a Retina-downscale option for smaller files, and a **correct** magnifier loupe for pixel-precise selection (the v1 loupe was removed for a recursion crash — this one samples a cached snapshot).

## Scope

**In:** self-timer / capture delay + on-screen countdown; Capture Last Area; capture-mouse-cursor toggle; downscale-Retina export option; magnifier loupe in the selection overlay.

**Out (the contract):** screen recording (M12), any editor/annotation changes (M8), OCR/QR (M9). No changes to the beautify/history/editor surfaces.

## Architecture

Testable logic in **MacShotCore**; GUI/system in the shell.

**MacShotCore (new / modified, TDD):**
- `Preferences` **(modify)** — add: `captureDelaySeconds: Int` (0), `captureCursor: Bool` (false), `downscaleRetina: Bool` (false), `lastAreaRect: CGRect?` (persisted as 4 doubles), and loupe settings `loupeSize: Double` (120), `loupeMagnification: Double` (8), `loupeOutlineEnabled: Bool` (true), `loupeOutlineColor: RGBAColor` (white).
- `DownscaleTransform` **(new)** — `targetSize(imagePixels: CGSize, displayScale: CGFloat, downscale: Bool) -> CGSize`: when `downscale` and `displayScale > 1`, return `imagePixels / displayScale` (→ 1× point-resolution, ~4× fewer pixels); else unchanged. Plus `downsampled(_ image: CGImage, to: CGSize) -> CGImage` (CGContext redraw) reused for save/export.
- `LoupeGeometry` **(new)** — `sampleRect(cursor: CGPoint, magnification: Double, loupeSize: Double) -> CGRect` (the source region under the cursor to magnify) and `loupeRect(cursor: CGPoint, loupeSize: Double, in bounds: CGRect) -> CGRect` (on-screen placement, offset from the cursor, clamped inside `bounds` so it never hangs off an edge). Pure geometry.
- `CountdownModel` **(new)** — `{ remaining: Int; init(seconds:); mutating func tick() -> Bool /* true when reaches 0 */ }`. Trivial but unit-tested (ticks, done-at-zero, zero-is-immediate).

**MacShot shell (new / modified, `swift build` + manual gate):**
- `SCKScreenCapturer` **(modify)** — set `SCStreamConfiguration.showsCursor = prefs.captureCursor`; after capture, if `downscaleRetina`, apply `DownscaleTransform` before returning/saving. Expose a `captureDisplayImage()` helper reused for the loupe snapshot.
- `SelectionOverlay` **(modify)** — accept a `screenshot: CGImage?` at present; when set, draw a magnifier loupe near the cursor by sampling `screenshot` at `LoupeGeometry.sampleRect(...)` and drawing into `LoupeGeometry.loupeRect(...)` with an outline. **Never** `cacheDisplay`/`bitmapImageRepForCachingDisplay` in `draw` (v1 crash). Loupe respects `loupe*` prefs; hidden if the snapshot is nil.
- `CountdownView` **(new)** — a borderless, click-through, centered `NSWindow` showing the countdown number; driven by `CountdownModel` on a 1s timer.
- `AppDelegate` **(modify)** — `runCapture` for area/window: if `captureDelaySeconds > 0`, show the countdown, then proceed; before presenting `SelectionOverlay`, capture the display image and pass it as `screenshot:` for the loupe. On a confirmed area selection, persist `prefs.lastAreaRect`. Add a **"Capture Last Area"** menu item + optional hotkey (`prefs.lastAreaHotkey`, default empty) that captures `.area(lastRect)` directly (no overlay) when a last rect exists.
- `PreferencesWindow` **(modify)** — a "Capture" section: delay picker (Off/3s/5s/10s), "Include mouse cursor" toggle, "Downscale Retina screenshots (~4× smaller)" toggle, a Capture-Last-Area hotkey recorder, and a "Loupe" subsection (enable outline, size, magnification, outline color).

## Data flow

**Delay:** hotkey/menu → `runCapture` → if delay>0 show `CountdownView` (CountdownModel ticks) → on zero, proceed. **Loupe:** before the overlay, `SCKScreenCapturer.captureDisplayImage()` → pass to `SelectionOverlay.present(screenshot:)` → `draw` samples it via `LoupeGeometry`. **Last area:** area confirm → `prefs.lastAreaRect = rect`; "Capture Last Area" → `engine.capture(.area(prefs.lastAreaRect!))`. **Cursor/downscale:** `SCKScreenCapturer` reads `captureCursor`/`downscaleRetina` per capture.

## Interfaces

- **ScreenCaptureKit** — `SCStreamConfiguration.showsCursor`; display snapshot for the loupe.
- **UserDefaults** — all new prefs via the existing `KeyValueStore`.
- **AppKit** — countdown window, overlay loupe drawing.

## Error handling

- No `lastAreaRect` yet → "Capture Last Area" no-ops with a notification ("No previous area").
- Loupe snapshot fails (TCC/first-run) → loupe simply not drawn; selection still works.
- Downscale on a non-retina display (scale 1) → no-op (returns original size).
- Countdown cancelled (Esc) → abort capture cleanly.
- `lastAreaRect` off-screen after a display change → clamp to the current display before capture; if empty, treat as no last area.

## Testing

Unit (`swift test`, headless TDD):
- `DownscaleTransform`: retina (scale 2) + downscale → half size; scale 1 → unchanged; downscale off → unchanged.
- `LoupeGeometry`: `sampleRect` centered on cursor with size = loupeSize/magnification; `loupeRect` clamps inside bounds near each edge/corner (never exceeds).
- `CountdownModel`: `init(3)` ticks 3→2→1→0 (done at 0); `init(0)` immediately done.
- `Preferences`: roundtrip `lastAreaRect`, `captureDelaySeconds`, `captureCursor`, `downscaleRetina`, loupe settings; defaults when unset.

Manual (human DoD): set a 3s delay → countdown → capture; drag an area, then "Capture Last Area" re-captures it; toggle cursor and confirm it appears/absent; toggle downscale and confirm smaller files; loupe magnifies under the cursor during selection with no crash.

## Open questions

None blocking — delays, loupe defaults, last-rect storage, and cursor default resolved with reversible `[auto]` defaults. The pre-selection snapshot latency is accepted for loupe precision; validated in manual acceptance.
