# MacShot

A free, native, on-device macOS screenshot tool. Runs in the menu bar — no dock icon, no cloud.

## Features

- **Capture** — area selection, window capture, and fullscreen via ScreenCaptureKit; global hotkeys; save to PNG or copy to clipboard.
- **Quick-access overlay & history** — floating post-capture panel (copy / save / delete / drag-out / pin); history browser showing a grid of past screenshots with pin support.
- **Annotation editor** — arrow, rectangle, ellipse, text, highlighter, blur, and numbered-step overlays; undo/redo; exports to a new annotated PNG (non-destructive).
- **Beautify** — share-ready export with solid/gradient/image backgrounds, padding, corner radius, shadow, and 1×/2×/3× scale; built-in and user-saved presets.
- **OCR** — on-device text recognition via Apple Vision (VNRecognizeTextRequest); copies recognized text to clipboard.

## Requirements

- macOS 14 (Sonoma) or later
- Apple Silicon or Intel (universal binary)

## Build from Source

```bash
swift build
```

Run tests:

```bash
swift test
```

Assemble the app bundle (ad-hoc signed, for local use):

```bash
bash Scripts/make_app.sh
```

This produces `MacShot.app`. Copy it to `/Applications` or run it in place.

## Install — Notarized Build (Signed for Distribution)

> **Prerequisite: Apple Developer Program membership ($99/year)**
> A notarized, Gatekeeper-trusted DMG requires a Developer ID certificate issued by Apple. Without an active paid membership you cannot produce a distributable signed build. This is a hard requirement — the script exits with an error if the credentials are absent.

Set your credentials, then build:

```bash
export DEVELOPER_ID_APP="Developer ID Application: Your Name (TEAMID)"
export AC_NOTARY_PROFILE="your-notarytool-profile"
bash Scripts/make_dmg.sh
```

The script codesigns with your Developer ID, packages a DMG, submits to Apple Notary Service via `xcrun notarytool`, and staples the ticket. It **will not emit an unsigned DMG** — it exits 1 if either environment variable is unset.

Drag `MacShot.dmg` → `/Applications` to install.

## Permissions

On first capture, macOS will prompt for **Screen Recording** access (TCC). Grant it in **System Settings → Privacy & Security → Screen Recording**.

## CI

GitHub Actions runs `swift build` and `swift test` on `macos-14` for every push and pull request. See `.github/workflows/ci.yml`.

## Status

**v0.1 — working title.**

Out of scope (per roadmap): cloud sync, video/screen recording, AI features, auto-update (Sparkle).

## License

TBD.
