cask "macshot" do
  version "0.2.0"
  # The DMG is published as a GitHub Release asset by .github/workflows/release.yml on a `v*`
  # tag — NOT committed to the repo. Pin a real sha256 per release once published; :no_check
  # lets the cask resolve before the first release exists.
  sha256 :no_check

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
