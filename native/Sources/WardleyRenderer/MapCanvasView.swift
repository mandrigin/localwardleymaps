import SwiftUI
import WardleyModel
import WardleyTheme

/// SwiftUI Canvas view that renders a complete Wardley Map.
public struct MapCanvasView: View {
    public let map: WardleyMap
    public let theme: MapTheme
    public let highlightedLine: Int?
    public let glitchProgress: [String: GlitchInfo]
    public let linkGlitchProgress: [LinkID: LinkGlitchInfo]
    public let ghostLinks: [MapLink]
    public let dragOverride: (elementName: String, position: CGPoint)?
    public let dragPhase: Double
    public let markerStrokes: [MarkerDrawing.StrokeSnapshot]
    public let isMarkerActive: Bool
    public let onDragChanged: ((_ elementName: String, _ canvasPosition: CGPoint) -> Void)?
    public let onDragEnded: ((_ elementName: String, _ canvasPosition: CGPoint, _ canvasSize: CGSize) -> Void)?
    public let onLabelDragEnded: ((_ elementName: String, _ newLabelX: Double, _ newLabelY: Double) -> Void)?
    public let onMarkerDragChanged: ((_ canvasPosition: CGPoint) -> Void)?
    public let onMarkerDragEnded: (() -> Void)?

    @State private var dragElementName: String? = nil
    @State private var viewSize: CGSize = .zero

    // Label-move mode state
    @State private var labelMoveElementName: String? = nil
    @State private var isDraggingLabel: Bool = false
    @State private var labelDragOffset: CGPoint? = nil
    @State private var labelDragStartOffset: CGPoint? = nil

