import SwiftUI
import WardleyModel
import WardleyTheme

/// Draws components (circles with labels), anchors, and evolved components.
public struct ComponentDrawing {
    // CRT brand colors (shared by glitch and drag effects)
    private static let alertColor = Color(red: 1.0, green: 0.267, blue: 0.0)       // #FF4400
    private static let signalColor = Color(red: 0.0, green: 1.0, blue: 0.533)      // #00FF88
    private static let cyanColor = Color(red: 0.0, green: 0.8, blue: 1.0)          // #00CCFF

    /// Snap curve: cubic-bezier(0.12, 0.8, 0.32, 1) approximation
    private static func snapCurve(_ t: Double) -> Double {
        let t2 = t * t
        let t3 = t2 * t
        return 3.0 * (1.0 - t) * (1.0 - t) * t * 0.8 + 3.0 * (1.0 - t) * t2 * 1.0 + t3
    }

    /// Draw a rounded-rect background behind a label for readability.
    private static func drawLabelBackground(
        context: inout GraphicsContext,
        at point: CGPoint,
        name: String,
        fontSize: CGFloat,
        anchor: UnitPoint = .topLeading,
        backgroundColor: Color,
        opacity: Double
    ) {
        let padding: CGFloat = 3
        let w = CGFloat(name.count) * fontSize * 0.6 + padding * 2
        let h = fontSize * 1.4 + padding * 2
        let x: CGFloat
        let y: CGFloat
        switch anchor {
        case .topLeading:
            x = point.x - padding
            y = point.y - padding
        case .bottom:
            x = point.x - w / 2
            y = point.y - h + padding
        default:
            x = point.x - padding
            y = point.y - padding
        }
        let rect = CGRect(x: x, y: y, width: w, height: h)
        context.fill(
            Path(roundedRect: rect, cornerRadius: 4),
            with: .color(backgroundColor.opacity(opacity))
        )
    }

