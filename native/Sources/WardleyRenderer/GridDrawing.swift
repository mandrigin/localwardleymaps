import SwiftUI
import WardleyModel
import WardleyTheme

/// Draws the background grid, evolution axis labels, and visibility axis.
public struct GridDrawing {
    public static func draw(
        context: inout GraphicsContext,
        size: CGSize,
        theme: MapTheme,
        evolution: [EvolutionLabel],
        calc: PositionCalculator
    ) {
        let padding = calc.padding

        // Background
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .color(theme.containerBackground)
        )

        // Evolution separation lines (vertical dashed)
        let separators: [CGFloat] = [0.25, 0.5, 0.75]
        for sep in separators {
            let x = calc.maturityToX(sep)
            var path = Path()
            path.move(to: CGPoint(x: x, y: padding))
            path.addLine(to: CGPoint(x: x, y: size.height - padding))
            context.stroke(
                path,
                with: .color(theme.evolutionSeparationStroke),
                style: StrokeStyle(
                    lineWidth: theme.strokeWidth,
                    dash: theme.strokeDashPattern
                )
            )
        }

        // X-axis line (bottom)
        var xAxisPath = Path()
        xAxisPath.move(to: CGPoint(x: padding, y: size.height - padding))
        xAxisPath.addLine(to: CGPoint(x: size.width - padding, y: size.height - padding))
        context.stroke(
            xAxisPath,
            with: .color(theme.stroke),
            style: StrokeStyle(lineWidth: theme.strokeWidth)
        )

        // Y-axis line (left)
        var yAxisPath = Path()
        yAxisPath.move(to: CGPoint(x: padding, y: padding))
        yAxisPath.addLine(to: CGPoint(x: padding, y: size.height - padding))
        context.stroke(
            yAxisPath,
            with: .color(theme.stroke),
            style: StrokeStyle(lineWidth: theme.strokeWidth)
        )

        // Evolution labels along bottom
        let labelFont = Font.system(size: 11)
        let resolvedFont = context.resolve(Text("X").font(labelFont))
        let labelPositions: [CGFloat] = [0.125, 0.375, 0.625, 0.875]
        for (i, pos) in labelPositions.enumerated() {
            guard i < evolution.count else { break }
            let evo = evolution[i]
            let x = calc.maturityToX(pos)
            let y = size.height - padding + 12

            context.draw(
                Text(evo.line1).font(labelFont).foregroundStyle(theme.mapGridTextColor),
                at: CGPoint(x: x, y: y)
            )
            if !evo.line2.isEmpty {
                context.draw(
                    Text(evo.line2).font(.system(size: 9)).foregroundStyle(theme.mapGridTextColor),
                    at: CGPoint(x: x, y: y + 14)
                )
            }
        }

        // Y-axis label: "Visibility" (rotated)
        // We'll draw "Value Chain" text at the top-left
        context.draw(
            Text("Visible").font(.system(size: 10)).foregroundStyle(theme.mapGridTextColor),
            at: CGPoint(x: padding - 2, y: padding - 10),
            anchor: .trailing
        )
        context.draw(
            Text("Invisible").font(.system(size: 10)).foregroundStyle(theme.mapGridTextColor),
            at: CGPoint(x: padding - 2, y: size.height - padding + 2),
            anchor: .trailing
        )

        // Evolution arrow at bottom
        let arrowY = size.height - padding + 35
        var arrowPath = Path()
        arrowPath.move(to: CGPoint(x: padding + 10, y: arrowY))
        arrowPath.addLine(to: CGPoint(x: size.width - padding - 10, y: arrowY))
        // Arrow head
        arrowPath.move(to: CGPoint(x: size.width - padding - 20, y: arrowY - 4))
        arrowPath.addLine(to: CGPoint(x: size.width - padding - 10, y: arrowY))
        arrowPath.addLine(to: CGPoint(x: size.width - padding - 20, y: arrowY + 4))
        context.stroke(
            arrowPath,
            with: .color(theme.mapGridTextColor),
            style: StrokeStyle(lineWidth: 1)
        )
        context.draw(
            Text("Evolution").font(.system(size: 10)).foregroundStyle(theme.mapGridTextColor),
            at: CGPoint(x: size.width / 2, y: arrowY + 12)
        )
    }
}
