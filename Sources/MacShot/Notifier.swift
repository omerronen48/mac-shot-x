import CoreGraphics
import Foundation
@preconcurrency import UserNotifications

// ponytail: stateless struct — Sendable free, no unsafe annotations needed
struct Notifier {
    // ponytail: nonisolated(unsafe) avoids storing non-Sendable UNUserNotificationCenter in a Swift-6 static
    private nonisolated(unsafe) static let center = UNUserNotificationCenter.current()

    // Request auth once, then deliver the given content.
    private static func post(_ content: UNMutableNotificationContent) {
        center.requestAuthorization(options: [.alert]) { granted, _ in
            guard granted else { return }
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
            center.add(request, withCompletionHandler: nil)
        }
    }

    func notifyCaptured(fileURL: URL?, size: CGSize) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Screenshot saved", bundle: .module)
        content.body = "\(Int(size.width))×\(Int(size.height))"

        if let url = fileURL,
           let attachment = try? UNNotificationAttachment(
               identifier: "thumbnail",
               url: url,
               options: nil
           ) {
            content.attachments = [attachment]
        }

        Notifier.post(content)
    }

    func notifyError(_ message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Screenshot failed"
        content.body = message
        Notifier.post(content)
    }

    func notify(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        Notifier.post(content)
    }
}