    /// Draw element dots/circles only (no labels).
    public static func drawElementDots(
        context: inout GraphicsContext,
        elements: [MapElement],
        theme: MapTheme,
        calc: PositionCalculator,
        highlightedLine: Int? = nil,
        glitchProgress: [String: GlitchInfo] = [:],
        positionOverrides: [String: CGPoint] = [:],
        dragPhase: Double = 0,
        labelMoveElementName: String? = nil
    ) {
        for element in elements {
            let pt = positionOverrides[element.name] ?? calc.point(visibility: element.visibility, maturity: element.maturity)
            let isDragging = positionOverrides[element.name] != nil
            let isHighlighted = highlightedLine == element.line
            let isEvolved = element.evolved
            let strokeColor = isEvolved ? theme.component.evolved : theme.component.stroke
            let fillColor = isEvolved ? theme.component.evolvedFill : theme.component.fill
            let r = theme.component.radius

            if isDragging {
                // === DRAG EFFECT: mostly clean signal, rare noise bursts ===
                let t = dragPhase
                let dragR = r * 1.5

                // Noise gate: two incommensurate sines multiplied — only spikes
                // above threshold produce a glitch. ~15% of frames are "noisy".
                let noiseRaw = sin(t * 17.3) * sin(t * 41.7)
                let noisy = noiseRaw > 0.6
                let noiseAmt = noisy ? (noiseRaw - 0.6) / 0.4 : 0.0  // 0..1 when active

                // Position: stable, with rare jitter
                let jX = noisy ? sin(t * 83) * 2.0 * noiseAmt : 0.0
                let jY = noisy ? cos(t * 71) * 1.5 * noiseAmt : 0.0
                let drawPt = CGPoint(x: pt.x + jX, y: pt.y + jY)

                // Chromatic aberration: only during noise
                if noisy {
                    let ab = 3.0 * noiseAmt
                    let rRect = CGRect(x: drawPt.x + ab - dragR, y: drawPt.y - 1 - dragR, width: dragR * 2, height: dragR * 2)
                    context.fill(Path(ellipseIn: rRect), with: .color(alertColor.opacity(0.3 * noiseAmt)))
                    let lRect = CGRect(x: drawPt.x - ab - dragR, y: drawPt.y + 1 - dragR, width: dragR * 2, height: dragR * 2)
                    context.fill(Path(ellipseIn: lRect), with: .color(cyanColor.opacity(0.3 * noiseAmt)))
                }

                // Rare flash: separate gate, ~5% of frames
                let flashGate = sin(t * 53.1) * sin(t * 29.7)
                if flashGate > 0.8 {
                    let fi = (flashGate - 0.8) / 0.2 * 0.5
                    let fRect = CGRect(x: drawPt.x - dragR - 2, y: drawPt.y - dragR - 2, width: (dragR + 2) * 2, height: (dragR + 2) * 2)
                    context.fill(Path(roundedRect: fRect, cornerRadius: 1), with: .color(signalColor.opacity(fi)))
                }

                // Main dot — stable opacity with rare dips
                let dotOpacity = noisy ? 0.45 + 0.15 * (1.0 - noiseAmt) : 0.6
                let mainRect = CGRect(x: drawPt.x - dragR, y: drawPt.y - dragR, width: dragR * 2, height: dragR * 2)
                context.fill(Path(ellipseIn: mainRect), with: .color(fillColor.opacity(dotOpacity)))
                context.stroke(
                    Path(ellipseIn: mainRect),
                    with: .color(strokeColor.opacity(dotOpacity + 0.15)),
                    style: StrokeStyle(lineWidth: theme.component.strokeWidth + 1)
                )

                // Shadow slab — steady with noise wobble
                let shadowOff = noisy ? 4.0 + sin(t * 23) * 1.5 * noiseAmt : 4.0
                let shadowRect = CGRect(
                    x: drawPt.x - dragR + shadowOff, y: drawPt.y - dragR + shadowOff,
                    width: dragR * 2, height: dragR * 2
                )
                context.fill(Path(roundedRect: shadowRect, cornerRadius: 0), with: .color(signalColor.opacity(0.15)))

                // Inertia marker
                if element.inertia {
                    var inertiaPath = Path()
                    inertiaPath.move(to: CGPoint(x: drawPt.x + dragR + 2, y: drawPt.y - 10))
                    inertiaPath.addLine(to: CGPoint(x: drawPt.x + dragR + 2, y: drawPt.y + 10))
                    context.stroke(
                        inertiaPath,
                        with: .color(strokeColor.opacity(0.5)),
                        style: StrokeStyle(lineWidth: 2)
                    )
                }

            } else if let glitch = glitchProgress[element.name], glitch.progress < 1.0 {
                // === CRT GLITCH EFFECT ===
                let p = glitch.progress
                let primaryColor = glitch.isNew ? signalColor : alertColor

                if p < 0.2 {
                    // --- TEAR PHASE ---
                    let tearProgress = p / 0.2
                    let aberration = 3.0 * (1.0 - tearProgress)

                    // Right-shifted ghost in primary color
                    let rightRect = CGRect(x: pt.x + aberration - r, y: pt.y - r, width: r * 2, height: r * 2)
                    context.fill(Path(ellipseIn: rightRect), with: .color(primaryColor.opacity(0.6)))

                    // Left-shifted ghost in cyan
                    let leftRect = CGRect(x: pt.x - aberration - r, y: pt.y - r, width: r * 2, height: r * 2)
                    context.fill(Path(ellipseIn: leftRect), with: .color(cyanColor.opacity(0.6)))

                    // Original dot at reduced opacity
                    let rect = CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(fillColor.opacity(0.3)))
                    context.stroke(
                        Path(ellipseIn: rect),
                        with: .color(strokeColor.opacity(0.3)),
                        style: StrokeStyle(lineWidth: theme.component.strokeWidth)
                    )

                } else if p < 0.45 {
                    // --- SNAP PHASE ---
                    let snapT = (p - 0.2) / 0.25
                    let curved = snapCurve(snapT)

                    // Collapsing aberration
                    let aberration = 3.0 * (1.0 - curved)
                    let rightRect = CGRect(x: pt.x + aberration - r, y: pt.y - r, width: r * 2, height: r * 2)
                    context.fill(Path(ellipseIn: rightRect), with: .color(primaryColor.opacity(0.6 * (1.0 - curved))))

                    let leftRect = CGRect(x: pt.x - aberration - r, y: pt.y - r, width: r * 2, height: r * 2)
                    context.fill(Path(ellipseIn: leftRect), with: .color(cyanColor.opacity(0.6 * (1.0 - curved))))

                    // Flash: brief full-opacity primary rectangle behind dot
                    let flashOpacity = snapT < 0.3 ? (0.3 - snapT) / 0.3 * 0.8 : 0.0
                    if flashOpacity > 0 {
                        let flashRect = CGRect(
                            x: pt.x - r - 2, y: pt.y - r - 2,
                            width: (r + 2) * 2, height: (r + 2) * 2
                        )
                        context.fill(Path(roundedRect: flashRect, cornerRadius: 1), with: .color(primaryColor.opacity(flashOpacity)))
                    }

                    // Normal dot (opacity rising from 0.3 to 1.0)
                    let dotOpacity = 0.3 + 0.7 * curved
                    let rect = CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(fillColor.opacity(dotOpacity)))
                    context.stroke(
                        Path(ellipseIn: rect),
                        with: .color(strokeColor.opacity(dotOpacity)),
                        style: StrokeStyle(lineWidth: theme.component.strokeWidth)
                    )

                } else {
                    // --- SETTLE PHASE ---
                    let settleT = (p - 0.45) / 0.55

                    // Hard shadow rectangle fading out (4px offset, brand style)
                    let shadowOpacity = 0.6 * (1.0 - settleT)
                    if shadowOpacity > 0.01 {
                        let shadowRect = CGRect(
                            x: pt.x - r + 4, y: pt.y - r + 4,
                            width: r * 2, height: r * 2
                        )
                        context.fill(Path(roundedRect: shadowRect, cornerRadius: 0), with: .color(primaryColor.opacity(shadowOpacity)))
                    }

                    // Normal dot at full opacity
                    let rect = CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(fillColor))
                    context.stroke(
                        Path(ellipseIn: rect),
                        with: .color(strokeColor),
                        style: StrokeStyle(lineWidth: theme.component.strokeWidth)
                    )
                }

