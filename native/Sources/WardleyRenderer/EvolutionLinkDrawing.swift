import SwiftUI
import WardleyModel
import WardleyTheme

/// Draws dashed red lines between evolving components and their evolved positions.
public struct EvolutionLinkDrawing {
    public static func draw(
        context: inout GraphicsContext,
        elements: [MapElement],
        evolved: [EvolvedElement],
        theme: MapTheme,
        calc: PositionCalculator,
        positionOverrides: [String: CGPoint] = [:]
    ) {
        for ev in evolved {
            // Find the original component
            guard let original = elements.first(where: { $0.name == ev.name }) else { continue }

            let startPt = positionOverrides[original.name] ?? calc.point(visibility: original.visibility, maturity: original.maturity)
            let displayName = ev.override.isEmpty ? ev.name : ev.override
            let endPt = positionOverrides[displayName] ?? calc.point(visibility: original.visibility, maturity: ev.maturity)

            // Dashed red line
            var path = Path()
            path.move(to: startPt)
            path.addLine(to: endPt)
            context.stroke(
                path,
                with: .color(theme.component.evolved),
                style: StrokeStyle(lineWidth: 1, dash: [5, 5])
            )

            // Arrow head at end
            let dx = endPt.x - startPt.x
            let dy = endPt.y - startPt.y
            let length = sqrt(dx * dx + dy * dy)
            guard length > 0 else { continue }
            let nx = dx / length
            let ny = dy / length
            let arrowSize: CGFloat = 6

            var arrow = Path()
            arrow.move(to: endPt)
            arrow.addLine(to: CGPoint(
                x: endPt.x - nx * arrowSize + ny * arrowSize * 0.4,
                y: endPt.y - ny * arrowSize - nx * arrowSize * 0.4
            ))
            arrow.move(to: endPt)
            arrow.addLine(to: CGPoint(
                x: endPt.x - nx * arrowSize - ny * arrowSize * 0.4,
                y: endPt.y - ny * arrowSize + nx * arrowSize * 0.4
            ))
            context.stroke(arrow, with: .color(theme.component.evolved), style: StrokeStyle(lineWidth: 1))

            // Draw evolved component circle
            let r = theme.component.radius
            let circleRect = CGRect(x: endPt.x - r, y: endPt.y - r, width: r * 2, height: r * 2)
            context.fill(Path(ellipseIn: circleRect), with: .color(theme.component.evolvedFill))
            context.stroke(
                Path(ellipseIn: circleRect),
                with: .color(theme.component.evolved),
                style: StrokeStyle(lineWidth: theme.component.strokeWidth)
            )

            // Label for evolved
            let labelPt = CGPoint(x: endPt.x + ev.label.x, y: endPt.y + ev.label.y)
            context.draw(
                Text(displayName)
                    .font(.system(size: theme.component.fontSize, weight: theme.component.fontWeight))
                    .foregroundStyle(theme.component.evolvedTextColor),
                at: labelPt,
                anchor: .topLeading
            )
        }
    }
}
