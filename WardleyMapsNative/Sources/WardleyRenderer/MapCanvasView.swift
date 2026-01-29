import SwiftUI
import WardleyModel
import WardleyTheme

/// SwiftUI Canvas view that renders a complete Wardley Map.
public struct MapCanvasView: View {
    public let map: WardleyMap
    public let theme: MapTheme
    public let highlightedLine: Int?
    public let onComponentTap: ((MapElement) -> Void)?
    public let onComponentDrag: ((MapElement, CGPoint) -> Void)?

    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero

    public init(
        map: WardleyMap,
        theme: MapTheme,
        highlightedLine: Int? = nil,
        onComponentTap: ((MapElement) -> Void)? = nil,
        onComponentDrag: ((MapElement, CGPoint) -> Void)? = nil
    ) {
        self.map = map
        self.theme = theme
        self.highlightedLine = highlightedLine
        self.onComponentTap = onComponentTap
        self.onComponentDrag = onComponentDrag
    }

    var mapWidth: CGFloat {
        map.presentation.size.width > 0 ? map.presentation.size.width : MapDefaults.canvasWidth
    }

    var mapHeight: CGFloat {
        map.presentation.size.height > 0 ? map.presentation.size.height : MapDefaults.canvasHeight
    }

    public var body: some View {
        GeometryReader { geo in
            let fitScale = min(
                geo.size.width / (mapWidth + 40),
                geo.size.height / (mapHeight + 60)
            )
            let effectiveScale = fitScale * scale

            ScrollView([.horizontal, .vertical]) {
                canvas
                    .frame(width: mapWidth + 40, height: mapHeight + 60)
                    .scaleEffect(effectiveScale)
                    .frame(
                        width: (mapWidth + 40) * effectiveScale,
                        height: (mapHeight + 60) * effectiveScale
                    )
            }
            .gesture(
                MagnifyGesture()
                    .onChanged { value in
                        scale = max(0.5, min(3.0, value.magnification))
                    }
            )
        }
    }

    var canvas: some View {
        Canvas { context, size in
            let calc = PositionCalculator(mapWidth: mapWidth, mapHeight: mapHeight)

            // 1. Grid background
            GridDrawing.draw(
                context: &context,
                size: size,
                theme: theme,
                evolution: map.evolution,
                calc: calc
            )

            // 2. Attitudes (behind everything)
            AttitudeDrawing.draw(
                context: &context,
                attitudes: map.attitudes,
                theme: theme,
                calc: calc
            )

            // 3. Pipelines
            PipelineDrawing.draw(
                context: &context,
                pipelines: map.pipelines,
                elements: map.elements,
                theme: theme,
                calc: calc
            )

            // 4. Links
            LinkDrawing.draw(
                context: &context,
                links: map.links,
                elements: map.elements,
                anchors: map.anchors,
                submaps: map.submaps,
                evolved: map.evolved,
                theme: theme,
                calc: calc
            )

            // 5. Evolution links (dashed red)
            EvolutionLinkDrawing.draw(
                context: &context,
                elements: map.elements,
                evolved: map.evolved,
                theme: theme,
                calc: calc
            )

            // 6. Components
            ComponentDrawing.drawElements(
                context: &context,
                elements: map.elements,
                theme: theme,
                calc: calc,
                highlightedLine: highlightedLine
            )

            // 7. Anchors
            ComponentDrawing.drawAnchors(
                context: &context,
                anchors: map.anchors,
                theme: theme,
                calc: calc
            )

            // 8. Submaps
            ComponentDrawing.drawSubmaps(
                context: &context,
                submaps: map.submaps,
                theme: theme,
                calc: calc
            )

            // 9. Annotations
            AnnotationDrawing.draw(
                context: &context,
                annotations: map.annotations,
                presentation: map.presentation,
                theme: theme,
                calc: calc
            )

            // 10. Notes
            NoteDrawing.drawNotes(
                context: &context,
                notes: map.notes,
                theme: theme,
                calc: calc
            )

            // 11. Accelerators
            NoteDrawing.drawAccelerators(
                context: &context,
                accelerators: map.accelerators,
                theme: theme,
                calc: calc
            )

            // 12. Methods
            MethodDrawing.draw(
                context: &context,
                methods: map.methods,
                elements: map.elements,
                theme: theme,
                calc: calc
            )

            // 13. Title
            if !map.title.isEmpty && map.title != "Untitled Map" {
                context.draw(
                    Text(map.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(theme.stroke),
                    at: CGPoint(x: mapWidth / 2, y: 10),
                    anchor: .top
                )
            }
        }
    }
}
