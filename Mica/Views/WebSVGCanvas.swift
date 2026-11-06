import AppKit
import Combine
import SwiftUI
import WebKit
import UniformTypeIdentifiers

/// SVG content is displayed as an image data URL, not inserted as executable markup.
/// This prevents scripts embedded in the SVG from executing in the viewer page.
final class CanvasEngine: NSObject, ObservableObject, WKScriptMessageHandler {
    @Published private(set) var zoomPercent = 100
    @Published var errorMessage: String?

    weak var webView: WKWebView?
    private(set) var loadedFileID: UUID?
    private var exportDestination: URL?

    func attach(_ view: WKWebView) {
        if webView !== view { loadedFileID = nil }
        webView = view
    }

    func load(_ file: SVGFile, into view: WKWebView) {
        loadedFileID = file.id
        zoomPercent = 100

        let source = file.data.base64EncodedString()
        // Limit image pixel dimensions to avoid unbounded memory use in the browser.
        let width = min(file.width, 100_000)
        let height = min(file.height, 100_000)
        let page = Self.html(svgBase64: source, width: width, height: height)
        view.loadHTMLString(page, baseURL: nil)
    }

    func fit() { run("window.viewer && window.viewer.fit()") }
    func actualSize() { run("window.viewer && window.viewer.actual()") }
    func zoomIn() { run("window.viewer && window.viewer.zoomBy(1.25)") }
    func zoomOut() { run("window.viewer && window.viewer.zoomBy(0.8)") }

