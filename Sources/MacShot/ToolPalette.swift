import SwiftUI
import MacShotCore
import AppKit

// ponytail: flat toolbar, no customization layer
struct ToolPalette: View {
    @Bindable var vm: EditorViewModel
    let onExport: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            toolButtons
            Divider().frame(height: 20)
            colorWell
            Stepper(value: $vm.style.lineWidth, in: 1...20, step: 1) {
                Text("\(Int(vm.style.lineWidth))pt")
                    .frame(width: 36, alignment: .trailing)
            }
            Divider().frame(height: 20)
            undoRedoButtons
            Divider().frame(height: 20)
            exportButton
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(shortcuts)
    }

    // MARK: Tool buttons

    private var toolButtons: some View {
        let items: [(Tool, String, String)] = [
            (.select,      "cursorarrow",          "v"),
            (.arrow,       "arrow.up.right",        "a"),
            (.rectangle,   "rectangle",             "r"),
            (.ellipse,     "circle",                "o"),
            (.text,        "textformat",            "t"),
            (.highlighter, "highlighter",           "h"),
            (.blur,        "drop",                  "b"),
            (.step,        "number.circle",         "s"),
        ]
        return ForEach(items, id: \.0.rawValue) { (tool, symbol, _) in
            Button {
                vm.activeTool = tool
            } label: {
                Image(systemName: symbol)
                    .frame(width: 24, height: 24)
                    .background(vm.activeTool == tool
                        ? Color.accentColor.opacity(0.25)
                        : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Color well

    private var colorWell: some View {
        let c = vm.style.strokeColor
        let binding = Binding<Color>(
            get: { Color(.sRGB, red: c.r, green: c.g, blue: c.b, opacity: c.a) },
            set: { newColor in
                // resolve via NSColor for RGBA extraction
                if let ns = NSColor(newColor).usingColorSpace(.sRGB) {
                    vm.style.strokeColor = RGBAColor(
                        r: Double(ns.redComponent),
                        g: Double(ns.greenComponent),
                        b: Double(ns.blueComponent),
                        a: Double(ns.alphaComponent)
                    )
                }
            }
        )
        return ColorPicker("", selection: binding)
            .labelsHidden()
            .frame(width: 28)
    }

    // MARK: Undo / Redo

    private var undoRedoButtons: some View {
        Group {
            Button { vm.undoAction() } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!vm.undo.canUndo)

            Button { vm.redoAction() } label: {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(!vm.undo.canRedo)
        }
        .buttonStyle(.plain)
    }

    // MARK: Export

    private var exportButton: some View {
        Button {
            onExport()
        } label: {
            Label("Export", systemImage: "square.and.arrow.up")
        }
        .keyboardShortcut("e", modifiers: .command)
    }

    // MARK: Hidden shortcut buttons

    @ViewBuilder
    private var shortcuts: some View {
        // undo/redo
        Button("") { vm.undoAction() }
            .keyboardShortcut("z", modifiers: .command).hidden()
        Button("") { vm.redoAction() }
            .keyboardShortcut("z", modifiers: [.command, .shift]).hidden()
        // delete selection
        Button("") { if let id = vm.selection { vm.delete(id: id) } }
            .keyboardShortcut(.delete, modifiers: []).hidden()
        // escape — deselect
        Button("") { vm.selection = nil; vm.activeTool = .select }
            .keyboardShortcut(.cancelAction).hidden()
        // tool letter keys
        Button("") { vm.activeTool = .select }      .keyboardShortcut("v", modifiers: []).hidden()
        Button("") { vm.activeTool = .arrow }       .keyboardShortcut("a", modifiers: []).hidden()
        Button("") { vm.activeTool = .rectangle }   .keyboardShortcut("r", modifiers: []).hidden()
        Button("") { vm.activeTool = .ellipse }     .keyboardShortcut("o", modifiers: []).hidden()
        Button("") { vm.activeTool = .text }        .keyboardShortcut("t", modifiers: []).hidden()
        Button("") { vm.activeTool = .highlighter } .keyboardShortcut("h", modifiers: []).hidden()
        Button("") { vm.activeTool = .blur }        .keyboardShortcut("b", modifiers: []).hidden()
        Button("") { vm.activeTool = .step }        .keyboardShortcut("s", modifiers: []).hidden()
    }
}

// Tool needs Hashable for ForEach id; rawValue for id
extension Tool: Hashable, RawRepresentable {
    typealias RawValue = Int
    init?(rawValue: Int) {
        let all: [Tool] = [.select, .arrow, .rectangle, .ellipse, .text, .highlighter, .blur, .step]
        guard rawValue >= 0, rawValue < all.count else { return nil }
        self = all[rawValue]
    }
    var rawValue: Int {
        switch self {
        case .select:      return 0
        case .arrow:       return 1
        case .rectangle:   return 2
        case .ellipse:     return 3
        case .text:        return 4
        case .highlighter: return 5
        case .blur:        return 6
        case .step:        return 7
        case .line:        return 8
        case .solidCensor: return 9
        case .emoji:       return 10
        }
    }
}
