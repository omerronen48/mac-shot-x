import AppKit
import MacShotCore

@MainActor final class PinController {

    private var windows: [PinnedWindow] = []

    func pin(_ image: CGImage) {
        var screen = NSScreen.main?.visibleFrame
            ?? NSScreen.screens.first?.visibleFrame
            ?? .zero
        // ponytail: guard zero rect so PinGeometry.initialFrame produces a usable frame
        if screen == .zero { screen = CGRect(x: 0, y: 0, width: 1440, height: 900) }

        let frame = PinGeometry.initialFrame(
            imageSize: CGSize(width: image.width, height: image.height),
            screen: screen
        )

        var window: PinnedWindow!
        window = PinnedWindow(image: image, frame: frame) { [weak self, weak window] in
            guard let self, let window else { return }
            self.windows.removeAll { $0 === window }
            // ponytail: PinnedWindow.closePin already calls orderOut; no double-close here
        }
        windows.append(window)
        window.makeKeyAndOrderFront(nil)
    }
}
