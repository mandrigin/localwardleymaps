import SwiftUI
import WardleyModel
import WardleyTheme

/// Draws annotations (numbered circles with text boxes).
public struct AnnotationDrawing {
    public static func draw(
        context: inout GraphicsContext,
        annotations: [MapAnnotation],
        presentation: MapPresentation,
        theme: MapTheme,
        calc: PositionCalculator
    ) {
        let boxOrigin = calc.point(
            visibility: presentation.annotations.visibility,
            maturity: presentation.annotations.maturity
        )

        // Draw annotation text box
        if !annotations.isEmpty {
            drawAnnotationBox(
                context: &context,
                annotations: annotations,
                origin: boxOrigin,
                theme: theme
            )
        }

        // Draw numbered circles at occurrence positions
        for annotation in annotations {
            for occurrence in annotation.occurances {
                let pt = calc.point(
                    visibility: occurrence.visibility,
                    maturity: occurrence.maturity
                )
                drawNumberCircle(
                    context: &context,
                    number: annotation.number,
                    at: pt,
                    theme: theme
                )
            }
        }
    }

    static func drawNumberCircle(
        context: inout GraphicsContext,
        number: Int,
        at point: CGPoint,
        theme: MapTheme
    ) {
        let r: CGFloat = 10
        let rect = CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2)
        context.fill(Path(ellipseIn: rect), with: .color(theme.annotation.fill))
        context.stroke(
            Path(ellipseIn: rect),
            with: .color(theme.annotation.stroke),
            style: StrokeStyle(lineWidth: theme.annotation.strokeWidth)
        )
        context.draw(
            Text("\(number)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(theme.annotation.text),
            at: point
        )
    }

    static func drawAnnotationBox(
        context: inout GraphicsContext,
        annotations: [MapAnnotation],
        origin: CGPoint,
        theme: MapTheme
    ) {
        let lineHeight: CGFloat = 16
        let padding: CGFloat = 8
        let maxWidth: CGFloat = 200

        let totalHeight = CGFloat(annotations.count) * lineHeight + padding * 2
        let boxRect = CGRect(
            x: origin.x,
            y: origin.y,
            width: maxWidth,
            height: totalHeight
        )

        // Box background
        context.fill(
            Path(roundedRect: boxRect, cornerRadius: 3),
            with: .color(theme.annotation.boxFill)
        )
        context.stroke(
            Path(roundedRect: boxRect, cornerRadius: 3),
            with: .color(theme.annotation.boxStroke),
            style: StrokeStyle(lineWidth: theme.annotation.boxStrokeWidth)
        )

        // Text lines
        for (i, annotation) in annotations.enumerated() {
            let y = origin.y + padding + CGFloat(i) * lineHeight + lineHeight / 2
            let text = "\(annotation.number). \(annotation.text)"
            context.draw(
                Text(text)
                    .font(.system(size: 11))
                    .foregroundStyle(theme.annotation.boxTextColor),
                at: CGPoint(x: origin.x + padding, y: y),
                anchor: .leading
            )
        }
    }
}
