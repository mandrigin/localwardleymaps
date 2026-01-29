import SwiftUI
import WardleyModel
import WardleyTheme

/// Draws method indicators (buy, build, outsource) on components.
public struct MethodDrawing {
    public static func draw(
        context: inout GraphicsContext,
        methods: [MapMethod],
        elements: [MapElement],
        theme: MapTheme,
        calc: PositionCalculator
    ) {
        for method in methods {
            // Find the component this method refers to
            guard let element = elements.first(where: { $0.name == method.name }) else { continue }

            let pt = calc.point(visibility: element.visibility, maturity: element.maturity)
            let methodTheme = themeFor(method: method, in: theme)

            // Draw a small rectangle below the component
            let width: CGFloat = 30
            let height: CGFloat = 12
            let rect = CGRect(
                x: pt.x - width / 2,
                y: pt.y + theme.component.radius + 2,
                width: width,
                height: height
            )

            context.fill(Path(rect), with: .color(methodTheme.fill))
            context.stroke(
                Path(rect),
                with: .color(methodTheme.stroke),
                style: StrokeStyle(lineWidth: 1)
            )

            // Label
            let label: String
            if method.decorators.buy { label = "Buy" }
            else if method.decorators.build { label = "Build" }
            else if method.decorators.outsource { label = "Outsource" }
            else { label = "" }

            context.draw(
                Text(label)
                    .font(.system(size: 8))
                    .foregroundStyle(.white),
                at: CGPoint(x: rect.midX, y: rect.midY)
            )
        }
    }

    static func themeFor(method: MapMethod, in theme: MapTheme) -> MethodTheme {
        if method.decorators.buy { return theme.methods.buy }
        if method.decorators.build { return theme.methods.build }
        if method.decorators.outsource { return theme.methods.outsource }
        return theme.methods.build
    }
}
