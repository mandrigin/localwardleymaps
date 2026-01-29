import UniformTypeIdentifiers

extension UTType {
    public static var wardleyMap: UTType {
        UTType("com.wardleymaps.owm") ?? .plainText
    }
}
