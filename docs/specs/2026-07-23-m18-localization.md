# Spec — M18: Localization (i18n)

> Milestone M18 of `docs/roadmaps/2026-07-23-macshot-v2.md` — the **final** v2 milestone. Autonomous under `/dev --auto`; open questions resolved with reversible `[auto]` defaults (see `.dev/memory/decisions.md` → phase18). Cross-cutting over M7–M17 UI; stacks on M17 branch `exec/m17-scrolling-capture-20260723`. No graphify graph — string surfaces read from the M17 branch.

## Mind map

```mermaid
mindmap
  root((M18 Localization))
    Components
      MacShotCore
        LocalizationAudit (CI guard)
      MacShot shell
        Localizable.xcstrings
        String(localized:) wrapping
      Package.swift
        defaultLocalization en
        .xcstrings resource
    Data flow
      UI string -> String(localized:) -> catalog
      catalog: en base + es/fr/de
      audit: required keys vs catalog
    Interfaces
      SwiftPM resource bundle (.module)
      Foundation String(localized:)
      system locale (dates/numbers)
    Risks
      SwiftPM .xcstrings processing
      missing translations (audit catches)
      filename stability (kept en_US_POSIX)
    Tests
      Unit audit finds missing keys
      Unit audit passes complete catalog
      Manual switch macOS language
```

## Purpose

Make MacShot translatable: migrate a curated set of user-facing strings to a String Catalog, ship base English plus a starter set (Spanish/French/German), and keep an automated guard against untranslated keys. The framework + starter set is the deliverable (not all 41 reference-app languages).

## Scope

**In:** a `Localizable.xcstrings` catalog; `defaultLocalization`/resource wiring in `Package.swift`; wrapping ~20–30 curated shell strings (menu items, primary buttons, notifications, top Preferences labels) in `String(localized:)`; a `LocalizationAudit` CI guard; locale-aware UI date/number formatting.

**Out (the contract):** translating every string / all 41 languages, localizing filenames (`FilenameFormatter` stays `en_US_POSIX` for stable filenames), pseudo-localization QA.

## Architecture

One pure guard in **MacShotCore** (headless-tested); the catalog + string-wrapping + package config in the shell.

**MacShotCore (new, TDD):**
- `LocalizationAudit` — `static func missingKeys(catalogJSON: Data, required: [String], languages: [String]) -> [String]`: decode the `.xcstrings` JSON (`{"strings": {"<key>": {"localizations": {"<lang>": {"stringUnit": {"value": ...}}}}}}` shape); a `required` key is missing if it has no source/base entry OR lacks a non-empty `stringUnit.value` for any `languages` entry. Returns the missing keys (empty = catalog complete). Deterministic.

**MacShot shell (new / modified, `swift build` + manual gate):**
- `Package.swift` **(modify)** — add `defaultLocalization: "en"` to the `MacShot` (and, if it carries strings, `MacShotCore`) target(s); add `resources: [.process("Localizable.xcstrings")]`.
- `Sources/MacShot/Localizable.xcstrings` **(new)** — the String Catalog: `sourceLanguage: "en"`, base English for the curated keys, and `es`/`fr`/`de` translations for each. Keys use the English text as the key (natural-key style) or short identifiers — pick natural keys for readability.
- **String wrapping (modify)** — replace the curated user-facing literals in `AppDelegate` (menu titles), `Notifier` (banner texts), `PreferencesWindow` (section/label/button text) with `String(localized: "…", bundle: .module)`. Curated set only (~20–30 strings); the rest stay literal for now.
- UI date/number formatting uses the system locale (default formatter behavior); the stable-filename formatter is untouched.

## Data flow

app renders a UI string → `String(localized: key, bundle: .module)` → resolves from `Localizable.xcstrings` for the user's locale (falls back to `en`). CI/test → `LocalizationAudit.missingKeys(catalog, required, ["es","fr","de"])` → fails the build if any curated key is untranslated.

## Interfaces

- **SwiftPM** — `defaultLocalization` + `.process` resource → a `.module` bundle.
- **Foundation** — `String(localized:bundle:)`, system-locale `DateFormatter`/`NumberFormatter` in the UI.

## Error handling

- A locale with no translation → falls back to the base English value (String Catalog default).
- Malformed/absent catalog JSON in the audit → treat all required keys as missing (fails loudly in CI).
- A curated key present in code but absent from the catalog → `LocalizationAudit` reports it.
- SwiftPM not processing `.xcstrings` (toolchain) → the build surfaces it; keys then resolve to their literal fallback (no crash).

## Testing

Unit (`swift test`, headless TDD):
- `LocalizationAudit.missingKeys`: a synthetic catalog missing `fr` for one key → returns that key; a catalog with base + all requested languages for every required key → returns `[]`; a key absent entirely → reported.
- (Optional) a test that loads the real `Localizable.xcstrings` and asserts `missingKeys(required: <the app's key list>, languages: ["es","fr","de"]) == []` — the live CI guard.

Manual (human DoD): set macOS system language to Spanish/French/German → the menu-bar items, key buttons, and notifications appear translated; English is the fallback for anything uncurated; filenames remain unchanged/stable.

## Open questions

None blocking — starter languages (es/fr/de), the curated ~20–30-key scope, skipped pseudo-localization, and non-localized filenames resolved with reversible `[auto]` defaults. Expanding coverage to more strings/languages is straightforward follow-on (add to the catalog; the audit guards it).
