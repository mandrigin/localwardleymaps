#!/usr/bin/env swift
// Generates a Wardley Maps app icon as AppIcon.icns
// Run: swift gen-icon.swift

import AppKit
import CoreGraphics

func renderIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let img = NSImage(size: NSSize(width: s, height: s))
    img.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        img.unlockFocus()
        return img
    }

    // Background gradient — deep blue to teal
    let colors = [
        CGColor(red: 0.08, green: 0.12, blue: 0.28, alpha: 1.0),
        CGColor(red: 0.10, green: 0.22, blue: 0.38, alpha: 1.0),
    ]
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors as CFArray,
        locations: [0.0, 1.0]
    )!
    ctx.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: s),
        end: CGPoint(x: s, y: 0),
        options: []
    )

    // Grid lines (subtle)
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.08))
    ctx.setLineWidth(s * 0.003)
    let gridLines = [0.25, 0.5, 0.75]
    for g in gridLines {
        let x = s * CGFloat(g)
        ctx.move(to: CGPoint(x: x, y: s * 0.1))
        ctx.addLine(to: CGPoint(x: x, y: s * 0.9))
        ctx.strokePath()
    }

    // Axis lines
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.25))
    ctx.setLineWidth(s * 0.006)
    // X-axis
    ctx.move(to: CGPoint(x: s * 0.1, y: s * 0.15))
    ctx.addLine(to: CGPoint(x: s * 0.9, y: s * 0.15))
    ctx.strokePath()
    // Y-axis
    ctx.move(to: CGPoint(x: s * 0.1, y: s * 0.15))
    ctx.addLine(to: CGPoint(x: s * 0.1, y: s * 0.88))
    ctx.strokePath()

    // Links between components (draw before dots)
    let components: [(x: CGFloat, y: CGFloat, r: CGFloat)] = [
        (0.50, 0.82, 0.040),   // top center — "User"
        (0.30, 0.62, 0.032),   // mid-left — need
        (0.70, 0.62, 0.032),   // mid-right — need
        (0.20, 0.40, 0.028),   // lower-left
        (0.50, 0.42, 0.028),   // lower-center
        (0.78, 0.38, 0.028),   // lower-right
        (0.35, 0.22, 0.024),   // bottom-left — commodity
        (0.62, 0.22, 0.024),   // bottom-right — commodity
    ]

    let links: [(Int, Int)] = [
        (0, 1), (0, 2),
        (1, 3), (1, 4),
        (2, 4), (2, 5),
        (3, 6), (4, 6), (4, 7), (5, 7),
    ]

    ctx.setStrokeColor(CGColor(red: 0.6, green: 0.75, blue: 0.9, alpha: 0.5))
    ctx.setLineWidth(s * 0.008)
    for (a, b) in links {
        let ca = components[a]
        let cb = components[b]
        ctx.move(to: CGPoint(x: s * ca.x, y: s * ca.y))
        ctx.addLine(to: CGPoint(x: s * cb.x, y: s * cb.y))
        ctx.strokePath()
    }

    // Component dots — white filled with subtle glow
    for c in components {
        let cx = s * c.x
        let cy = s * c.y
        let cr = s * c.r

        // Glow
        ctx.setFillColor(CGColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 0.3))
        let glowRect = CGRect(x: cx - cr * 1.8, y: cy - cr * 1.8, width: cr * 3.6, height: cr * 3.6)
        ctx.fillEllipse(in: glowRect)

        // Dot
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.95))
        let dotRect = CGRect(x: cx - cr, y: cy - cr, width: cr * 2, height: cr * 2)
        ctx.fillEllipse(in: dotRect)
    }

    // Evolution arrow at bottom
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.2))
    ctx.setLineWidth(s * 0.005)
    let arrowY = s * 0.08
    ctx.move(to: CGPoint(x: s * 0.15, y: arrowY))
    ctx.addLine(to: CGPoint(x: s * 0.85, y: arrowY))
    ctx.strokePath()
    // Arrowhead
    ctx.move(to: CGPoint(x: s * 0.82, y: arrowY - s * 0.02))
    ctx.addLine(to: CGPoint(x: s * 0.85, y: arrowY))
    ctx.addLine(to: CGPoint(x: s * 0.82, y: arrowY + s * 0.02))
    ctx.strokePath()

    img.unlockFocus()
    return img
}

func createICNS(at path: String) {
    let sizes = [16, 32, 64, 128, 256, 512, 1024]
    let iconFamily = NSMutableData()

    // Create individual PNGs and assemble
    let tempDir = NSTemporaryDirectory() + "wardley-icon-\(ProcessInfo.processInfo.processIdentifier)/"
    try? FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)

    // Use iconutil: create .iconset directory
    let iconsetPath = tempDir + "AppIcon.iconset"
    try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

    let sizeMap: [(name: String, size: Int)] = [
        ("icon_16x16", 16),
        ("icon_16x16@2x", 32),
        ("icon_32x32", 32),
        ("icon_32x32@2x", 64),
        ("icon_128x128", 128),
        ("icon_128x128@2x", 256),
        ("icon_256x256", 256),
        ("icon_256x256@2x", 512),
        ("icon_512x512", 512),
        ("icon_512x512@2x", 1024),
    ]

    for entry in sizeMap {
        let img = renderIcon(size: entry.size)
        guard let tiff = img.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            print("Failed to render \(entry.name)")
            continue
        }
        let filePath = iconsetPath + "/\(entry.name).png"
        try? png.write(to: URL(fileURLWithPath: filePath))
    }

    // Run iconutil to create .icns
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    process.arguments = ["-c", "icns", iconsetPath, "-o", path]
    try? process.run()
    process.waitUntilExit()

    // Cleanup
    try? FileManager.default.removeItem(atPath: tempDir)

    if process.terminationStatus == 0 {
        print("Icon created: \(path)")
    } else {
        print("iconutil failed with status \(process.terminationStatus)")
    }
}

// Need AppKit initialized for NSImage/NSGraphicsContext
let _ = NSApplication.shared

let outputPath: String
if CommandLine.arguments.count > 1 {
    outputPath = CommandLine.arguments[1]
} else {
    outputPath = "AppIcon.icns"
}

// Ensure output directory exists
let dir = (outputPath as NSString).deletingLastPathComponent
if !dir.isEmpty {
    try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
}

createICNS(at: outputPath)
