import Cocoa

extension ControlPanelDelegate {
    func buildWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 365),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = appName

        let content = NSView()
        content.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = content

        let iconView = NSImageView()
        iconView.image = NSApp.applicationIconImage
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 44),
            iconView.heightAnchor.constraint(equalToConstant: 44),
        ])

        let title = NSTextField(labelWithString: appName)
        title.font = .systemFont(ofSize: 22, weight: .bold)

        let subtitle = NSTextField(labelWithString: localized("app.subtitle"))
        subtitle.font = .systemFont(ofSize: 11)
        subtitle.textColor = .secondaryLabelColor

        let titleStack = NSStackView(views: [title, subtitle])
        titleStack.orientation = .vertical
        titleStack.alignment = .leading
        titleStack.spacing = 3

        let headerRow = NSStackView(views: [iconView, titleStack])
        headerRow.orientation = .horizontal
        headerRow.alignment = .centerY
        headerRow.spacing = 14
        headerRow.translatesAutoresizingMaskIntoConstraints = false

        statusDot.font = .systemFont(ofSize: 12)
        statusDot.setContentHuggingPriority(.required, for: .horizontal)

        statusValue.font = .systemFont(ofSize: 14, weight: .semibold)
        statusValue.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let statusRow = NSStackView(views: [statusDot, statusValue])
        statusRow.orientation = .horizontal
        statusRow.spacing = 8
        statusRow.alignment = .centerY

        let card = NSBox()
        card.boxType = .custom
        card.cornerRadius = 10
        card.borderWidth = 1
        card.borderColor = .separatorColor
        card.fillColor = .controlBackgroundColor
        card.translatesAutoresizingMaskIntoConstraints = false

        let row1 = createRow(label: label(localized("status.version")), value: versionValue)
        let row2 = createRow(label: label(localized("status.pid")), value: pidValue)
        let row3 = createRow(label: label(localized("status.duplicates")), value: duplicateValue)
        let row4 = createRow(label: label(localized("status.autoStart")), value: autoStartSwitch)

        let rowsStack = NSStackView(views: [row1, row2, row3, row4])
        rowsStack.orientation = .vertical
        rowsStack.spacing = 12
        rowsStack.alignment = .leading
        rowsStack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(rowsStack)

        NSLayoutConstraint.activate([
            rowsStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            rowsStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            rowsStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            rowsStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            row1.widthAnchor.constraint(equalTo: rowsStack.widthAnchor),
            row2.widthAnchor.constraint(equalTo: rowsStack.widthAnchor),
            row3.widthAnchor.constraint(equalTo: rowsStack.widthAnchor),
            row4.widthAnchor.constraint(equalTo: rowsStack.widthAnchor),
        ])

        versionValue.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        versionValue.alignment = .right
        pidValue.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        pidValue.alignment = .right
        duplicateValue.font = .systemFont(ofSize: 12, weight: .regular)
        duplicateValue.alignment = .right

        autoStartSwitch.target = self
        autoStartSwitch.action = #selector(toggleAutoStart)
        autoStartSwitch.controlSize = .small

        startButton.bezelStyle = .rounded
        stopButton.bezelStyle = .rounded
        refreshButton.bezelStyle = .rounded

        if #available(macOS 10.12, *) {
            startButton.bezelColor = .controlAccentColor
        }

        startButton.target = self
        startButton.action = #selector(startClicked)
        stopButton.target = self
        stopButton.action = #selector(stopClicked)
        refreshButton.target = self
        refreshButton.action = #selector(refreshClicked)

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let buttons = NSStackView(views: [startButton, stopButton, spacer, refreshButton])
        buttons.orientation = .horizontal
        buttons.spacing = 8
        buttons.alignment = .centerY

        messageValue.font = .systemFont(ofSize: 11)
        messageValue.textColor = .secondaryLabelColor
        messageValue.cell?.wraps = true
        messageValue.cell?.isScrollable = false
        messageValue.cell?.lineBreakMode = .byWordWrapping
        messageValue.maximumNumberOfLines = 3
        messageValue.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let stack = NSStackView(views: [headerRow, statusRow, card, buttons, messageValue])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.setCustomSpacing(6, after: headerRow)
        stack.setCustomSpacing(14, after: statusRow)
        stack.setCustomSpacing(16, after: card)
        stack.setCustomSpacing(12, after: buttons)
        content.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 22),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor, constant: -22),
            card.widthAnchor.constraint(equalTo: stack.widthAnchor),
            buttons.widthAnchor.constraint(equalTo: stack.widthAnchor),
            messageValue.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])
    }

    private func createRow(label: NSTextField, value: NSView) -> NSStackView {
        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let row = NSStackView(views: [label, spacer, value])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8
        row.translatesAutoresizingMaskIntoConstraints = false
        return row
    }

    private func label(_ text: String) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = .systemFont(ofSize: 12, weight: .medium)
        field.textColor = .secondaryLabelColor
        return field
    }
}
