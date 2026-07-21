import ServiceManagement

/// Register/unregister MacShot as a macOS login item (open at startup). Backed by
/// SMAppService — the system is the source of truth, so `isEnabled` reflects real status.
enum LoginItem {
    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    @discardableResult
    static func setEnabled(_ on: Bool) -> Bool {
        do {
            if on {
                if SMAppService.mainApp.status != .enabled { try SMAppService.mainApp.register() }
            } else {
                if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
            }
            return true
        } catch {
            NSLog("LoginItem: failed to \(on ? "register" : "unregister"): \(error)")
            return false
        }
    }
}
