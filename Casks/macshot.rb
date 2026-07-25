cask "macshot" do
  version "0.2.0"
  # DMG is a GitHub Release asset built by .github/workflows/release.yml on a `v*` tag
  # (not committed to the repo). Update version + sha256 for each new release.
  sha256 "faabe096485ce1a2fc1304f58f1f148549dd05a598d4baea453b77f71c1c2bf5"

  url "https://github.com/omerronen48/mac-shot-x/releases/download/v#{version}/mac-shot-x.dmg"
  name "mac-shot-X"
  desc "Native macOS screenshot tool — capture, overlay, annotate, beautify, OCR"
  homepage "https://github.com/omerronen48/mac-shot-x"

  depends_on macos: ">= :sonoma"

  app "mac-shot-X.app"

  # mac-shot-X needs Screen Recording permission; grant it on first capture.
  caveats <<~EOS
    On first launch, grant mac-shot-X the Screen Recording permission when prompted
    (System Settings → Privacy & Security → Screen Recording), then relaunch.
  EOS

  zap trash: [
    "~/Library/Preferences/com.omerronen.macshot.plist",
  ]
end
