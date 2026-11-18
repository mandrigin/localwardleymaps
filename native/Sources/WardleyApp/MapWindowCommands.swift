import SwiftUI

public struct MapWindowCommands: Commands {
    let windows: MapWindowManager

    public init(windows: MapWindowManager) { self.windows = windows }

    public var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Window") { windows.newWindow() }
                .keyboardShortcut("n")
            Button("Open...") { windows.openFilePanel() }
                .keyboardShortcut("o")
            Menu("Open Recent") {
                ForEach(windows.recentFiles.recentFiles, id: \.self) { url in
                    Button(url.lastPathComponent) { windows.openFile(url) }
                }
                if !windows.recentFiles.recentFiles.isEmpty {
                    Divider()
                    Button("Clear Recents") { windows.recentFiles.clear() }
                }
            }
            Divider()
            Button("Close Window") { windows.activeController?.window?.performClose(nil) }
                .keyboardShortcut("w")
                .disabled(windows.activeController == nil)
        }
        CommandGroup(replacing: .saveItem) {
            Button("Save") { windows.activeController?.state.saveToDisk() }
                .keyboardShortcut("s")
                .disabled(windows.activeController?.state.hasUnsavedChanges != true)
            Button("Export as PNG...") { windows.sendToActiveWindow(.exportPNG) }
                .keyboardShortcut("e")
                .disabled(windows.activeController?.state.fileURL == nil)
            Button("Copy Image to Pasteboard") { windows.sendToActiveWindow(.copyImageToPasteboard) }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(windows.activeController?.state.fileURL == nil)
        }
        CommandGroup(after: .toolbar) {
            Button("Toggle Marker") { windows.sendToActiveWindow(.toggleMarker) }
                .keyboardShortcut("m", modifiers: [.command, .shift])
                .disabled(windows.activeController?.state.fileURL == nil)
            Button("Clear All Markers") { windows.sendToActiveWindow(.clearMarkers) }
                .keyboardShortcut(.delete, modifiers: [.command, .shift])
                .disabled(windows.activeController?.state.fileURL == nil)
        }
    }
}
