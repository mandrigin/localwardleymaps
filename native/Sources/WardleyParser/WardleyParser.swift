import Foundation
import WardleyModel

/// Main parser that converts DSL text into a WardleyMap value type.
/// Port of Converter.ts — runs 15 extraction strategies sequentially.
public struct WardleyParser: Sendable {
    public var enableNewPipelines: Bool

    public init(enableNewPipelines: Bool = true) {
        self.enableNewPipelines = enableNewPipelines
    }

    public func parse(_ data: String) -> WardleyMap {
        let cleaned = stripComments(data)
        var map = WardleyMap()
        var allErrors: [ParseError] = []

        // Strategy 1: Title
        let (title, _) = extractTitle(from: cleaned)
        map.title = title

        // Strategy 2: X-Axis Labels (evolution)
        let (evolution, evoErrors) = extractEvolution(from: cleaned)
        map.evolution = evolution
        allErrors.append(contentsOf: evoErrors)

        // Strategy 3: Presentation
        map.presentation = extractPresentation(from: cleaned)

        // Strategy 4: Notes
        map.notes = extractNotes(from: cleaned)

        // Strategy 5: Annotations
        map.annotations = extractAnnotations(from: cleaned)

        // Strategy 6: Components (elements)
        let (elements, elemErrors) = extractComponents(from: cleaned)
        map.elements = elements
        allErrors.append(contentsOf: elemErrors)

        // Strategy 7: Pipelines
        let (pipelines, pipeErrors) = extractPipelines(from: cleaned)
        map.pipelines = pipelines
        allErrors.append(contentsOf: pipeErrors)

        // Strategy 8: Evolve
        let (evolved, evolveErrors) = extractEvolved(from: cleaned)
        map.evolved = evolved
        allErrors.append(contentsOf: evolveErrors)

        // Strategy 9: Anchors
        let (anchors, anchorErrors) = extractAnchors(from: cleaned)
        map.anchors = anchors
        allErrors.append(contentsOf: anchorErrors)

        // Strategy 10: Links
        let (links, linkErrors) = extractLinks(from: cleaned)
        map.links = links
        allErrors.append(contentsOf: linkErrors)

        // Strategy 11: Submaps
        let (submaps, submapErrors) = extractSubmaps(from: cleaned)
        map.submaps = submaps
        allErrors.append(contentsOf: submapErrors)

        // Strategy 12: URLs
        let (urls, urlErrors) = extractURLs(from: cleaned)
        map.urls = urls
        allErrors.append(contentsOf: urlErrors)

        // Strategy 13: Attitudes
        map.attitudes = extractAttitudes(from: cleaned)

        // Strategy 14: Accelerators
        map.accelerators = extractAccelerators(from: cleaned)

        // Strategy 15: Methods
        map.methods = extractMethods(from: cleaned)

        map.errors = allErrors
        return map
    }

    // MARK: - Comment Stripping

    func stripComments(_ data: String) -> String {
        // First pass: strip // comments (except on url lines)
        let lines = data.split(separator: "\n", omittingEmptySubsequences: false).map { line -> String in
            let s = String(line)
            if s.trimmingCharacters(in: .whitespaces).hasPrefix("url") {
                return s
            }
            return String(s.split(separator: "//", maxSplits: 1).first ?? Substring(s))
        }

        // Second pass: strip /* ... */ block comments
        var result: [String] = []
        var inBlock = false
        for line in lines {
            if line.contains("/*") {
                inBlock = true
                let before = String(line.split(separator: "/*", maxSplits: 1).first ?? "")
                    .trimmingCharacters(in: .whitespaces)
                result.append(before)
            } else if inBlock {
                if line.contains("*/") {
                    inBlock = false
                    let after = line.split(separator: "*/", maxSplits: 1).last.map(String.init) ?? ""
                    result.append(after.trimmingCharacters(in: .whitespaces))
                }
                // else skip line entirely (inside block comment)
            } else {
                result.append(line)
            }
        }

        return result.joined(separator: "\n")
    }

