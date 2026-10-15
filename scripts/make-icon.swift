// Renders the ClipVault app icon (a clipboard with a vault-door wheel) and the
// menu bar template glyph with AppKit — no external design tools needed.
//
//   swiftc scripts/make-icon.swift -o build/make-icon && build/make-icon
//
// Writes Resources/AppIcon.icns, Resources/MenuBarIcon.png and MenuBarIcon@2x.png.
import AppKit

// MARK: - Palette

let bgTop = NSColor(calibratedRed: 0.30, green: 0.36, blue: 0.98, alpha: 1)      // indigo
let bgBottom = NSColor(calibratedRed: 0.12, green: 0.10, blue: 0.45, alpha: 1)   // deep navy
let boardColor = NSColor(calibratedRed: 0.97, green: 0.97, blue: 1.00, alpha: 1)
let boardShadow = NSColor(calibratedWhite: 0, alpha: 0.28)
let clipColor = NSColor(calibratedRed: 0.17, green: 0.18, blue: 0.26, alpha: 1)
let wheelOuter = NSColor(calibratedRed: 0.27, green: 0.40, blue: 0.98, alpha: 1)
let wheelInner = NSColor(calibratedRed: 0.14, green: 0.22, blue: 0.75, alpha: 1)
let wheelMetal = NSColor(calibratedWhite: 0.98, alpha: 1)
let accent = NSColor(calibratedRed: 0.99, green: 0.74, blue: 0.22, alpha: 1)     // amber

// MARK: - Drawing helpers

func rr(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: NSRect(x: x, y: y, width: w, height: h), xRadius: r, yRadius: r)
}

func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> NSBezierPath {
    NSBezierPath(ovalIn: NSRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))
}

func withShadow(_ color: NSColor, blur: CGFloat, offset: CGSize, _ body: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = color
    shadow.shadowBlurRadius = blur
    shadow.shadowOffset = offset
    shadow.set()
    body()
    NSGraphicsContext.restoreGraphicsState()
}

// MARK: - App icon

func drawAppIcon(size s: CGFloat) {
    // Background squircle with gradient and a soft inner highlight.
    let inset = s * 0.055
    let bg = rr(inset, inset, s - 2 * inset, s - 2 * inset, s * 0.225)
    NSGradient(colors: [bgTop, bgBottom])!.draw(in: bg, angle: -65)
    NSGraphicsContext.saveGraphicsState()
    bg.addClip()
    NSGradient(colors: [NSColor(calibratedWhite: 1, alpha: 0), NSColor(calibratedWhite: 1, alpha: 0.20)])!
        .draw(in: NSRect(x: 0, y: 0, width: s, height: s), angle: 90)
    NSGraphicsContext.restoreGraphicsState()

    // Clipboard body.
    let board = rr(s * 0.25, s * 0.15, s * 0.50, s * 0.62, s * 0.065)
    withShadow(boardShadow, blur: s * 0.04, offset: CGSize(width: 0, height: -s * 0.02)) {
        boardColor.setFill()
        board.fill()
    }

    // Vault wheel on the board.
    let cx = s * 0.50, cy = s * 0.42, R = s * 0.165
    withShadow(NSColor(calibratedWhite: 0, alpha: 0.25), blur: s * 0.025, offset: CGSize(width: 0, height: -s * 0.012)) {
        NSGradient(colors: [wheelOuter, wheelInner])!.draw(in: circle(cx, cy, R), angle: -90)
    }
    // Rim ring
    wheelMetal.setStroke()
    let rim = circle(cx, cy, R * 0.72)
    rim.lineWidth = s * 0.028
    rim.stroke()
    // Spokes
    for i in 0..<5 {
        let angle = CGFloat(i) * (2 * .pi / 5) + .pi / 2
        let spoke = NSBezierPath()
        spoke.move(to: NSPoint(x: cx, y: cy))
        spoke.line(to: NSPoint(x: cx + cos(angle) * R * 0.72, y: cy + sin(angle) * R * 0.72))
        spoke.lineWidth = s * 0.026
        spoke.lineCapStyle = .round
        spoke.stroke()
    }
    // Hub
    wheelMetal.setFill()
    circle(cx, cy, R * 0.2).fill()
    wheelInner.setFill()
    circle(cx, cy, R * 0.09).fill()

    // Two short "text" lines above the wheel.
    accent.setFill()
    rr(s * 0.33, s * 0.655, s * 0.34, s * 0.035, s * 0.0175).fill()
    NSColor(calibratedRed: 0.72, green: 0.75, blue: 0.90, alpha: 1).setFill()
    rr(s * 0.33, s * 0.605, s * 0.22, s * 0.028, s * 0.014).fill()

    // Clip at the top.
    withShadow(NSColor(calibratedWhite: 0, alpha: 0.3), blur: s * 0.02, offset: CGSize(width: 0, height: -s * 0.01)) {
        clipColor.setFill()
        rr(s * 0.39, s * 0.725, s * 0.22, s * 0.10, s * 0.035).fill()
    }
    // Clip ring / hole.
    NSColor(calibratedWhite: 1, alpha: 0.9).setStroke()
    let ring = circle(s * 0.50, s * 0.80, s * 0.035)
    ring.lineWidth = s * 0.018
    ring.stroke()
}

