import SwiftUI
import WardleyModel
import WardleyTheme

/// Draws pipelines as horizontal boxes with embedded components.
public struct PipelineDrawing {
    public static func draw(
        context: inout GraphicsContext,
        pipelines: [Pipeline],
        elements: [MapElement],
        theme: MapTheme,
        calc: PositionCalculator
    ) {
        for pipeline in pipelines {
            guard !pipeline.hidden else { continue }

            // Find the matching element for this pipeline (by name) to get visibility
            let matchingElement = elements.first { $0.name == pipeline.name }
            let visibility = matchingElement?.visibility ?? pipeline.visibility

            let y = calc.visibilityToY(visibility)
            let x1 = calc.maturityToX(pipeline.maturity1) - 10
            let x2 = calc.maturityToX(pipeline.maturity2) + 10
            let pipeHeight: CGFloat = 16

            let rect = CGRect(x: x1, y: y - pipeHeight / 2, width: x2 - x1, height: pipeHeight)

            // Draw pipeline box
            context.stroke(
                Path(roundedRect: rect, cornerRadius: 3),
                with: .color(theme.component.stroke),
                style: StrokeStyle(lineWidth: theme.component.pipelineStrokeWidth)
            )

            // Pipeline arrow heads on left and right
            let arrowH = theme.pipelineArrowHeight
            let arrowW = theme.pipelineArrowWidth

            // Left arrow (pointing right)
            var leftArrow = Path()
            leftArrow.move(to: CGPoint(x: x1 - arrowW, y: y - arrowH))
            leftArrow.addLine(to: CGPoint(x: x1, y: y))
            leftArrow.addLine(to: CGPoint(x: x1 - arrowW, y: y + arrowH))
            context.stroke(leftArrow, with: .color(theme.pipelineArrowStroke),
                           style: StrokeStyle(lineWidth: 1))

            // Right arrow (pointing right)
            var rightArrow = Path()
            rightArrow.move(to: CGPoint(x: x2, y: y - arrowH))
            rightArrow.addLine(to: CGPoint(x: x2 + arrowW, y: y))
            rightArrow.addLine(to: CGPoint(x: x2, y: y + arrowH))
            context.stroke(rightArrow, with: .color(theme.pipelineArrowStroke),
                           style: StrokeStyle(lineWidth: 1))

            // Draw pipeline child components
            for child in pipeline.components {
                let cx = calc.maturityToX(child.maturity)
                let r = theme.component.radius

                let circleRect = CGRect(x: cx - r, y: y - r, width: r * 2, height: r * 2)
                context.fill(Path(ellipseIn: circleRect), with: .color(theme.component.fill))
                context.stroke(
                    Path(ellipseIn: circleRect),
                    with: .color(theme.component.stroke),
                    style: StrokeStyle(lineWidth: theme.component.strokeWidth)
                )

                let labelPt = CGPoint(x: cx + child.label.x, y: y + child.label.y)
                context.draw(
                    Text(child.name)
                        .font(.system(size: theme.component.fontSize))
                        .foregroundStyle(theme.component.textColor),
                    at: labelPt,
                    anchor: .topLeading
                )
            }
        }
    }
}
