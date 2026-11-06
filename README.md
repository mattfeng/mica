# Mica

An intentionally minimal, native macOS SVG viewer. Free, open source, and dependency-free.

## Run

1. Requires **macOS 14 or later** and **Xcode 16 or later**.
2. Open `Mica.xcodeproj` in Xcode.
3. Select the **Mica** scheme and **My Mac**, then click **Run** (`⌘R`). Alternatively, execute `./build.command` in Terminal to build a local Release `.app`.
4. Drop an `.svg` file onto the window, or choose **Open SVG** (`⌘O`).

This archive contains the **source project**, not a prebuilt or notarized `.app`. A macOS build could not be performed in the Linux authoring environment.

## Controls

| Action | Control |
|---|---|
| Open an SVG | `⌘O`, Open SVG button, drag-and-drop, or Open With in Finder |
| Fit to window | `⌘0` or expand icon |
| Actual size | `⌘1` or click the zoom percentage |
| Zoom | `⌘=` / `⌘-`, toolbar buttons, or trackpad scroll |
| Pan | Click and drag |
| Change backdrop | Background menu in the bottom toolbar |
| Export PNG | Export icon; choose a preset to save directly, or Custom… to specify a scale factor, width, or height. Aspect ratio is preserved; each dimension is limited to 4096 px. |
| Show metadata | Sidebar icon in the upper-right toolbar |

## Features

- Native SwiftUI macOS interface, automatic light and dark appearance.
- WebKit-backed vector rendering with smooth zoom and pan.
- Paper, dot-grid, checkerboard, and night canvas backgrounds.
- File metadata, copy source, and reveal in Finder.
- PNG export with a transparent background.
- SVG is loaded as an **image** in a locally generated WebKit page rather than as active HTML; the page uses a restrictive Content Security Policy. External SVG resources are intentionally unavailable.
- No accounts, analytics, external packages, or network requests.

## Limitations

- Supports uncompressed `.svg` files, not `.svgz`.
- Malformed XML is rejected. A safety limit rejects SVG files larger than 30 MB.
- SVG dimensions without explicit pixel-sized width/height use `viewBox`, then an 800×600 fallback. Percentage-based SVG sizing may render differently than in some design applications.
- PNG export uses a browser canvas, so SVG features that the browser cannot rasterize or resources that violate canvas origin rules may fail to export.
- Full platform compilation and UI testing require macOS/Xcode; the project files and Swift syntax have only been checked in the authoring environment.

## License

MIT. See [LICENSE](LICENSE).
