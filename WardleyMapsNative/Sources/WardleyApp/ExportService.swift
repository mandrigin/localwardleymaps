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
        scale: CGFloat = 2.0
    ) -> NSImage? {
        let width = map.presentation.size.width > 0 ? map.presentation.size.width : MapDefaults.canvasWidth
        let height = map.presentation.size.height > 0 ? map.presentation.size.height : MapDefaults.canvasHeight
        let size = CGSize(width: width + 40, height: height + 60)

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
        to url: URL
    ) -> Bool {
        guard let image = exportPNG(map: map, theme: theme) else { return false }
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
}
