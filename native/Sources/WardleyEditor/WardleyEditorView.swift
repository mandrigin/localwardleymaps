import AppKit
import SwiftUI
import WardleyModel

/// NSViewRepresentable wrapping NSTextView with syntax highlighting and line numbers.
public struct WardleyEditorView: NSViewRepresentable {
    @Binding public var text: String
    public var highlightedLine: Int?
    public var errorLines: Set<Int>
    public var onTextChange: ((String) -> Void)?
    public var scrollToLine: Int?

    public init(
        text: Binding<String>,
        highlightedLine: Int? = nil,
        errorLines: Set<Int> = [],
        onTextChange: ((String) -> Void)? = nil,
        scrollToLine: Int? = nil
    ) {
        self._text = text
        self.highlightedLine = highlightedLine
        self.errorLines = errorLines
        self.onTextChange = onTextChange
        self.scrollToLine = scrollToLine
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        let textView = LineNumberTextView()
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = NSColor.textColor
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.insertionPointColor = NSColor.textColor

        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        )

        textView.delegate = context.coordinator
        textView.string = text

        scrollView.documentView = textView
        context.coordinator.textView = textView

        // Initial highlighting
        applySyntaxHighlighting(to: textView)
        applyLineHighlighting(to: textView)

        return scrollView
    }

    public func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? LineNumberTextView else { return }

        // Update text only if it changed externally
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
        }

        applySyntaxHighlighting(to: textView)
        applyLineHighlighting(to: textView)

        // Scroll to line if requested
        if let line = scrollToLine, line > 0 {
            scrollToLine(line, in: textView)
        }

        textView.errorLines = errorLines
        textView.highlightedLine = highlightedLine
        textView.needsDisplay = true
    }

    func scrollToLine(_ line: Int, in textView: NSTextView) {
        let lines = textView.string.split(separator: "\n", omittingEmptySubsequences: false)
        guard line <= lines.count else { return }
        var charIndex = 0
        for i in 0..<(line - 1) {
            charIndex += lines[i].count + 1
        }
        let range = NSRange(location: min(charIndex, textView.string.count), length: 0)
        textView.scrollRangeToVisible(range)
        textView.showFindIndicator(for: range)
    }

    // MARK: - Syntax Highlighting

    func applySyntaxHighlighting(to textView: NSTextView) {
        let text = textView.string
        let fullRange = NSRange(location: 0, length: (text as NSString).length)
        let storage = textView.textStorage!

        storage.beginEditing()

        // Reset to default
        storage.addAttribute(.foregroundColor, value: NSColor.textColor, range: fullRange)
        storage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular), range: fullRange)

        let nsText = text as NSString
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        var offset = 0

        for line in lines {
            let lineStr = String(line)
            let trimmed = lineStr.trimmingCharacters(in: .whitespaces)
            let lineRange = NSRange(location: offset, length: lineStr.count)

            // Keywords
            let keywords = [
                "title", "component", "evolve", "anchor", "pipeline", "annotation",
                "annotations", "note", "style", "evolution", "submap", "url",
                "pioneers", "settlers", "townplanners", "accelerator", "deaccelerator",
                "buy", "build", "outsource", "market", "ecosystem", "size", "label",
                "inertia",
            ]

            for keyword in keywords {
                if trimmed.hasPrefix(keyword + " ") || trimmed == keyword {
                    let kwRange = NSRange(location: offset + (lineStr.count - trimmed.count), length: keyword.count)
                    if kwRange.location + kwRange.length <= nsText.length {
                        storage.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: kwRange)
                        storage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 13, weight: .bold), range: kwRange)
                    }
                    break
                }
            }

            // Coordinates [x, y] — green
            let coordPattern = try? NSRegularExpression(pattern: "\\[[-\\d.,\\s]+\\]")
            coordPattern?.enumerateMatches(in: text, range: lineRange) { match, _, _ in
                if let r = match?.range {
                    storage.addAttribute(.foregroundColor, value: NSColor.systemGreen, range: r)
                }
            }

            // Link operators -> +> +< +<>
            let linkOps = ["->", "+>", "+<>", "+<"]
            for op in linkOps {
                var searchRange = NSRange(location: offset, length: lineStr.count)
                while searchRange.location < offset + lineStr.count {
                    let found = nsText.range(of: op, options: [], range: searchRange)
                    guard found.location != NSNotFound else { break }
                    storage.addAttribute(.foregroundColor, value: NSColor.systemOrange, range: found)
                    storage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 13, weight: .bold), range: found)
                    searchRange.location = found.location + found.length
                    searchRange.length = (offset + lineStr.count) - searchRange.location
                    if searchRange.length <= 0 { break }
                }
            }

            // Comments — gray (// and after)
            if let commentRange = lineStr.range(of: "//") {
                let commentStart = lineStr.distance(from: lineStr.startIndex, to: commentRange.lowerBound)
                let commentNSRange = NSRange(location: offset + commentStart, length: lineStr.count - commentStart)
                storage.addAttribute(.foregroundColor, value: NSColor.systemGray, range: commentNSRange)
            }

            // Decorators (buy), (build), (outsource), (market), (ecosystem) — purple
            let decPattern = try? NSRegularExpression(pattern: "\\((buy|build|outsource|market|ecosystem|inertia)\\)")
            decPattern?.enumerateMatches(in: text, range: lineRange) { match, _, _ in
                if let r = match?.range {
                    storage.addAttribute(.foregroundColor, value: NSColor.systemPurple, range: r)
                }
            }

            // Context after ; — italic gray
            if let semiIndex = lineStr.firstIndex(of: ";"),
               !trimmed.hasPrefix("annotation") {
                let semiOffset = lineStr.distance(from: lineStr.startIndex, to: semiIndex)
                let contextRange = NSRange(location: offset + semiOffset, length: lineStr.count - semiOffset)
                storage.addAttribute(.foregroundColor, value: NSColor.systemGray, range: contextRange)
                storage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 13, weight: .light), range: contextRange)
            }

            offset += lineStr.count + 1  // +1 for newline
        }

        storage.endEditing()
    }

    func applyLineHighlighting(to textView: NSTextView) {
        // Line highlighting is handled by the LineNumberTextView subclass
    }

    // MARK: - Coordinator

    public class Coordinator: NSObject, NSTextViewDelegate {
        var parent: WardleyEditorView
        weak var textView: NSTextView?

        init(_ parent: WardleyEditorView) {
            self.parent = parent
        }

        public func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            let newText = textView.string
            if newText != parent.text {
                parent.text = newText
                parent.onTextChange?(newText)
            }
            parent.applySyntaxHighlighting(to: textView)
        }
    }
}

