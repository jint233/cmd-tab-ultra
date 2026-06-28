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
arrowPath.move(to: CGPoint(x: 230, y: 210))
arrowPath.line(to: CGPoint(x: 335, y: 210))
arrowPath.lineWidth = 16
arrowPath.lineCapStyle = .round
arrowColor.setStroke()
arrowPath.stroke()

let arrowHead = NSBezierPath()
arrowHead.move(to: CGPoint(x: 375, y: 210))
arrowHead.line(to: CGPoint(x: 328, y: 244))
arrowHead.line(to: CGPoint(x: 328, y: 176))
arrowHead.close()
arrowColor.setFill()
arrowHead.fill()

let hint = "Drop to install" as NSString
let hintAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 19, weight: .semibold),
    .foregroundColor: arrowColor,
]
let hintSize = hint.size(withAttributes: hintAttributes)
hint.draw(
    at: CGPoint(x: (size.width - hintSize.width) / 2, y: 135),
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
