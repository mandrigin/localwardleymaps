import SwiftUI

// MARK: - Built-in Themes

public enum Themes {
    public static let all: [String: MapTheme] = [
        "plain": plain,
        "wardley": wardley,
        "handwritten": handwritten,
        "colour": colour,
        "dark": dark,
        "gateway": gateway,
    ]

    public static func theme(named name: String) -> MapTheme {
        all[name.lowercased()] ?? plain
    }

    // MARK: - Plain (default)

    public static let plain = MapTheme()

    // MARK: - Wardley

    public static let wardley = MapTheme(
        name: "wardley",
        fontFamily: "Menlo",
        evolutionSeparationStroke: Color(hex: "#b8b8b8"),
        component: ComponentTheme(
            fontSize: 12
        )
    )

    // MARK: - Handwritten

    public static let handwritten = MapTheme(
        name: "handwritten",
        fontFamily: "Noteworthy",
        component: ComponentTheme(
            fontSize: 12
        )
    )

    // MARK: - Colour

    public static let colour = MapTheme(
        name: "colour",
        stroke: Color(hex: "#c23667"),
        pipelineArrowStroke: Color(hex: "#8cb358"),
        evolutionSeparationStroke: Color(hex: "#b8b8b8"),
        strokeWidth: 3,
        component: ComponentTheme(
            fill: .white,
            stroke: Color(hex: "#8cb358"),
            evolved: Color(hex: "#ea7f5b"),
            evolvedFill: .white,
            strokeWidth: 2,
            radius: 7,
            textColor: Color(hex: "#486b1a"),
            evolvedTextColor: Color(hex: "#ea7f5b")
        ),
        submap: SubMapTheme(
            fill: Color(hex: "#8cb358"),
            stroke: Color(hex: "#8cb358"),
            evolved: Color(hex: "#ea7f5b"),
            evolvedFill: Color(hex: "#8cb358"),
            strokeWidth: 2,
            radius: 7,
            textColor: Color(hex: "#486b1a"),
            evolvedTextColor: Color(hex: "#ea7f5b")
        ),
        link: LinkTheme(
            stroke: Color(hex: "#5c5c5c"),
            evolvedStroke: Color(hex: "#ea7f5b")
        ),
        annotation: AnnotationTheme(
            stroke: Color(hex: "#015fa5"),
            strokeWidth: 2,
            fill: Color(hex: "#99c5ee"),
            boxStroke: Color(hex: "#015fa5"),
            boxStrokeWidth: 2,
            boxFill: Color(hex: "#99c5ee")
        )
    )

    // MARK: - Dark

    public static let dark = MapTheme(
        name: "dark",
        containerBackground: Color(hex: "#353347"),
        stroke: .white,
        pipelineArrowStroke: .white,
        evolutionSeparationStroke: .white,
        mapGridTextColor: .white.opacity(0.8),
        market: MarketTheme(
            stroke: Color(hex: "#90caf9")
        ),
        component: ComponentTheme(
            fill: .white.opacity(0.8),
            stroke: .white,
            evolved: Color(hex: "#90caf9"),
            evolvedFill: .white,
            textColor: .white.opacity(0.8),
            evolvedTextColor: Color(hex: "#90caf9"),
            fontSize: 13
        ),
        submap: SubMapTheme(
            fontSize: 13,
            fill: .white,
            stroke: .white,
            evolved: Color(hex: "#90caf9"),
            evolvedFill: .white,
            textColor: .white,
            evolvedTextColor: Color(hex: "#90caf9")
        ),
        link: LinkTheme(
            stroke: .white,
            evolvedStroke: Color(hex: "#90caf9")
        ),
        fluidLink: FluidLinkTheme(
            stroke: .white
        ),
        annotation: AnnotationTheme(
            fill: .white.opacity(0.8),
            text: .black,
            boxFill: .white.opacity(0.8),
            boxTextColor: .black
        ),
        note: NoteTheme(
            textColor: .white.opacity(0.8)
        )
    )

    // MARK: - Gateway.fm

    public static let gateway = MapTheme(
        name: "gateway",
        containerBackground: .white,
        fontFamily: "Gotham",
        fontSize: 13,
        stroke: Color(hex: "#1e1b4b"),
        pipelineArrowStroke: Color(hex: "#6366f1"),
        evolutionSeparationStroke: Color(hex: "#cbd5e1"),
        mapGridTextColor: Color(hex: "#64748b"),
        component: ComponentTheme(
            fill: .white,
            stroke: Color(hex: "#6366f1"),
            evolved: Color(hex: "#a855f7"),
            evolvedFill: Color(hex: "#f5f3ff"),
            strokeWidth: 2,
            radius: 6,
            textColor: Color(hex: "#1e1b4b"),
            evolvedTextColor: Color(hex: "#7c3aed"),
            fontSize: 13,
            fontWeight: .medium
        ),
        submap: SubMapTheme(
            fontSize: 13,
            fill: Color(hex: "#6366f1"),
            stroke: Color(hex: "#6366f1"),
            evolved: Color(hex: "#a855f7"),
            evolvedFill: Color(hex: "#6366f1"),
            strokeWidth: 2,
            radius: 6,
            textColor: Color(hex: "#1e1b4b"),
            evolvedTextColor: Color(hex: "#7c3aed")
        ),
        link: LinkTheme(
            stroke: Color(hex: "#94a3b8"),
            evolvedStroke: Color(hex: "#a855f7")
        ),
        fluidLink: FluidLinkTheme(
            stroke: Color(hex: "#94a3b8")
        ),
        annotation: AnnotationTheme(
            stroke: Color(hex: "#6366f1"),
            strokeWidth: 2,
            fill: Color(hex: "#f5f3ff"),
            text: Color(hex: "#1e1b4b"),
            boxStroke: Color(hex: "#6366f1"),
            boxStrokeWidth: 1,
            boxFill: Color(hex: "#f5f3ff"),
            boxTextColor: Color(hex: "#1e1b4b")
        ),
        note: NoteTheme(
            fontWeight: .semibold,
            fontSize: 12,
            fill: Color(hex: "#1e1b4b"),
            textColor: Color(hex: "#1e1b4b"),
            evolvedTextColor: Color(hex: "#7c3aed")
        )
    )
}
