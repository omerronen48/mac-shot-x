import AppKit
import MacShotCore

// ponytail: AppKit — one NSWindow + NSTextField, no SwiftUI needed for a number on screen

@MainActor
public final class CountdownView {

    private var window: CountdownWindow?

    public init() {}

    public func present(seconds: Int, onFinish: @escaping () -> Void, onCancel: @escaping () -> Void) {
        let w = CountdownWindow(seconds: seconds, onFinish: { [weak self] in
            self?.window = nil
            onFinish()
        }, onCancel: { [weak self] in
            self?.window = nil
            onCancel()
        })
        window = w
        w.makeKeyAndOrderFront(nil)
    }

    public func cancel() {
        window?.dismiss(finished: false)
    }
}

// MARK: - Window

@MainActor
private final class CountdownWindow: NSWindow {

    private var model: CountdownModel
    private let label: NSTextField
    private var timer: Timer?
    private let onFinish: () -> Void
    private let onCancel: () -> Void

    init(seconds: Int, onFinish: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.model = CountdownModel(seconds: seconds)
        self.onFinish = onFinish
        self.onCancel = onCancel

        let size: CGFloat = 200
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let cx = screen.frame.midX - size / 2
        let cy = screen.frame.midY - size / 2

        label = NSTextField(labelWithString: "\(seconds)")
        label.font = .monospacedDigitSystemFont(ofSize: 120, weight: .bold)
        label.textColor = .white
        label.alignment = .center
        label.frame = CGRect(x: 0, y: 0, width: size, height: size)

        super.init(
            contentRect: CGRect(x: cx, y: cy, width: size, height: size),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = NSColor(white: 0, alpha: 0.55)
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)))
        ignoresMouseEvents = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let view = NSView(frame: CGRect(x: 0, y: 0, width: size, height: size))
        view.addSubview(label)
        contentView = view

        makeFirstResponder(nil)  // click-through; Esc via global monitor below
        startTimer()
        installEscMonitor()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated { self.tick() }
        }
    }

    @MainActor private func tick() {
        model.tick()
        label.stringValue = "\(model.remaining)"
        if model.isDone {
            dismiss(finished: true)
        }
    }

    // MARK: Esc via global event monitor (window ignores mouse/key events)

    private var escMonitor: Any?

    private func installEscMonitor() {
        escMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Esc
                DispatchQueue.main.async { self?.dismiss(finished: false) }
            }
        }
    }

    func dismiss(finished: Bool) {
        timer?.invalidate()
        timer = nil
        if let m = escMonitor { NSEvent.removeMonitor(m); escMonitor = nil }
        orderOut(nil)
        if finished { onFinish() } else { onCancel() }
    }
}
