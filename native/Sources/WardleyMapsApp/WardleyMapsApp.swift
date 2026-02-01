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
                Button("Save") {
                    state.saveToDisk()
                }
                .keyboardShortcut("s")
                .disabled(!state.hasUnsavedChanges)

                Button("Export as PNG...") {
                    NotificationCenter.default.post(name: .exportPNG, object: nil)
                }
                .keyboardShortcut("e")

                Button("Copy Image to Pasteboard") {
                    NotificationCenter.default.post(name: .copyImageToPasteboard, object: nil)
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            }
            CommandGroup(after: .toolbar) {
                Button("Toggle Marker") {
                    NotificationCenter.default.post(name: .toggleMarker, object: nil)
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])

                Button("Clear All Markers") {
                    NotificationCenter.default.post(name: .clearMarkers, object: nil)
                }
                .keyboardShortcut(.delete, modifiers: [.command, .shift])
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

