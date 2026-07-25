import Carbon.HIToolbox
import AppKit
import MacShotCore

// ponytail: @MainActor pins all state to the main actor; avoids sending-across-isolation errors in Swift 6
@MainActor
final class HotkeyManager {
    private var refs: [UInt32: EventHotKeyRef] = [:]
    private var handlers: [UInt32: () -> Void] = [:]
    private var eventHandlerRef: EventHandlerRef?

    init() {
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        // ponytail: pass self as refcon; restored inside the C callback below
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(),
                            hotkeyEventHandler,
                            1, &eventSpec,
                            selfPtr,
                            &eventHandlerRef)
    }

    /// Returns false when the OS refuses the hotkey (e.g. already claimed by another app) —
    /// previously this failed silently, so the user set a shortcut that did nothing.
    @discardableResult
    func register(_ spec: HotkeySpec, id: UInt32, handler: @escaping () -> Void) -> Bool {
        var ref: EventHotKeyRef?
        let hkID = EventHotKeyID(signature: fourCharCode("MSHT"), id: id)
        let status = RegisterEventHotKey(spec.keyCode, spec.carbonModifierMask,
                                         hkID, GetApplicationEventTarget(), 0, &ref)
        guard status == noErr, let ref else {
            NSLog("HotkeyManager: hotkey id=\(id) failed to register (status \(status)) — likely already in use by another app")
            handlers[id] = handler   // keep the intent; re-register may succeed after unregisterAll
            return false
        }
        refs[id] = ref
        handlers[id] = handler
        return true
    }

    func unregisterAll() {
        refs.values.forEach { UnregisterEventHotKey($0) }
        refs.removeAll()
        handlers.removeAll()
    }

    // ponytail: Carbon fires on the main thread; assumeIsolated is safe and avoids a hop
    nonisolated func invoke(id: UInt32) {
        MainActor.assumeIsolated { self.handlers[id]?() }
    }
}

// C-compatible callback — cannot capture Swift context; uses refcon
private func hotkeyEventHandler(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event, let userData else { return OSStatus(eventNotHandledErr) }
    var hkID = EventHotKeyID()
    let status = GetEventParameter(event,
                                   EventParamName(kEventParamDirectObject),
                                   EventParamType(typeEventHotKeyID),
                                   nil,
                                   MemoryLayout<EventHotKeyID>.size,
                                   nil,
                                   &hkID)
    guard status == noErr else { return OSStatus(eventNotHandledErr) }
    let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
    let id = hkID.id
    manager.invoke(id: id)
    return noErr
}

private func fourCharCode(_ s: String) -> OSType {
    // ponytail: fold exactly 4 ASCII chars into OSType (big-endian UInt32)
    s.utf8.prefix(4).reduce(0 as OSType) { ($0 << 8) | OSType($1) }
}
