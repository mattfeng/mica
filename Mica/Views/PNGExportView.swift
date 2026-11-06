import SwiftUI

struct PNGExportSize {
    static let maximumDimension = 4096

    let width: Int
    let height: Int

    init?(width: Double, height: Double) {
        guard width.isFinite, height.isFinite, width > 0, height > 0 else { return nil }
        let roundedWidth = max(1, width.rounded())
        let roundedHeight = max(1, height.rounded())
        guard roundedWidth <= Double(Self.maximumDimension),
              roundedHeight <= Double(Self.maximumDimension) else { return nil }
        self.width = Int(roundedWidth)
        self.height = Int(roundedHeight)
    }
}

struct PNGExportView: View {
    let file: SVGFile
    let engine: CanvasEngine
    @Environment(\.dismiss) private var dismiss
    @State private var mode: PNGExportPreset.Dimension = .scale
    @State private var value: String

    init(file: SVGFile, engine: CanvasEngine) {
        self.file = file
        self.engine = engine
        let scale = min(2, Double(PNGExportSize.maximumDimension) / max(file.width, file.height))
        _value = State(initialValue: Self.formatted(scale))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export PNG")
                .font(.headline)
            Text(file.name)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Picker("Size by", selection: $mode) {
                ForEach(PNGExportPreset.Dimension.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: mode) { oldMode, newMode in
                guard let size = outputSize(for: oldMode) else { return }
                let newValue: Double
                switch newMode {
                case .scale: newValue = Double(size.width) / file.width
                case .width: newValue = Double(size.width)
                case .height: newValue = Double(size.height)
                }
                value = Self.formatted(newValue)
            }

            HStack(spacing: 8) {
                TextField(mode.rawValue, text: $value)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel(mode == .scale ? "Scale factor" : "\(mode.rawValue) in pixels")
                Text(mode == .scale ? "×" : "px")
                    .foregroundStyle(.secondary)
            }

            if let size = outputSize(for: mode) {
                Text("\(size.width) × \(size.height) px")
                    .font(.system(.caption, design: .monospaced))
            } else {
                Text("Enter a positive size up to \(PNGExportSize.maximumDimension) px per side.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            Text("Aspect ratio is preserved. Maximum dimension: \(PNGExportSize.maximumDimension) px.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Export…") {
                    guard let size = outputSize(for: mode) else { return }
                    engine.exportPNG(file: file, size: size)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(outputSize(for: mode) == nil)
            }
        }
        .padding(16)
        .frame(width: 320)
    }

    private func outputSize(for mode: PNGExportPreset.Dimension) -> PNGExportSize? {
        guard let input = try? Double(value, format: .number) else { return nil }
        return mode.size(value: input, for: file)
    }

    private static func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.significantDigits(1...12)).grouping(.never))
    }
}
