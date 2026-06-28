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
let installGuideCenterX: CGFloat = 310
let arrowY: CGFloat = 240
let arrowTailX = installGuideCenterX - 82
let arrowHeadBaseX = installGuideCenterX + 30
let arrowTipX = installGuideCenterX + 78

let arrowPath = NSBezierPath()
arrowPath.move(to: CGPoint(x: arrowTailX, y: arrowY))
arrowPath.line(to: CGPoint(x: arrowHeadBaseX, y: arrowY))
arrowPath.lineWidth = 16
arrowPath.lineCapStyle = .round
arrowColor.setStroke()
arrowPath.stroke()

let arrowHead = NSBezierPath()
arrowHead.move(to: CGPoint(x: arrowTipX, y: arrowY))
arrowHead.line(to: CGPoint(x: arrowHeadBaseX, y: arrowY + 34))
arrowHead.line(to: CGPoint(x: arrowHeadBaseX, y: arrowY - 34))
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
    at: CGPoint(x: installGuideCenterX - hintSize.width / 2, y: 165),
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
