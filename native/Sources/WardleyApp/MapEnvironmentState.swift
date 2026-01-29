import Foundation
import Observation
import WardleyModel
import WardleyParser
import WardleyTheme

/// Central observable state for the map preview environment.
@MainActor
@Observable
public final class MapEnvironmentState {
    public var mapText: String {
        didSet {
            if mapText != oldValue {
                reparseMap()
            }
        }
    }

    public var parsedMap: WardleyMap
    public var currentThemeName: String {
        didSet { updateTheme() }
    }
    public var currentTheme: MapTheme
    public var fileURL: URL?
    public var lastModified: Date?

    // MARK: - Glitch Animation State

    public var glitchEntries: [GlitchEntry] = []

    public var isGlitching: Bool { !glitchEntries.isEmpty }

    /// Remove entries whose animation has completed (older than 0.8s).
    public func cleanupExpiredGlitches(at date: Date) {
        glitchEntries.removeAll { entry in
            date.timeIntervalSince(entry.startTime) >= GlitchEntry.duration
        }
    }

    private let parser = WardleyParser()
    private let fileMonitor = FileMonitorService()

    public init(text: String = "") {
        self.mapText = text
        self.parsedMap = WardleyMap()
        self.currentThemeName = "plain"
        self.currentTheme = Themes.plain
        if !text.isEmpty {
            self.parsedMap = parser.parse(text)
            let styleName = self.parsedMap.presentation.style
            if !styleName.isEmpty {
                self.currentThemeName = styleName
                self.currentTheme = Themes.theme(named: styleName)
            }
        }
    }

    /// Open and start monitoring a file.
    public func openFile(_ url: URL) {
        fileURL = url
        reloadFromDisk()
        startMonitoring()
    }

    /// Re-read the file from disk.
    public func reloadFromDisk() {
        guard let url = fileURL else { return }
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .utf8) else { return }
        mapText = text
        lastModified = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date ?? Date()
    }

    /// Stop monitoring the current file.
    public func stopMonitoring() {
        fileMonitor.stop()
    }

    // MARK: - Private

    private func startMonitoring() {
        guard let url = fileURL else { return }
        fileMonitor.watch(url: url) { [weak self] in
            Task { @MainActor [weak self] in
                self?.reloadFromDisk()
            }
        }
    }

    public func reparseMap() {
        // Snapshot old element positions by name for diff
        let oldElements = Dictionary(
            parsedMap.elements.map { ($0.name, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        parsedMap = parser.parse(mapText)
        let styleName = parsedMap.presentation.style
        if !styleName.isEmpty && styleName != currentThemeName {
            currentThemeName = styleName
        }

        // Diff: detect new and changed elements
        let now = Date()
        let activeNames = Set(glitchEntries.map(\.elementName))
        for element in parsedMap.elements {
            guard !activeNames.contains(element.name) else { continue }

            if let old = oldElements[element.name] {
                let visMoved = abs(old.visibility - element.visibility) > 0.001
                let matMoved = abs(old.maturity - element.maturity) > 0.001
                if visMoved || matMoved {
                    glitchEntries.append(GlitchEntry(
                        elementName: element.name,
                        startTime: now,
                        isNew: false
                    ))
                }
            } else if !oldElements.isEmpty {
                glitchEntries.append(GlitchEntry(
                    elementName: element.name,
                    startTime: now,
                    isNew: true
                ))
            }
        }
    }

    private func updateTheme() {
        currentTheme = Themes.theme(named: currentThemeName)
    }

    public var errorLines: Set<Int> {
        Set(parsedMap.errors.map(\.line))
    }
}
