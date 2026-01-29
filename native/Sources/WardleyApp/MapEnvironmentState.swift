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
        parsedMap = parser.parse(mapText)
        let styleName = parsedMap.presentation.style
        if !styleName.isEmpty && styleName != currentThemeName {
            currentThemeName = styleName
        }
    }

    private func updateTheme() {
        currentTheme = Themes.theme(named: currentThemeName)
    }

    public var errorLines: Set<Int> {
        Set(parsedMap.errors.map(\.line))
    }
}
