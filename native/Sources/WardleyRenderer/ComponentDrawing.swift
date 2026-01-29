import SwiftUI
import WardleyModel
import WardleyTheme

/// Draws components (circles with labels), anchors, and evolved components.
public struct ComponentDrawing {
    public static func drawElements(
        context: inout GraphicsContext,
        elements: [MapElement],
        theme: MapTheme,
        calc: PositionCalculator,
        highlightedLine: Int? = nil
    ) {
        for element in elements {
            let pt = calc.point(visibility: element.visibility, maturity: element.maturity)
            let isHighlighted = highlightedLine == element.line
            let isEvolved = element.evolved
            let strokeColor = isEvolved ? theme.component.evolved : theme.component.stroke
            let fillColor = isEvolved ? theme.component.evolvedFill : theme.component.fill
            let textColor = isEvolved ? theme.component.evolvedTextColor : theme.component.textColor
            let r = theme.component.radius

            // Draw circle
            let rect = CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)
            context.fill(Path(ellipseIn: rect), with: .color(fillColor))
            context.stroke(
                Path(ellipseIn: rect),
                with: .color(strokeColor),
                style: StrokeStyle(lineWidth: isHighlighted ? theme.component.strokeWidth + 2 : theme.component.strokeWidth)
            )

            // Inertia marker (small bar)
            if element.inertia {
                var inertiaPath = Path()
                inertiaPath.move(to: CGPoint(x: pt.x + r + 2, y: pt.y - 8))
                inertiaPath.addLine(to: CGPoint(x: pt.x + r + 2, y: pt.y + 8))
                context.stroke(
                    inertiaPath,
                    with: .color(strokeColor),
                    style: StrokeStyle(lineWidth: 2)
                )
            }

            // Label
            let labelPt = CGPoint(
                x: pt.x + element.label.x,
                y: pt.y + element.label.y
            )
            context.draw(
                Text(element.name)
                    .font(.system(size: theme.component.fontSize, weight: theme.component.fontWeight))
                    .foregroundStyle(textColor),
                at: labelPt,
                anchor: .topLeading
            )

            // Highlight ring
            if isHighlighted {
                let highlightRect = CGRect(
                    x: pt.x - r - 3, y: pt.y - r - 3,
                    width: (r + 3) * 2, height: (r + 3) * 2
                )
                context.stroke(
                    Path(ellipseIn: highlightRect),
                    with: .color(.accentColor),
                    style: StrokeStyle(lineWidth: 2, dash: [4, 2])
                )
            }
        }
    }

    public static func drawAnchors(
        context: inout GraphicsContext,
        anchors: [MapAnchor],
        theme: MapTheme,
        calc: PositionCalculator
    ) {
        for anchor in anchors {
            let pt = calc.point(visibility: anchor.visibility, maturity: anchor.maturity)

            context.draw(
                Text(anchor.name)
                    .font(.system(size: theme.anchor.fontSize, weight: .bold))
                    .foregroundStyle(theme.component.textColor),
                at: pt,
                anchor: .leading
            )
        }
    }

    public static func drawSubmaps(
        context: inout GraphicsContext,
        submaps: [MapElement],
        theme: MapTheme,
        calc: PositionCalculator
    ) {
        for submap in submaps {
            let pt = calc.point(visibility: submap.visibility, maturity: submap.maturity)
            let r = theme.submap.radius
            let isEvolved = submap.evolved

            let fillColor = isEvolved ? theme.submap.evolvedFill : theme.submap.fill
            let strokeColor = isEvolved ? theme.submap.evolved : theme.submap.stroke
            let textColor = isEvolved ? theme.submap.evolvedTextColor : theme.submap.textColor

            // Draw filled circle
            let rect = CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)
            context.fill(Path(ellipseIn: rect), with: .color(fillColor))
            context.stroke(
                Path(ellipseIn: rect),
                with: .color(strokeColor),
                style: StrokeStyle(lineWidth: theme.submap.strokeWidth)
            )

            // Label
            let labelPt = CGPoint(
                x: pt.x + submap.label.x,
                y: pt.y + submap.label.y
            )
            context.draw(
                Text(submap.name)
                    .font(.system(size: theme.submap.fontSize))
                    .foregroundStyle(textColor),
                at: labelPt,
                anchor: .topLeading
            )
        }
    }
}
