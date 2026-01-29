import SwiftUI
import WardleyApp
import WardleyModel
import WardleyTheme

@main
struct WardleyMapsNativeApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: WardleyMapDocument()) { file in
            DocumentContentView(document: file.$document)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Map") {
                    NSDocumentController.shared.newDocument(nil)
                }
                .keyboardShortcut("n")
            }
            CommandGroup(after: .saveItem) {
                Button("Export as PNG...") {
                    NotificationCenter.default.post(name: .exportPNG, object: nil)
                }
                .keyboardShortcut("e")
            }
            CommandMenu("Theme") {
                ForEach(["plain", "wardley", "colour", "handwritten", "dark"], id: \.self) { name in
                    Button(name.capitalized) {
                        NotificationCenter.default.post(
                            name: .changeTheme,
                            object: name
                        )
                    }
                }
            }
        }
    }
}

/// Wrapper view that bridges DocumentGroup's Binding<WardleyMapDocument> to MapEnvironmentState
struct DocumentContentView: View {
    @Binding var document: WardleyMapDocument
    @State private var state: MapEnvironmentState

    init(document: Binding<WardleyMapDocument>) {
        self._document = document
        self._state = State(initialValue: MapEnvironmentState(text: document.wrappedValue.text))
    }

    var body: some View {
        ContentView(state: state)
            .onChange(of: state.mapText) { _, newValue in
                document.text = newValue
            }
            .onReceive(NotificationCenter.default.publisher(for: .exportPNG)) { _ in
                exportPNG()
            }
            .onReceive(NotificationCenter.default.publisher(for: .changeTheme)) { notification in
                if let name = notification.object as? String {
                    state.currentThemeName = name
                }
            }
            .frame(minWidth: 800, minHeight: 600)
    }

    private func exportPNG() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "\(state.parsedMap.title).png"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            Task { @MainActor in
                _ = ExportService.savePNG(
                    map: state.parsedMap,
                    theme: state.currentTheme,
                    to: url
                )
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let exportPNG = Notification.Name("exportPNG")
    static let changeTheme = Notification.Name("changeTheme")
}
