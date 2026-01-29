import SwiftUI
import WardleyModel
import WardleyTheme

/// Draws attitude zones (pioneers, settlers, town planners).
public struct AttitudeDrawing {
    public static func draw(
        context: inout GraphicsContext,
        attitudes: [Attitude],
        theme: MapTheme,
        calc: PositionCalculator
    ) {
        for attitude in attitudes {
            let attitudeTheme = themeFor(attitude: attitude.attitude, in: theme)

            let x1 = calc.maturityToX(attitude.maturity)
            let y1 = calc.visibilityToY(attitude.visibility)
            let x2 = calc.maturityToX(attitude.maturity2)
            let y2 = calc.visibilityToY(attitude.visibility2)

            let rect = CGRect(
                x: min(x1, x2),
                y: min(y1, y2),
                width: abs(x2 - x1),
                height: abs(y2 - y1)
            )

            // Fill
            context.fill(
                Path(rect),
                with: .color(attitudeTheme.fill.opacity(attitudeTheme.fillOpacity))
            )

            // Stroke
            context.stroke(
                Path(rect),
                with: .color(attitudeTheme.stroke.opacity(attitudeTheme.strokeOpacity)),
                style: StrokeStyle(lineWidth: theme.attitudes.strokeWidth)
            )

            // Label
            context.draw(
                Text(attitude.attitude.capitalized)
                    .font(.system(size: theme.attitudes.fontSize))
                    .foregroundStyle(attitudeTheme.stroke),
                at: CGPoint(x: rect.midX, y: rect.minY - 12)
            )
        }
    }

    static func themeFor(attitude: String, in theme: MapTheme) -> AttitudeTypeTheme {
        switch attitude {
        case "pioneers": return theme.attitudes.pioneers
        case "settlers": return theme.attitudes.settlers
        case "townplanners": return theme.attitudes.townplanners
        default: return theme.attitudes.pioneers
        }
    }
}
