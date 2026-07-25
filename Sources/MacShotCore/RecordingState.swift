/// Pure recording state — drives the stop pill + menu label. The actual capture is in the shell.
public struct RecordingState: Sendable {
    public private(set) var isRecording = false
    public private(set) var elapsedSeconds = 0
    public init() {}
    public mutating func start() { isRecording = true; elapsedSeconds = 0 }
    public mutating func stop() { isRecording = false }
    public mutating func tick() { if isRecording { elapsedSeconds += 1 } }
    public var label: String { String(format: "%d:%02d", elapsedSeconds / 60, elapsedSeconds % 60) }
}