    // MARK: - Strategy 1: Title

    func extractTitle(from data: String) -> (String, [ParseError]) {
        let lines = data.split(separator: "\n", omittingEmptySubsequences: false)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("title ") {
                let title = String(trimmed.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                return (title, [])
            }
        }
        return ("Untitled Map", [])
    }

    // MARK: - Strategy 2: Evolution Labels

    func extractEvolution(from data: String) -> ([EvolutionLabel], [ParseError]) {
        let lines = data.split(separator: "\n", omittingEmptySubsequences: false)
        var errors: [ParseError] = []
        for (i, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("evolution ") {
                do {
                    let rest = String(trimmed.dropFirst(10)).trimmingCharacters(in: .whitespaces)
                    let parts = rest.split(separator: "->")
                    guard parts.count >= 4 else { throw NSError() }
                    return (parts.map { EvolutionLabel(line1: String($0).trimmingCharacters(in: .whitespaces)) }, [])
                } catch {
                    errors.append(ParseError(line: i, name: "Invalid evolution"))
                }
            }
        }
        return (EvolutionLabel.defaults, errors)
    }

    // MARK: - Strategy 3: Presentation

    func extractPresentation(from data: String) -> MapPresentation {
        var presentation = MapPresentation()
        let lines = data.split(separator: "\n", omittingEmptySubsequences: false)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("style ") {
                presentation.style = String(trimmed.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            }
            if trimmed.hasPrefix("annotations ") {
                let loc = extractLocation(from: String(trimmed))
                presentation.annotations = AnnotationPosition(visibility: loc.visibility, maturity: loc.maturity)
            }
            if trimmed.hasPrefix("size ") {
                let s = extractSize(from: String(trimmed))
                presentation.size = MapSize(width: s.width, height: s.height)
            }
        }
        return presentation
    }

    // MARK: - Strategy 4: Notes

    func extractNotes(from data: String) -> [MapNote] {
        let lines = data.split(separator: "\n", omittingEmptySubsequences: false)
        var notes: [MapNote] = []
        for (i, line) in lines.enumerated() {
            let element = String(line)
            let trimmed = element.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("note ") else { continue }
            let text = extractText(from: element, keyword: "note")
            let coords = extractLocation(from: element)
            notes.append(MapNote(
                id: "\(i + 1)",
                line: i + 1,
                text: text,
                visibility: coords.visibility,
                maturity: coords.maturity
            ))
        }
        return notes
    }

    // MARK: - Strategy 5: Annotations

    func extractAnnotations(from data: String) -> [MapAnnotation] {
        let lines = data.split(separator: "\n", omittingEmptySubsequences: false)
        var annotations: [MapAnnotation] = []
        for (i, line) in lines.enumerated() {
            let element = String(line)
            let trimmed = element.trimmingCharacters(in: .whitespaces)
            // Must start with "annotation " but not "annotations "
            guard trimmed.hasPrefix("annotation "),
                  !trimmed.hasPrefix("annotations ") else { continue }

            let number = extractNumber(from: element, keyword: "annotation")
            let occurances = extractOccurrences(from: element)
            let text = extractTextFromEnding(from: element)

            guard !occurances.isEmpty else { continue }

            annotations.append(MapAnnotation(
                id: "\(i + 1)",
                line: i + 1,
                number: number,
                occurances: occurances,
                text: text
            ))
        }
        return annotations
    }

    // MARK: - Strategy 6: Components

    func extractComponents(from data: String) -> ([MapElement], [ParseError]) {
        // Filter out lines inside pipeline { } blocks
        let cleanedData = filterNestedContainers(from: data)
        return runComponentExtraction(from: cleanedData, keyword: "component", spacing: 0)
    }

