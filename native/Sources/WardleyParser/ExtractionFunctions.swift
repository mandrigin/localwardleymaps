import Foundation
import WardleyModel

// MARK: - Extraction Helpers

/// Extract a coordinate pair [visibility, maturity] from a string like "[0.5, 0.7]"
public func extractLocation(
    from input: String,
    defaultVisibility: Double = 0.9,
    defaultMaturity: Double = 0.1
) -> (visibility: Double, maturity: Double) {
    guard let openBracket = input.firstIndex(of: "["),
          let closeBracket = input.firstIndex(of: "]") else {
        return (defaultVisibility, defaultMaturity)
    }
    let inside = input[input.index(after: openBracket)..<closeBracket]
        .replacingOccurrences(of: " ", with: "")
    let parts = inside.split(separator: ",")
    let vis = parts.count > 0 ? Double(parts[0]) ?? defaultVisibility : defaultVisibility
    let mat = parts.count > 1 ? Double(parts[1]) ?? defaultMaturity : defaultMaturity
    return (vis, mat)
}

/// Extract four coordinates [v1, m1, v2, m2]
public func extractManyLocations(
    from input: String,
    defaults: (Double, Double, Double, Double) = (0.9, 0.1, 0.8, 0.2)
) -> (visibility: Double, maturity: Double, visibility2: Double, maturity2: Double) {
    guard let openBracket = input.firstIndex(of: "["),
          let closeBracket = input.firstIndex(of: "]") else {
        return defaults
    }
    let inside = input[input.index(after: openBracket)..<closeBracket]
        .replacingOccurrences(of: " ", with: "")
    let parts = inside.split(separator: ",")
    let v1 = parts.count > 0 ? Double(parts[0]) ?? defaults.0 : defaults.0
    let m1 = parts.count > 1 ? Double(parts[1]) ?? defaults.1 : defaults.1
    let v2 = parts.count > 2 ? Double(parts[2]) ?? defaults.2 : defaults.2
    let m2 = parts.count > 3 ? Double(parts[3]) ?? defaults.3 : defaults.3
    return (v1, m1, v2, m2)
}

/// Extract a size pair [width, height]
public func extractSize(
    from input: String,
    defaultWidth: Double = 0,
    defaultHeight: Double = 0
) -> (width: Double, height: Double) {
    guard let openBracket = input.firstIndex(of: "["),
          let closeBracket = input.firstIndex(of: "]") else {
        return (defaultWidth, defaultHeight)
    }
    let inside = input[input.index(after: openBracket)..<closeBracket]
        .replacingOccurrences(of: " ", with: "")
    let parts = inside.split(separator: ",")
    let w = parts.count > 0 ? Double(parts[0]) ?? defaultWidth : defaultWidth
    let h = parts.count > 1 ? Double(parts[1]) ?? defaultHeight : defaultHeight
    return (w, h)
}

/// Extract name from "keyword Name [coords]" -> "Name"
public func extractName(from element: String, keyword: String) -> String {
    guard let keyRange = element.range(of: "\(keyword) ") else { return "" }
    let afterKeyword = String(element[keyRange.upperBound...]).trimmingCharacters(in: .whitespaces)
    // Name ends at first " [" bracket
    if let bracketRange = afterKeyword.range(of: " [") {
        return String(afterKeyword[..<bracketRange.lowerBound]).trimmingCharacters(in: .whitespaces)
    }
    return afterKeyword.trimmingCharacters(in: .whitespaces)
}

/// Extract text after the last ] bracket
public func extractTextFromEnding(from element: String) -> String {
    let trimmed = element.trimmingCharacters(in: .whitespaces)
    guard trimmed.contains("]") else { return "" }
    let noSpaces = trimmed.replacingOccurrences(of: " ", with: "")
    if noSpaces.contains("]]") {
        // find last ]
        guard let lastBracket = trimmed.lastIndex(of: "]") else { return "" }
        let afterIndex = trimmed.index(after: lastBracket)
        guard afterIndex < trimmed.endIndex else { return "" }
        return String(trimmed[afterIndex...]).trimmingCharacters(in: .whitespaces)
    } else {
        // single bracket - check if ] is not at end
        guard let bracketIndex = trimmed.firstIndex(of: "]") else { return "" }
        let afterIndex = trimmed.index(after: bracketIndex)
        guard afterIndex < trimmed.endIndex else { return "" }
        return String(trimmed[afterIndex...]).trimmingCharacters(in: .whitespaces)
    }
}

/// Extract text from "keyword text [coords]"
public func extractText(from element: String, keyword: String) -> String {
    let start = element.range(of: keyword)?.lowerBound ?? element.startIndex
    let afterKeyword = String(element[start...])
    let stripped = String(afterKeyword.dropFirst(keyword.count + 1))
        .trimmingCharacters(in: .whitespaces)
    if let bracketRange = stripped.range(of: " [") {
        return String(stripped[..<bracketRange.lowerBound]).trimmingCharacters(in: .whitespaces)
    }
    return stripped
}

