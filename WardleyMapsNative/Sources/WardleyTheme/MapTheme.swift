import SwiftUI
import WardleyModel

// MARK: - Theme Data Structures

public struct MapTheme: Sendable {
    public var name: String
    public var containerBackground: Color
    public var fontFamily: String
    public var fontSize: CGFloat
    public var stroke: Color
    public var pipelineArrowStroke: Color
    public var evolutionSeparationStroke: Color
    public var mapGridTextColor: Color
    public var pipelineArrowHeight: CGFloat
    public var pipelineArrowWidth: CGFloat
    public var strokeWidth: CGFloat
    public var strokeDashPattern: [CGFloat]

    public var anchor: AnchorTheme
    public var attitudes: AttitudesTheme
    public var methods: MethodsTheme
    public var market: MarketTheme
    public var component: ComponentTheme
    public var submap: SubMapTheme
    public var link: LinkTheme
    public var fluidLink: FluidLinkTheme
    public var annotation: AnnotationTheme
    public var note: NoteTheme

    public init(
        name: String = "plain",
        containerBackground: Color = .white,
        fontFamily: String = "Helvetica Neue",
        fontSize: CGFloat = 13,
        stroke: Color = .black,
        pipelineArrowStroke: Color = .black,
        evolutionSeparationStroke: Color = .black,
        mapGridTextColor: Color = .black,
        pipelineArrowHeight: CGFloat = 5,
        pipelineArrowWidth: CGFloat = 5,
        strokeWidth: CGFloat = 1,
        strokeDashPattern: [CGFloat] = [2, 2],
        anchor: AnchorTheme = .init(),
        attitudes: AttitudesTheme = .init(),
        methods: MethodsTheme = .init(),
        market: MarketTheme = .init(),
        component: ComponentTheme = .init(),
        submap: SubMapTheme = .init(),
        link: LinkTheme = .init(),
        fluidLink: FluidLinkTheme = .init(),
        annotation: AnnotationTheme = .init(),
        note: NoteTheme = .init()
    ) {
        self.name = name
        self.containerBackground = containerBackground
        self.fontFamily = fontFamily
        self.fontSize = fontSize
        self.stroke = stroke
        self.pipelineArrowStroke = pipelineArrowStroke
        self.evolutionSeparationStroke = evolutionSeparationStroke
        self.mapGridTextColor = mapGridTextColor
        self.pipelineArrowHeight = pipelineArrowHeight
        self.pipelineArrowWidth = pipelineArrowWidth
        self.strokeWidth = strokeWidth
        self.strokeDashPattern = strokeDashPattern
        self.anchor = anchor
        self.attitudes = attitudes
        self.methods = methods
        self.market = market
        self.component = component
        self.submap = submap
        self.link = link
        self.fluidLink = fluidLink
        self.annotation = annotation
        self.note = note
    }
}

public struct AnchorTheme: Sendable {
    public var fontSize: CGFloat
    public init(fontSize: CGFloat = 14) {
        self.fontSize = fontSize
    }
}

public struct AttitudeTypeTheme: Sendable {
    public var stroke: Color
    public var fill: Color
    public var fillOpacity: Double
    public var strokeOpacity: Double

    public init(
        stroke: Color = .blue,
        fill: Color = .blue,
        fillOpacity: Double = 0.4,
        strokeOpacity: Double = 0.7
    ) {
        self.stroke = stroke
        self.fill = fill
        self.fillOpacity = fillOpacity
        self.strokeOpacity = strokeOpacity
    }
}

public struct AttitudesTheme: Sendable {
    public var strokeWidth: CGFloat
    public var fontSize: CGFloat
    public var pioneers: AttitudeTypeTheme
    public var settlers: AttitudeTypeTheme
    public var townplanners: AttitudeTypeTheme

    public init(
        strokeWidth: CGFloat = 5,
        fontSize: CGFloat = 14,
        pioneers: AttitudeTypeTheme = AttitudeTypeTheme(
            stroke: Color(hex: "#3490dd"), fill: Color(hex: "#3ccaf8")
        ),
        settlers: AttitudeTypeTheme = AttitudeTypeTheme(
            stroke: Color(hex: "#396dc0"), fill: Color(hex: "#599afa")
        ),
        townplanners: AttitudeTypeTheme = AttitudeTypeTheme(
            stroke: Color(hex: "#4768c8"), fill: Color(hex: "#936ff9")
        )
    ) {
        self.strokeWidth = strokeWidth
        self.fontSize = fontSize
        self.pioneers = pioneers
        self.settlers = settlers
        self.townplanners = townplanners
    }
}

public struct MethodTheme: Sendable {
    public var stroke: Color
    public var fill: Color
    public init(stroke: Color = .gray, fill: Color = .gray) {
        self.stroke = stroke
        self.fill = fill
    }
}

public struct MethodsTheme: Sendable {
    public var buy: MethodTheme
    public var build: MethodTheme
    public var outsource: MethodTheme

    public init(
        buy: MethodTheme = MethodTheme(stroke: Color(hex: "#D6D6D6"), fill: Color(hex: "#AAA5A9")),
        build: MethodTheme = MethodTheme(stroke: .black, fill: Color(hex: "#D6D6D6")),
        outsource: MethodTheme = MethodTheme(stroke: Color(hex: "#444444"), fill: Color(hex: "#444444"))
    ) {
        self.buy = buy
        self.build = build
        self.outsource = outsource
    }
}

public struct MarketTheme: Sendable {
    public var stroke: Color
    public var fill: Color
    public init(stroke: Color = .red, fill: Color = .white) {
        self.stroke = stroke
        self.fill = fill
    }
}

