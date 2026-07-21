import AppKit
import SwiftUI
import MacShotCore

// MARK: - NSViewRepresentable wrapper

public struct HotkeyRecorderField: NSViewRepresentable {
    public let current: String
    public let onRecorded: (HotkeySpec) -> Void

    public init(current: String, onRecorded: @escaping (HotkeySpec) -> Void) {
        self.current = current
        self.onRecorded = onRecorded
    }

    public func makeNSView(context: Context) -> RecorderView {
        RecorderView(displayText: current, onRecorded: onRecorded)
    }

    public func updateNSView(_ nsView: RecorderView, context: Context) {
        nsView.displayText = current
    }
}

// MARK: - AppKit first-responder view

@MainActor
public final class RecorderView: NSView {

    public var displayText: String {
        didSet { needsDisplay = true }
    }

    private let onRecorded: (HotkeySpec) -> Void
    private var isRecording = false

    public init(displayText: String, onRecorded: @escaping (HotkeySpec) -> Void) {
        self.displayText = displayText
        self.onRecorded = onRecorded
        super.init(frame: NSRect(x: 0, y: 0, width: 140, height: 22))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: First responder

    override public var acceptsFirstResponder: Bool { true }

    override public func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        isRecording = true
        needsDisplay = true
    }

    override public func resignFirstResponder() -> Bool {
        isRecording = false
        needsDisplay = true
        return super.resignFirstResponder()
    }

    // MARK: Key capture

    override public func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Esc — cancel
            isRecording = false
            needsDisplay = true
            window?.makeFirstResponder(nil)
            return
        }
        guard let spec = HotkeyRecorder.spec(
            fromKeyCode: UInt32(event.keyCode),
            cocoaModifierRawValue: event.modifierFlags.rawValue
        ), !HotkeyRecorder.isReserved(spec) else {
            NSSound.beep()
            return
        }
        displayText = spec.description
        isRecording = false
        needsDisplay = true
        window?.makeFirstResponder(nil)
        onRecorded(spec)
    }

    // MARK: Drawing — button-style bordered label

    override public func draw(_ dirtyRect: NSRect) {
        let b = bounds

        // Background: lighter when recording
        let bg: NSColor = isRecording ? NSColor.selectedControlColor : NSColor.controlBackgroundColor
        bg.setFill()
        let path = NSBezierPath(roundedRect: b.insetBy(dx: 0.5, dy: 0.5), xRadius: 4, yRadius: 4)
        path.fill()

        // Border
        (isRecording ? NSColor.controlAccentColor : NSColor.separatorColor).setStroke()
        path.lineWidth = 1
        path.stroke()

        // Label
        let label = isRecording ? "Type shortcut…" : displayText
        let color: NSColor = isRecording ? .secondaryLabelColor : .labelColor
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
            .foregroundColor: color
        ]
        let str = NSAttributedString(string: label, attributes: attrs)
        let size = str.size()
        str.draw(at: NSPoint(x: (b.width - size.width) / 2, y: (b.height - size.height) / 2))
    }
}
