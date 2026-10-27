// Draws the ezTime app icon and writes Resources/AppIcon.icns
// Usage (from the repo root): swift scripts/make-icon.swift
import AppKit

let size: CGFloat = 1024
let center = CGPoint(x: size / 2, y: size / 2)

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

func point(angle degrees: CGFloat, radius: CGFloat) -> CGPoint {
    // 0° = 12 o'clock, clockwise.
    let radians = (90 - degrees) * .pi / 180
    return CGPoint(x: center.x + cos(radians) * radius, y: center.y + sin(radians) * radius)
}

func line(from a: CGPoint, to b: CGPoint, width: CGFloat, color c: NSColor) {
    let path = NSBezierPath()
    path.move(to: a)
    path.line(to: b)
    path.lineWidth = width
    path.lineCapStyle = .round
    c.setStroke()
    path.stroke()
}

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Background tile on Apple's 824pt icon grid, with a soft drop shadow.
let tile = NSBezierPath(roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824), xRadius: 185, yRadius: 185)
NSGraphicsContext.saveGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = color(0x000000, 0.35)
shadow.shadowOffset = NSSize(width: 0, height: -12)
shadow.shadowBlurRadius = 24
shadow.set()
color(0x2350C8).setFill()
tile.fill()
NSGraphicsContext.restoreGraphicsState()
NSGradient(starting: color(0x4C8DFF), ending: color(0x1B3A9E))!.draw(in: tile, angle: -90)

// Clock face.
let radius: CGFloat = 300
let face = NSBezierPath(ovalIn: NSRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
color(0xFFFFFF).setFill()
face.fill()

// Faint globe lines on the face: meridians and parallels.
NSGraphicsContext.saveGraphicsState()
face.addClip()
let globe = color(0x2F6BFF, 0.16)
globe.setStroke()
for width in [radius * 0.45, radius * 0.85] {
    let meridian = NSBezierPath(ovalIn: NSRect(x: center.x - width, y: center.y - radius, width: width * 2, height: radius * 2))
    meridian.lineWidth = 8
    meridian.stroke()
}
for offset in [-radius * 0.5, 0, radius * 0.5] {
    line(from: CGPoint(x: center.x - radius, y: center.y + offset),
         to: CGPoint(x: center.x + radius, y: center.y + offset), width: 8, color: globe)
}
line(from: CGPoint(x: center.x, y: center.y - radius), to: CGPoint(x: center.x, y: center.y + radius), width: 8, color: globe)
NSGraphicsContext.restoreGraphicsState()

// Hour ticks.
for hour in 0..<12 {
    let angle = CGFloat(hour) * 30
    let major = hour % 3 == 0
    line(from: point(angle: angle, radius: major ? 235 : 252), to: point(angle: angle, radius: 270),
         width: major ? 16 : 10, color: color(0x1B2A4A, major ? 1 : 0.55))
}

// Hands at 10:09, the classic watch-ad time.
let ink = color(0x1B2A4A)
line(from: center, to: point(angle: 304.5, radius: 150), width: 26, color: ink)
line(from: center, to: point(angle: 54, radius: 225), width: 18, color: ink)
line(from: point(angle: 210, radius: 50), to: point(angle: 30, radius: 245), width: 8, color: color(0xFF7A1A))
color(0xFF7A1A).setFill()
NSBezierPath(ovalIn: NSRect(x: center.x - 20, y: center.y - 20, width: 40, height: 40)).fill()

NSGraphicsContext.current = nil

// Write an .iconset with all required sizes, then convert it with iconutil.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let master = NSImage(size: NSSize(width: size, height: size))
master.addRepresentation(rep)
for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = base * scale
        let scaled = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                      colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: scaled)
        NSGraphicsContext.current?.imageInterpolation = .high
        master.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
        NSGraphicsContext.current = nil
        let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        try scaled.representation(using: .png, properties: [:])!.write(to: iconset.appendingPathComponent(name))
    }
}

let resources = root.appendingPathComponent("Resources")
try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)
try rep.representation(using: .png, properties: [:])!.write(to: resources.appendingPathComponent("AppIcon.png"))

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", resources.appendingPathComponent("AppIcon.icns").path]
try iconutil.run()
iconutil.waitUntilExit()
print("Wrote Resources/AppIcon.icns and Resources/AppIcon.png")
