import SwiftUI
import WardleyEditor
import WardleyModel
import WardleyRenderer
import WardleyTheme

/// Main content view with split editor and canvas.
public struct ContentView: View {
    @Bindable var state: MapEnvironmentState

    public init(state: MapEnvironmentState) {
        self.state = state
    }

    public var body: some View {
        HSplitView {
            // Left: Editor
            VStack(spacing: 0) {
                editorHeader
                WardleyEditorView(
                    text: $state.mapText,
                    highlightedLine: state.highlightedLine,
                    errorLines: state.errorLines,
                    onTextChange: { _ in
                        state.isDirty = true
                    },
                    scrollToLine: state.scrollToLine
                )
            }
            .frame(minWidth: 250, idealWidth: 350)

            // Right: Canvas
            VStack(spacing: 0) {
                canvasHeader
                MapCanvasView(
                    map: state.parsedMap,
                    theme: state.currentTheme,
                    highlightedLine: state.highlightedLine,
                    onComponentTap: { element in
                        state.highlightComponent(element)
                    },
                    onComponentDrag: { element, newPosition in
                        let calc = PositionCalculator()
                        let newVis = calc.yToVisibility(newPosition.y)
                        let newMat = calc.xToMaturity(newPosition.x)
                        if let updated = PositionUpdater.updatePosition(
                            in: state.mapText,
                            componentName: element.name,
                            newVisibility: newVis,
                            newMaturity: newMat
                        ) {
                            state.mapText = updated
                        }
                    }
                )
                .background(state.currentTheme.containerBackground)
            }
            .frame(minWidth: 300, idealWidth: 500)
        }
    }

    private var editorHeader: some View {
        HStack {
            Text("Editor")
                .font(.headline)
            Spacer()
            if !state.parsedMap.errors.isEmpty {
                Label("\(state.parsedMap.errors.count) error(s)", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.bar)
    }

    private var canvasHeader: some View {
        HStack {
            Text(state.parsedMap.title)
                .font(.headline)
            Spacer()
            Picker("Theme", selection: $state.currentThemeName) {
                Text("Plain").tag("plain")
                Text("Wardley").tag("wardley")
                Text("Colour").tag("colour")
                Text("Handwritten").tag("handwritten")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 300)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.bar)
    }
}
