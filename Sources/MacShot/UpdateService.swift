import AppKit
import Foundation
import MacShotCore

/// "Check for Updates": queries the latest GitHub release, compares versions, and — only on
/// explicit user action — downloads + opens the new DMG. No background/automatic network calls.
enum UpdateService {
    static let repo = "omerronen48/mac-shot-x"

    struct Release { let tag: String; let dmgURL: URL?; let htmlURL: URL? }

    static var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    static func latestRelease() async -> Release? {
        guard let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest") else { return nil }
        var req = URLRequest(url: url)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        guard let (data, _) = try? await URLSession.shared.data(for: req),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tag = json["tag_name"] as? String else { return nil }
        let assets = json["assets"] as? [[String: Any]] ?? []
        let dmg = assets.first { ($0["name"] as? String)?.lowercased().hasSuffix(".dmg") == true }
        return Release(tag: tag,
                       dmgURL: (dmg?["browser_download_url"] as? String).flatMap(URL.init),
                       htmlURL: (json["html_url"] as? String).flatMap(URL.init))
    }

    /// User pressed "Check for Updates". Fetches, compares, and presents the result.
    @MainActor static func checkForUpdates() {
        Task {
            guard let rel = await latestRelease() else {
                alert("Couldn’t check for updates", "No releases found, or the network is unavailable.")
                return
            }
            guard UpdateChecker.isNewer(rel.tag, than: currentVersion) else {
                alert("You’re up to date", "MacShot \(currentVersion) is the latest version.")
                return
            }
            let a = NSAlert()
            a.messageText = "Update available: \(rel.tag)"
            a.informativeText = "You have \(currentVersion). Download and open the new version?"
            a.addButton(withTitle: "Download")
            a.addButton(withTitle: "Later")
            if a.runModal() == .alertFirstButtonReturn {
                if let dmg = rel.dmgURL { downloadAndOpen(dmg) }
                else if let page = rel.htmlURL { NSWorkspace.shared.open(page) }
            }
        }
    }

    /// Download the DMG to ~/Downloads and open it (mounts for drag-install).
    @MainActor static func downloadAndOpen(_ url: URL) {
        Task {
            let dest = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Downloads/MacShot-update.dmg")
            guard let (tmp, _) = try? await URLSession.shared.download(from: url) else {
                alert("Download failed", "Couldn’t download the update. Try the Releases page.")
                return
            }
            try? FileManager.default.removeItem(at: dest)
            try? FileManager.default.moveItem(at: tmp, to: dest)
            NSWorkspace.shared.open(dest)   // mounts the DMG; user drags MacShot to Applications
        }
    }

    @MainActor private static func alert(_ title: String, _ message: String) {
        let a = NSAlert(); a.messageText = title; a.informativeText = message; a.runModal()
    }
}
