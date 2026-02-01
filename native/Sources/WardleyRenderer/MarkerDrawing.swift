import SwiftUI

/// Renders marker/highlighter strokes on the canvas as an overlay.
public enum MarkerDrawing {
    /// A snapshot of a stroke for rendering (avoids coupling to MarkerState).
    public struct StrokeSnapshot {
        public let points: [CGPoint]
        public let opacity: Double
        public let isPermanent: Bool

        public init(points: [CGPoint], opacity: Double, isPermanent: Bool) {
            self.points = points
            self.opacity = opacity
            self.isPermanent = isPermanent
        }
    }

    /// Stroke color for temporary markers (yellow highlighter).
    private static let temporaryColor = Color(red: 1.0, green: 0.85, blue: 0.0)

    /// Stroke color for permanent markers (red).
    private static let permanentColor = Color(red: 1.0, green: 0.25, blue: 0.2)

    /// Line width for marker strokes.
    private static let lineWidth: CGFloat = 6

    /// Draw all marker strokes on the canvas.
    public static func draw(
        context: inout GraphicsContext,
        strokes: [StrokeSnapshot]
    ) {
        for stroke in strokes {
            guard stroke.points.count >= 2, stroke.opacity > 0.001 else { continue }
            drawStroke(context: &context, stroke: stroke)
        }
    }

    private static func drawStroke(
        context: inout GraphicsContext,
        stroke: StrokeSnapshot
    ) {
        let path = smoothPath(from: stroke.points)
        let color = stroke.isPermanent ? permanentColor : temporaryColor

        // Draw glow layer (wider, lower opacity)
        var glowContext = context
        glowContext.opacity = stroke.opacity * 0.3
        glowContext.blendMode = .plusLighter
        glowContext.stroke(
            path,
            with: .color(color),
            style: StrokeStyle(lineWidth: lineWidth * 3, lineCap: .round, lineJoin: .round)
        )

        // Draw main stroke
        var mainContext = context
        mainContext.opacity = stroke.opacity
        mainContext.stroke(
            path,
            with: .color(color),
            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
        )
    }

    /// Build a smooth path through the given points using Catmull-Rom interpolation.
    private static func smoothPath(from points: [CGPoint]) -> Path {
        guard points.count >= 2 else { return Path() }

        var path = Path()
        path.move(to: points[0])

        if points.count == 2 {
            path.addLine(to: points[1])
            return path
        }

        // Use Catmull-Rom to smooth through all points
        for i in 0..<(points.count - 1) {
            let p0 = points[max(i - 1, 0)]
            let p1 = points[i]
            let p2 = points[min(i + 1, points.count - 1)]
            let p3 = points[min(i + 2, points.count - 1)]

            let cp1 = CGPoint(
                x: p1.x + (p2.x - p0.x) / 6,
                y: p1.y + (p2.y - p0.y) / 6
            )
            let cp2 = CGPoint(
                x: p2.x - (p3.x - p1.x) / 6,
                y: p2.y - (p3.y - p1.y) / 6
            )
            path.addCurve(to: p2, control1: cp1, control2: cp2)
        }

        return path
    }
}
