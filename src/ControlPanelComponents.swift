import Cocoa

enum ControlPanelLayout {
    static let cardMinWidth: CGFloat = 440
    static let cardHorizontalInset: CGFloat = 16
    static let cardVerticalInset: CGFloat = 12
    static let cornerRadius: CGFloat = 12
    static let controlCornerRadius: CGFloat = 8
    static let listSelectionCornerRadius: CGFloat = 6
    static let selectionVerticalInset: CGFloat = 3
    static let selectionHorizontalInset: CGFloat = 0
    static let selectionTextHorizontalInset: CGFloat = 14
    static let pageCardHeight: CGFloat = 252
    static let statusSectionMinHeight: CGFloat = 42
    static let settingsBottomSpacerMaxHeight: CGFloat = 8
    static let settingsRowSpacing: CGFloat = 15
    static let buttonHeight: CGFloat = 28
    static let primaryButtonMinWidth: CGFloat = 78
    static let utilityButtonMinWidth: CGFloat = 72
    static let cardButtonSpacing: CGFloat = 8
    static let rowSpacing: CGFloat = 8
}

enum ControlPanelTab: Int, CaseIterable {
    case settings
    case exclusions
    case logs

    var identifier: String {
        switch self {
        case .settings: return "settings"
        case .exclusions: return "exclusions"
        case .logs: return "logs"
        }
    }

    var localizationKey: String {
        switch self {
        case .settings: return "tab.settings"
        case .exclusions: return "tab.exclusions"
        case .logs: return "tab.logs"
        }
    }
}

final class RoundedSelectionTableRowView: NSTableRowView {
    override func drawSelection(in dirtyRect: NSRect) {
        guard selectionHighlightStyle != .none else { return }

        let selectionRect = bounds.insetBy(
            dx: ControlPanelLayout.selectionHorizontalInset,
            dy: ControlPanelLayout.selectionVerticalInset
        )
        NSColor.controlAccentColor.setFill()
        NSBezierPath(
            roundedRect: selectionRect,
            xRadius: ControlPanelLayout.listSelectionCornerRadius,
            yRadius: ControlPanelLayout.listSelectionCornerRadius
        ).fill()
    }
}

final class RoundedTabSegmentedControl: NSSegmentedControl {
    override var selectedSegment: Int {
        get { super.selectedSegment }
        set {
            super.selectedSegment = newValue
            needsDisplay = true
        }
    }

    override func setLabel(_ label: String, forSegment segment: Int) {
        super.setLabel(label, forSegment: segment)
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard segmentCount > 0 else { return }

        let radius = ControlPanelLayout.controlCornerRadius
        NSColor.controlColor.withAlphaComponent(0.55).setFill()
        NSBezierPath(
            roundedRect: bounds,
            xRadius: radius,
            yRadius: radius
        ).fill()

        let segmentWidth = bounds.width / CGFloat(segmentCount)
        if selectedSegment >= 0 && selectedSegment < segmentCount {
            let selectedRect = NSRect(
                x: bounds.minX + CGFloat(selectedSegment) * segmentWidth,
                y: bounds.minY,
                width: segmentWidth,
                height: bounds.height
            )
            NSColor.controlAccentColor.setFill()
            NSBezierPath(
                roundedRect: selectedRect,
                xRadius: radius,
                yRadius: radius
            ).fill()
        }

        drawSeparators(segmentWidth: segmentWidth)
        drawLabels(segmentWidth: segmentWidth)
    }

    private func drawSeparators(segmentWidth: CGFloat) {
        guard segmentCount > 1 else { return }

        NSColor.separatorColor.withAlphaComponent(0.45).setStroke()
        for segment in 1..<segmentCount {
            if segment == selectedSegment || segment - 1 == selectedSegment {
                continue
            }
            let x = bounds.minX + CGFloat(segment) * segmentWidth
            let path = NSBezierPath()
            path.lineWidth = 1
            path.move(to: NSPoint(x: x, y: bounds.minY + 8))
            path.line(to: NSPoint(x: x, y: bounds.maxY - 8))
            path.stroke()
        }
    }

    private func drawLabels(segmentWidth: CGFloat) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        for segment in 0..<segmentCount {
            let label = self.label(forSegment: segment) ?? ""
            let selected = segment == selectedSegment
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: selected ? NSColor.white : NSColor.labelColor,
                .paragraphStyle: paragraph,
            ]
            let segmentRect = NSRect(
                x: bounds.minX + CGFloat(segment) * segmentWidth,
                y: bounds.minY,
                width: segmentWidth,
                height: bounds.height
            )
            let textSize = label.size(withAttributes: attributes)
            let textRect = NSRect(
                x: segmentRect.minX,
                y: segmentRect.midY - textSize.height / 2,
                width: segmentRect.width,
                height: textSize.height
            )
            label.draw(in: textRect, withAttributes: attributes)
        }
    }
}
