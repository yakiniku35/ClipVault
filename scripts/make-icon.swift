// Renders the ClipVault app icon with AppKit and writes Resources/AppIcon.icns.
//   swiftc scripts/make-icon.swift -o /tmp/make-icon && /tmp/make-icon
import AppKit

func render(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let inset = size * 0.06
    let bg = NSBezierPath(roundedRect: rect.insetBy(dx: inset, dy: inset), xRadius: size * 0.22, yRadius: size * 0.22)
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.20, green: 0.47, blue: 0.96, alpha: 1),
        NSColor(calibratedRed: 0.09, green: 0.26, blue: 0.70, alpha: 1),
    ])!
    gradient.draw(in: bg, angle: -70)

    // Clipboard body
    let boardRect = NSRect(x: size * 0.26, y: size * 0.18, width: size * 0.48, height: size * 0.58)
    let board = NSBezierPath(roundedRect: boardRect, xRadius: size * 0.06, yRadius: size * 0.06)
    NSColor(calibratedWhite: 1, alpha: 0.95).setFill()
    board.fill()

    // Clip at the top
    let clipRect = NSRect(x: size * 0.40, y: size * 0.70, width: size * 0.20, height: size * 0.11)
    let clip = NSBezierPath(roundedRect: clipRect, xRadius: size * 0.03, yRadius: size * 0.03)
    NSColor(calibratedRed: 0.95, green: 0.72, blue: 0.20, alpha: 1).setFill()
    clip.fill()

    // Text lines
    NSColor(calibratedRed: 0.20, green: 0.47, blue: 0.96, alpha: 0.9).setFill()
    for (i, w) in [0.32, 0.26, 0.30, 0.18].enumerated() {
        let y = size * (0.60 - CGFloat(i) * 0.10)
        NSBezierPath(roundedRect: NSRect(x: size * 0.34, y: y, width: size * CGFloat(w), height: size * 0.045),
                     xRadius: size * 0.02, yRadius: size * 0.02).fill()
    }
    image.unlockFocus()
    return image
}

func writePNG(_ image: NSImage, pixels: Int, to url: URL) throws {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels), from: .zero, operation: .copy, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    try rep.representation(using: .png, properties: [:])!.write(to: url)
}

let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : FileManager.default.currentDirectoryPath)
let iconset = root.appendingPathComponent("build/AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let px = base * scale
        let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        try writePNG(render(size: CGFloat(px)), pixels: px, to: iconset.appendingPathComponent(name))
    }
}

let out = root.appendingPathComponent("Resources/AppIcon.icns")
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset.path, "-o", out.path]
try task.run()
task.waitUntilExit()
print(task.terminationStatus == 0 ? "✓ Wrote \(out.path)" : "✗ iconutil failed")
exit(task.terminationStatus)
