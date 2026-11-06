import AppKit
import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system = "System", light = "Light", dark = "Dark"
    var id: Self { self }

    var nativeAppearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }
}

struct PreferencesView: View {
    @AppStorage("appearance") private var appearance: AppAppearance = .system
    private enum Section: String, CaseIterable, Identifiable {
        case general = "General", export = "Export"
        var id: Self { self }

        var symbol: String {
            switch self {
            case .general: return "gearshape"
            case .export: return "square.and.arrow.up"
            }
        }
    }

    @AppStorage("pngExportPresets") private var exportPresetsData = Data()
    @State private var errorMessage: String?

    @State private var section: Section = .general
    private var exportPresets: [PNGExportPreset] {
        (try? JSONDecoder().decode([PNGExportPreset].self, from: exportPresetsData))
            ?? PNGExportPreset.defaults
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Preferences section", selection: $section) {
                ForEach(Section.allCases) { section in
                    Label(section.rawValue, systemImage: section.symbol)
                        .labelStyle(.titleAndIcon)
                        .tag(section)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .padding(12)

            Divider()

            switch section {
            case .general:
                VStack(alignment: .leading, spacing: 12) {
                    Text("Appearance")
                        .font(.headline)
                    Picker("Appearance", selection: $appearance) {
                        ForEach(AppAppearance.allCases) { appearance in
                            Text(appearance.rawValue).tag(appearance)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }
                .padding(16)
            case .export:
                PNGExportPresetsView(presets: exportPresets) { presets in
                    do {
                        exportPresetsData = try JSONEncoder().encode(presets)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
        .frame(width: 440)
        .fixedSize(horizontal: false, vertical: true)
        .onChange(of: appearance, initial: true) { _, appearance in
            // Clearing the native override restores live system appearance updates.
            NSApplication.shared.appearance = appearance.nativeAppearance
        }
        .alert("Preferences", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
}
