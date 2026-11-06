import AppKit
import SwiftUI

@main
struct MicaApp: App {
    init() {
        let storedAppearance = UserDefaults.standard.string(forKey: "appearance")
        let appearance = storedAppearance.flatMap(AppAppearance.init(rawValue:)) ?? .system
        NSApplication.shared.appearance = appearance.nativeAppearance
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 820, minHeight: 560)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1180, height: 790)
        .commands {
            CommandGroup(replacing: .appSettings) {
                SettingsLink {
                    Text("Preferences…")
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            CommandGroup(replacing: .newItem) {
                Button("Open SVG…") { NotificationCenter.default.post(name: .micaOpen, object: nil) }
                    .keyboardShortcut("o", modifiers: .command)
            }
            CommandMenu("Canvas") {
                Button("Fit to Window") { NotificationCenter.default.post(name: .micaFit, object: nil) }
                    .keyboardShortcut("0", modifiers: .command)
                Button("Actual Size") { NotificationCenter.default.post(name: .micaActual, object: nil) }
                    .keyboardShortcut("1", modifiers: .command)
                Divider()
                Button("Zoom In") { NotificationCenter.default.post(name: .micaZoomIn, object: nil) }
                    .keyboardShortcut("=", modifiers: .command)
                Button("Zoom Out") { NotificationCenter.default.post(name: .micaZoomOut, object: nil) }
                    .keyboardShortcut("-", modifiers: .command)
            }
        }

        Settings {
            PreferencesView()
        }
        .windowResizability(.contentSize)
    }
}

extension Notification.Name {
    static let micaOpen = Notification.Name("mica.open")
    static let micaFit = Notification.Name("mica.fit")
    static let micaActual = Notification.Name("mica.actual")
    static let micaZoomIn = Notification.Name("mica.zoomIn")
    static let micaZoomOut = Notification.Name("mica.zoomOut")
}
