import UniformTypeIdentifiers

extension UTType {
    public static var wardleyMap: UTType {
        UTType(filenameExtension: "owm", conformingTo: .plainText) ?? .plainText
    }
}
