import SwiftUI
import WardleyModel
import WardleyTheme

/// Draws dependency links between components, with CRT glitch animations for add/remove.
public struct LinkDrawing {
    public static func draw(
        context: inout GraphicsContext,
        links: [MapLink],
        elements: [MapElement],
        anchors: [MapAnchor],
        submaps: [MapElement],
        evolved: [EvolvedElement],
        theme: MapTheme,
        calc: PositionCalculator,
        positionOverrides: [String: CGPoint] = [:],
        linkGlitchProgress: [LinkID: LinkGlitchInfo] = [:],
        ghostLinks: [MapLink] = []
    ) {
        // Build lookup: name -> point
        var nameToPoint: [String: CGPoint] = [:]
        var nameToEvolved: [String: Bool] = [:]

        for el in elements {
            nameToPoint[el.name] = positionOverrides[el.name] ?? calc.point(visibility: el.visibility, maturity: el.maturity)
            nameToEvolved[el.name] = el.evolved
        }
        for a in anchors {
            nameToPoint[a.name] = positionOverrides[a.name] ?? calc.point(visibility: a.visibility, maturity: a.maturity)
        }
        for s in submaps {
            nameToPoint[s.name] = positionOverrides[s.name] ?? calc.point(visibility: s.visibility, maturity: s.maturity)
        }
        // Evolved elements override lookup for their override name
        for ev in evolved {
            let displayName = ev.override.isEmpty ? ev.name : ev.override
            if let original = elements.first(where: { $0.name == ev.name }) {
                nameToPoint[displayName] = positionOverrides[displayName] ?? calc.point(visibility: original.visibility, maturity: ev.maturity)
                nameToEvolved[displayName] = true
            }
        }

        // Merge normal links + ghost links for iteration
        let allLinks = links + ghostLinks

        for link in allLinks {
            guard let startPt = nameToPoint[link.start],
                  let endPt = nameToPoint[link.end] else { continue }

            let lid = LinkID(start: link.start, end: link.end)
            let isEvolvedLink = (nameToEvolved[link.start] == true) || (nameToEvolved[link.end] == true)

            // Check for glitch animation
            if let glitch = linkGlitchProgress[lid] {
                drawAnimatedLink(
                    context: &context,
                    from: startPt,
                    to: endPt,
                    link: link,
                    isEvolvedLink: isEvolvedLink,
                    glitch: glitch,
                    theme: theme
                )
                continue
            }

            // Normal (non-animated) drawing
            if link.flow {
                drawFlowLink(context: &context, from: startPt, to: endPt, link: link, theme: theme)
            } else {
                let stroke = isEvolvedLink ? theme.link.evolvedStroke : theme.link.stroke
                let width = isEvolvedLink ? theme.link.evolvedStrokeWidth : theme.link.strokeWidth
                drawLine(context: &context, from: startPt, to: endPt, color: stroke, width: width)

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

    // MARK: - Animated Link Drawing

    private static func drawAnimatedLink(
        context: inout GraphicsContext,
        from startPt: CGPoint,
        to endPt: CGPoint,
        link: MapLink,
        isEvolvedLink: Bool,
        glitch: LinkGlitchInfo,
        theme: MapTheme
    ) {
        let p = glitch.progress
        let baseStroke = isEvolvedLink ? theme.link.evolvedStroke : theme.link.stroke
        let baseWidth = link.flow ? theme.link.flowStrokeWidth : (isEvolvedLink ? theme.link.evolvedStrokeWidth : theme.link.strokeWidth)

        // CRT colors
        let signalGreen = Color(red: 0.0, green: 1.0, blue: 0.3)
        let cyanGhost = Color(red: 0.0, green: 0.8, blue: 1.0)
        let alertOrange = Color(red: 1.0, green: 0.5, blue: 0.0)
        let alertRed = Color(red: 1.0, green: 0.1, blue: 0.1)

        if glitch.isNew {
            // --- APPEARING ---
            if p < 0.2 {
                // TEAR: Chromatic split lines, main at low opacity
                let tearProgress = p / 0.2
                let aberration = 3.0 * (1.0 - tearProgress)

                // Green ghost line offset up
                drawLine(context: &context,
                         from: startPt.offsetY(-aberration),
                         to: endPt.offsetY(-aberration),
                         color: signalGreen, width: baseWidth, opacity: 0.5)
                // Cyan ghost line offset down
                drawLine(context: &context,
                         from: startPt.offsetY(aberration),
                         to: endPt.offsetY(aberration),
                         color: cyanGhost, width: baseWidth, opacity: 0.5)
                // Main line at low opacity
                drawLine(context: &context, from: startPt, to: endPt,
                         color: baseStroke, width: baseWidth, opacity: 0.3)

            } else if p < 0.45 {
                // SNAP: Ghosts converge, green flash, opacity rises
                let snapT = (p - 0.2) / 0.25
                let converge = 3.0 * (1.0 - snapT)

                // Converging ghost lines
                drawLine(context: &context,
                         from: startPt.offsetY(-converge),
                         to: endPt.offsetY(-converge),
                         color: signalGreen, width: baseWidth, opacity: 0.3 * (1.0 - snapT))
                drawLine(context: &context,
                         from: startPt.offsetY(converge),
                         to: endPt.offsetY(converge),
                         color: cyanGhost, width: baseWidth, opacity: 0.3 * (1.0 - snapT))

                // Brief green flash at snap point
                let flashIntensity = snapT < 0.5 ? snapT * 2 : (1.0 - snapT) * 2
                drawLine(context: &context, from: startPt, to: endPt,
                         color: signalGreen, width: baseWidth + 2, opacity: flashIntensity * 0.6)

                // Main line rising opacity
                let mainOpacity = 0.3 + 0.7 * snapT
                drawLine(context: &context, from: startPt, to: endPt,
                         color: baseStroke, width: baseWidth, opacity: mainOpacity)

            } else {
                // SETTLE: Full line + fading green shadow
                let settleT = (p - 0.45) / 0.55
                let shadowOpacity = 0.4 * (1.0 - settleT)

                // Fading green shadow
                if shadowOpacity > 0.01 {
                    drawLine(context: &context, from: startPt, to: endPt,
                             color: signalGreen, width: baseWidth + 2, opacity: shadowOpacity)
                }

                // Full main line
                drawLine(context: &context, from: startPt, to: endPt,
                         color: baseStroke, width: baseWidth)
            }

        } else {
            // --- DISAPPEARING ---
            if p < 0.2 {
                // TEAR: Line starts splitting, main fades
                let tearProgress = p / 0.2
                let aberration = 3.0 * tearProgress

                // Orange ghost up
                drawLine(context: &context,
                         from: startPt.offsetY(-aberration),
                         to: endPt.offsetY(-aberration),
                         color: alertOrange, width: baseWidth, opacity: 0.5 * tearProgress)
                // Cyan ghost down
                drawLine(context: &context,
                         from: startPt.offsetY(aberration),
                         to: endPt.offsetY(aberration),
                         color: cyanGhost, width: baseWidth, opacity: 0.5 * tearProgress)

                // Main line fading
                let mainOpacity = 1.0 - 0.7 * tearProgress
                drawLine(context: &context, from: startPt, to: endPt,
                         color: baseStroke, width: baseWidth, opacity: mainOpacity)

            } else if p < 0.45 {
                // SNAP: Ghosts spread apart, red flash, main fades to 0
                let snapT = (p - 0.2) / 0.25
                let spread = 3.0 + 5.0 * snapT

                // Spreading ghosts
                drawLine(context: &context,
                         from: startPt.offsetY(-spread),
                         to: endPt.offsetY(-spread),
                         color: alertOrange, width: baseWidth, opacity: 0.5 * (1.0 - snapT))
                drawLine(context: &context,
                         from: startPt.offsetY(spread),
                         to: endPt.offsetY(spread),
                         color: cyanGhost, width: baseWidth, opacity: 0.5 * (1.0 - snapT))

                // Brief red flash
                let flashIntensity = snapT < 0.5 ? snapT * 2 : (1.0 - snapT) * 2
                drawLine(context: &context, from: startPt, to: endPt,
                         color: alertRed, width: baseWidth + 1, opacity: flashIntensity * 0.5)

                // Main fading to 0
                let mainOpacity = 0.3 * (1.0 - snapT)
                if mainOpacity > 0.01 {
                    drawLine(context: &context, from: startPt, to: endPt,
                             color: baseStroke, width: baseWidth, opacity: mainOpacity)
                }

            } else {
                // SETTLE: Faint ghost traces fading to 0
                let settleT = (p - 0.45) / 0.55
                let traceOpacity = 0.2 * (1.0 - settleT)
                let traceSpread = 8.0 * (1.0 - settleT * 0.5)

                if traceOpacity > 0.01 {
                    drawLine(context: &context,
                             from: startPt.offsetY(-traceSpread),
                             to: endPt.offsetY(-traceSpread),
                             color: alertOrange, width: baseWidth * 0.5, opacity: traceOpacity)
                    drawLine(context: &context,
                             from: startPt.offsetY(traceSpread),
                             to: endPt.offsetY(traceSpread),
                             color: cyanGhost, width: baseWidth * 0.5, opacity: traceOpacity)
                }
            }
        }
    }

    // MARK: - Helpers

    private static func drawLine(
        context: inout GraphicsContext,
        from start: CGPoint,
        to end: CGPoint,
        color: Color,
        width: CGFloat,
        opacity: Double = 1.0
    ) {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        context.stroke(
            path,
            with: .color(color.opacity(opacity)),
            style: StrokeStyle(lineWidth: width, lineCap: .round)
        )
    }

    private static func drawFlowLink(
        context: inout GraphicsContext,
        from startPt: CGPoint,
        to endPt: CGPoint,
        link: MapLink,
        theme: MapTheme
    ) {
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

// MARK: - CGPoint Extension

private extension CGPoint {
    func offsetY(_ dy: Double) -> CGPoint {
        CGPoint(x: x, y: y + dy)
    }
}