/// Extract label offset from "label [x, y]"
public func extractLabel(from element: String, increaseLabelSpacing: Int) -> LabelOffset {
    var offset = LabelOffset.default
    if increaseLabelSpacing > 0 {
        offset = LabelOffset(
            x: offset.x * Double(increaseLabelSpacing),
            y: offset.y * Double(increaseLabelSpacing)
        )
    }

    guard element.contains("label "),
          let labelRange = element.range(of: "label [") else {
        return offset
    }
    let afterLabel = String(element[labelRange.upperBound...])
    guard let closeBracket = afterLabel.firstIndex(of: "]") else { return offset }
    let coords = String(afterLabel[..<closeBracket]).split(separator: ",")
    if coords.count >= 2 {
        offset.x = Double(coords[0].trimmingCharacters(in: .whitespaces)) ?? offset.x
        offset.y = Double(coords[1].trimmingCharacters(in: .whitespaces)) ?? offset.y
    }
    return offset
}

/// Check if element contains inertia keyword
public func extractInertia(from element: String) -> Bool {
    element.contains("inertia") || element.contains("(inertia)")
}

/// Extract evolve maturity from inline "evolve 0.65"
public func extractEvolve(from element: String) -> (evolveMaturity: Double?, evolving: Bool) {
    guard element.contains("evolve ") else { return (nil, false) }
    var part = element.split(separator: "evolve ", maxSplits: 1).last.map(String.init) ?? ""
    part = part.replacingOccurrences(of: "inertia", with: "").trimmingCharacters(in: .whitespaces)
    if let val = Double(part) {
        return (val, true)
    }
    return (nil, false)
}

/// Extract decorators from parenthesized markers like (buy), (build), (outsource), (market), (ecosystem)
public func extractDecorators(from element: String) -> (decorators: ComponentDecorators, increaseLabelSpacing: Int) {
    var decs = ComponentDecorators()
    var spacing = 0

    let methods = ["build", "buy", "outsource"]
    for meth in methods {
        if let methRange = element.range(of: meth),
           let parenOpen = element.firstIndex(of: "("),
           let parenClose = element.firstIndex(of: ")"),
           parenOpen < methRange.lowerBound,
           parenClose >= methRange.upperBound {
            switch meth {
            case "build": decs.build = true
            case "buy": decs.buy = true
            case "outsource": decs.outsource = true
            default: break
            }
            spacing = 2
            break
        }
    }

    // market decorator
    if let marketRange = element.range(of: "market") {
        if element.hasPrefix("market") {
            decs.market = true
            spacing = 2
        } else if let parenOpen = element.firstIndex(of: "("),
                  let parenClose = element.firstIndex(of: ")"),
                  parenOpen < marketRange.lowerBound,
                  parenClose >= marketRange.upperBound {
            decs.market = true
            spacing = 2
        }
    }

    // ecosystem decorator
    if let ecoRange = element.range(of: "ecosystem") {
        if element.hasPrefix("ecosystem") {
            decs.ecosystem = true
            spacing = 3
        } else if let parenOpen = element.firstIndex(of: "("),
                  let parenClose = element.firstIndex(of: ")"),
                  parenOpen < ecoRange.lowerBound,
                  parenClose >= ecoRange.upperBound {
            decs.ecosystem = true
            spacing = 3
        }
    }

    return (decs, spacing)
}

/// Extract name with maturity from evolve line: "evolve Name->NewName 0.65 label [x,y]"
public func extractNameWithMaturity(from element: String) -> (name: String, override: String, maturity: Double) {
    guard let evolveRange = element.range(of: "evolve ") else {
        return ("", "", 0.85)
    }
    var name = String(element[evolveRange.upperBound...]).trimmingCharacters(in: .whitespaces)
    var override = ""
    var newPoint: Double = 0.85

    // Find the maturity value (a decimal number preceded by whitespace)
    let regex = try? NSRegularExpression(pattern: "\\s[0-9]?\\.[0-9]+[0-9]?")
    if let match = regex?.firstMatch(in: element, range: NSRange(element.startIndex..., in: element)),
       let range = Range(match.range, in: element) {
        let matchStr = String(element[range]).trimmingCharacters(in: .whitespaces)
        newPoint = Double(matchStr) ?? 0.85
        let unprocessedName = name.split(separator: String(newPoint), maxSplits: 1)
            .first.map { String($0).trimmingCharacters(in: .whitespaces) } ?? name
        name = unprocessedName
        if name.contains("->") {
            let parts = name.split(separator: "->", maxSplits: 1)
            name = String(parts[0]).trimmingCharacters(in: .whitespaces)
            override = parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespaces) : ""
        }
    }

    // Strip label portion if present
    if let labelRange = name.range(of: " label") {
        name = String(name[..<labelRange.lowerBound]).trimmingCharacters(in: .whitespaces)
    }

    return (name, override, newPoint)
}

