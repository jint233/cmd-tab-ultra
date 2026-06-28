import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outputURL =
    root
    .appendingPathComponent("dist", isDirectory: true)
    .appendingPathComponent("dmg-background.png")

try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)

let size = NSSize(width: 620, height: 360)
let image = NSImage(size: size)

image.lockFocus()

let bounds = CGRect(origin: .zero, size: size)
NSColor(calibratedWhite: 0.98, alpha: 1).setFill()
bounds.fill()

let arrowColor = NSColor(calibratedRed: 0.02, green: 0.48, blue: 1.0, alpha: 1.0)
let arrowPath = NSBezierPath()
arrowPath.move(to: CGPoint(x: 250, y: 208))
arrowPath.line(to: CGPoint(x: 390, y: 208))
arrowPath.lineWidth = 18
arrowPath.lineCapStyle = .round
arrowColor.setStroke()
arrowPath.stroke()

let arrowHead = NSBezierPath()
arrowHead.move(to: CGPoint(x: 430, y: 208))
arrowHead.line(to: CGPoint(x: 372, y: 248))
arrowHead.line(to: CGPoint(x: 372, y: 168))
arrowHead.close()
arrowColor.setFill()
arrowHead.fill()

let hint = "Drop to install" as NSString
let hintAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 22, weight: .semibold),
    .foregroundColor: arrowColor,
]
let hintSize = hint.size(withAttributes: hintAttributes)
hint.draw(
    at: CGPoint(x: (size.width - hintSize.width) / 2, y: 118),
    withAttributes: hintAttributes
)

image.unlockFocus()

guard
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let data = bitmap.representation(using: .png, properties: [:])
else {
    throw NSError(domain: "CmdTabUltraDMGBackground", code: 1)
}

try data.write(to: outputURL)
print("Generated \(outputURL.path)")
