import Foundation
import WardleyModel

/// Mutates DSL text when a component is dragged to a new position.
public struct PositionUpdater {

    /// Update the coordinates of a component in the DSL text.
    /// Returns the modified text, or nil if the component wasn't found.
    public static func updatePosition(
        in text: String,
        componentName: String,
        newVisibility: Double,
        newMaturity: Double
    ) -> String? {
        var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        for (i, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Match "component <name> [vis, mat]"
            if trimmed.hasPrefix("component \(componentName) [") ||
               trimmed.hasPrefix("component \(componentName) [") {
                if let updated = replaceCoordinates(in: line, keyword: "component", name: componentName,
                                                      vis: newVisibility, mat: newMaturity) {
                    lines[i] = updated
                    return lines.joined(separator: "\n")
                }
            }

            // Match "component <name>" without coordinates — INSERT
            if trimmed == "component \(componentName)" ||
               (trimmed.hasPrefix("component \(componentName) ") && !trimmed.contains("[")) {
                lines[i] = insertCoordinatesAfterName(in: line, keyword: "component", name: componentName,
                                                        vis: newVisibility, mat: newMaturity)
                return lines.joined(separator: "\n")
            }

            // Match "anchor <name> [vis, mat]"
            if trimmed.hasPrefix("anchor \(componentName) [") {
                if let updated = replaceCoordinates(in: line, keyword: "anchor", name: componentName,
                                                      vis: newVisibility, mat: newMaturity) {
                    lines[i] = updated
                    return lines.joined(separator: "\n")
                }
            }

            // Match "anchor <name>" without coordinates — INSERT
            if trimmed == "anchor \(componentName)" ||
               (trimmed.hasPrefix("anchor \(componentName) ") && !trimmed.contains("[")) {
                lines[i] = insertCoordinatesAfterName(in: line, keyword: "anchor", name: componentName,
                                                        vis: newVisibility, mat: newMaturity)
                return lines.joined(separator: "\n")
            }

            // Match "submap <name> [vis, mat]"
            if trimmed.hasPrefix("submap \(componentName) [") {
                if let updated = replaceCoordinates(in: line, keyword: "submap", name: componentName,
                                                      vis: newVisibility, mat: newMaturity) {
                    lines[i] = updated
                    return lines.joined(separator: "\n")
                }
            }

            // Match "submap <name>" without coordinates — INSERT
            if trimmed == "submap \(componentName)" ||
               (trimmed.hasPrefix("submap \(componentName) ") && !trimmed.contains("[")) {
                lines[i] = insertCoordinatesAfterName(in: line, keyword: "submap", name: componentName,
                                                        vis: newVisibility, mat: newMaturity)
                return lines.joined(separator: "\n")
            }

            // Match "note +<text> [vis, mat]"
            if trimmed.hasPrefix("note ") && trimmed.contains(componentName) {
                if let updated = replaceFirstBracketedCoords(in: line, vis: newVisibility, mat: newMaturity) {
                    lines[i] = updated
                    return lines.joined(separator: "\n")
                }
            }
        }

        return nil
    }

    /// Update the maturity of an evolve line.
    public static func updateEvolveMaturity(
        in text: String,
        evolveName: String,
        newMaturity: Double
    ) -> String? {
        var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        for (i, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("evolve \(evolveName)") ||
                  trimmed.hasPrefix("evolve \(evolveName)->") else { continue }

            // Replace the decimal number in the evolve line
            let regex = try? NSRegularExpression(pattern: "\\s([0-9]?\\.[0-9]+[0-9]?)")
            if let match = regex?.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
               let range = Range(match.range, in: line) {
                let formatted = String(format: "%.2f", newMaturity)
                var newLine = line
                newLine.replaceSubrange(range, with: " \(formatted)")
                lines[i] = newLine
                return lines.joined(separator: "\n")
            }
        }

        return nil
    }

    /// Update the label offset of a component in the DSL text.
    /// Returns the modified text, or nil if the component wasn't found.
    public static func updateLabelOffset(
        in text: String,
        componentName: String,
        newX: Double,
        newY: Double
    ) -> String? {
        var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let labelText = String(format: " label [%.2f, %.2f]", newX, newY)

        for (i, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            guard matchesElementLine(trimmed, name: componentName) else { continue }

            // Replace existing label or append new one
            if let updated = replaceLabelInLine(line, with: labelText) {
                lines[i] = updated
            } else {
                lines[i] = line + labelText
            }
            return lines.joined(separator: "\n")
        }

        return nil
    }

    // MARK: - Private

    private static func matchesElementLine(_ trimmed: String, name: String) -> Bool {
        for keyword in ["component", "anchor", "submap"] {
            let prefix = "\(keyword) \(name)"
            if trimmed.hasPrefix(prefix) {
                let rest = trimmed.dropFirst(prefix.count)
                if rest.isEmpty || rest.first == " " || rest.first == "[" { return true }
            }
        }
        let evolvePrefix = "evolve \(name)"
        if trimmed.hasPrefix(evolvePrefix) {
            let rest = trimmed.dropFirst(evolvePrefix.count)
            if rest.isEmpty || rest.first == " " || rest.first == "-" { return true }
        }
        return false
    }

    private static func replaceLabelInLine(_ line: String, with labelText: String) -> String? {
        guard let labelStart = line.range(of: " label [") else { return nil }
        let afterBracket = line[labelStart.upperBound...]
        guard let closeBracket = afterBracket.firstIndex(of: "]") else { return nil }
        let endIndex = line.index(after: closeBracket)
        var newLine = line
        newLine.replaceSubrange(labelStart.lowerBound..<endIndex, with: labelText)
        return newLine
    }

    private static func replaceCoordinates(
        in line: String,
        keyword: String,
        name: String,
        vis: Double,
        mat: Double
    ) -> String? {
        let prefix = "\(keyword) \(name)"
        guard let prefixRange = line.range(of: prefix) else { return nil }
        let afterPrefix = String(line[prefixRange.upperBound...])

        guard let openBracket = afterPrefix.firstIndex(of: "["),
              let closeBracket = afterPrefix.firstIndex(of: "]") else { return nil }

        let before = String(line[..<prefixRange.upperBound]) + String(afterPrefix[..<openBracket])
        let after = String(afterPrefix[afterPrefix.index(after: closeBracket)...])
        let newCoords = String(format: "[%.2f, %.2f]", vis, mat)
        return before + newCoords + after
    }

    private static func insertCoordinatesAfterName(
        in line: String,
        keyword: String,
        name: String,
        vis: Double,
        mat: Double
    ) -> String {
        let prefix = "\(keyword) \(name)"
        guard let prefixRange = line.range(of: prefix) else { return line }
        let before = String(line[..<prefixRange.upperBound])
        let after = String(line[prefixRange.upperBound...])
        let newCoords = String(format: " [%.2f, %.2f]", vis, mat)
        return before + newCoords + after
    }

    private static func replaceFirstBracketedCoords(
        in line: String,
        vis: Double,
        mat: Double
    ) -> String? {
        guard let openBracket = line.firstIndex(of: "["),
              let closeBracket = line.firstIndex(of: "]") else { return nil }

        let before = String(line[..<openBracket])
        let after = String(line[line.index(after: closeBracket)...])
        let newCoords = String(format: "[%.2f, %.2f]", vis, mat)
        return before + newCoords + after
    }
}
