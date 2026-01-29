import Foundation
import Observation
import WardleyModel
import WardleyParser
import WardleyTheme

/// Central observable state for the entire map editing environment.
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
    public var highlightedLine: Int?
    public var scrollToLine: Int?
    public var isDirty: Bool = false

    private let parser = WardleyParser()

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

    public func reparseMap() {
        parsedMap = parser.parse(mapText)
        isDirty = true
        // Auto-detect theme from DSL style directive
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

    public func highlightComponent(_ element: MapElement) {
        highlightedLine = element.line
        scrollToLine = element.line
    }

    public func clearHighlight() {
        highlightedLine = nil
        scrollToLine = nil
    }
}
