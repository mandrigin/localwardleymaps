import Foundation

// MARK: - Core Map Structure

public struct WardleyMap: Sendable, Equatable {
    public var title: String
    public var elements: [MapElement]
    public var links: [MapLink]
    public var anchors: [MapAnchor]
    public var evolved: [EvolvedElement]
    public var pipelines: [Pipeline]
    public var annotations: [MapAnnotation]
    public var notes: [MapNote]
    public var evolution: [EvolutionLabel]
    public var submaps: [MapElement]
    public var urls: [MapURL]
    public var attitudes: [Attitude]
    public var accelerators: [Accelerator]
    public var methods: [MapMethod]
    public var presentation: MapPresentation
    public var errors: [ParseError]

    public init(
        title: String = "Untitled Map",
        elements: [MapElement] = [],
        links: [MapLink] = [],
        anchors: [MapAnchor] = [],
        evolved: [EvolvedElement] = [],
        pipelines: [Pipeline] = [],
        annotations: [MapAnnotation] = [],
        notes: [MapNote] = [],
        evolution: [EvolutionLabel] = EvolutionLabel.defaults,
        submaps: [MapElement] = [],
        urls: [MapURL] = [],
        attitudes: [Attitude] = [],
        accelerators: [Accelerator] = [],
        methods: [MapMethod] = [],
        presentation: MapPresentation = .init(),
        errors: [ParseError] = []
    ) {
        self.title = title
        self.elements = elements
        self.links = links
        self.anchors = anchors
        self.evolved = evolved
        self.pipelines = pipelines
        self.annotations = annotations
        self.notes = notes
        self.evolution = evolution
        self.submaps = submaps
        self.urls = urls
        self.attitudes = attitudes
        self.accelerators = accelerators
        self.methods = methods
        self.presentation = presentation
        self.errors = errors
    }
}

// MARK: - Map Element (Component)

public struct MapElement: Sendable, Equatable, Identifiable {
    public var id: String
    public var line: Int
    public var name: String
    public var visibility: Double
    public var maturity: Double
    public var inertia: Bool
    public var evolving: Bool
    public var evolved: Bool
    public var pseudoComponent: Bool
    public var offsetY: Double
    public var label: LabelOffset
    public var decorators: ComponentDecorators
    public var increaseLabelSpacing: Int
    public var pipeline: Bool
    public var evolveMaturity: Double?
    public var url: String?

    public init(
        id: String = "",
        line: Int = 0,
        name: String = "",
        visibility: Double = 0.9,
        maturity: Double = 0.1,
        inertia: Bool = false,
        evolving: Bool = false,
        evolved: Bool = false,
        pseudoComponent: Bool = false,
        offsetY: Double = 0,
        label: LabelOffset = .default,
        decorators: ComponentDecorators = .init(),
        increaseLabelSpacing: Int = 0,
        pipeline: Bool = false,
        evolveMaturity: Double? = nil,
        url: String? = nil
    ) {
        self.id = id
        self.line = line
        self.name = name
        self.visibility = visibility
        self.maturity = maturity
        self.inertia = inertia
        self.evolving = evolving
        self.evolved = evolved
        self.pseudoComponent = pseudoComponent
        self.offsetY = offsetY
        self.label = label
        self.decorators = decorators
        self.increaseLabelSpacing = increaseLabelSpacing
        self.pipeline = pipeline
        self.evolveMaturity = evolveMaturity
        self.url = url
    }
}

// MARK: - Map Link

public struct MapLink: Sendable, Equatable {
    public var start: String
    public var end: String
    public var flow: Bool
    public var future: Bool
    public var past: Bool
    public var context: String?
    public var flowValue: String?

    public init(
        start: String = "",
        end: String = "",
        flow: Bool = false,
        future: Bool = false,
        past: Bool = false,
        context: String? = nil,
        flowValue: String? = nil
    ) {
        self.start = start
        self.end = end
        self.flow = flow
        self.future = future
        self.past = past
        self.context = context
        self.flowValue = flowValue
    }
}

// MARK: - Map Anchor

public struct MapAnchor: Sendable, Equatable, Identifiable {
    public var id: String
    public var line: Int
    public var name: String
    public var visibility: Double
    public var maturity: Double
    public var inertia: Bool
    public var evolved: Bool
    public var evolving: Bool
    public var pseudoComponent: Bool
    public var offsetY: Double
    public var label: LabelOffset
    public var decorators: ComponentDecorators
    public var increaseLabelSpacing: Int

