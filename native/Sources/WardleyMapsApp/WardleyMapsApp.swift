import SwiftUI
import AppKit
import UniformTypeIdentifiers
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

                Menu("Open Recent") {
                    ForEach(recentFiles.recentFiles, id: \.self) { url in
                        Button(url.lastPathComponent) {
                            openAndMonitor(url)
                        }
                    }

                    if !recentFiles.recentFiles.isEmpty {
                        Divider()
                        Button("Clear Recents") {
                            recentFiles.clear()
                        }
                    }
                }
            }
            CommandGroup(after: .saveItem) {
                Button("Export as PNG...") {
                    NotificationCenter.default.post(name: .exportPNG, object: nil)
                }
                .keyboardShortcut("e")
            }
        }
    }

    private func openAndMonitor(_ url: URL) {
        recentFiles.add(url)
        NSDocumentController.shared.noteNewRecentDocumentURL(url)
        state.openFile(url)
        isPreviewing = true
    }

    private func openFilePanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.wardleyMap, .plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            openAndMonitor(url)
        }
    }

    private func handleCLIArguments() {
        let args = CommandLine.arguments
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

extension Notification.Name {
    static let exportPNG = Notification.Name("exportPNG")
}
