import SwiftUI
import WardleyModel
import WardleyTheme

/// SwiftUI Canvas view that renders a complete Wardley Map.
public struct MapCanvasView: View {
    public let map: WardleyMap
    public let theme: MapTheme
    public let highlightedLine: Int?
    public let glitchProgress: [String: GlitchInfo]
    public let dragOverride: (elementName: String, position: CGPoint)?
    public let dragPhase: Double
    public let onDragChanged: ((_ elementName: String, _ canvasPosition: CGPoint) -> Void)?
    public let onDragEnded: ((_ elementName: String, _ canvasPosition: CGPoint, _ canvasSize: CGSize) -> Void)?

    @State private var dragElementName: String? = nil
    @State private var viewSize: CGSize = .zero

    public init(
        map: WardleyMap,
        theme: MapTheme,
        highlightedLine: Int? = nil,
        glitchProgress: [String: GlitchInfo] = [:],
        dragOverride: (elementName: String, position: CGPoint)? = nil,
        dragPhase: Double = 0,
        onDragChanged: ((_ elementName: String, _ canvasPosition: CGPoint) -> Void)? = nil,
        onDragEnded: ((_ elementName: String, _ canvasPosition: CGPoint, _ canvasSize: CGSize) -> Void)? = nil
    ) {
        self.map = map
        self.theme = theme
        self.highlightedLine = highlightedLine
        self.glitchProgress = glitchProgress
        self.dragOverride = dragOverride
        self.dragPhase = dragPhase
        self.onDragChanged = onDragChanged
        self.onDragEnded = onDragEnded
    }

    /// Estimated label bounding rect for hit-testing (topLeading anchor).
    private func labelRect(center pt: CGPoint, labelX: Double, labelY: Double, name: String, fontSize: CGFloat) -> CGRect {
        let w = CGFloat(name.count) * fontSize * 0.6
        let h = fontSize * 1.4
        let padding: CGFloat = 4
        return CGRect(
            x: pt.x + labelX - padding,
            y: pt.y + labelY - padding,
            width: w + padding * 2,
            height: h + padding * 2
        )
    }

    private func handleCanvasDragChanged(_ value: DragGesture.Value, size: CGSize) {
        let calc = PositionCalculator(mapWidth: size.width, mapHeight: size.height)

        // First touch: hit-test to find nearest element (dot OR label)
        if dragElementName == nil {
            let hitRadius: CGFloat = theme.component.radius + 8
            var bestDist: CGFloat = .infinity
            var bestName: String? = nil

            for element in map.elements {
                let pt = calc.point(visibility: element.visibility, maturity: element.maturity)

                // Hit-test dot
                let dx = pt.x - value.startLocation.x
                let dy = pt.y - value.startLocation.y
                let dist = sqrt(dx * dx + dy * dy)
                if dist < hitRadius && dist < bestDist {
                    bestDist = dist
                    bestName = element.name
                }

                // Hit-test label
                let lr = labelRect(center: pt, labelX: element.label.x, labelY: element.label.y, name: element.name, fontSize: theme.component.fontSize)
                if lr.contains(value.startLocation) {
                    let labelDist = hypot(
                        lr.midX - value.startLocation.x,
                        lr.midY - value.startLocation.y
                    )
                    if labelDist < bestDist {
                        bestDist = labelDist
                        bestName = element.name
                    }
                }
            }
            for anchor in map.anchors {
                let pt = calc.point(visibility: anchor.visibility, maturity: anchor.maturity)
                let dx = pt.x - value.startLocation.x
                let dy = pt.y - value.startLocation.y
                let dist = sqrt(dx * dx + dy * dy)
                if dist < hitRadius && dist < bestDist {
                    bestDist = dist
                    bestName = anchor.name
                }
            }
            for submap in map.submaps {
                let pt = calc.point(visibility: submap.visibility, maturity: submap.maturity)
                let dx = pt.x - value.startLocation.x
                let dy = pt.y - value.startLocation.y
                let dist = sqrt(dx * dx + dy * dy)
                if dist < hitRadius && dist < bestDist {
                    bestDist = dist
                    bestName = submap.name
                }
            }
            dragElementName = bestName
        }

        if let name = dragElementName {
            onDragChanged?(name, value.location)
        }
    }

