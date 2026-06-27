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
NSColor(calibratedWhite: 0.97, alpha: 1).setFill()
bounds.fill()

let title = "Drag CmdTabUltra to Applications" as NSString
let titleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 22, weight: .semibold),
    .foregroundColor: NSColor(calibratedWhite: 0.20, alpha: 1),
]
let titleSize = title.size(withAttributes: titleAttributes)
title.draw(
    at: CGPoint(x: (size.width - titleSize.width) / 2, y: 292),
    withAttributes: titleAttributes
)

let subtitle = "Replace the old app if macOS asks." as NSString
let subtitleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 13, weight: .regular),
    .foregroundColor: NSColor(calibratedWhite: 0.38, alpha: 1),
]
let subtitleSize = subtitle.size(withAttributes: subtitleAttributes)
subtitle.draw(
    at: CGPoint(x: (size.width - subtitleSize.width) / 2, y: 270),
    withAttributes: subtitleAttributes
)

let arrowPath = NSBezierPath()
arrowPath.move(to: CGPoint(x: 245, y: 172))
arrowPath.line(to: CGPoint(x: 374, y: 172))
arrowPath.lineWidth = 10
arrowPath.lineCapStyle = .round
NSColor.systemBlue.setStroke()
arrowPath.stroke()

let arrowHead = NSBezierPath()
arrowHead.move(to: CGPoint(x: 374, y: 172))
arrowHead.line(to: CGPoint(x: 346, y: 194))
arrowHead.line(to: CGPoint(x: 346, y: 150))
arrowHead.close()
NSColor.systemBlue.setFill()
arrowHead.fill()

let hint = "Drop to install" as NSString
let hintAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 13, weight: .medium),
    .foregroundColor: NSColor.systemBlue,
]
let hintSize = hint.size(withAttributes: hintAttributes)
hint.draw(
    at: CGPoint(x: (size.width - hintSize.width) / 2, y: 124),
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
