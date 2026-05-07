#!/usr/bin/env swift

// Renders a 1024×1024 macOS-style app icon for Paperclip and writes it as a
// PNG to the path given as the last argument.
//
// Usage: swift scripts/render-icon.swift <outpath.png>

import AppKit

let outPath: String
if CommandLine.arguments.count >= 2 {
    outPath = CommandLine.arguments[CommandLine.arguments.count - 1]
} else {
    outPath = "icon.png"
}
let outURL = URL(fileURLWithPath: outPath)

let size: CGFloat = 1024
let canvas = NSImage(size: NSSize(width: size, height: size))
canvas.lockFocus()

// Rounded squircle background filled with a soft lavender gradient,
// matching the in-app Clippy palette.
let bgInset: CGFloat = 80
let bgRect = NSRect(x: bgInset, y: bgInset,
                    width: size - 2 * bgInset, height: size - 2 * bgInset)
let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: 220, yRadius: 220)
let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.95, green: 0.93, blue: 1.00, alpha: 1.0),
    NSColor(calibratedRed: 0.66, green: 0.60, blue: 0.86, alpha: 1.0)
])
gradient?.draw(in: bgPath, angle: 270)

// Subtle hairline border.
NSColor(calibratedWhite: 0, alpha: 0.10).setStroke()
bgPath.lineWidth = 4
bgPath.stroke()

// Paperclip SF Symbol, tinted dark purple, rotated to stand upright.
var sc = NSImage.SymbolConfiguration(pointSize: 760, weight: .light)
sc = sc.applying(NSImage.SymbolConfiguration(paletteColors: [
    NSColor(calibratedRed: 0.34, green: 0.30, blue: 0.46, alpha: 1.0)
]))
if let symbol = NSImage(systemSymbolName: "paperclip",
                        accessibilityDescription: nil)?
    .withSymbolConfiguration(sc) {
    let s = symbol.size
    let ctx = NSGraphicsContext.current?.cgContext
    ctx?.saveGState()
    ctx?.translateBy(x: size / 2, y: size / 2)
    ctx?.rotate(by: 32 * .pi / 180)
    symbol.draw(in: NSRect(x: -s.width / 2, y: -s.height / 2,
                           width: s.width, height: s.height))
    ctx?.restoreGState()
}

canvas.unlockFocus()

guard let tiff = canvas.tiffRepresentation,
      let rep  = NSBitmapImageRep(data: tiff),
      let png  = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("error: could not render PNG\n".utf8))
    exit(1)
}

try png.write(to: outURL)
print("wrote \(outURL.path) (\(png.count) bytes)")