// MARK: - Menu bar glyph (template: black shapes on transparent)

func drawMenuBarGlyph(size s: CGFloat) {
    NSColor.black.setStroke()
    NSColor.black.setFill()
    let lw = s * 0.085

    // Board outline
    let board = rr(s * 0.18, s * 0.06, s * 0.64, s * 0.78, s * 0.12)
    board.lineWidth = lw
    board.stroke()
    // Clip
    rr(s * 0.36, s * 0.76, s * 0.28, s * 0.16, s * 0.06).fill()
    // Wheel: ring + hub + 3 spokes
    let cx = s * 0.50, cy = s * 0.42, R = s * 0.20
    let ring = circle(cx, cy, R)
    ring.lineWidth = lw
    ring.stroke()
    circle(cx, cy, s * 0.055).fill()
    for i in 0..<3 {
        let a = CGFloat(i) * (2 * .pi / 3) + .pi / 2
        let p = NSBezierPath()
        p.move(to: NSPoint(x: cx, y: cy))
        p.line(to: NSPoint(x: cx + cos(a) * R, y: cy + sin(a) * R))
        p.lineWidth = lw * 0.9
        p.lineCapStyle = .round
        p.stroke()
    }
}

// MARK: - Output

func renderPNG(pixels: Int, pointSize: CGFloat, to url: URL, draw: (CGFloat) -> Void) throws {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: pointSize, height: pointSize)
    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    ctx.shouldAntialias = true
    draw(CGFloat(pixels))
    NSGraphicsContext.restoreGraphicsState()
    try rep.representation(using: .png, properties: [:])!.write(to: url)
}

let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : FileManager.default.currentDirectoryPath)
let resources = root.appendingPathComponent("Resources")
let iconset = root.appendingPathComponent("build/AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)

for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let px = base * scale
        let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        try renderPNG(pixels: px, pointSize: CGFloat(base), to: iconset.appendingPathComponent(name), draw: drawAppIcon)
    }
}
try renderPNG(pixels: 1024, pointSize: 1024, to: root.appendingPathComponent("docs/icon-1024.png"), draw: drawAppIcon)

try renderPNG(pixels: 18, pointSize: 18, to: resources.appendingPathComponent("MenuBarIcon.png"), draw: drawMenuBarGlyph)
try renderPNG(pixels: 36, pointSize: 18, to: resources.appendingPathComponent("MenuBarIcon@2x.png"), draw: drawMenuBarGlyph)
try renderPNG(pixels: 144, pointSize: 144, to: root.appendingPathComponent("build/menubar-glyph-preview.png"), draw: drawMenuBarGlyph)

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset.path, "-o", resources.appendingPathComponent("AppIcon.icns").path]
try task.run()
task.waitUntilExit()
print(task.terminationStatus == 0 ? "✓ Wrote AppIcon.icns, MenuBarIcon.png, MenuBarIcon@2x.png, docs/icon-1024.png" : "✗ iconutil failed")
exit(task.terminationStatus)
