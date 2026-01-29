import SwiftUI
import WardleyModel
import WardleyTheme

/// Draws components (circles with labels), anchors, and evolved components.
public struct ComponentDrawing {

    /// Draw element dots/circles only (no labels).
    public static func drawElementDots(
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
            let r = theme.component.radius

            let rect = CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)
            context.fill(Path(ellipseIn: rect), with: .color(fillColor))
            context.stroke(
                Path(ellipseIn: rect),
                with: .color(strokeColor),
                style: StrokeStyle(lineWidth: isHighlighted ? theme.component.strokeWidth + 2 : theme.component.strokeWidth)
            )

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

    /// Draw element labels only (on top of everything).
    public static func drawElementLabels(
        context: inout GraphicsContext,
        elements: [MapElement],
        theme: MapTheme,
        calc: PositionCalculator
    ) {
        for element in elements {
            let pt = calc.point(visibility: element.visibility, maturity: element.maturity)
            let isEvolved = element.evolved
            let textColor = isEvolved ? theme.component.evolvedTextColor : theme.component.textColor

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
        }
    }

    /// Draw anchor dots only.
    public static func drawAnchorDots(
        context: inout GraphicsContext,
        anchors: [MapAnchor],
        theme: MapTheme,
        calc: PositionCalculator
    ) {
        for anchor in anchors {
            let pt = calc.point(visibility: anchor.visibility, maturity: anchor.maturity)
            let r: CGFloat = 3
            let dot = CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)
            context.fill(Path(ellipseIn: dot), with: .color(theme.component.stroke))
        }
    }

    /// Draw anchor labels only (on top of dots).
    public static func drawAnchorLabels(
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
                at: CGPoint(x: pt.x, y: pt.y - 12),
                anchor: .bottom
            )
        }
    }

    /// Draw submap dots only.
    public static func drawSubmapDots(
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

            let rect = CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)
            context.fill(Path(ellipseIn: rect), with: .color(fillColor))
            context.stroke(
                Path(ellipseIn: rect),
                with: .color(strokeColor),
                style: StrokeStyle(lineWidth: theme.submap.strokeWidth)
            )
        }
    }

    /// Draw submap labels only (on top of dots).
    public static func drawSubmapLabels(
        context: inout GraphicsContext,
        submaps: [MapElement],
        theme: MapTheme,
        calc: PositionCalculator
    ) {
        for submap in submaps {
            let pt = calc.point(visibility: submap.visibility, maturity: submap.maturity)
            let isEvolved = submap.evolved
            let textColor = isEvolved ? theme.submap.evolvedTextColor : theme.submap.textColor

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
