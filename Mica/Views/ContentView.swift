import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.colorScheme) private var scheme
    @StateObject private var engine = CanvasEngine()
    @State private var file: SVGFile?
    @State private var inspectorVisible = false
    @State private var importing = false
    @State private var dropTargeted = false
    @State private var canvasHovered = false

    var body: some View {
        HStack(spacing: 8) {
            canvas
            if inspectorVisible, let file {
                inspector(for: file)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(8)
        .background(MicaPalette.window(scheme).ignoresSafeArea())
        .animation(.easeInOut(duration: 0.23), value: inspectorVisible)
        .fileImporter(
            isPresented: $importing,
            allowedContentTypes: [UTType(filenameExtension: "svg") ?? .image]
        ) { result in
            switch result {
            case .success(let url): open(url)
            case .failure(let error): engine.errorMessage = error.localizedDescription
            }
        }
        .onOpenURL(perform: open)
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $dropTargeted, perform: handleDrop)
        .onReceive(NotificationCenter.default.publisher(for: .micaOpen)) { _ in importing = true }
        .onReceive(NotificationCenter.default.publisher(for: .micaFit)) { _ in engine.fit() }
        .onReceive(NotificationCenter.default.publisher(for: .micaActual)) { _ in engine.actualSize() }
        .onReceive(NotificationCenter.default.publisher(for: .micaZoomIn)) { _ in engine.zoomIn() }
        .onReceive(NotificationCenter.default.publisher(for: .micaZoomOut)) { _ in engine.zoomOut() }
        .alert("Mica", isPresented: Binding(
            get: { engine.errorMessage != nil },
            set: { if !$0 { engine.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { engine.errorMessage = nil }
        } message: {
            Text(engine.errorMessage ?? "")
        }
    }

    private var canvas: some View {
        ZStack {
            CanvasBackdrop(scheme: scheme)

            if let file {
                WebSVGCanvas(file: file, engine: engine)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
            } else {
                emptyState
            }

            if dropTargeted {
                Color(red: 0.47, green: 0.59, blue: 0.49)
                    .opacity(0.09)
                    .allowsHitTesting(false)
            }
        }
        .overlay(alignment: .top) {
            if let file {
                Text(file.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(MicaPalette.muted(scheme))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.horizontal, 88)
                    .padding(.top, 10)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .allowsHitTesting(false)
            }
        }
        .overlay(alignment: .bottom) {
            if file != nil {
                bottomToolbar
                    .padding(.bottom, 10)
                    .opacity(canvasHovered ? 1 : 0)
                    .allowsHitTesting(canvasHovered)
                    .animation(.easeInOut(duration: 0.2), value: canvasHovered)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(
                    dropTargeted ? Color(red: 0.44, green: 0.61, blue: 0.49) : MicaPalette.line(scheme),
                    lineWidth: dropTargeted ? 2.5 : 1
                )
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .onHover { canvasHovered = $0 }
    }

    private var emptyState: some View {
        Text("Drop an SVG here or press ⌘O to open.")
            .font(.system(size: 12))
            .foregroundStyle(MicaPalette.muted(scheme))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var bottomToolbar: some View {
        HStack(spacing: 2) {
            toolbarButton("minus", hint: "Zoom out") { engine.zoomOut() }

            Button { engine.actualSize() } label: {
                Text("\(engine.zoomPercent)%")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .monospacedDigit()
                    .frame(minWidth: 48)
                    .frame(height: 30)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Actual size")

            toolbarButton("plus", hint: "Zoom in") { engine.zoomIn() }
            toolbarDivider
            toolbarButton("arrow.up.left.and.arrow.down.right", hint: "Fit to window") { engine.fit() }
            if let file {
                toolbarDivider
                toolbarButton("square.and.arrow.up", hint: "Export PNG") {
                    engine.exportPNG(file: file)
                }
                toolbarButton("sidebar.right", hint: "Toggle details") {
                    inspectorVisible.toggle()
                }
            }
        }
        .foregroundStyle(.primary)
        .fixedSize(horizontal: true, vertical: true)
        .padding(4)
        .background(MicaPalette.surface(scheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(MicaPalette.line(scheme)))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
    }

    private var toolbarDivider: some View {
        Rectangle()
            .fill(MicaPalette.line(scheme))
            .frame(width: 1, height: 16)
            .padding(.horizontal, 4)
    }

    private func toolbarButton(_ symbol: String, hint: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(hint)
    }

    private func inspector(for file: SVGFile) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("DETAILS")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1.4)
                .foregroundStyle(MicaPalette.muted(scheme))
                .padding(.bottom, 16)

            Text(file.stem)
                .font(.system(size: 18, weight: .semibold))
                .lineLimit(2)
                .textSelection(.enabled)
                .padding(.bottom, 6)

            Text("Scalable vector graphic")
                .font(.system(size: 12))
                .foregroundStyle(MicaPalette.muted(scheme))

            Rectangle().fill(MicaPalette.line(scheme)).frame(height: 1).padding(.vertical, 14)

            detailRow("FORMAT", "SVG")
            detailRow("DIMENSIONS", file.dimensions)
            detailRow("FILE SIZE", file.fileSize)
            if let viewBox = file.viewBox {
                detailRow("VIEWBOX", viewBox)
            }

            Rectangle().fill(MicaPalette.line(scheme)).frame(height: 1).padding(.vertical, 12)

            Button {
                if let text = String(data: file.data, encoding: .utf8) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                } else {
                    engine.errorMessage = "This SVG cannot be copied as UTF-8 text."
                }
            } label: {
                inspectorAction("Copy SVG source", symbol: "doc.on.doc")
            }
            .buttonStyle(.plain)
            .padding(.bottom, 12)

            Button {
                NSWorkspace.shared.activateFileViewerSelecting([file.url])
            } label: {
                inspectorAction("Reveal in Finder", symbol: "folder")
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(16)
        .frame(width: 232)
        .frame(maxHeight: .infinity)
        .background(MicaPalette.surface(scheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(MicaPalette.line(scheme)))
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .tracking(1)
                .foregroundStyle(MicaPalette.muted(scheme))
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .lineLimit(2)
                .textSelection(.enabled)
                .foregroundStyle(.primary)
        }
        .padding(.bottom, 12)
    }

    private func inspectorAction(_ title: String, symbol: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 18)
            Text(title)
                .font(.system(size: 12, weight: .medium))
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.system(size: 10))
                .foregroundStyle(MicaPalette.muted(scheme))
        }
        .foregroundStyle(.primary)
    }

    private func open(_ url: URL) {
        do {
            file = try SVGFile.open(url)
        } catch {
            engine.errorMessage = error.localizedDescription
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) else {
            return false
        }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            if let error {
                DispatchQueue.main.async { engine.errorMessage = error.localizedDescription }
                return
            }
            let url: URL?
            if let value = item as? URL {
                url = value
            } else if let value = item as? Data {
                url = URL(dataRepresentation: value, relativeTo: nil)
            } else if let value = item as? String {
                url = URL(string: value)
            } else {
                url = nil
            }
            DispatchQueue.main.async {
                if let url { open(url) }
                else { engine.errorMessage = "Please drop an SVG file from Finder." }
            }
        }
        return true
    }
}
