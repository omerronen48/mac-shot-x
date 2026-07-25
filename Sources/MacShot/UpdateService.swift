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

    /// Only download release assets served by GitHub — the URL comes from the API response,
    /// so verify its host before fetching+opening (defense against a spoofed API response).
    static func isTrustedGitHubHost(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "https", let host = url.host?.lowercased() else { return false }
        return host == "github.com" || host == "objects.githubusercontent.com" || host.hasSuffix(".githubusercontent.com")
    }

    static func latestRelease() async -> Release? {
        guard let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest") else { return nil }
        var req = URLRequest(url: url)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        req.timeoutInterval = 15   // don't hang forever on a flaky network
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
                alert("You’re up to date", "mac-shot-X \(currentVersion) is the latest version.")
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
        guard isTrustedGitHubHost(url) else {
            alert("Update blocked", "The update download URL is not a trusted GitHub host. Open the Releases page manually.")
            return
        }
        Task {
            let dest = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Downloads/mac-shot-X-update.dmg")
            guard let (tmp, _) = try? await URLSession.shared.download(from: url) else {
                alert("Download failed", "Couldn’t download the update. Try the Releases page.")
                return
            }
            try? FileManager.default.removeItem(at: dest)
            do {
                try FileManager.default.moveItem(at: tmp, to: dest)
                NSWorkspace.shared.open(dest)   // mounts the DMG; user drags mac-shot-X to Applications
            } catch {
                NSWorkspace.shared.open(tmp)     // fall back to the just-downloaded temp file, never a stale one
            }
        }
    }

    @MainActor private static func alert(_ title: String, _ message: String) {
        let a = NSAlert(); a.messageText = title; a.informativeText = message; a.runModal()
    }
}
