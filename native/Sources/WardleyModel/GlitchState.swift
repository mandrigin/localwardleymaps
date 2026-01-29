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

// MARK: - Link Glitch Types

/// Identifies a link by its start/end component names.
public struct LinkID: Hashable, Sendable, Equatable {
    public var start: String
    public var end: String

    public init(start: String, end: String) {
        self.start = start
        self.end = end
    }
}

/// Tracks a single link's glitch animation triggered by a file change.
public struct LinkGlitchEntry: Sendable, Equatable {
    public var linkID: LinkID
    public var startTime: Date
    public var isNew: Bool              // true = appearing, false = disappearing
    public var ghostLink: MapLink?      // non-nil for removed links (preserved for rendering)

    public init(linkID: LinkID, startTime: Date, isNew: Bool, ghostLink: MapLink? = nil) {
        self.linkID = linkID
        self.startTime = startTime
        self.isNew = isNew
        self.ghostLink = ghostLink
    }

    public static let duration: TimeInterval = 0.8
}

/// Per-frame glitch state passed to the renderer for a single link.
public struct LinkGlitchInfo: Sendable {
    public var progress: Double  // 0..1
    public var isNew: Bool

    public init(progress: Double, isNew: Bool) {
        self.progress = progress
        self.isNew = isNew
    }
}