// MARK: - LineNumberTextView

class LineNumberTextView: NSTextView {
    var highlightedLine: Int?
    var errorLines: Set<Int> = []

    private let gutterWidth: CGFloat = 40

    override var textContainerInset: NSSize {
        get { NSSize(width: gutterWidth + 4, height: 4) }
        set {}
    }

    override func draw(_ dirtyRect: NSRect) {
        // Draw line number gutter background
        let gutterRect = NSRect(x: 0, y: 0, width: gutterWidth, height: bounds.height)
        NSColor.controlBackgroundColor.setFill()
        gutterRect.fill()

        // Separator line
        NSColor.separatorColor.setStroke()
        let sepPath = NSBezierPath()
        sepPath.move(to: NSPoint(x: gutterWidth, y: 0))
        sepPath.line(to: NSPoint(x: gutterWidth, y: bounds.height))
        sepPath.lineWidth = 0.5
        sepPath.stroke()

        super.draw(dirtyRect)

        // Draw line numbers
        drawLineNumbers()
    }

    private func drawLineNumbers() {
        guard let layoutManager = layoutManager,
              let textContainer = textContainer else { return }

        let visibleRect = enclosingScrollView?.contentView.bounds ?? bounds
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

        let text = string as NSString
        var lineNumber = 1

        // Count lines before visible range
        text.enumerateSubstrings(in: NSRange(location: 0, length: charRange.location), options: [.byLines, .substringNotRequired]) { _, _, _, _ in
            lineNumber += 1
        }

        // Draw line numbers for visible lines
        text.enumerateSubstrings(in: charRange, options: [.byLines, .substringNotRequired]) { [weak self] _, substringRange, _, _ in
            guard let self = self else { return }

            let lineGlyphRange = layoutManager.glyphRange(forCharacterRange: substringRange, actualCharacterRange: nil)
            var lineRect = layoutManager.lineFragmentRect(forGlyphAt: lineGlyphRange.location, effectiveRange: nil)
            lineRect.origin.y += self.textContainerOrigin.y

            // Error line background
            if self.errorLines.contains(lineNumber) {
                NSColor.systemRed.withAlphaComponent(0.15).setFill()
                NSRect(x: 0, y: lineRect.origin.y, width: self.bounds.width, height: lineRect.height).fill()
            }

            // Highlighted line background
            if self.highlightedLine == lineNumber {
                NSColor.systemYellow.withAlphaComponent(0.2).setFill()
                NSRect(x: 0, y: lineRect.origin.y, width: self.bounds.width, height: lineRect.height).fill()
            }

            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular),
                .foregroundColor: NSColor.secondaryLabelColor,
            ]
            let numStr = "\(lineNumber)" as NSString
            let numSize = numStr.size(withAttributes: attrs)
            let numPoint = NSPoint(
                x: self.gutterWidth - numSize.width - 6,
                y: lineRect.origin.y + (lineRect.height - numSize.height) / 2
            )
            numStr.draw(at: numPoint, withAttributes: attrs)

            lineNumber += 1
        }
    }
}
