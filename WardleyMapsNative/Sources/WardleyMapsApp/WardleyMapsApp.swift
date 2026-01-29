import SwiftUI
import WardleyApp
import WardleyModel
import WardleyTheme

@main
struct WardleyMapsNativeApp: App {
    @State private var state = MapEnvironmentState()
    @State private var recentFiles = RecentFilesService()
    @State private var isPreviewing = false

    var body: some Scene {
        WindowGroup {
            Group {
                if isPreviewing {
                    ContentView(
                        state: state,
                        recentFiles: recentFiles,
                        onStop: {
                            state.stopMonitoring()
                            isPreviewing = false
                        }
                    )
                } else {
                    WelcomeView(
                        state: state,
                        recentFiles: recentFiles,
                        onFileOpened: { url in
                            openAndMonitor(url)
                        }
                    )
                }
            }
            .onAppear {
                handleCLIArguments()
            }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open...") {
                    openFilePanel()
                }
                .keyboardShortcut("o")
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
                        state.currentThemeName = name
                    }
                }
            }
        }
    }

    private func openAndMonitor(_ url: URL) {
        recentFiles.add(url)
        state.openFile(url)
        isPreviewing = true
    }

    private func openFilePanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            openAndMonitor(url)
        }
    }

    private func handleCLIArguments() {
        let args = CommandLine.arguments
        // Skip first arg (executable path). Look for a file path argument.
        for arg in args.dropFirst() {
            if arg.hasPrefix("-") { continue }
            let url = URL(fileURLWithPath: arg)
            if FileManager.default.fileExists(atPath: url.path) {
                openAndMonitor(url)
                return
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let exportPNG = Notification.Name("exportPNG")
    static let changeTheme = Notification.Name("changeTheme")
}
