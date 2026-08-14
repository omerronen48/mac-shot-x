import AppKit

// Top-level main.swift code runs on the main thread; assert that to the
// compiler so the MainActor-isolated AppKit setup type-checks under the
// newer toolchain (release built under Swift 5 semantics).
MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
