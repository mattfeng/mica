import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

struct SVGFile: Identifiable {
    let id = UUID()
    let url: URL
    let data: Data
    let width: Double
    let height: Double
    let viewBox: String?

    var name: String { url.lastPathComponent }
    var stem: String { url.deletingPathExtension().lastPathComponent }

    var dimensions: String {
        "\(Int(width.rounded())) × \(Int(height.rounded()))"
    }

    var fileSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
    }

    static func open(_ url: URL) throws -> SVGFile {
        #if os(macOS)
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        #endif

        let data = try Data(contentsOf: url)
        guard !data.isEmpty else { throw SVGFileError.empty }
        guard data.count <= 30_000_000 else { throw SVGFileError.tooLarge }

        let inspector = SVGRootInspector()
        let parser = XMLParser(data: data)
        parser.shouldResolveExternalEntities = false
        parser.delegate = inspector
        guard parser.parse(), inspector.isSVG else {
            throw SVGFileError.invalidSVG
        }

        let viewBox = inspector.attributes["viewBox"]
        let values = viewBox?
            .split(whereSeparator: { $0 == " " || $0 == "," || $0 == "\n" || $0 == "\t" })
            .compactMap { Double($0) }
        let viewBoxWidth = (values?.count == 4) ? abs(values![2]) : nil
        let viewBoxHeight = (values?.count == 4) ? abs(values![3]) : nil

        let width = SVGRootInspector.pixelLength(inspector.attributes["width"])
            ?? viewBoxWidth ?? 800
        let height = SVGRootInspector.pixelLength(inspector.attributes["height"])
            ?? viewBoxHeight ?? 600

        guard width.isFinite, height.isFinite, width > 0, height > 0 else {
            throw SVGFileError.invalidSize
        }
        return SVGFile(url: url, data: data, width: width, height: height, viewBox: viewBox)
    }
}

private final class SVGRootInspector: NSObject, XMLParserDelegate {
    var isSVG = false
    var attributes: [String: String] = [:]
    private var sawRoot = false

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String]
    ) {
        guard !sawRoot else { return }
        sawRoot = true
        isSVG = elementName.split(separator: ":").last == "svg"
        attributes = attributeDict
    }

    static func pixelLength(_ raw: String?) -> Double? {
        guard let raw else { return nil }
        let source = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        // CSS absolute lengths; percentages and relative units defer to the viewBox.
        let units: [(String, Double)] = [
            ("px", 1), ("pt", 96.0 / 72), ("pc", 16),
            ("in", 96), ("cm", 96.0 / 2.54), ("mm", 96.0 / 25.4), ("q", 96.0 / 101.6)
        ]
        for (suffix, multiplier) in units where source.hasSuffix(suffix) {
            let value = String(source.dropLast(suffix.count))
                .trimmingCharacters(in: .whitespaces)
            guard let number = Double(value), number > 0 else { return nil }
            return number * multiplier
        }
        guard let number = Double(source), number > 0 else { return nil }
        return number
    }
}

enum SVGFileError: LocalizedError {
    case empty
    case tooLarge
    case invalidSVG
    case invalidSize

    var errorDescription: String? {
        switch self {
        case .empty: return "This file is empty."
        case .tooLarge: return "This SVG exceeds the 30 MB safety limit."
        case .invalidSVG: return "This is not a valid SVG document."
        case .invalidSize: return "The SVG has invalid dimensions."
        }
    }
}
