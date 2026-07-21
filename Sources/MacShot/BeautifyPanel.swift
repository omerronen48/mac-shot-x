import SwiftUI
import AppKit
import MacShotCore

// MARK: - BeautifyPanel

struct BeautifyPanel: View {
    @Bindable var vm: EditorViewModel

    // Local state for the save-preset flow
    @State private var presetName: String = ""
    @State private var savingPreset = false
    // Track selected preset name for delete
    @State private var selectedPresetName: String? = nil

    var body: some View {
        Form {
            backgroundSection
            sliderSection
            shadowSection
            scaleSection
            presetsSection
        }
        .formStyle(.grouped)
        .frame(minWidth: 280)
    }

    // MARK: - Background

    private var backgroundSection: some View {
        Section("Background") {
            Picker("Type", selection: bgTypePicker) {
                Text("Solid").tag(0)
                Text("Gradient").tag(1)
                Text("Image").tag(2)
            }
            .pickerStyle(.segmented)

            switch vm.beautifyStyle.background {
            case .solid:
                ColorPicker("Color", selection: solidColorBinding)
            case let .linearGradient(colors, angle):
                ColorPicker("Start color", selection: gradientColor0Binding(colors: colors, angle: angle))
                ColorPicker("End color", selection: gradientColor1Binding(colors: colors, angle: angle))
                Slider(value: gradientAngleBinding(colors: colors), in: 0...360, step: 1) {
                    Text("Angle")
                } minimumValueLabel: {
                    Text("0°")
                } maximumValueLabel: {
                    Text("360°")
                }
                Text("Angle: \(Int(currentGradientAngle))°").font(.caption).foregroundStyle(.secondary)
            case let .image(path):
                HStack {
                    Button("Choose Image…") { chooseImage() }
                    if path.isEmpty {
                        Text("None selected").foregroundStyle(.secondary).font(.caption)
                    } else {
                        Text((path as NSString).lastPathComponent)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
        }
    }

    // MARK: - Padding / Corner radius

    private var sliderSection: some View {
        Section("Frame") {
            LabeledContent("Padding: \(Int(vm.beautifyStyle.padding))") {
                Slider(value: $vm.beautifyStyle.padding, in: 0...200)
            }
            LabeledContent("Corner radius: \(Int(vm.beautifyStyle.cornerRadius))") {
                Slider(value: $vm.beautifyStyle.cornerRadius, in: 0...80)
            }
        }
    }

    // MARK: - Shadow

    private var shadowSection: some View {
        Section("Shadow") {
            Toggle("Enable shadow", isOn: shadowToggleBinding)
            if let _ = vm.beautifyStyle.shadow {
                LabeledContent("Radius: \(Int(vm.beautifyStyle.shadow!.radius))") {
                    Slider(value: Binding(
                        get: { vm.beautifyStyle.shadow?.radius ?? 24 },
                        set: { vm.beautifyStyle.shadow?.radius = $0 }
                    ), in: 0...60)
                }
                LabeledContent("Opacity: \(String(format: "%.2f", vm.beautifyStyle.shadow!.opacity))") {
                    Slider(value: Binding(
                        get: { vm.beautifyStyle.shadow?.opacity ?? 0.35 },
                        set: { vm.beautifyStyle.shadow?.opacity = $0 }
                    ), in: 0...1)
                }
                HStack {
                    Text("Offset X")
                    Slider(value: Binding(
                        get: { vm.beautifyStyle.shadow?.offset.width ?? 0 },
                        set: { vm.beautifyStyle.shadow?.offset.width = $0 }
                    ), in: -40...40)
                    Text("\(Int(vm.beautifyStyle.shadow?.offset.width ?? 0))")
                        .frame(width: 28, alignment: .trailing)
                }
                HStack {
                    Text("Offset Y")
                    Slider(value: Binding(
                        get: { vm.beautifyStyle.shadow?.offset.height ?? 10 },
                        set: { vm.beautifyStyle.shadow?.offset.height = $0 }
                    ), in: -40...40)
                    Text("\(Int(vm.beautifyStyle.shadow?.offset.height ?? 0))")
                        .frame(width: 28, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Scale

    private var scaleSection: some View {
        Section("Export Scale") {
            Picker("Scale", selection: scalePicker) {
                Text("1×").tag(1.0)
                Text("2×").tag(2.0)
                Text("3×").tag(3.0)
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Presets

    private var presetsSection: some View {
        Section("Presets") {
            // Load preset
            let presets = vm.presetStore.presets()
            Picker("Preset", selection: $selectedPresetName) {
                Text("—").tag(Optional<String>.none)
                ForEach(presets, id: \.name) { preset in
                    Text(preset.name).tag(Optional(preset.name))
                }
            }
            .onChange(of: selectedPresetName) { _, name in
                if let name, let p = presets.first(where: { $0.name == name }) {
                    vm.beautifyStyle = p.style
                }
            }

            // Delete (only user presets; deleting a builtin name is a no-op per PresetStore)
            if let name = selectedPresetName {
                Button("Delete \"\(name)\"", role: .destructive) {
                    vm.presetStore.delete(name: name)
                    selectedPresetName = nil
                }
            }

            // Save
            if savingPreset {
                HStack {
                    TextField("Name", text: $presetName)
                        .textFieldStyle(.roundedBorder)
                    Button("Save") {
                        let name = presetName.trimmingCharacters(in: .whitespaces)
                        guard !name.isEmpty else { return }
                        vm.presetStore.save(BeautifyPreset(name: name, style: vm.beautifyStyle))
                        selectedPresetName = name
                        presetName = ""
                        savingPreset = false
                    }
                    Button("Cancel") {
                        presetName = ""
                        savingPreset = false
                    }
                }
            } else {
                Button("Save current as…") { savingPreset = true }
            }
        }
    }

    // MARK: - Background type picker binding (0=solid, 1=gradient, 2=image)

    private var bgTypePicker: Binding<Int> {
        Binding(
            get: {
                switch vm.beautifyStyle.background {
                case .solid:           return 0
                case .linearGradient:  return 1
                case .image:           return 2
                }
            },
            set: { tag in
                switch tag {
                case 0:
                    vm.beautifyStyle.background = .solid(RGBAColor(r: 1, g: 1, b: 1, a: 1))
                case 1:
                    vm.beautifyStyle.background = .linearGradient(
                        colors: [RGBAColor(r: 0.2, g: 0.5, b: 1, a: 1),
                                 RGBAColor(r: 0.1, g: 0.2, b: 0.6, a: 1)],
                        angle: 135
                    )
                default:
                    vm.beautifyStyle.background = .image(path: "")
                }
            }
        )
    }

    // MARK: - Solid color binding

    private var solidColorBinding: Binding<Color> {
        Binding(
            get: {
                guard case let .solid(c) = vm.beautifyStyle.background else { return .white }
                return Color(.sRGB, red: c.r, green: c.g, blue: c.b, opacity: c.a)
            },
            set: { newColor in
                // ponytail: NSColor.sRGB extraction — same pattern as ToolPalette
                if let ns = NSColor(newColor).usingColorSpace(.sRGB) {
                    vm.beautifyStyle.background = .solid(RGBAColor(
                        r: Double(ns.redComponent),
                        g: Double(ns.greenComponent),
                        b: Double(ns.blueComponent),
                        a: Double(ns.alphaComponent)
                    ))
                }
            }
        )
    }

    // MARK: - Gradient bindings

    private func gradientColor0Binding(colors: [RGBAColor], angle: Double) -> Binding<Color> {
        Binding(
            get: {
                let c = colors.first ?? RGBAColor(r: 0, g: 0, b: 0, a: 1)
                return Color(.sRGB, red: c.r, green: c.g, blue: c.b, opacity: c.a)
            },
            set: { newColor in
                if let ns = NSColor(newColor).usingColorSpace(.sRGB) {
                    let c1 = colors.count > 1 ? colors[1] : RGBAColor(r: 0, g: 0, b: 0, a: 1)
                    vm.beautifyStyle.background = .linearGradient(
                        colors: [RGBAColor(r: Double(ns.redComponent), g: Double(ns.greenComponent),
                                           b: Double(ns.blueComponent), a: Double(ns.alphaComponent)), c1],
                        angle: angle
                    )
                }
            }
        )
    }

    private func gradientColor1Binding(colors: [RGBAColor], angle: Double) -> Binding<Color> {
        Binding(
            get: {
                let c = colors.count > 1 ? colors[1] : RGBAColor(r: 0, g: 0, b: 0, a: 1)
                return Color(.sRGB, red: c.r, green: c.g, blue: c.b, opacity: c.a)
            },
            set: { newColor in
                if let ns = NSColor(newColor).usingColorSpace(.sRGB) {
                    let c0 = colors.first ?? RGBAColor(r: 0, g: 0, b: 0, a: 1)
                    vm.beautifyStyle.background = .linearGradient(
                        colors: [c0, RGBAColor(r: Double(ns.redComponent), g: Double(ns.greenComponent),
                                               b: Double(ns.blueComponent), a: Double(ns.alphaComponent))],
                        angle: angle
                    )
                }
            }
        )
    }

    private func gradientAngleBinding(colors: [RGBAColor]) -> Binding<Double> {
        Binding(
            get: {
                guard case let .linearGradient(_, angle) = vm.beautifyStyle.background else { return 135 }
                return angle
            },
            set: { newAngle in
                vm.beautifyStyle.background = .linearGradient(colors: colors, angle: newAngle)
            }
        )
    }

    private var currentGradientAngle: Double {
        guard case let .linearGradient(_, angle) = vm.beautifyStyle.background else { return 135 }
        return angle
    }

    // MARK: - Shadow toggle binding

    private var shadowToggleBinding: Binding<Bool> {
        Binding(
            get: { vm.beautifyStyle.shadow != nil },
            set: { on in
                vm.beautifyStyle.shadow = on
                    ? BeautifyShadow(color: RGBAColor(r: 0, g: 0, b: 0, a: 1),
                                     radius: 24, opacity: 0.35,
                                     offset: CGSize(width: 0, height: 10))
                    : nil
            }
        )
    }

    // MARK: - Scale picker binding (Double ↔ segmented tag)

    private var scalePicker: Binding<Double> {
        $vm.beautifyStyle.scale
    }

    // MARK: - Image picker

    private func chooseImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .heic, .image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            vm.beautifyStyle.background = .image(path: url.path)
        }
    }
}