                // Inertia marker (always drawn during glitch)
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

            } else {
                // === NORMAL DRAWING (no glitch, no drag) ===
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

                if labelMoveElementName == element.name {
                    let selR = r + 4
                    let selRect = CGRect(
                        x: pt.x - selR, y: pt.y - selR,
                        width: selR * 2, height: selR * 2
                    )
                    context.stroke(
                        Path(ellipseIn: selRect),
                        with: .color(strokeColor.opacity(0.7)),
                        style: StrokeStyle(lineWidth: 2, dash: [4, 2])
                    )
                }
            }
        }
    }

    /// Draw element labels only (on top of everything).
    public static func drawElementLabels(
        context: inout GraphicsContext,
        elements: [MapElement],
        theme: MapTheme,
        calc: PositionCalculator,
        glitchProgress: [String: GlitchInfo] = [:],
        positionOverrides: [String: CGPoint] = [:],
        dragPhase: Double = 0,
        labelMoveElementName: String? = nil,
        labelOffsetOverrides: [String: CGPoint] = [:]
    ) {
        for element in elements {
            let pt = positionOverrides[element.name] ?? calc.point(visibility: element.visibility, maturity: element.maturity)
            let isDragging = positionOverrides[element.name] != nil
            let isEvolved = element.evolved
            let textColor = isEvolved ? theme.component.evolvedTextColor : theme.component.textColor

            if isDragging {
                // Drag label: mostly stable, rare noise jitter
                let t = dragPhase
                let noiseRaw = sin(t * 17.3) * sin(t * 41.7)
                let noisy = noiseRaw > 0.6
                let noiseAmt = noisy ? (noiseRaw - 0.6) / 0.4 : 0.0
                let jX = noisy ? sin(t * 83) * 2.0 * noiseAmt : 0.0
                let jY = noisy ? cos(t * 71) * 1.5 * noiseAmt : 0.0
                let labelOpacity = noisy ? 0.5 + 0.15 * (1.0 - noiseAmt) : 0.65
                let labelPt = CGPoint(
                    x: pt.x + element.label.x + jX,
                    y: pt.y + element.label.y + jY
                )
                drawLabelBackground(
                    context: &context,
                    at: labelPt,
                    name: element.name,
                    fontSize: theme.component.fontSize,
                    anchor: .topLeading,
                    backgroundColor: theme.containerBackground,
                    opacity: labelOpacity
                )
                context.draw(
                    Text(element.name)
                        .font(.system(size: theme.component.fontSize, weight: theme.component.fontWeight))
                        .foregroundStyle(textColor.opacity(labelOpacity)),
                    at: labelPt,
                    anchor: .topLeading
                )
            } else if let glitch = glitchProgress[element.name], glitch.progress < 1.0 {
                let p = glitch.progress

                if p < 0.2 {
                    // Tear phase: jitter label horizontally
                    let tearProgress = p / 0.2
                    let jitterDirection: Double = element.name.hashValue % 2 == 0 ? 1.0 : -1.0
                    let jitter = 2.0 * (1.0 - tearProgress) * jitterDirection
                    let labelPt = CGPoint(
                        x: pt.x + element.label.x + jitter,
                        y: pt.y + element.label.y
                    )
                    drawLabelBackground(
                        context: &context,
                        at: labelPt,
                        name: element.name,
                        fontSize: theme.component.fontSize,
                        anchor: .topLeading,
                        backgroundColor: theme.containerBackground,
                        opacity: 0.3
                    )
                    context.draw(
                        Text(element.name)
                            .font(.system(size: theme.component.fontSize, weight: theme.component.fontWeight))
                            .foregroundStyle(textColor.opacity(0.3)),
                        at: labelPt,
                        anchor: .topLeading
                    )
                } else if p < 0.45 {
                    // Snap phase: rising opacity
                    let snapT = (p - 0.2) / 0.25
                    let curved = snapCurve(snapT)
                    let dotOpacity = 0.3 + 0.7 * curved
                    let labelPt = CGPoint(
                        x: pt.x + element.label.x,
                        y: pt.y + element.label.y
                    )
                    drawLabelBackground(
                        context: &context,
                        at: labelPt,
                        name: element.name,
                        fontSize: theme.component.fontSize,
                        anchor: .topLeading,
                        backgroundColor: theme.containerBackground,
                        opacity: dotOpacity
                    )
                    context.draw(
                        Text(element.name)
                            .font(.system(size: theme.component.fontSize, weight: theme.component.fontWeight))
                            .foregroundStyle(textColor.opacity(dotOpacity)),
                        at: labelPt,
                        anchor: .topLeading
                    )
                } else {
                    // Settle phase: normal label
                    let labelPt = CGPoint(
                        x: pt.x + element.label.x,
                        y: pt.y + element.label.y
                    )
                    drawLabelBackground(
                        context: &context,
                        at: labelPt,
                        name: element.name,
                        fontSize: theme.component.fontSize,
                        anchor: .topLeading,
                        backgroundColor: theme.containerBackground,
                        opacity: 0.6
                    )
                    context.draw(
                        Text(element.name)
                            .font(.system(size: theme.component.fontSize, weight: theme.component.fontWeight))
                            .foregroundStyle(textColor),
                        at: labelPt,
                        anchor: .topLeading
                    )
                }
            } else {
                // Normal label (or label-move mode)
                let labelOffset = labelOffsetOverrides[element.name] ?? CGPoint(x: element.label.x, y: element.label.y)
                let labelPt = CGPoint(
                    x: pt.x + labelOffset.x,
                    y: pt.y + labelOffset.y
                )
                let isLabelMove = labelMoveElementName == element.name
                let fontWeight: Font.Weight = isLabelMove ? .bold : theme.component.fontWeight
                let strokeColor = isEvolved ? theme.component.evolved : theme.component.stroke

                if isLabelMove {
                    // Connector line from dot to label
                    var connectorPath = Path()
                    connectorPath.move(to: pt)
                    connectorPath.addLine(to: labelPt)
                    context.stroke(
                        connectorPath,
                        with: .color(strokeColor.opacity(0.4)),
                        style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                    )

                    // Highlight background behind label
                    let labelW = CGFloat(element.name.count) * theme.component.fontSize * 0.6
                    let labelH = theme.component.fontSize * 1.4
                    let bgRect = CGRect(x: labelPt.x - 2, y: labelPt.y - 2, width: labelW + 4, height: labelH + 4)
                    context.fill(
                        Path(roundedRect: bgRect, cornerRadius: 3),
                        with: .color(textColor.opacity(0.08))
                    )
                }

                drawLabelBackground(
                    context: &context,
                    at: labelPt,
                    name: element.name,
                    fontSize: theme.component.fontSize,
                    anchor: .topLeading,
                    backgroundColor: theme.containerBackground,
                    opacity: 0.6
                )
                context.draw(
                    Text(element.name)
                        .font(.system(size: theme.component.fontSize, weight: fontWeight))
                        .foregroundStyle(textColor),
                    at: labelPt,
                    anchor: .topLeading
                )
            }
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
            let anchorLabelPt = CGPoint(x: pt.x, y: pt.y - 12)
            drawLabelBackground(
                context: &context,
                at: anchorLabelPt,
                name: anchor.name,
                fontSize: theme.anchor.fontSize,
                anchor: .bottom,
                backgroundColor: theme.containerBackground,
                opacity: 0.6
            )
            context.draw(
                Text(anchor.name)
                    .font(.system(size: theme.anchor.fontSize, weight: .bold))
                    .foregroundStyle(theme.component.textColor),
                at: anchorLabelPt,
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
            drawLabelBackground(
                context: &context,
                at: labelPt,
                name: submap.name,
                fontSize: theme.submap.fontSize,
                anchor: .topLeading,
                backgroundColor: theme.containerBackground,
                opacity: 0.6
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