/// Extract pipeline maturity range from "[0.2, 0.8]"
public func extractPipelineMaturity(from element: String) -> (hidden: Bool, maturity1: Double, maturity2: Double) {
    let parts = element.split(separator: "[", maxSplits: 1)
    guard parts.count > 1 else { return (true, 0.2, 0.8) }
    let afterBracket = String(parts[1])
    guard let closeBracket = afterBracket.firstIndex(of: "]") else { return (true, 0.2, 0.8) }
    let coords = String(afterBracket[..<closeBracket]).split(separator: ",")
    guard coords.count >= 2 else { return (true, 0.2, 0.8) }
    let m1 = Double(coords[0].trimmingCharacters(in: .whitespaces)) ?? 0.2
    let m2 = Double(coords[1].trimmingCharacters(in: .whitespaces)) ?? 0.8
    return (false, m1, m2)
}

/// Extract pipeline component maturity from "[0.5]"
public func extractPipelineComponentMaturity(from element: String) -> Double {
    let parts = element.split(separator: "[", maxSplits: 1)
    guard parts.count > 1 else { return 0.2 }
    let afterBracket = String(parts[1])
    guard let closeBracket = afterBracket.firstIndex(of: "]") else { return 0.2 }
    let val = String(afterBracket[..<closeBracket]).trimmingCharacters(in: .whitespaces)
    return Double(val) ?? 0.2
}

/// Extract occurrences from annotation, e.g. [[0.5,0.6],[0.7,0.8]] or [0.5, 0.6]
public func extractOccurrences(from element: String) -> [AnnotationOccurance] {
    let stripped = element.replacingOccurrences(of: " ", with: "")
    var results: [AnnotationOccurance] = []

    if stripped.contains("[[") {
        // multiple occurrences
        guard let start = stripped.range(of: "[["),
              let end = stripped.range(of: "]]") else { return results }
        let inner = "[" + String(stripped[start.upperBound..<end.lowerBound]) + "]"
        let items = inner.replacingOccurrences(of: "],[", with: "]|[").split(separator: "|")
        for item in items {
            let loc = extractLocation(from: String(item))
            results.append(AnnotationOccurance(visibility: loc.visibility, maturity: loc.maturity))
        }
    } else if element.contains("[") && element.contains("]") {
        let loc = extractLocation(from: element)
        results.append(AnnotationOccurance(visibility: loc.visibility, maturity: loc.maturity))
    }

    return results
}

/// Extract annotation number from "annotation 2 [...]"
public func extractNumber(from element: String, keyword: String) -> Int {
    guard let keyRange = element.range(of: "\(keyword) ") else { return 0 }
    let afterKeyword = String(element[keyRange.upperBound...]).trimmingCharacters(in: .whitespaces)
    let numberStr = afterKeyword.split(separator: " ").first.flatMap { s in
        s.split(separator: "[").first
    }.map(String.init) ?? ""
    return Int(numberStr.trimmingCharacters(in: .whitespaces)) ?? 0
}

/// Extract ref URL from "url(...)"
public func extractRef(from element: String) -> String? {
    guard element.contains("url(") else { return nil }
    guard let start = element.range(of: "url("),
          let end = element[start.upperBound...].firstIndex(of: ")") else { return nil }
    return String(element[start.upperBound..<end]).trimmingCharacters(in: .whitespaces)
}

/// Extract URL path from "url Name [path]"
public func extractURLPath(from element: String) -> String {
    let parts = element.split(separator: "[", maxSplits: 1)
    guard parts.count > 1 else { return "" }
    let afterBracket = String(parts[1])
    guard let closeBracket = afterBracket.firstIndex(of: "]") else { return "" }
    return String(afterBracket[..<closeBracket]).trimmingCharacters(in: .whitespaces)
}

/// Extract height/width from text after "]"
public func extractHeightWidth(from element: String) -> (width: String?, height: String?) {
    guard element.contains("]") else { return (nil, nil) }
    guard let bracketIndex = element.firstIndex(of: "]") else { return (nil, nil) }
    let afterBracket = String(element[element.index(after: bracketIndex)...])
        .trimmingCharacters(in: .whitespaces)
    let parts = afterBracket.split(separator: " ")
    let w = parts.count > 0 ? String(parts[0]) : nil
    let h = parts.count > 1 ? String(parts[1]) : nil
    return (w, h)
}
