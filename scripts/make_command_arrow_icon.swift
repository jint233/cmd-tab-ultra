import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let resourcesURL = root.appendingPathComponent("resources", isDirectory: true)
let iconsetURL = FileManager.default.temporaryDirectory
    .appendingPathComponent("CmdTabUltra-\(UUID().uuidString).iconset", isDirectory: true)
let outputIcon = resourcesURL.appendingPathComponent("CmdTabUltra.icns")

try FileManager.default.createDirectory(at: resourcesURL, withIntermediateDirectories: true)
try? FileManager.default.removeItem(at: iconsetURL)
defer { try? FileManager.default.removeItem(at: iconsetURL) }

try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

struct IconSize {
    let name: String
    let pixels: Int
}

let sizes = [
    IconSize(name: "icon_16x16.png", pixels: 16),
    IconSize(name: "icon_16x16@2x.png", pixels: 32),
    IconSize(name: "icon_32x32.png", pixels: 32),
    IconSize(name: "icon_32x32@2x.png", pixels: 64),
    IconSize(name: "icon_128x128.png", pixels: 128),
    IconSize(name: "icon_128x128@2x.png", pixels: 256),
    IconSize(name: "icon_256x256.png", pixels: 256),
    IconSize(name: "icon_256x256@2x.png", pixels: 512),
    IconSize(name: "icon_512x512.png", pixels: 512),
    IconSize(name: "icon_512x512@2x.png", pixels: 1024),
]

func drawIcon(size: Int) -> NSImage {
    let side = CGFloat(size)
    let image = NSImage(size: NSSize(width: side, height: side))
    image.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    NSGraphicsContext.current?.shouldAntialias = true

    let bounds = CGRect(x: 0, y: 0, width: side, height: side)
    NSColor.clear.setFill()
    bounds.fill()

    // Keycap shadow.
    let shadow = NSShadow()
    shadow.shadowOffset = NSSize(width: 0, height: -side * 0.015)
    shadow.shadowBlurRadius = side * 0.026
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.16)
    shadow.set()

    let keycap = CGRect(x: side * 0.135, y: side * 0.135, width: side * 0.730, height: side * 0.730)
    let keycapPath = NSBezierPath(roundedRect: keycap, xRadius: side * 0.135, yRadius: side * 0.135)
    NSColor.white.setFill()
    keycapPath.fill()

    NSShadow().set()

    NSColor.white.setStroke()
    keycapPath.lineWidth = max(1, side * 0.006)
    keycapPath.stroke()

    // Draw Command Symbol (⌘)
    let glyphColor = NSColor(calibratedWhite: 0.22, alpha: 1)
    let command = "⌘" as NSString
    let font = NSFont.systemFont(ofSize: side * 0.32, weight: .regular)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: glyphColor,
    ]
    let commandSize = command.size(withAttributes: attributes)
    let commandPoint = CGPoint(
        x: (side - commandSize.width) / 2.0,
        y: side * 0.54 - commandSize.height / 2.0
    )
    command.draw(at: commandPoint, withAttributes: attributes)

    // Draw "Ultra" text.
    let ultra = "Ultra" as NSString
    let ultraFont = NSFont.systemFont(ofSize: side * 0.065, weight: .bold)
    let ultraColor = NSColor.black

    let ultraAttributes: [NSAttributedString.Key: Any] = [
        .font: ultraFont,
        .foregroundColor: ultraColor,
        .kern: NSNumber(value: Float(side * 0.015)),
    ]

    let ultraSize = ultra.size(withAttributes: ultraAttributes)
    let ultraPoint = CGPoint(
        x: (side - ultraSize.width) / 2.0,
        y: side * 0.28 - ultraSize.height / 2.0
    )
    ultra.draw(at: ultraPoint, withAttributes: ultraAttributes)

    image.unlockFocus()
    return image
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let data = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "CmdTabUltraIcon", code: 1)
    }
    try data.write(to: url)
}

for size in sizes {
    try writePNG(drawIcon(size: size.pixels), to: iconsetURL.appendingPathComponent(size.name))
}

try? FileManager.default.removeItem(at: outputIcon)
let pack = Process()
pack.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
pack.arguments = ["-c", "icns", iconsetURL.path, "-o", outputIcon.path]
try pack.run()
pack.waitUntilExit()
guard pack.terminationStatus == 0 else {
    throw NSError(domain: "CmdTabUltraIcon", code: Int(pack.terminationStatus))
}

print("Generated \(outputIcon.path)")
