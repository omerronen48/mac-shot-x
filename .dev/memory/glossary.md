# Glossary

- **Capture** — an image file + metadata (timestamp, mode, source display/window, dimensions). The central noun.
- **Annotation** — a vector element (arrow/shape/text/blur/step number) with geometry + style, belonging to a Capture. Non-destructive until export.
- **BeautifyStyle** — background/padding/shadow/corner config applied at export; presets are saved instances.
- **HistoryEntry** — a Capture's presence in history (file path + thumbnail); derived from the folder.
- **Preferences** — hotkeys, save location, filename format, after-capture behavior.
- **Capture Engine** — single entry point for all capture modes (area/window/full/OCR as a mode flag).
- **Quick-Access Overlay** — the floating post-capture hub; editor/pin/OCR/save are actions off it.
- **TCC** — macOS Transparency, Consent & Control; the screen-recording permission the app needs.
- **ScreenCaptureKit** — modern Apple capture API used instead of deprecated CGWindowListCreateImage.
