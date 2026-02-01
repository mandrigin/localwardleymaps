import Foundation
import Observation

/// A single freehand stroke drawn by the marker tool.
public struct MarkerStroke: Identifiable, Sendable {
    public let id = UUID()
    public var points: [CGPoint]
    public let createdAt: Date
    public let isPermanent: Bool

    public init(points: [CGPoint] = [], createdAt: Date = Date(), isPermanent: Bool = false) {
        self.points = points
        self.createdAt = createdAt
        self.isPermanent = isPermanent
    }
}

/// Manages marker/highlighter overlay state for presentation mode.
@MainActor
@Observable
public final class MarkerState {
    /// Whether marker drawing mode is active (drag draws strokes instead of moving components).
    public var isActive: Bool = false

    /// When true, new strokes are permanent until manually cleared.
    public var permanentMode: Bool = false

    /// Duration in seconds before temporary strokes fully fade out.
    public var fadeDuration: Double = 2.5

    /// All strokes (active drawing + completed).
    public var strokes: [MarkerStroke] = []

    /// The stroke currently being drawn (nil when not drawing).
    public var activeStroke: MarkerStroke? = nil

    /// True when there are strokes that need animation updates.
    public var needsAnimation: Bool {
        if activeStroke != nil { return true }
        let now = Date()
        return strokes.contains { stroke in
            if stroke.isPermanent { return false }
            return now.timeIntervalSince(stroke.createdAt) < fadeDuration
        }
    }

    public init() {}

    // MARK: - Drawing

    /// Begin a new stroke at the given point.
    public func beginStroke(at point: CGPoint) {
        activeStroke = MarkerStroke(
            points: [point],
            createdAt: Date(),
            isPermanent: permanentMode
        )
    }

    /// Add a point to the stroke currently being drawn.
    public func continueStroke(to point: CGPoint) {
        activeStroke?.points.append(point)
    }

    /// Finish the current stroke and add it to the completed strokes list.
    public func endStroke() {
        guard let stroke = activeStroke else { return }
        // Only add strokes with at least 2 points (otherwise it's just a tap)
        if stroke.points.count >= 2 {
            strokes.append(stroke)
        }
        activeStroke = nil
    }

    // MARK: - Cleanup

    /// Remove all strokes that have fully faded out.
    public func cleanupExpired(at date: Date) {
        strokes.removeAll { stroke in
            if stroke.isPermanent { return false }
            return date.timeIntervalSince(stroke.createdAt) >= fadeDuration
        }
    }

    /// Remove all permanent strokes (and any remaining temporary ones).
    public func clearAll() {
        strokes.removeAll()
        activeStroke = nil
    }

    /// Remove only permanent strokes.
    public func clearPermanent() {
        strokes.removeAll { $0.isPermanent }
    }

    /// Compute the opacity for a stroke based on elapsed time.
    public func opacity(for stroke: MarkerStroke, at date: Date) -> Double {
        if stroke.isPermanent { return 1.0 }
        let elapsed = date.timeIntervalSince(stroke.createdAt)
        if elapsed < 0 { return 1.0 }
        if elapsed >= fadeDuration { return 0.0 }
        // Smooth ease-out: stay fully visible for first 40%, then fade
        let holdRatio = 0.4
        let holdTime = fadeDuration * holdRatio
        if elapsed < holdTime { return 1.0 }
        let fadeElapsed = elapsed - holdTime
        let fadePortion = fadeDuration - holdTime
        let t = fadeElapsed / fadePortion
        // Ease-out cubic
        return 1.0 - (t * t * t)
    }
}
