import SwiftUI
import WardleyModel
import WardleyTheme

/// Draws notes and accelerators on the map.
public struct NoteDrawing {
    public static func drawNotes(
        context: inout GraphicsContext,
        notes: [MapNote],
        theme: MapTheme,
        calc: PositionCalculator
    ) {
        for note in notes {
            let pt = calc.point(visibility: note.visibility, maturity: note.maturity)
            // Strip leading "+" if present (convention from DSL)
            let text = note.text.hasPrefix("+") ? String(note.text.dropFirst()) : note.text
            context.draw(
                Text(text)
                    .font(.system(size: theme.note.fontSize, weight: theme.note.fontWeight))
                    .foregroundStyle(theme.note.textColor),
                at: pt,
                anchor: .topLeading
            )
        }
    }

    public static func drawAccelerators(
        context: inout GraphicsContext,
        accelerators: [Accelerator],
        theme: MapTheme,
        calc: PositionCalculator
    ) {
        for acc in accelerators {
            let pt = calc.point(visibility: acc.visibility, maturity: acc.maturity)
            let symbol = acc.deaccelerator ? "<<" : ">>"

            context.draw(
                Text(symbol)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(theme.component.textColor),
                at: CGPoint(x: pt.x, y: pt.y - 8)
            )
            context.draw(
                Text(acc.name)
                    .font(.system(size: 11))
                    .foregroundStyle(theme.component.textColor),
                at: CGPoint(x: pt.x, y: pt.y + 8),
                anchor: .top
            )
        }
    }
}