public struct ComponentTheme: Sendable {
    public var fill: Color
    public var stroke: Color
    public var evolved: Color
    public var evolvedFill: Color
    public var strokeWidth: CGFloat
    public var pipelineStrokeWidth: CGFloat
    public var radius: CGFloat
    public var textColor: Color
    public var textOffset: CGFloat
    public var evolvedTextColor: Color
    public var fontSize: CGFloat
    public var fontWeight: Font.Weight

    public init(
        fill: Color = .white,
        stroke: Color = .black,
        evolved: Color = .red,
        evolvedFill: Color = .white,
        strokeWidth: CGFloat = 1,
        pipelineStrokeWidth: CGFloat = 1,
        radius: CGFloat = 5,
        textColor: Color = .black,
        textOffset: CGFloat = 8,
        evolvedTextColor: Color = .red,
        fontSize: CGFloat = 14,
        fontWeight: Font.Weight = .regular
    ) {
        self.fill = fill
        self.stroke = stroke
        self.evolved = evolved
        self.evolvedFill = evolvedFill
        self.strokeWidth = strokeWidth
        self.pipelineStrokeWidth = pipelineStrokeWidth
        self.radius = radius
        self.textColor = textColor
        self.textOffset = textOffset
        self.evolvedTextColor = evolvedTextColor
        self.fontSize = fontSize
        self.fontWeight = fontWeight
    }
}

public struct SubMapTheme: Sendable {
    public var fontSize: CGFloat
    public var fill: Color
    public var stroke: Color
    public var evolved: Color
    public var evolvedFill: Color
    public var strokeWidth: CGFloat
    public var pipelineStrokeWidth: CGFloat
    public var radius: CGFloat
    public var textColor: Color
    public var textOffset: CGFloat
    public var evolvedTextColor: Color

    public init(
        fontSize: CGFloat = 13,
        fill: Color = .black,
        stroke: Color = .black,
        evolved: Color = .red,
        evolvedFill: Color = .black,
        strokeWidth: CGFloat = 1,
        pipelineStrokeWidth: CGFloat = 1,
        radius: CGFloat = 5,
        textColor: Color = .black,
        textOffset: CGFloat = 8,
        evolvedTextColor: Color = .red
    ) {
        self.fontSize = fontSize
        self.fill = fill
        self.stroke = stroke
        self.evolved = evolved
        self.evolvedFill = evolvedFill
        self.strokeWidth = strokeWidth
        self.pipelineStrokeWidth = pipelineStrokeWidth
        self.radius = radius
        self.textColor = textColor
        self.textOffset = textOffset
        self.evolvedTextColor = evolvedTextColor
    }
}

public struct LinkTheme: Sendable {
    public var stroke: Color
    public var strokeWidth: CGFloat
    public var evolvedStroke: Color
    public var evolvedStrokeWidth: CGFloat
    public var flow: Color
    public var flowStrokeWidth: CGFloat
    public var flowText: Color
    public var contextFontSize: CGFloat

    public init(
        stroke: Color = .gray,
        strokeWidth: CGFloat = 1,
        evolvedStroke: Color = .red,
        evolvedStrokeWidth: CGFloat = 1,
        flow: Color = Color(hex: "#99c5ee").opacity(0.62),
        flowStrokeWidth: CGFloat = 10,
        flowText: Color = Color(hex: "#03a9f4"),
        contextFontSize: CGFloat = 11
    ) {
        self.stroke = stroke
        self.strokeWidth = strokeWidth
        self.evolvedStroke = evolvedStroke
        self.evolvedStrokeWidth = evolvedStrokeWidth
        self.flow = flow
        self.flowStrokeWidth = flowStrokeWidth
        self.flowText = flowText
        self.contextFontSize = contextFontSize
    }
}

public struct FluidLinkTheme: Sendable {
    public var stroke: Color
    public var strokeDashPattern: [CGFloat]
    public var strokeWidth: CGFloat

    public init(
        stroke: Color = .gray,
        strokeDashPattern: [CGFloat] = [2, 2],
        strokeWidth: CGFloat = 2
    ) {
        self.stroke = stroke
        self.strokeDashPattern = strokeDashPattern
        self.strokeWidth = strokeWidth
    }
}

public struct AnnotationTheme: Sendable {
    public var stroke: Color
    public var strokeWidth: CGFloat
    public var fill: Color
    public var text: Color
    public var boxStroke: Color
    public var boxStrokeWidth: CGFloat
    public var boxFill: Color
    public var boxTextColor: Color

    public init(
        stroke: Color = Color(hex: "#595959"),
        strokeWidth: CGFloat = 2,
        fill: Color = .white,
        text: Color = .black,
        boxStroke: Color = Color(hex: "#595959"),
        boxStrokeWidth: CGFloat = 1,
        boxFill: Color = .white,
        boxTextColor: Color = .black
    ) {
        self.stroke = stroke
        self.strokeWidth = strokeWidth
        self.fill = fill
        self.text = text
        self.boxStroke = boxStroke
        self.boxStrokeWidth = boxStrokeWidth
        self.boxFill = boxFill
        self.boxTextColor = boxTextColor
    }
}

public struct NoteTheme: Sendable {
    public var fontWeight: Font.Weight
    public var fontSize: CGFloat
    public var fill: Color
    public var textColor: Color
    public var evolvedTextColor: Color

    public init(
        fontWeight: Font.Weight = .bold,
        fontSize: CGFloat = 12,
        fill: Color = .black,
        textColor: Color = .black,
        evolvedTextColor: Color = .red
    ) {
        self.fontWeight = fontWeight
        self.fontSize = fontSize
        self.fill = fill
        self.textColor = textColor
        self.evolvedTextColor = evolvedTextColor
    }
}

// MARK: - Color Hex Extension

extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
