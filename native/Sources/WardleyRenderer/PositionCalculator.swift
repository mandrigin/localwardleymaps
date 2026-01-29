import Foundation
import WardleyModel

/// Converts between map coordinates (0..1 visibility, 0..1 maturity) and pixel positions.
public struct PositionCalculator: Sendable {
    public let mapWidth: CGFloat
    public let mapHeight: CGFloat
    public let padding: CGFloat

    public init(mapWidth: CGFloat = 500, mapHeight: CGFloat = 600, padding: CGFloat = 20) {
        self.mapWidth = mapWidth
        self.mapHeight = mapHeight
        self.padding = padding
    }

    /// Convert maturity (0..1) to X pixel position
    public func maturityToX(_ maturity: Double) -> CGFloat {
        padding + CGFloat(maturity) * (mapWidth - 2 * padding)
    }

    /// Convert visibility (0..1, where 0=top, 1=bottom) to Y pixel position
    public func visibilityToY(_ visibility: Double) -> CGFloat {
        padding + (1.0 - CGFloat(visibility)) * (mapHeight - 2 * padding)
    }

    /// Convert X pixel position back to maturity (0..1)
    public func xToMaturity(_ x: CGFloat) -> Double {
        Double((x - padding) / (mapWidth - 2 * padding))
    }

    /// Convert Y pixel position back to visibility (0..1)
    public func yToVisibility(_ y: CGFloat) -> Double {
        1.0 - Double((y - padding) / (mapHeight - 2 * padding))
    }

    /// Get CGPoint for a component's position
    public func point(visibility: Double, maturity: Double) -> CGPoint {
        CGPoint(x: maturityToX(maturity), y: visibilityToY(visibility))
    }
}