    public init(
        id: String = "",
        line: Int = 0,
        name: String = "",
        visibility: Double = 0.9,
        maturity: Double = 0.1,
        inertia: Bool = false,
        evolved: Bool = false,
        evolving: Bool = false,
        pseudoComponent: Bool = false,
        offsetY: Double = 0,
        label: LabelOffset = .default,
        decorators: ComponentDecorators = .init(),
        increaseLabelSpacing: Int = 0
    ) {
        self.id = id
        self.line = line
        self.name = name
        self.visibility = visibility
        self.maturity = maturity
        self.inertia = inertia
        self.evolved = evolved
        self.evolving = evolving
        self.pseudoComponent = pseudoComponent
        self.offsetY = offsetY
        self.label = label
        self.decorators = decorators
        self.increaseLabelSpacing = increaseLabelSpacing
    }
}

// MARK: - Evolved Element

public struct EvolvedElement: Sendable, Equatable {
    public var id: String
    public var line: Int
    public var name: String
    public var maturity: Double
    public var label: LabelOffset
    public var override: String
    public var decorators: ComponentDecorators
    public var increaseLabelSpacing: Int

    public init(
        id: String = "",
        line: Int = 0,
        name: String = "",
        maturity: Double = 0.85,
        label: LabelOffset = .default,
        override: String = "",
        decorators: ComponentDecorators = .init(),
        increaseLabelSpacing: Int = 0
    ) {
        self.id = id
        self.line = line
        self.name = name
        self.maturity = maturity
        self.label = label
        self.override = override
        self.decorators = decorators
        self.increaseLabelSpacing = increaseLabelSpacing
    }
}

// MARK: - Pipeline

public struct Pipeline: Sendable, Equatable {
    public var id: String
    public var line: Int
    public var name: String
    public var visibility: Double
    public var inertia: Bool
    public var hidden: Bool
    public var maturity1: Double
    public var maturity2: Double
    public var components: [PipelineComponent]
    public var increaseLabelSpacing: Int

    public init(
        id: String = "",
        line: Int = 0,
        name: String = "",
        visibility: Double = 0,
        inertia: Bool = false,
        hidden: Bool = true,
        maturity1: Double = 0.2,
        maturity2: Double = 0.8,
        components: [PipelineComponent] = [],
        increaseLabelSpacing: Int = 0
    ) {
        self.id = id
        self.line = line
        self.name = name
        self.visibility = visibility
        self.inertia = inertia
        self.hidden = hidden
        self.maturity1 = maturity1
        self.maturity2 = maturity2
        self.components = components
        self.increaseLabelSpacing = increaseLabelSpacing
    }
}

public struct PipelineComponent: Sendable, Equatable {
    public var id: String
    public var line: Int
    public var name: String
    public var maturity: Double
    public var label: LabelOffset
    public var increaseLabelSpacing: Int

    public init(
        id: String = "",
        line: Int = 0,
        name: String = "",
        maturity: Double = 0.2,
        label: LabelOffset = .default,
        increaseLabelSpacing: Int = 0
    ) {
        self.id = id
        self.line = line
        self.name = name
        self.maturity = maturity
        self.label = label
        self.increaseLabelSpacing = increaseLabelSpacing
    }
}

// MARK: - Annotation

public struct MapAnnotation: Sendable, Equatable {
    public var id: String
    public var line: Int
    public var number: Int
    public var occurances: [AnnotationOccurance]
    public var text: String
    public var increaseLabelSpacing: Int

    public init(
        id: String = "",
        line: Int = 0,
        number: Int = 0,
        occurances: [AnnotationOccurance] = [],
        text: String = "",
        increaseLabelSpacing: Int = 0
    ) {
        self.id = id
        self.line = line
        self.number = number
        self.occurances = occurances
        self.text = text
        self.increaseLabelSpacing = increaseLabelSpacing
    }
}

public struct AnnotationOccurance: Sendable, Equatable {
    public var visibility: Double
    public var maturity: Double

    public init(visibility: Double = 0.9, maturity: Double = 0.1) {
        self.visibility = visibility
        self.maturity = maturity
    }
}

// MARK: - Note

public struct MapNote: Sendable, Equatable, Identifiable {
    public var id: String
    public var line: Int
    public var text: String
    public var visibility: Double
    public var maturity: Double

    public init(
        id: String = "",
        line: Int = 0,
        text: String = "",
        visibility: Double = 0.9,
        maturity: Double = 0.1
    ) {
        self.id = id
        self.line = line
        self.text = text
        self.visibility = visibility
        self.maturity = maturity
    }
}

// MARK: - Evolution Label

public struct EvolutionLabel: Sendable, Equatable {
    public var line1: String
    public var line2: String

    public init(line1: String, line2: String = "") {
        self.line1 = line1
        self.line2 = line2
    }