    public init(
        map: WardleyMap,
        theme: MapTheme,
        highlightedLine: Int? = nil,
        glitchProgress: [String: GlitchInfo] = [:],
        linkGlitchProgress: [LinkID: LinkGlitchInfo] = [:],
        ghostLinks: [MapLink] = [],
        dragOverride: (elementName: String, position: CGPoint)? = nil,
        dragPhase: Double = 0,
        markerStrokes: [MarkerDrawing.StrokeSnapshot] = [],
        isMarkerActive: Bool = false,
        onDragChanged: ((_ elementName: String, _ canvasPosition: CGPoint) -> Void)? = nil,
        onDragEnded: ((_ elementName: String, _ canvasPosition: CGPoint, _ canvasSize: CGSize) -> Void)? = nil,
        onLabelDragEnded: ((_ elementName: String, _ newLabelX: Double, _ newLabelY: Double) -> Void)? = nil,
        onMarkerDragChanged: ((_ canvasPosition: CGPoint) -> Void)? = nil,
        onMarkerDragEnded: (() -> Void)? = nil
    ) {
        self.map = map
        self.theme = theme
        self.highlightedLine = highlightedLine
        self.glitchProgress = glitchProgress
        self.linkGlitchProgress = linkGlitchProgress
        self.ghostLinks = ghostLinks
        self.dragOverride = dragOverride
        self.dragPhase = dragPhase
        self.markerStrokes = markerStrokes
        self.isMarkerActive = isMarkerActive
        self.onDragChanged = onDragChanged
        self.onDragEnded = onDragEnded
        self.onLabelDragEnded = onLabelDragEnded
        self.onMarkerDragChanged = onMarkerDragChanged
        self.onMarkerDragEnded = onMarkerDragEnded
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

    /// Check if a point is near the selected element's dot or label.
    private func isNearSelectedElement(_ point: CGPoint, size: CGSize) -> Bool {
        guard let selectedName = labelMoveElementName else { return false }
        let calc = PositionCalculator(mapWidth: size.width, mapHeight: size.height)
        let hitRadius: CGFloat = theme.component.radius + 12

        for element in map.elements where element.name == selectedName {
            let pt = calc.point(visibility: element.visibility, maturity: element.maturity)

            // Check dot
            let dist = hypot(pt.x - point.x, pt.y - point.y)
            if dist < hitRadius { return true }

            // Check label
            let lr = labelRect(center: pt, labelX: element.label.x, labelY: element.label.y,
                             name: element.name, fontSize: theme.component.fontSize)
            if lr.contains(point) { return true }
        }
        return false
    }

    private func handleDoubleClick(at location: CGPoint, size: CGSize) {
        let calc = PositionCalculator(mapWidth: size.width, mapHeight: size.height)
        let hitRadius: CGFloat = theme.component.radius + 8
        var bestDist: CGFloat = .infinity
        var bestName: String? = nil

        for element in map.elements {
            let pt = calc.point(visibility: element.visibility, maturity: element.maturity)
            let dist = hypot(pt.x - location.x, pt.y - location.y)
            if dist < hitRadius && dist < bestDist {
                bestDist = dist
                bestName = element.name
            }

            // Also allow double-click on label
            let lr = labelRect(center: pt, labelX: element.label.x, labelY: element.label.y,
                             name: element.name, fontSize: theme.component.fontSize)
            if lr.contains(location) {
                let labelDist = hypot(lr.midX - location.x, lr.midY - location.y)
                if labelDist < bestDist {
                    bestDist = labelDist
                    bestName = element.name
                }
            }
        }

        if let name = bestName {
            // Toggle label-move mode
            if labelMoveElementName == name {
                labelMoveElementName = nil
            } else {
                labelMoveElementName = name
            }
        } else {
            labelMoveElementName = nil
        }
    }

    private func handleSingleClick(at location: CGPoint, size: CGSize) {
        guard labelMoveElementName != nil else { return }
        // Exit label-move mode if clicking outside the selected element
        if !isNearSelectedElement(location, size: size) {
            labelMoveElementName = nil
        }
    }

    private func handleCanvasDragChanged(_ value: DragGesture.Value, size: CGSize) {
        // In marker mode, route all drags to marker drawing
        if isMarkerActive {
            onMarkerDragChanged?(value.location)
            return
        }

        let calc = PositionCalculator(mapWidth: size.width, mapHeight: size.height)

        // Label-move mode: drag moves the label
        if let selectedName = labelMoveElementName {
            if isDraggingLabel {
                // Continue dragging label
                let delta = CGPoint(
                    x: value.location.x - value.startLocation.x,
                    y: value.location.y - value.startLocation.y
                )
                if let startOffset = labelDragStartOffset {
                    labelDragOffset = CGPoint(
                        x: startOffset.x + delta.x,
                        y: startOffset.y + delta.y
                    )
                }
                return
            }

            if dragElementName == nil {
                // First touch in label-move mode: check if near selected element
                if isNearSelectedElement(value.startLocation, size: size) {
                    // Start label drag
                    isDraggingLabel = true
                    dragElementName = selectedName
                    if let element = map.elements.first(where: { $0.name == selectedName }) {
                        labelDragStartOffset = CGPoint(x: element.label.x, y: element.label.y)
                    }
                    let delta = CGPoint(
                        x: value.location.x - value.startLocation.x,
                        y: value.location.y - value.startLocation.y
                    )
                    if let startOffset = labelDragStartOffset {
                        labelDragOffset = CGPoint(
                            x: startOffset.x + delta.x,
                            y: startOffset.y + delta.y
                        )
                    }
                    return
                } else {
                    // Drag started outside selected element — exit label-move mode
                    labelMoveElementName = nil
                    // Fall through to normal drag handling
                }
            }
        }

        // Normal drag handling (move component position)
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
        if isDraggingLabel {
            // Finish label drag
            if let name = dragElementName, let offset = labelDragOffset {
                onLabelDragEnded?(name, Double(offset.x), Double(offset.y))
            }
            isDraggingLabel = false
            labelDragOffset = nil
            labelDragStartOffset = nil
            dragElementName = nil
            return
        }

        if isMarkerActive {
            onMarkerDragEnded?()
            return
        }
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

            // Build label offset overrides from label drag state
            var labelOverrides: [String: CGPoint] = [:]
            if let name = labelMoveElementName, let offset = labelDragOffset {
                labelOverrides[name] = offset
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
                positionOverrides: posOverrides,
                linkGlitchProgress: linkGlitchProgress,
                ghostLinks: ghostLinks
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
                dragPhase: dragPhase,
                labelMoveElementName: labelMoveElementName
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
                dragPhase: dragPhase,
                labelMoveElementName: labelMoveElementName,
                labelOffsetOverrides: labelOverrides
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

            // --- Marker overlay (on top of everything) ---
            MarkerDrawing.draw(
                context: &context,
                strokes: markerStrokes
            )
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
        .simultaneousGesture(
            SpatialTapGesture(count: 2)
                .onEnded { value in
                    handleDoubleClick(at: value.location, size: viewSize)
                }
        )
        .simultaneousGesture(
            SpatialTapGesture(count: 1)
                .onEnded { value in
                    handleSingleClick(at: value.location, size: viewSize)
                }
        )
        .onKeyPress(.escape) {
            if labelMoveElementName != nil {
                labelMoveElementName = nil
                return .handled
            }
            return .ignored
        }
    }
}
