import SwiftUI
import AppKit
import MacShotCore

// MARK: - Model

@MainActor
final class HistoryModel: ObservableObject {
    @Published var entries: [HistoryEntry] = []
    private let store: HistoryStore

    init(store: HistoryStore) {
        self.store = store
        refresh()
    }

    func refresh() {
        entries = store.entries()
    }

    func delete(_ entry: HistoryEntry) {
        try? store.delete(entry)
        refresh()
    }

    func pin(_ entry: HistoryEntry) {
        store.pin(entry)
        refresh()
    }

    func unpin(_ entry: HistoryEntry) {
        store.unpin(entry)
        refresh()
    }
}

// MARK: - Thumbnail loader (downsampled via ImageIO)

private func loadThumbnail(url: URL, maxPixel: Int = 160) -> NSImage? {
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    let opts: [CFString: Any] = [
        kCGImageSourceThumbnailMaxPixelSize: maxPixel,
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
    ]
    guard let cgImg = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary) else { return nil }
    return NSImage(cgImage: cgImg, size: NSSize(width: cgImg.width, height: cgImg.height))
}

// MARK: - Thumbnail cell

private struct ThumbnailCell: View {
    let entry: HistoryEntry
    let onDelete: () -> Void
    let onPin: () -> Void
    let onUnpin: () -> Void
    let onEdit: () -> Void
    let onPinToScreen: () -> Void

    @State private var image: NSImage? = nil

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let img = image {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.secondary.opacity(0.15)
                }
            }
            .frame(width: 160, height: 120)
            .clipped()
            .cornerRadius(6)

            if entry.isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                    .padding(4)
            }
        }
        .contextMenu {
            Button("Edit") { onEdit() }
            Button("Pin to Screen") { onPinToScreen() }
            Button("Copy") { copyToPasteboard(entry.url) }
            Button("Reveal in Finder") { NSWorkspace.shared.activateFileViewerSelecting([entry.url]) }
            Divider()
            if entry.isPinned {
                Button("Unpin") { onUnpin() }
            } else {
                Button("Pin") { onPin() }
            }
            Divider()
            Button("Delete", role: .destructive) { onDelete() }
        }
        .task {
            // ponytail: off main thread thumbnail decode; detached so SwiftUI task isolation is satisfied
            let url = entry.url
            let img = await Task.detached(priority: .background) {
                loadThumbnail(url: url)
            }.value
            self.image = img
        }
    }

    private func copyToPasteboard(_ url: URL) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([url as NSURL])
    }
}

// MARK: - Grid view

struct HistoryGrid: View {
    @ObservedObject var model: HistoryModel
    var onChooseFolder: (() -> Void)?
    var onEdit: ((HistoryEntry) -> Void)?
    var onPinToScreen: ((HistoryEntry) -> Void)?

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 12)]
    private var pinned: [HistoryEntry] { model.entries.filter(\.isPinned) }
    private var rest:   [HistoryEntry] { model.entries.filter { !$0.isPinned } }

    var body: some View {
        Group {
            if model.entries.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        if !pinned.isEmpty {
                            Section {
                                ForEach(pinned, id: \.url) { cell($0) }
                            } header: {
                                Text("Pinned")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.bottom, 2)
                            }
                        }
                        if !rest.isEmpty {
                            Section {
                                ForEach(rest, id: \.url) { cell($0) }
                            } header: {
                                if !pinned.isEmpty {
                                    Text("Screenshots")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.bottom, 2)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(minWidth: 560, minHeight: 400)
    }

    private func cell(_ entry: HistoryEntry) -> some View {
        ThumbnailCell(
            entry: entry,
            onDelete:      { model.delete(entry) },
            onPin:         { model.pin(entry) },
            onUnpin:       { model.unpin(entry) },
            onEdit:        { onEdit?(entry) },
            onPinToScreen: { onPinToScreen?(entry) }
        )
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("No screenshots yet")
                .font(.title2)
                .foregroundStyle(.secondary)
            Button("Choose folder…") { onChooseFolder?() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Public entry point (mirrors PreferencesWindowController pattern)

@MainActor
public final class HistoryWindowController {
    private var window: NSWindow?
    private let model: HistoryModel

    /// Optional: called when user taps "Choose folder…" in empty state.
    public var onChooseFolder: (() -> Void)?
    /// Optional: called when user taps "Edit" on a history entry.
    public var onEdit: ((HistoryEntry) -> Void)?
    /// Optional: called when user taps "Pin to Screen" on a history entry.
    public var onPinToScreen: ((HistoryEntry) -> Void)?

    public init(store: HistoryStore) {
        model = HistoryModel(store: store)
    }

    public func show() {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let view = HistoryGrid(model: model,
                               onChooseFolder: { [weak self] in self?.onChooseFolder?() },
                               onEdit:         { [weak self] entry in self?.onEdit?(entry) },
                               onPinToScreen:  { [weak self] entry in self?.onPinToScreen?(entry) })
        let host = NSHostingController(rootView: view)
        let win  = NSWindow(contentViewController: host)
        win.title = "Screenshot History"
        win.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        win.setContentSize(NSSize(width: 700, height: 520))
        win.center()
        win.isReleasedWhenClosed = false
        self.window = win
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func refresh() {
        model.refresh()
    }
}
