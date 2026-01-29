import Foundation

/// Tracks a single element's glitch animation triggered by a file change.
public struct GlitchEntry: Sendable, Equatable {
    public var elementName: String
    public var startTime: Date
    public var isNew: Bool  // true = new element (green signal), false = changed (alert red)

    public init(elementName: String, startTime: Date, isNew: Bool) {
        self.elementName = elementName
        self.startTime = startTime
        self.isNew = isNew
    }

    public static let duration: TimeInterval = 0.8
}

/// Per-frame glitch state passed to the renderer for a single element.
public struct GlitchInfo: Sendable {
    public var progress: Double   // 0..1 over 0.8s
    public var isNew: Bool        // green vs red

    public init(progress: Double, isNew: Bool) {
        self.progress = progress
        self.isNew = isNew
    }
}
