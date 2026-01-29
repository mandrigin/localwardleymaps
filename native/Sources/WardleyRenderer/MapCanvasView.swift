import SwiftUI
import WardleyModel
import WardleyTheme

/// SwiftUI Canvas view that renders a complete Wardley Map.
public struct MapCanvasView: View {
    public let map: WardleyMap
    public let theme: MapTheme
    public let highlightedLine: Int?
    public let glitchProgress: [String: GlitchInfo]
    public let onComponentTap: ((MapElement) -> Void)?
    public let onComponentDrag: ((MapElement, CGPoint) -> Void)?

    public init(
        map: WardleyMap,
        theme: MapTheme,
        highlightedLine: Int? = nil,
        glitchProgress: [String: GlitchInfo] = [:],
        onComponentTap: ((MapElement) -> Void)? = nil,
        onComponentDrag: ((MapElement, CGPoint) -> Void)? = nil
    ) {
        self.map = map
        self.theme = theme
        self.highlightedLine = highlightedLine
        self.glitchProgress = glitchProgress
        self.onComponentTap = onComponentTap
        self.onComponentDrag = onComponentDrag
    }

    public var body: some View {
        Canvas { context, size in
            let calc = PositionCalculator(mapWidth: size.width, mapHeight: size.height)

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
                calc: calc
            )

            EvolutionLinkDrawing.draw(
                context: &context,
                elements: map.elements,
                evolved: map.evolved,
                theme: theme,
                calc: calc
            )

            // --- Dots layer (below labels) ---
            ComponentDrawing.drawElementDots(
                context: &context,
                elements: map.elements,
                theme: theme,
                calc: calc,
                highlightedLine: highlightedLine,
                glitchProgress: glitchProgress
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
                glitchProgress: glitchProgress
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
    }
}
