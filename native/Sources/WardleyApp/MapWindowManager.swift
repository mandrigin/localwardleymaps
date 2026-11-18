import AppKit
import Observation
import SwiftUI
import UniformTypeIdentifiers

/// One controller, map state and file monitor per open document.
@MainActor
@Observable
public final class MapWindowManager {
    public let recentFiles = RecentFilesService()
    public private(set) var controllers: [MapWindowController] = []
    public private(set) var activeController: MapWindowController?

    public init() {}

    public func newWindow() {
        let controller = makeWindow()
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
    }

    public func openFiles(_ urls: [URL]) {
        for url in urls { openFile(url) }
    }

    public func openFile(_ url: URL) {
        guard url.isFileURL else { return }
        let url = url.standardizedFileURL.resolvingSymlinksInPath()
        if let existing = controllers.first(where: { $0.state.fileURL == url }) {
            existing.window?.deminiaturize(nil)
            existing.window?.makeKeyAndOrderFront(nil)
            return
        }

        do {
            // Validate before opening a window or replacing the welcome screen.
            _ = try String(contentsOf: url, encoding: .utf8)
        } catch {
            NSAlert(error: error).runModal()
            return
        }

        let controller = controllers.first(where: { $0.state.fileURL == nil }) ?? makeWindow()
        controller.state.openFile(url)
        controller.window?.title = url.lastPathComponent
        controller.window?.representedURL = url
        recentFiles.add(url)
        NSDocumentController.shared.noteNewRecentDocumentURL(url)
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
    }

    public func openFilePanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.wardleyMap, .plainText]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.begin { [weak self] response in
            guard response == .OK else { return }
            self?.openFiles(panel.urls)
        }
    }

    public func sendToActiveWindow(_ name: Notification.Name) {
        guard let state = activeController?.state, state.fileURL != nil else { return }
        NotificationCenter.default.post(name: name, object: state)
    }

    private func makeWindow() -> MapWindowController {
        let controller = MapWindowController(owner: self)
        controllers.append(controller)
        return controller
    }

    fileprivate func activated(_ controller: MapWindowController) {
        activeController = controller
    }

    fileprivate func closed(_ controller: MapWindowController) {
        controllers.removeAll { $0 === controller }
        if activeController === controller { activeController = nil }
    }
}

@MainActor
public final class MapWindowController: NSWindowController, NSWindowDelegate {
    public let state = MapEnvironmentState()
    private weak var manager: MapWindowManager?

    fileprivate init(owner: MapWindowManager) {
        self.manager = owner
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1100, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        super.init(window: window)
        window.title = "Wardley Maps"
        window.minSize = NSSize(width: 600, height: 440)
        window.isReleasedWhenClosed = false
        window.tabbingMode = .disallowed
        window.delegate = self
        window.center()
        if let previous = owner.controllers.last?.window {
            window.cascadeTopLeft(from: NSPoint(x: previous.frame.minX + 24, y: previous.frame.maxY - 24))
        }
        window.contentView = NSHostingView(rootView: MapWindowView(
            state: state,
            recentFiles: owner.recentFiles,
            onOpenFiles: { [weak owner] in owner?.openFiles($0) },
            onStop: { [weak self] in self?.stopPreview() }
        ))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public func windowDidBecomeKey(_ notification: Notification) {
        manager?.activated(self)
    }

    public func windowShouldClose(_ sender: NSWindow) -> Bool { confirmClose() }

    public func windowWillClose(_ notification: Notification) {
        state.stopMonitoring()
        manager?.closed(self)
        window?.contentView = nil
    }

    public func confirmClose() -> Bool {
        guard state.hasUnsavedChanges else { return true }
        if state.autoSaveEnabled && state.saveToDisk() { return true }
        let alert = NSAlert()
        alert.messageText = "Save changes to \(state.fileURL?.lastPathComponent ?? "this map")?"
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Discard Changes")
        switch alert.runModal() {
        case .alertFirstButtonReturn: return state.saveToDisk()
        case .alertThirdButtonReturn: return true
        default: return false
        }
    }

    private func stopPreview() {
        guard confirmClose() else { return }
        state.stopMonitoring()
        state.fileURL = nil
        state.hasUnsavedChanges = false
        state.marker.clearAll()
        window?.title = "Wardley Maps"
        window?.representedURL = nil
    }
}

private struct MapWindowView: View {
    @Bindable var state: MapEnvironmentState
    let recentFiles: RecentFilesService
    let onOpenFiles: ([URL]) -> Void
    let onStop: () -> Void

    var body: some View {
        Group {
            if state.fileURL != nil {
                ContentView(state: state, recentFiles: recentFiles, onStop: onStop, onOpenFiles: onOpenFiles)
            } else {
                WelcomeView(state: state, recentFiles: recentFiles, onFilesOpened: onOpenFiles)
            }
        }
    }
}
