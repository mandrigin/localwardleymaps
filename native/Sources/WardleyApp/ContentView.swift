import SwiftUI
import WardleyModel
import WardleyRenderer
import WardleyTheme
import UniformTypeIdentifiers

public extension Notification.Name {
    static let exportPNG = Notification.Name("exportPNG")
    static let copyImageToPasteboard = Notification.Name("copyImageToPasteboard")
}

/// Full-window preview of a monitored Wardley Map file.
public struct ContentView: View {
    @Bindable var state: MapEnvironmentState
    var recentFiles: RecentFilesService
    var onStop: () -> Void

    public init(
        state: MapEnvironmentState,
        recentFiles: RecentFilesService,
        onStop: @escaping () -> Void
    ) {
        self.state = state
        self.recentFiles = recentFiles
        self.onStop = onStop
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Full canvas wrapped in TimelineView for glitch animation
            TimelineView(.animation(minimumInterval: 1.0/60, paused: !state.isGlitching)) { timeline in
                let glitchProgress = computeGlitchProgress(at: timeline.date)
                let linkGlitch = computeLinkGlitchProgress(at: timeline.date)
                MapCanvasView(
                    map: state.parsedMap,
                    theme: state.currentTheme,
                    glitchProgress: glitchProgress,
                    linkGlitchProgress: linkGlitch.progress,
                    ghostLinks: linkGlitch.ghosts,
                    dragOverride: state.dragOverride,
                    dragPhase: state.dragOverride != nil ? timeline.date.timeIntervalSinceReferenceDate : 0,
                    onDragChanged: { elementName, canvasPosition in
                        state.dragOverride = (elementName: elementName, position: canvasPosition)
                    },
                    onDragEnded: { elementName, canvasPosition, canvasSize in
                        let calc = PositionCalculator(mapWidth: canvasSize.width, mapHeight: canvasSize.height)
                        let newVis = calc.yToVisibility(canvasPosition.y)
                        let newMat = calc.xToMaturity(canvasPosition.x)

                        if let updated = PositionUpdater.updatePosition(
                            in: state.mapText,
                            componentName: elementName,
                            newVisibility: newVis,
                            newMaturity: newMat
                        ) {
                            state.mapText = updated
                            state.hasUnsavedChanges = true
                        }
                        state.dragOverride = nil
                    }
                )
            }
            .background(state.currentTheme.containerBackground)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Status bar
            StatusBarView(
                state: state,
                onExport: exportPNG,
                onCopyImage: copyImageToPasteboard,
                onStop: {
                    state.stopMonitoring()
                    onStop()
                },
                onReload: {
                    state.reloadFromDisk()
                }
            )
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers)
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportPNG)) { _ in
            exportPNG()
        }
        .onReceive(NotificationCenter.default.publisher(for: .copyImageToPasteboard)) { _ in
            copyImageToPasteboard()
        }
        .frame(minWidth: 600, minHeight: 400)
    }

    private func computeGlitchProgress(at date: Date) -> [String: GlitchInfo] {
        state.cleanupExpiredGlitches(at: date)
        var result: [String: GlitchInfo] = [:]
        for entry in state.glitchEntries {
            let elapsed = date.timeIntervalSince(entry.startTime)
            let progress = min(max(elapsed / GlitchEntry.duration, 0), 1)
            result[entry.elementName] = GlitchInfo(progress: progress, isNew: entry.isNew)
        }
        return result
    }

    private func computeLinkGlitchProgress(at date: Date) -> (progress: [LinkID: LinkGlitchInfo], ghosts: [MapLink]) {
        state.cleanupExpiredLinkGlitches(at: date)
        var progress: [LinkID: LinkGlitchInfo] = [:]
        var ghosts: [MapLink] = []
        for entry in state.linkGlitchEntries {
            let elapsed = date.timeIntervalSince(entry.startTime)
            let p = min(max(elapsed / LinkGlitchEntry.duration, 0), 1)
            progress[entry.linkID] = LinkGlitchInfo(progress: p, isNew: entry.isNew)
            if let ghost = entry.ghostLink {
                ghosts.append(ghost)
            }
        }
        return (progress, ghosts)
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

    private func copyImageToPasteboard() {
        Task { @MainActor in
            _ = ExportService.copyToPasteboard(
                map: state.parsedMap,
                theme: state.currentTheme
            )
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { data, _ in
            guard let data = data as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            Task { @MainActor in
                recentFiles.add(url)
                state.openFile(url)
            }
        }
        return true
    }
}