    public static let defaults: [EvolutionLabel] = [
        EvolutionLabel(line1: "Genesis"),
        EvolutionLabel(line1: "Custom-Built"),
        EvolutionLabel(line1: "Product", line2: "(+rental)"),
        EvolutionLabel(line1: "Commodity", line2: "(+utility)"),
    ]
}

// MARK: - URL

public struct MapURL: Sendable, Equatable {
    public var id: String
    public var line: Int
    public var name: String
    public var url: String

    public init(id: String = "", line: Int = 0, name: String = "", url: String = "") {
        self.id = id
        self.line = line
        self.name = name
        self.url = url
    }
}

// MARK: - Attitude

public struct Attitude: Sendable, Equatable {
    public var id: String
    public var line: Int
    public var attitude: String
    public var visibility: Double
    public var maturity: Double
    public var visibility2: Double
    public var maturity2: Double
    public var width: String?
    public var height: String?

    public init(
        id: String = "",
        line: Int = 0,
        attitude: String = "",
        visibility: Double = 0.9,
        maturity: Double = 0.1,
        visibility2: Double = 0.8,
        maturity2: Double = 0.2,
        width: String? = nil,
        height: String? = nil
    ) {
        self.id = id
        self.line = line
        self.attitude = attitude
        self.visibility = visibility
        self.maturity = maturity
        self.visibility2 = visibility2
        self.maturity2 = maturity2
        self.width = width
        self.height = height
    }
}

// MARK: - Accelerator

public struct Accelerator: Sendable, Equatable, Identifiable {
    public var id: String
    public var line: Int
    public var name: String
    public var maturity: Double
    public var visibility: Double
    public var offsetY: Double
    public var evolved: Bool
    public var deaccelerator: Bool

    public init(
        id: String = "",
        line: Int = 0,
        name: String = "",
        maturity: Double = 0.1,
        visibility: Double = 0.9,
        offsetY: Double = 0,
        evolved: Bool = false,
        deaccelerator: Bool = false
    ) {
        self.id = id
        self.line = line
        self.name = name
        self.maturity = maturity
        self.visibility = visibility
        self.offsetY = offsetY
        self.evolved = evolved
        self.deaccelerator = deaccelerator
    }
}

// MARK: - Method

public struct MapMethod: Sendable, Equatable {
    public var id: String
    public var line: Int
    public var name: String
    public var decorators: ComponentDecorators
    public var increaseLabelSpacing: Int

    public init(
        id: String = "",
        line: Int = 0,
        name: String = "",
        decorators: ComponentDecorators = .init(),
        increaseLabelSpacing: Int = 0
    ) {
        self.id = id
        self.line = line
        self.name = name
        self.decorators = decorators
        self.increaseLabelSpacing = increaseLabelSpacing
    }
}

// MARK: - Presentation

public struct MapPresentation: Sendable, Equatable {
    public var style: String
    public var annotations: AnnotationPosition
    public var size: MapSize

    public init(
        style: String = "plain",
        annotations: AnnotationPosition = .init(),
        size: MapSize = .init()
    ) {
        self.style = style
        self.annotations = annotations
        self.size = size
    }
}

public struct AnnotationPosition: Sendable, Equatable {
    public var visibility: Double
    public var maturity: Double

    public init(visibility: Double = 0.9, maturity: Double = 0.1) {
        self.visibility = visibility
        self.maturity = maturity
    }
}

public struct MapSize: Sendable, Equatable {
    public var width: Double
    public var height: Double

    public init(width: Double = 0, height: Double = 0) {
        self.width = width
        self.height = height
    }
}

// MARK: - Component Decorators

public struct ComponentDecorators: Sendable, Equatable {
    public var ecosystem: Bool
    public var market: Bool
    public var buy: Bool
    public var build: Bool
    public var outsource: Bool

    public init(
        ecosystem: Bool = false,
        market: Bool = false,
        buy: Bool = false,
        build: Bool = false,
        outsource: Bool = false
    ) {
        self.ecosystem = ecosystem
        self.market = market
        self.buy = buy
        self.build = build
        self.outsource = outsource
    }
}

// MARK: - Label Offset

public struct LabelOffset: Sendable, Equatable {
    public var x: Double
    public var y: Double

    public init(x: Double = 5, y: Double = -10) {
        self.x = x
        self.y = y
    }

    public static let `default` = LabelOffset(x: 5, y: -10)
    public static let increased = LabelOffset(x: 5, y: -20)
}

// MARK: - Parse Error

public struct ParseError: Sendable, Equatable {
    public var line: Int
    public var name: String

    public init(line: Int, name: String = "") {
        self.line = line
        self.name = name
    }
}

// MARK: - Constants

public enum MapDefaults {
    public static let canvasWidth: Double = 500
    public static let canvasHeight: Double = 600
}
