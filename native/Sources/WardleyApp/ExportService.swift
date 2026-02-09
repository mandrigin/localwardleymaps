import AppKit
import SwiftUI
import WardleyModel
import WardleyRenderer
import WardleyTheme

/// Exports the current map as a PNG image.
public struct ExportService {
    @MainActor
    public static func exportPNG(
        map: WardleyMap,
        theme: MapTheme,
        canvasSize: CGSize? = nil,
        scale: CGFloat = 2.0
    ) -> NSImage? {
        let width: CGFloat
        let height: CGFloat
        if let size = canvasSize {
            width = size.width
            height = size.height
        } else {
            width = map.presentation.size.width > 0 ? map.presentation.size.width : MapDefaults.canvasWidth
            height = map.presentation.size.height > 0 ? map.presentation.size.height : MapDefaults.canvasHeight
        }
        let size = CGSize(width: width, height: height)

        let renderer = ImageRenderer(content:
            MapCanvasView(map: map, theme: theme)
                .frame(width: size.width, height: size.height)
        )
        renderer.scale = scale

        guard let cgImage = renderer.cgImage else { return nil }
        return NSImage(cgImage: cgImage, size: size)
    }

    @MainActor
    public static func savePNG(
        map: WardleyMap,
        theme: MapTheme,
        canvasSize: CGSize? = nil,
        to url: URL
    ) -> Bool {
        guard let image = exportPNG(map: map, theme: theme, canvasSize: canvasSize) else { return false }
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return false
        }
        do {
            try pngData.write(to: url)
            return true
        } catch {
            return false
        }
    }

    @MainActor
    public static func copyToPasteboard(
        map: WardleyMap,
        theme: MapTheme,
        canvasSize: CGSize? = nil
    ) -> Bool {
        guard let image = exportPNG(map: map, theme: theme, canvasSize: canvasSize) else { return false }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        return pasteboard.writeObjects([image])
    }
}
