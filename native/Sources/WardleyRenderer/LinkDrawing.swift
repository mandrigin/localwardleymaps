import SwiftUI
import WardleyModel
import WardleyTheme

/// Draws dependency links between components.
public struct LinkDrawing {
    public static func draw(
        context: inout GraphicsContext,
        links: [MapLink],
        elements: [MapElement],
        anchors: [MapAnchor],
        submaps: [MapElement],
        evolved: [EvolvedElement],
        theme: MapTheme,
        calc: PositionCalculator
    ) {
        // Build lookup: name -> point
        var nameToPoint: [String: CGPoint] = [:]
        var nameToEvolved: [String: Bool] = [:]

        for el in elements {
            nameToPoint[el.name] = calc.point(visibility: el.visibility, maturity: el.maturity)
            nameToEvolved[el.name] = el.evolved
        }
        for a in anchors {
            nameToPoint[a.name] = calc.point(visibility: a.visibility, maturity: a.maturity)
        }
        for s in submaps {
            nameToPoint[s.name] = calc.point(visibility: s.visibility, maturity: s.maturity)
        }
        // Evolved elements override lookup for their override name
        for ev in evolved {
            let displayName = ev.override.isEmpty ? ev.name : ev.override
            // We need to find the original component to get its visibility
            if let original = elements.first(where: { $0.name == ev.name }) {
                nameToPoint[displayName] = calc.point(visibility: original.visibility, maturity: ev.maturity)
                nameToEvolved[displayName] = true
            }
        }

        for link in links {
            guard let startPt = nameToPoint[link.start],
                  let endPt = nameToPoint[link.end] else { continue }

            let isEvolvedLink = (nameToEvolved[link.start] == true) || (nameToEvolved[link.end] == true)

            if link.flow {
                // Flow link — thicker, colored
                var path = Path()
                path.move(to: startPt)
                path.addLine(to: endPt)
                context.stroke(
                    path,
                    with: .color(theme.link.flow),
                    style: StrokeStyle(lineWidth: theme.link.flowStrokeWidth, lineCap: .round)
                )

                // Flow value text
                if let flowValue = link.flowValue, !flowValue.isEmpty {
                    let midPt = CGPoint(
                        x: (startPt.x + endPt.x) / 2,
                        y: (startPt.y + endPt.y) / 2 - 10
                    )
                    context.draw(
                        Text(flowValue)
                            .font(.system(size: 10))
                            .foregroundStyle(theme.link.flowText),
                        at: midPt
                    )
                }

                // Future/past arrows
                if link.future || link.past {
                    drawFlowArrow(
                        context: &context,
                        from: startPt,
                        to: endPt,
                        future: link.future,
                        past: link.past,
                        theme: theme
                    )
                }
            } else {
                // Standard dependency link
                let stroke = isEvolvedLink ? theme.link.evolvedStroke : theme.link.stroke
                let width = isEvolvedLink ? theme.link.evolvedStrokeWidth : theme.link.strokeWidth

                var path = Path()
                path.move(to: startPt)
                path.addLine(to: endPt)
                context.stroke(
                    path,
                    with: .color(stroke),
                    style: StrokeStyle(lineWidth: width)
                )

                // Context annotation
                if let ctx = link.context, !ctx.isEmpty {
                    let midPt = CGPoint(
                        x: (startPt.x + endPt.x) / 2,
                        y: (startPt.y + endPt.y) / 2 - 8
                    )
                    context.draw(
                        Text(ctx)
                            .font(.system(size: theme.link.contextFontSize))
                            .foregroundStyle(theme.link.stroke),
                        at: midPt
                    )
                }
            }
        }
    }

    static func drawFlowArrow(
        context: inout GraphicsContext,
        from start: CGPoint,
        to end: CGPoint,
        future: Bool,
        past: Bool,
        theme: MapTheme
    ) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = sqrt(dx * dx + dy * dy)
        guard length > 0 else { return }
        let nx = dx / length
        let ny = dy / length

        let arrowSize: CGFloat = 8

        if future {
            // Arrow pointing toward end
            let tip = CGPoint(x: end.x - nx * 8, y: end.y - ny * 8)
            var arrow = Path()
            arrow.move(to: tip)
            arrow.addLine(to: CGPoint(x: tip.x - nx * arrowSize + ny * arrowSize * 0.4,
                                       y: tip.y - ny * arrowSize - nx * arrowSize * 0.4))
            arrow.move(to: tip)
            arrow.addLine(to: CGPoint(x: tip.x - nx * arrowSize - ny * arrowSize * 0.4,
                                       y: tip.y - ny * arrowSize + nx * arrowSize * 0.4))
            context.stroke(arrow, with: .color(theme.link.flow), style: StrokeStyle(lineWidth: 2))
        }

        if past {
            // Arrow pointing toward start
            let tip = CGPoint(x: start.x + nx * 8, y: start.y + ny * 8)
            var arrow = Path()
            arrow.move(to: tip)
            arrow.addLine(to: CGPoint(x: tip.x + nx * arrowSize + ny * arrowSize * 0.4,
                                       y: tip.y + ny * arrowSize - nx * arrowSize * 0.4))
            arrow.move(to: tip)
            arrow.addLine(to: CGPoint(x: tip.x + nx * arrowSize - ny * arrowSize * 0.4,
                                       y: tip.y + ny * arrowSize + nx * arrowSize * 0.4))
            context.stroke(arrow, with: .color(theme.link.flow), style: StrokeStyle(lineWidth: 2))
        }
    }
}
