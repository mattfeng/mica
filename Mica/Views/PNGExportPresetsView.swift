import SwiftUI

struct PNGExportPreset: Codable, Identifiable {
    enum Dimension: String, Codable, CaseIterable, Identifiable {
        case scale = "Scale", width = "Width", height = "Height"
        var id: Self { self }

        func size(value: Double, for file: SVGFile) -> PNGExportSize? {
            guard value.isFinite, value > 0 else { return nil }
            let scale: Double
            switch self {
            case .scale: scale = value
            case .width: scale = value / file.width
            case .height: scale = value / file.height
            }
            return PNGExportSize(width: file.width * scale, height: file.height * scale)
        }
    }

    let id: UUID
    var dimension: Dimension
    var value: Double

    init(id: UUID = UUID(), dimension: Dimension, value: Double) {
        self.id = id
        self.dimension = dimension
        self.value = value
    }

    var title: String {
        let number = value.formatted(.number.precision(.significantDigits(1...12)).grouping(.never))
        switch dimension {
        case .scale: return "\(number)×"
        case .width: return "\(number) px wide"
        case .height: return "\(number) px high"
        }
    }

    static let defaults: [PNGExportPreset] = [
        PNGExportPreset(dimension: .scale, value: 1),
        PNGExportPreset(dimension: .scale, value: 2),
        PNGExportPreset(dimension: .width, value: 1500),
        PNGExportPreset(dimension: .width, value: 3000)
    ]
}

struct PNGExportPresetsView: View {
    private struct Draft: Identifiable, Equatable {
        let id: UUID
        var dimension: PNGExportPreset.Dimension
        var input: String

        init(_ preset: PNGExportPreset) {
            id = preset.id
            dimension = preset.dimension
            input = preset.value.formatted(.number.precision(.significantDigits(1...12)).grouping(.never))
        }

        var preset: PNGExportPreset? {
            guard let value = try? Double(input, format: .number), value.isFinite, value > 0 else { return nil }
            return PNGExportPreset(id: id, dimension: dimension, value: value)
        }
    }

    private struct ListHeightKey: PreferenceKey {
        static var defaultValue: CGFloat { 0 }

        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }

    @State private var drafts: [Draft]
    @State private var listHeight: CGFloat = 0
    let onSave: ([PNGExportPreset]) -> Void

    init(presets: [PNGExportPreset], onSave: @escaping ([PNGExportPreset]) -> Void) {
        _drafts = State(initialValue: presets.map(Draft.init))
        self.onSave = onSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export Presets")
                .font(.headline)

            ScrollView {
                VStack(spacing: 6) {
                    ForEach($drafts) { $draft in
                        let id = draft.id
                        HStack(spacing: 8) {
                            Picker("Size by", selection: $draft.dimension) {
                                ForEach(PNGExportPreset.Dimension.allCases) { dimension in
                                    Text(dimension.rawValue).tag(dimension)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 100)
                            TextField("Value", text: $draft.input)
                                .textFieldStyle(.roundedBorder)
                                .accessibilityLabel(draft.dimension == .scale ? "Scale factor" : "\(draft.dimension.rawValue) in pixels")
                            Text(draft.dimension == .scale ? "×" : "px")
                                .foregroundStyle(.secondary)
                                .frame(width: 18)
                            Button {
                                drafts.removeAll { $0.id == id }
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .buttonStyle(.borderless)
                            .help("Remove preset")
                            .accessibilityLabel("Remove preset")
                        }
                    }
                    if drafts.isEmpty {
                        Text("No export presets. Custom export is always available.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .background {
                    GeometryReader { geometry in
                        Color.clear.preference(key: ListHeightKey.self, value: geometry.size.height)
                    }
                }
            }
            // Short lists fit their rows; long lists scroll instead of overflowing the screen.
            .frame(height: min(listHeight, 360))
            .onPreferenceChange(ListHeightKey.self) { listHeight = $0 }

            HStack {
                Button("Add Preset") {
                    drafts.append(Draft(PNGExportPreset(dimension: .scale, value: 1)))
                }
                Spacer()
                Button("Restore Defaults") {
                    drafts = PNGExportPreset.defaults.map(Draft.init)
                }
            }

            if drafts.contains(where: { $0.preset == nil }) {
                Text("Enter a positive number for every preset.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            Text("Aspect ratio is preserved. Presets exceeding \(PNGExportSize.maximumDimension) px per side are disabled for that SVG.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Changes are saved automatically.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .onChange(of: drafts) { _, drafts in
            let presets = drafts.compactMap(\.preset)
            guard presets.count == drafts.count else { return }
            onSave(presets)
        }
    }
}