    func filterNestedContainers(from data: String) -> String {
        let lines = data.split(separator: "\n", omittingEmptySubsequences: false)
        var result: [String] = []
        var insideNested = false
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("{") {
                insideNested = true
                result.append(" ")
            } else if insideNested && trimmed.hasPrefix("}") {
                insideNested = false
                result.append(" ")
            } else if insideNested && !trimmed.contains("}") && !trimmed.contains("{") {
                result.append(" ")
            } else if !insideNested && !trimmed.contains("}") {
                result.append(String(line))
            } else {
                result.append(String(line))
            }
        }
        return result.joined(separator: "\n")
    }

    func runComponentExtraction(
        from data: String,
        keyword: String,
        spacing: Int
    ) -> ([MapElement], [ParseError]) {
        let lines = data.split(separator: "\n", omittingEmptySubsequences: false)
        var elements: [MapElement] = []
        var errors: [ParseError] = []
        var unpositionedIndices: [Int] = []

        for (i, line) in lines.enumerated() {
            let element = String(line)
            let trimmed = element.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("\(keyword) ") else { continue }

            do {
                let (decs, decSpacing) = extractDecorators(from: element)
                let effectiveSpacing = max(spacing, decSpacing)
                let hasCoords = element.contains("[") && element.contains("]")
                let coords = extractLocation(from: element)
                let name = extractName(from: element, keyword: keyword)
                let inertia = extractInertia(from: element)
                let label = extractLabel(from: element, increaseLabelSpacing: effectiveSpacing)
                let evolve = extractEvolve(from: element)
                let ref = extractRef(from: element)

                let elementIndex = elements.count
                elements.append(MapElement(
                    id: "\(i + 1)",
                    line: i + 1,
                    name: name,
                    visibility: coords.visibility,
                    maturity: coords.maturity,
                    inertia: inertia,
                    evolving: evolve.evolving,
                    label: label,
                    decorators: decs,
                    increaseLabelSpacing: effectiveSpacing,
                    evolveMaturity: evolve.evolveMaturity,
                    url: ref
                ))

                if !hasCoords {
                    unpositionedIndices.append(elementIndex)
                }
            } catch {
                errors.append(ParseError(line: i, name: "\(error)"))
            }
        }

        // Distribute unpositioned components so they don't stack on each other
        if unpositionedIndices.count > 1 {
            let count = unpositionedIndices.count
            for (offset, idx) in unpositionedIndices.enumerated() {
                let maturity = 0.1 + (0.8 * Double(offset) / Double(count - 1))
                elements[idx].maturity = maturity
            }
        }

        return (elements, errors)
    }

    // MARK: - Strategy 7: Pipelines

    func extractPipelines(from data: String) -> ([Pipeline], [ParseError]) {
        let lines = data.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var pipelines: [Pipeline] = []
        var errors: [ParseError] = []

        for (i, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("pipeline ") else { continue }

            do {
                let name = extractName(from: line, keyword: "pipeline")
                let pm = extractPipelineMaturity(from: line)

                var pipeline = Pipeline(
                    id: "\(i + 1)",
                    line: i + 1,
                    name: name,
                    hidden: pm.hidden,
                    maturity1: pm.maturity1,
                    maturity2: pm.maturity2
                )

                if enableNewPipelines {
                    // Scan for child components inside { }
                    var children: [PipelineComponent] = []
                    var hasPassedOpening = false
                    for j in (i + 1)..<lines.count {
                        let currentLine = lines[j].trimmingCharacters(in: .whitespaces)
                        if currentLine.hasPrefix("{") && !hasPassedOpening {
                            hasPassedOpening = true
                            continue
                        }
                        if !hasPassedOpening && currentLine.hasPrefix("pipeline ") {
                            break
                        }
                        if hasPassedOpening && currentLine.contains("}") {
                            break
                        }
                        if hasPassedOpening && currentLine.hasPrefix("component ") {
                            let childName = extractName(from: currentLine, keyword: "component")
                            let childMaturity = extractPipelineComponentMaturity(from: currentLine)
                            let childLabel = extractLabel(from: currentLine, increaseLabelSpacing: 0)
                            children.append(PipelineComponent(
                                id: "\(i + 1)-\(j)",
                                line: j + 1,
                                name: childName,
                                maturity: childMaturity,
                                label: childLabel
                            ))
                        }
                    }
                    pipeline.components = children
                    if !children.isEmpty {
                        var mostLeft: Double = 1
                        var mostRight: Double = 0
                        for child in children {
                            if child.maturity < mostLeft { mostLeft = child.maturity }
                            if child.maturity > mostRight { mostRight = child.maturity }
                        }
                        pipeline.maturity1 = mostLeft
                        pipeline.maturity2 = mostRight
                        pipeline.hidden = false
                    }
                }

                pipelines.append(pipeline)
            } catch {
                errors.append(ParseError(line: i, name: "\(error)"))
            }
        }
        return (pipelines, errors)
    }

    // MARK: - Strategy 8: Evolve

    func extractEvolved(from data: String) -> ([EvolvedElement], [ParseError]) {
        let lines = data.split(separator: "\n", omittingEmptySubsequences: false)
        var evolved: [EvolvedElement] = []
        var errors: [ParseError] = []

        for (i, line) in lines.enumerated() {
            let element = String(line)
            let trimmed = element.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("evolve ") else { continue }

            do {
                let (decs, decSpacing) = extractDecorators(from: element)
                let label = extractLabel(from: element, increaseLabelSpacing: decSpacing)
                let nameResult = extractNameWithMaturity(from: element)

                evolved.append(EvolvedElement(
                    id: "\(i + 1)",
                    line: i + 1,
                    name: nameResult.name,
                    maturity: nameResult.maturity,
                    label: label,
                    override: nameResult.override,
                    decorators: decs,
                    increaseLabelSpacing: decSpacing
                ))
            } catch {
                errors.append(ParseError(line: i, name: "\(error)"))
            }
        }
        return (evolved, errors)
    }

    // MARK: - Strategy 9: Anchors

    func extractAnchors(from data: String) -> ([MapAnchor], [ParseError]) {
        let lines = data.split(separator: "\n", omittingEmptySubsequences: false)
        var anchors: [MapAnchor] = []
        var errors: [ParseError] = []

        for (i, line) in lines.enumerated() {
            let element = String(line)
            let trimmed = element.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("anchor ") else { continue }

            do {
                let name = extractName(from: element, keyword: "anchor")
                let coords = extractLocation(from: element)
                anchors.append(MapAnchor(
                    id: "\(i + 1)",
                    line: i + 1,
                    name: name,
                    visibility: coords.visibility,
                    maturity: coords.maturity
                ))
            } catch {
                errors.append(ParseError(line: i, name: "\(error)"))
            }
        }
        return (anchors, errors)
    }

    // MARK: - Strategy 10: Links

    func extractLinks(from data: String) -> ([MapLink], [ParseError]) {
        let notLinkPrefixes = [
            "evolution", "anchor", "evolve", "component", "style", "build",
            "buy", "outsource", "title", "annotation", "annotations",
            "pipeline", "note", "pioneers", "settlers", "townplanners",
            "submap", "url", "{", "}", "accelerator", "deaccelerator", "size",
            "market", "ecosystem",
        ]

        let lines = data.split(separator: "\n", omittingEmptySubsequences: false)
        var links: [MapLink] = []
        var errors: [ParseError] = []

        for (i, line) in lines.enumerated() {
            let element = String(line)
            let trimmed = element.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            // Check if this is a non-link line
            var isNonLink = false
            for prefix in notLinkPrefixes {
                if trimmed.hasPrefix(prefix) || trimmed.contains("(\(prefix))") {
                    isNonLink = true
                    break
                }
            }
            guard !isNonLink else { continue }

            do {
                var start = ""
                var end = ""
                var flow = true
                var future = false
                var past = false
                var flowValue: String?
                var context: String?

                if element.contains("+'") {
                    // Flow with value
                    let parts = element.split(separator: "+'", maxSplits: 1)
                    start = String(parts[0]).trimmingCharacters(in: .whitespaces)

                    if parts.count > 1 {
                        let rest = String(parts[1])
                        if rest.contains("'>") {
                            let flowParts = rest.split(separator: "'>", maxSplits: 1)
                            flowValue = String(flowParts[0])
                            end = flowParts.count > 1 ? String(flowParts[1]) : ""
                            future = true
                        } else if rest.contains("'<>") {
                            let flowParts = rest.split(separator: "'<>", maxSplits: 1)
                            flowValue = String(flowParts[0])
                            end = flowParts.count > 1 ? String(flowParts[1]) : ""
                            past = true
                            future = true
                        } else if rest.contains("'<") {
                            let flowParts = rest.split(separator: "'<", maxSplits: 1)
                            flowValue = String(flowParts[0])
                            end = flowParts.count > 1 ? String(flowParts[1]) : ""
                            past = true
                        }
                    }

                    // Handle context
                    if end.contains(";") {
                        let contextParts = end.split(separator: ";", maxSplits: 1)
                        end = String(contextParts[0])
                        context = contextParts.count > 1 ? String(contextParts[1]).trimmingCharacters(in: .whitespaces) : nil
                    }

                    end = end.trimmingCharacters(in: .whitespaces)

                    links.append(MapLink(
                        start: start,
                        end: end,
                        flow: flow,
                        future: future,
                        past: past,
                        context: context,
                        flowValue: flowValue
                    ))
                    continue
                }

                if element.contains("+>") {
                    let parts = element.split(separator: "+>", maxSplits: 1)
                    start = String(parts[0])
                    end = parts.count > 1 ? String(parts[1]) : ""
                } else if element.contains("+<>") {
                    let parts = element.split(separator: "+<>", maxSplits: 1)
                    start = String(parts[0])
                    end = parts.count > 1 ? String(parts[1]) : ""
                    past = true
                } else if element.contains("+<") {
                    let parts = element.split(separator: "+<", maxSplits: 1)
                    start = String(parts[0])
                    end = parts.count > 1 ? String(parts[1]) : ""
                    future = true
                } else if element.contains("->") {
                    let parts = element.split(separator: "->", maxSplits: 1)
                    start = String(parts[0])
                    end = parts.count > 1 ? String(parts[1]) : ""
                    flow = false
                } else {
                    continue
                }

                // Handle context (;)
                if element.contains(";") {
                    context = String(element.split(separator: ";", maxSplits: 1).last ?? "")
                        .trimmingCharacters(in: .whitespaces)
                }

                start = start.trimmingCharacters(in: .whitespaces)
                // Strip context from end
                end = end.split(separator: ";", maxSplits: 1).first.map { String($0) } ?? end
                end = end.trimmingCharacters(in: .whitespaces)

                guard !start.isEmpty || !end.isEmpty else {
                    errors.append(ParseError(line: i))
                    continue
                }

                links.append(MapLink(
                    start: start,
                    end: end,
                    flow: flow,
                    future: future,
                    past: past,
                    context: context
                ))
            } catch {
                errors.append(ParseError(line: i))
            }
        }
        return (links, errors)
    }

    // MARK: - Strategy 11: Submaps

    func extractSubmaps(from data: String) -> ([MapElement], [ParseError]) {
        let lines = data.split(separator: "\n", omittingEmptySubsequences: false)
        var submaps: [MapElement] = []
        var errors: [ParseError] = []

        for (i, line) in lines.enumerated() {
            let element = String(line)
            let trimmed = element.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("submap ") else { continue }

            do {
                let (decs, decSpacing) = extractDecorators(from: element)
                let coords = extractLocation(from: element)
                let name = extractName(from: element, keyword: "submap")
                let inertia = extractInertia(from: element)
                let label = extractLabel(from: element, increaseLabelSpacing: decSpacing)
                let evolve = extractEvolve(from: element)
                let ref = extractRef(from: element)

                submaps.append(MapElement(
                    id: "\(i + 1)",
                    line: i + 1,
                    name: name,
                    visibility: coords.visibility,
                    maturity: coords.maturity,
                    inertia: inertia,
                    evolving: evolve.evolving,
                    label: label,
                    decorators: decs,
                    increaseLabelSpacing: decSpacing,
                    evolveMaturity: evolve.evolveMaturity,
                    url: ref
                ))
            } catch {
                errors.append(ParseError(line: i, name: "\(error)"))
            }
        }
        return (submaps, errors)
    }

    // MARK: - Strategy 12: URLs

    func extractURLs(from data: String) -> ([MapURL], [ParseError]) {
        let lines = data.split(separator: "\n", omittingEmptySubsequences: false)
        var urls: [MapURL] = []
        var errors: [ParseError] = []

        for (i, line) in lines.enumerated() {
            let element = String(line)
            let trimmed = element.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("url ") else { continue }

            do {
                let name = extractName(from: element, keyword: "url")
                let path = extractURLPath(from: element)
                urls.append(MapURL(
                    id: "\(i + 1)",
                    line: i + 1,
                    name: name,
                    url: path
                ))
            } catch {
                errors.append(ParseError(line: i, name: "\(error)"))
            }
        }
        return (urls, errors)
    }

    // MARK: - Strategy 13: Attitudes

    func extractAttitudes(from data: String) -> [Attitude] {
        let keywords = ["pioneers", "settlers", "townplanners"]
        var attitudes: [Attitude] = []

        let lines = data.split(separator: "\n", omittingEmptySubsequences: false)
        for keyword in keywords {
            for (i, line) in lines.enumerated() {
                let element = String(line)
                let trimmed = element.trimmingCharacters(in: .whitespaces)
                guard trimmed.hasPrefix("\(keyword) ") else { continue }

                let manyCoords = extractManyLocations(from: element)
                let hw = extractHeightWidth(from: element)

                attitudes.append(Attitude(
                    id: "\(i + 1)",
                    line: i + 1,
                    attitude: keyword,
                    visibility: manyCoords.visibility,
                    maturity: manyCoords.maturity,
                    visibility2: manyCoords.visibility2,
                    maturity2: manyCoords.maturity2,
                    width: hw.width,
                    height: hw.height
                ))
            }
        }
        return attitudes
    }

    // MARK: - Strategy 14: Accelerators

    func extractAccelerators(from data: String) -> [Accelerator] {
        let keywords = ["accelerator", "deaccelerator"]
        var accelerators: [Accelerator] = []

        let lines = data.split(separator: "\n", omittingEmptySubsequences: false)
        for keyword in keywords {
            for (i, line) in lines.enumerated() {
                let element = String(line)
                let trimmed = element.trimmingCharacters(in: .whitespaces)
                guard trimmed.hasPrefix("\(keyword) ") else { continue }

                let name = extractName(from: element, keyword: keyword)
                let coords = extractLocation(from: element)
                accelerators.append(Accelerator(
                    id: "\(i + 1)",
                    line: i + 1,
                    name: name,
                    maturity: coords.maturity,
                    visibility: coords.visibility,
                    deaccelerator: keyword == "deaccelerator"
                ))
            }
        }
        return accelerators
    }

    // MARK: - Strategy 15: Methods

    func extractMethods(from data: String) -> [MapMethod] {
        let keywords = ["buy", "outsource", "build"]
        var methods: [MapMethod] = []

        let lines = data.split(separator: "\n", omittingEmptySubsequences: false)
        for keyword in keywords {
            for (i, line) in lines.enumerated() {
                let element = String(line)
                let trimmed = element.trimmingCharacters(in: .whitespaces)
                guard trimmed.hasPrefix("\(keyword) ") else { continue }

                let name = String(trimmed.dropFirst(keyword.count + 1)).trimmingCharacters(in: .whitespaces)
                var decs = ComponentDecorators()
                switch keyword {
                case "buy": decs.buy = true
                case "build": decs.build = true
                case "outsource": decs.outsource = true
                default: break
                }
                methods.append(MapMethod(
                    id: "\(i + 1)",
                    line: i + 1,
                    name: name,
                    decorators: decs
                ))
            }
        }
        return methods
    }
}