    func exportPNG(file: SVGFile) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = file.stem + ".png"
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        exportDestination = url
        run("window.viewer && window.viewer.exportPNG(2)")
    }

    private func run(_ javascript: String) {
        webView?.evaluateJavaScript(javascript) { [weak self] _, error in
            if let error { self?.errorMessage = error.localizedDescription }
        }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "zoom":
            guard let value = message.body as? NSNumber else { return }
            DispatchQueue.main.async { [weak self] in
                self?.zoomPercent = value.intValue
            }
        case "export":
            guard let raw = message.body as? String,
                  let destination = exportDestination,
                  let image = Data(base64Encoded: raw) else {
                errorMessage = "The image could not be exported."
                exportDestination = nil
                return
            }
            exportDestination = nil
            do {
                try image.write(to: destination, options: .atomic)
            } catch {
                errorMessage = error.localizedDescription
            }
        case "error":
            exportDestination = nil
            errorMessage = message.body as? String ?? "The SVG could not be rendered."
        default:
            break
        }
    }

    private static func html(svgBase64: String, width: Double, height: Double) -> String {
        // Constants substituted here are either numeric or base64, never raw SVG markup.
        """
        <!doctype html>
        <html><head><meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src data:; style-src 'unsafe-inline'; script-src 'unsafe-inline';">
        <style>
          html, body { width: 100%; height: 100%; margin: 0; overflow: hidden; background: transparent; }
          body { cursor: grab; user-select: none; -webkit-user-select: none; touch-action: none; }
          body.dragging { cursor: grabbing; }
          #art { position: absolute; left: 50%; top: 50%; width: \(width)px; height: \(height)px;
                 transform-origin: center; max-width: none; max-height: none;
                 pointer-events: none; -webkit-user-drag: none; }
        </style></head><body>
        <img id="art" alt="SVG drawing" src="data:image/svg+xml;base64,\(svgBase64)">
        <script>
        (() => {
          const img = document.getElementById('art');
          const source = img.src;
          const iw = \(width), ih = \(height);
          const state = { scale: 1, x: 0, y: 0, fitMode: true };
          const clamp = (n, lo, hi) => Math.min(hi, Math.max(lo, n));
          const send = (name, value) => window.webkit?.messageHandlers?.[name]?.postMessage(value);
          function apply() {
            img.style.transform = `translate(-50%, -50%) translate(${state.x}px, ${state.y}px) scale(${state.scale})`;
            send('zoom', Math.round(state.scale * 100));
          }
          function fit() {
            state.fitMode = true;
            state.scale = clamp(Math.min((innerWidth - 128) / iw, (innerHeight - 128) / ih), .01, 128);
            state.x = 0; state.y = 0; apply();
          }
          function actual() { state.fitMode = false; state.scale = 1; state.x = 0; state.y = 0; apply(); }
          function zoomAt(factor, px = innerWidth / 2, py = innerHeight / 2) {
            state.fitMode = false;
            const before = state.scale;
            const after = clamp(before * factor, .01, 128);
            const ratio = after / before;
            state.x = px - innerWidth/2 - (px - innerWidth/2 - state.x) * ratio;
            state.y = py - innerHeight/2 - (py - innerHeight/2 - state.y) * ratio;
            state.scale = after; apply();
          }
          function exportPNG(multiplier) {
            const scale = Math.min(multiplier, 4096 / Math.max(iw, ih));
            const w = Math.max(1, Math.round(iw * scale));
            const h = Math.max(1, Math.round(ih * scale));
            const image = new Image();
            image.onload = () => {
              try {
                const canvas = document.createElement('canvas');
                canvas.width = w; canvas.height = h;
                canvas.getContext('2d').drawImage(image, 0, 0, w, h);
                send('export', canvas.toDataURL('image/png').split(',')[1]);
              } catch (e) { send('error', 'PNG export failed: ' + e.message); }
            };
            image.onerror = () => send('error', 'This SVG could not be exported as PNG.');
            image.src = source;
          }
          window.viewer = { fit, actual, zoomBy: f => zoomAt(f), exportPNG };
          let dragging = false, lastX = 0, lastY = 0;
          document.addEventListener('pointerdown', e => {
            if (e.button !== 0) return;
            dragging = true; lastX = e.clientX; lastY = e.clientY;
            document.body.classList.add('dragging');
            document.body.setPointerCapture(e.pointerId);
          });
          document.addEventListener('pointermove', e => {
            if (!dragging) return;
            state.fitMode = false;
            state.x += e.clientX - lastX;
            state.y += e.clientY - lastY;
            lastX = e.clientX; lastY = e.clientY; apply();
          });
          function stopDrag() { dragging = false; document.body.classList.remove('dragging'); }
          document.addEventListener('pointerup', stopDrag);
          document.addEventListener('pointercancel', stopDrag);
          document.addEventListener('wheel', e => {
            e.preventDefault();
            zoomAt(Math.exp(-e.deltaY * (e.ctrlKey ? .012 : .003)), e.clientX, e.clientY);
          }, { passive: false });
          window.addEventListener('resize', () => { if (state.fitMode) fit(); else apply(); });
          img.addEventListener('load', fit);
          img.addEventListener('error', () => send('error', 'The SVG image could not be rendered.'));
          if (img.complete && img.naturalWidth) fit();
        })();
        </script></body></html>
        """
    }
}

struct WebSVGCanvas: NSViewRepresentable {
    let file: SVGFile
    @ObservedObject var engine: CanvasEngine

    func makeNSView(context: Context) -> WKWebView {
        let messages = WKUserContentController()
        for name in ["zoom", "export", "error"] {
            messages.add(engine, name: name)
        }
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = messages
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.underPageBackgroundColor = .clear
        // macOS WebKit does not expose transparent drawing as a public property.
        view.setValue(false, forKey: "drawsBackground")
        engine.attach(view)
        return view
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        if engine.loadedFileID != file.id {
            engine.attach(nsView)
            engine.load(file, into: nsView)
        }
    }

    static func dismantleNSView(_ nsView: WKWebView, coordinator: ()) {
        for name in ["zoom", "export", "error"] {
            nsView.configuration.userContentController.removeScriptMessageHandler(forName: name)
        }
    }
}
