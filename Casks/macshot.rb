cask "macshot" do
  version "0.1.0"
  sha256 "897147bc52db5f935f2f25631f9dbdd2fb30a986ba28e8254e67299e92a4fb41"

  # Points at the DMG committed to the repo. For versioned releases, switch this to the
  # release asset, e.g.:
  #   url "https://github.com/omerronen48/mac-shot-x/releases/download/v#{version}/MacShot.dmg"
  url "https://github.com/omerronen48/mac-shot-x/raw/main/MacShot.dmg"
  name "MacShot"
  desc "Native macOS screenshot tool — capture, overlay, annotate, beautify, OCR"
  homepage "https://github.com/omerronen48/mac-shot-x"

  depends_on macos: ">= :sonoma"

  app "mac-shot-X.app"

  # MacShot needs Screen Recording permission; grant it on first capture.
  caveats <<~EOS
    On first launch, grant MacShot the Screen Recording permission when prompted
    (System Settings → Privacy & Security → Screen Recording), then relaunch.
  EOS

  zap trash: [
    "~/Library/Preferences/com.omerronen.macshot.plist",
  ]
end
