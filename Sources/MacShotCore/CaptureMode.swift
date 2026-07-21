import CoreGraphics

/// The single capture request type. Every mode is a case on this enum, not a
/// separate code path (roadmap: single Capture Engine entry point).
public enum CaptureMode: Equatable, Sendable {
    case area(CGRect?)         // nil = ask via overlay
    case window(CGWindowID?)   // nil = pick via overlay
    case fullscreen(CGDirectDisplayID?) // nil = main display

    public var slug: String {
        switch self {
        case .area: return "area"
        case .window: return "window"
        case .fullscreen: return "fullscreen"
        }
    }

    public var needsSelectionUI: Bool {
        switch self {
        case .area, .window: return true
        case .fullscreen: return false
        }
    }
}