    private func handleCanvasDragEnded(_ value: DragGesture.Value) {
        if let name = dragElementName {
            onDragEnded?(name, value.location, viewSize)
        }
        dragElementName = nil
    }

    public var body: some View {
        Canvas { context, size in
            let calc = PositionCalculator(mapWidth: size.width, mapHeight: size.height)

            // Build position overrides from drag state
            var posOverrides: [String: CGPoint] = [:]
            if let drag = dragOverride {
                posOverrides[drag.elementName] = drag.position
            }

            GridDrawing.draw(
                context: &context,
                size: size,
                theme: theme,
                evolution: map.evolution,
                calc: calc
            )

            AttitudeDrawing.draw(
                context: &context,
                attitudes: map.attitudes,
                theme: theme,
                calc: calc
            )

            PipelineDrawing.draw(
                context: &context,
                pipelines: map.pipelines,
                elements: map.elements,
                theme: theme,
                calc: calc
            )

            LinkDrawing.draw(
                context: &context,
                links: map.links,
                elements: map.elements,
                anchors: map.anchors,
                submaps: map.submaps,
                evolved: map.evolved,
                theme: theme,
                calc: calc,
                positionOverrides: posOverrides
            )

            EvolutionLinkDrawing.draw(
                context: &context,
                elements: map.elements,
                evolved: map.evolved,
                theme: theme,
                calc: calc,
                positionOverrides: posOverrides
            )

            // --- Dots layer (below labels) ---
            ComponentDrawing.drawElementDots(
                context: &context,
                elements: map.elements,
                theme: theme,
                calc: calc,
                highlightedLine: highlightedLine,
                glitchProgress: glitchProgress,
                positionOverrides: posOverrides,
                dragPhase: dragPhase
            )

            ComponentDrawing.drawAnchorDots(
                context: &context,
                anchors: map.anchors,
                theme: theme,
                calc: calc
            )

            ComponentDrawing.drawSubmapDots(
                context: &context,
                submaps: map.submaps,
                theme: theme,
                calc: calc
            )

            AnnotationDrawing.draw(
                context: &context,
                annotations: map.annotations,
                presentation: map.presentation,
                theme: theme,
                calc: calc
            )

            NoteDrawing.drawNotes(
                context: &context,
                notes: map.notes,
                theme: theme,
                calc: calc
            )

            NoteDrawing.drawAccelerators(
                context: &context,
                accelerators: map.accelerators,
                theme: theme,
                calc: calc
            )

            MethodDrawing.draw(
                context: &context,
                methods: map.methods,
                elements: map.elements,
                theme: theme,
                calc: calc
            )

            // --- Labels layer (on top of everything) ---
            ComponentDrawing.drawElementLabels(
                context: &context,
                elements: map.elements,
                theme: theme,
                calc: calc,
                glitchProgress: glitchProgress,
                positionOverrides: posOverrides,
                dragPhase: dragPhase
            )

            ComponentDrawing.drawAnchorLabels(
                context: &context,
                anchors: map.anchors,
                theme: theme,
                calc: calc
            )

            ComponentDrawing.drawSubmapLabels(
                context: &context,
                submaps: map.submaps,
                theme: theme,
                calc: calc
            )

            if !map.title.isEmpty && map.title != "Untitled Map" {
                context.draw(
                    Text(map.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(theme.stroke),
                    at: CGPoint(x: size.width / 2, y: 10),
                    anchor: .top
                )
            }
        }
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newSize in
            viewSize = newSize
        }
        .gesture(
            DragGesture(minimumDistance: 4)
                .onChanged { value in
                    handleCanvasDragChanged(value, size: viewSize)
                }
                .onEnded { value in
                    handleCanvasDragEnded(value)
                }
        )
    }
}
