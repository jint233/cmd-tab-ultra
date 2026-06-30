import Cocoa

extension ControlPanelDelegate {
    func buildWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 390),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = appName
        window.minSize = NSSize(width: 420, height: 360)

        let content = NSView()
        content.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = content

        statusDot.font = .systemFont(ofSize: 12)
        statusDot.setContentHuggingPriority(.required, for: .horizontal)

        statusValue.font = .systemFont(ofSize: 20, weight: .semibold)
        statusValue.setContentHuggingPriority(.defaultLow, for: .horizontal)
        statusValue.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let statusTitleRow = NSStackView(views: [statusDot, statusValue])
        statusTitleRow.orientation = .horizontal
        statusTitleRow.spacing = 8
        statusTitleRow.alignment = .centerY

        statusDescription.font = .systemFont(ofSize: 11)
        statusDescription.textColor = .secondaryLabelColor
        configureWrappingLabel(statusDescription, maximumNumberOfLines: 2)

        let statusTextStack = NSStackView(views: [statusTitleRow, statusDescription])
        statusTextStack.orientation = .vertical
        statusTextStack.spacing = 6
        statusTextStack.alignment = .leading
        statusTextStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let statusCard = makeCard()
        statusCard.addSubview(statusTextStack)
        statusTextStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusTextStack.leadingAnchor.constraint(
                equalTo: statusCard.leadingAnchor, constant: 16),
            statusTextStack.trailingAnchor.constraint(
                equalTo: statusCard.trailingAnchor, constant: -16),
            statusTextStack.topAnchor.constraint(equalTo: statusCard.topAnchor, constant: 16),
            statusTextStack.bottomAnchor.constraint(
                equalTo: statusCard.bottomAnchor, constant: -16),
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

        languageLabel.font = .systemFont(ofSize: 12)
        languageLabel.textColor = .secondaryLabelColor
        languagePopup.target = self
        languagePopup.action = #selector(languageChanged)
        languagePopup.controlSize = .small

        let serviceRow = createRow(label: autoStartLabel, value: autoStartSwitch)
        let languageRow = createRow(label: languageLabel, value: languagePopup)
        let settingsRows = createRowsStack(views: [serviceRow, languageRow])
        let settingsCard = makeCard()
        settingsCard.addSubview(settingsRows)

        let row1 = createRow(label: versionLabel, value: versionValue)
        let row2 = createRow(label: pidLabel, value: pidValue)
        let row3 = createRow(label: duplicateLabel, value: duplicateValue)
        let diagnosticsRows = createRowsStack(views: [row1, row2, row3])
        let diagnosticsCard = makeCard()
        diagnosticsCard.addSubview(diagnosticsRows)

        NSLayoutConstraint.activate([
            settingsRows.leadingAnchor.constraint(
                equalTo: settingsCard.leadingAnchor, constant: 16),
            settingsRows.trailingAnchor.constraint(
                equalTo: settingsCard.trailingAnchor, constant: -16),
            settingsRows.topAnchor.constraint(equalTo: settingsCard.topAnchor, constant: 12),
            settingsRows.bottomAnchor.constraint(equalTo: settingsCard.bottomAnchor, constant: -12),
            serviceRow.widthAnchor.constraint(equalTo: settingsRows.widthAnchor),
            languageRow.widthAnchor.constraint(equalTo: settingsRows.widthAnchor),

            diagnosticsRows.leadingAnchor.constraint(
                equalTo: diagnosticsCard.leadingAnchor, constant: 16),
            diagnosticsRows.trailingAnchor.constraint(
                equalTo: diagnosticsCard.trailingAnchor, constant: -16),
            diagnosticsRows.topAnchor.constraint(equalTo: diagnosticsCard.topAnchor, constant: 12),
            diagnosticsRows.bottomAnchor.constraint(
                equalTo: diagnosticsCard.bottomAnchor, constant: -12),
            row1.widthAnchor.constraint(equalTo: diagnosticsRows.widthAnchor),
            row2.widthAnchor.constraint(equalTo: diagnosticsRows.widthAnchor),
            row3.widthAnchor.constraint(equalTo: diagnosticsRows.widthAnchor),
        ])

        let buttonSpacer = NSView()
        buttonSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let buttons = NSStackView(views: [startButton, stopButton, buttonSpacer, refreshButton])
        buttons.orientation = .horizontal
        buttons.spacing = 8
        buttons.alignment = .centerY

        messageValue.font = .systemFont(ofSize: 11)
        messageValue.textColor = .secondaryLabelColor
        configureWrappingLabel(messageValue, maximumNumberOfLines: 2)

        let stack = NSStackView(views: [
            statusCard, settingsCard, diagnosticsCard, buttons, messageValue,
        ])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.setCustomSpacing(12, after: statusCard)
        stack.setCustomSpacing(12, after: settingsCard)
        stack.setCustomSpacing(16, after: diagnosticsCard)
        stack.setCustomSpacing(8, after: buttons)
        content.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor, constant: -20),
            statusCard.widthAnchor.constraint(equalTo: stack.widthAnchor),
            settingsCard.widthAnchor.constraint(equalTo: stack.widthAnchor),
            diagnosticsCard.widthAnchor.constraint(equalTo: stack.widthAnchor),
            buttons.widthAnchor.constraint(equalTo: stack.widthAnchor),
            messageValue.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])
    }

    func applyLocalizedText() {
        versionLabel.stringValue = localized("status.version")
        pidLabel.stringValue = localized("status.pid")
        duplicateLabel.stringValue = localized("status.duplicates")
        autoStartLabel.stringValue = localized("status.autoStart")
        stopButton.title = localized("control.stop")
        refreshButton.title = localized("control.refresh")
        languageLabel.stringValue = localized("language.label")
        updateLanguagePopup()
        applyPrimaryActionTitle()
    }

    func applyPrimaryActionTitle() {
        switch primaryAction {
        case .start:
            startButton.title = localized("control.start")
        case .authorize:
            startButton.title = localized("control.authorize")
        case .restart:
            startButton.title = localized("control.restart")
        }
    }

    func applyPrimaryButtonStyle(isServiceRunning: Bool) {
        if #available(macOS 10.12, *) {
            startButton.bezelColor = isServiceRunning ? nil : .controlAccentColor
            stopButton.bezelColor = isServiceRunning ? .controlAccentColor : nil
        }
    }

    @objc func languageChanged() {
        let selectedIndex = languagePopup.indexOfSelectedItem
        guard ControlPanelLanguage.allCases.indices.contains(selectedIndex) else { return }
        let language = ControlPanelLanguage.allCases[selectedIndex]
        selectedControlPanelLanguage = language
        applyLocalizedText()
        refresh()
    }

    private func updateLanguagePopup() {
        let selectedLanguage = selectedControlPanelLanguage
        languagePopup.removeAllItems()
        languagePopup.addItems(withTitles: [
            localized("language.system"),
            localized("language.zhHans"),
            localized("language.en"),
        ])
        let selectedIndex =
            ControlPanelLanguage.allCases.firstIndex(of: selectedLanguage) ?? 0
        languagePopup.selectItem(at: selectedIndex)
    }

    private func makeCard() -> NSBox {
        let card = NSBox()
        card.boxType = .custom
        card.cornerRadius = 8
        card.borderWidth = 1
        card.borderColor = .separatorColor
        card.fillColor = .controlBackgroundColor
        card.translatesAutoresizingMaskIntoConstraints = false
        return card
    }

    private func createRow(label: NSTextField, value: NSView) -> NSStackView {
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabelColor
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

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

    private func createRowsStack(views: [NSView]) -> NSStackView {
        let rows = NSStackView(views: views)
        rows.orientation = .vertical
        rows.spacing = 10
        rows.alignment = .leading
        rows.translatesAutoresizingMaskIntoConstraints = false
        return rows
    }

    private func configureWrappingLabel(
        _ label: NSTextField,
        maximumNumberOfLines: Int
    ) {
        label.cell?.wraps = true
        label.cell?.isScrollable = false
        label.cell?.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = maximumNumberOfLines
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }
}
