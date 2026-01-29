import SwiftUI
import UniformTypeIdentifiers
import WardleyModel

/// FileDocument for .owm/.wardley/.txt Wardley Map files.
public struct WardleyMapDocument: FileDocument {
    public var text: String

    public static var readableContentTypes: [UTType] {
        [.wardleyMap, .plainText]
    }

    public static var writableContentTypes: [UTType] {
        [.wardleyMap, .plainText]
    }

    public init(text: String = Self.exampleMap) {
        self.text = text
    }

    public init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }

    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = text.data(using: .utf8) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return FileWrapper(regularFileWithContents: data)
    }

    public static let exampleMap = """
    title Tea Shop
    anchor Business [0.95, 0.63]
    anchor Public [0.95, 0.78]
    component Cup of Tea [0.79, 0.61] label [-85.48, 3.78]
    component Cup [0.73, 0.78]
    component Tea [0.63, 0.81]
    component Hot Water [0.52, 0.80]
    component Water [0.38, 0.82]
    component Kettle [0.43, 0.35] label [-57, 4]
    evolve Kettle->Electric Kettle 0.62 label [16, 5]
    component Power [0.1, 0.7] label [-27, 20]
    evolve Power 0.89 label [-12, 21]
    Business->Cup of Tea
    Public->Cup of Tea
    Cup of Tea->Cup
    Cup of Tea->Tea
    Cup of Tea->Hot Water
    Hot Water->Water
    Hot Water->Kettle; limited by
    Kettle->Power

    annotation 1 [[0.43,0.49],[0.08,0.79]] Standardising power allows Kettles to evolve faster
    annotation 2 [0.48, 0.85] Hot water is obvious and well known
    annotations [0.72, 0.03]

    note +a generic note appeared [0.23, 0.33]

    style wardley
    """
}

// MARK: - Custom UTType

extension UTType {
    public static var wardleyMap: UTType {
        UTType(exportedAs: "com.wardleymaps.owm", conformingTo: .plainText)
    }
}
