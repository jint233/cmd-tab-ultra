import Cocoa

extension ControlPanelDelegate {
    func buildWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = appDisplayName
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.minSize = NSSize(width: 480, height: 380)

        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = .sidebar
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        window.contentView = visualEffectView

        let content = NSView()
        content.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.addSubview(content)

        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
            content.topAnchor.constraint(equalTo: visualEffectView.topAnchor),
            content.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor),
        ])

        configureButtons()

        let settingsView = makeOverviewCard()
        let exclusionsView = makeExcludedAppsCard()
        let logsView = makeRecentActionsCard()

        let headerLabel = NSTextField(labelWithString: appDisplayName)
        headerLabel.font = .systemFont(ofSize: 18, weight: .bold)
        headerLabel.textColor = .labelColor
        headerLabel.isEditable = false
        headerLabel.isBordered = false
        headerLabel.drawsBackground = false
        headerLabel.translatesAutoresizingMaskIntoConstraints = false

        versionValue.font = .systemFont(ofSize: 11, weight: .medium)
        versionValue.textColor = .secondaryLabelColor
        versionValue.isEditable = false
        versionValue.isBordered = false
        versionValue.drawsBackground = false
        versionValue.translatesAutoresizingMaskIntoConstraints = false

        let titleStack = NSStackView(views: [headerLabel, versionValue])
        titleStack.orientation = .horizontal
        titleStack.spacing = 6
        titleStack.alignment = .firstBaseline
        titleStack.translatesAutoresizingMaskIntoConstraints = false

        tabSegmentedControl.segmentCount = ControlPanelTab.allCases.count
        tabSegmentedControl.trackingMode = .selectOne
        tabSegmentedControl.selectedSegment = ControlPanelTab.settings.rawValue
        tabSegmentedControl.target = self
        tabSegmentedControl.action = #selector(tabSegmentChanged)
        tabSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        tabSegmentedControl.widthAnchor.constraint(equalToConstant: 280).isActive = true

        tabView.tabViewType = .noTabsNoBorder
        tabView.drawsBackground = false
        tabView.translatesAutoresizingMaskIntoConstraints = false
        tabView.addTabViewItem(makeTabItem(tab: .settings, view: settingsView))
        tabView.addTabViewItem(makeTabItem(tab: .exclusions, view: exclusionsView))
        tabView.addTabViewItem(makeTabItem(tab: .logs, view: logsView))

        let stack = NSStackView(views: [titleStack, tabSegmentedControl, tabView])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 36),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -16),
            tabView.leadingAnchor.constraint(equalTo: stack.leadingAnchor),
            tabView.trailingAnchor.constraint(equalTo: stack.trailingAnchor),
        ])

        DispatchQueue.main.async { [weak self] in
            self?.refreshTabLayout()
        }
    }

    func applyLocalizedText() {
        updateTabLabels()
        autoStartLabel.stringValue = localized("status.autoStart")
        restoreMinimizedLabel.stringValue = localized("policy.restoreMinimized")
        reopenWindowsLabel.stringValue = localized("policy.reopenWindows")
        commandNFallbackLabel.stringValue = localized("policy.commandNFallback")
        excludedAppsLabel.stringValue = localized("excluded.title")
        chooseExcludedAppButton.title = localized("control.chooseApp")
        removeExcludedButton.title = localized("control.remove")
        clearLogsButton.title = localized("control.clear")
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

    @objc func tabSegmentChanged() {
        tabView.selectTabViewItem(at: tabSegmentedControl.selectedSegment)
        refreshTabLayout()
    }

    @objc func languageChanged() {
        let selectedIndex = languagePopup.indexOfSelectedItem
        guard ControlPanelLanguage.allCases.indices.contains(selectedIndex) else { return }
        let language = ControlPanelLanguage.allCases[selectedIndex]
        selectedControlPanelLanguage = language
        applyLocalizedText()
        refresh()
    }

    func updateExcludedBundleIDList(selecting bundleIDToSelect: String? = nil) {
        let bundleIDs = AppPreferences.excludedBundleIDs.sorted()
        let previousSelection =
            bundleIDToSelect
            ?? selectedExcludedBundleID()
        excludedBundleIDsSnapshot = bundleIDs
        excludedBundleIDTable.reloadData()
        if let previousSelection,
            let index = bundleIDs.firstIndex(of: previousSelection)
        {
            excludedBundleIDTable.selectRowIndexes(
                IndexSet(integer: index),
                byExtendingSelection: false
            )
        } else {
            excludedBundleIDTable.deselectAll(nil)
        }
        updateExcludedAppSelection()
    }

    func updatePreferenceControls() {
        let policy = AppPreferences.restorePolicy
        restoreMinimizedSwitch.state = policy.restoreMinimizedWindows ? .on : .off
        reopenWindowsSwitch.state = policy.reopenAppsWithoutWindows ? .on : .off
        commandNFallbackSwitch.state = policy.useCommandNFallback ? .on : .off
        updateExcludedBundleIDList()
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    func updateRecentActions() {
        let records = recentActionRecords()
        guard !records.isEmpty else {
            recentActionsValue.stringValue = localized("recent.empty")
            return
        }
        recentActionsValue.stringValue = records.map { record in
            let time = Self.timeFormatter.string(from: record.date)
            return "\(time)  \(record.appName)  •  \(localizedAction(record))"
        }.joined(separator: "\n")
    }

    private func configureButtons() {
        configureButton(
            startButton, action: #selector(startClicked),
            minWidth: ControlPanelLayout.primaryButtonMinWidth)
        configureButton(
            stopButton, action: #selector(stopClicked),
            minWidth: ControlPanelLayout.primaryButtonMinWidth)
        configureButton(
            refreshButton, action: #selector(refreshClicked),
            minWidth: ControlPanelLayout.utilityButtonMinWidth)
        if #available(macOS 10.12, *) {
            startButton.bezelColor = .controlAccentColor
        }
    }

    private func makeOverviewCard() -> NSView {
        // Status Section
        statusDot.font = .systemFont(ofSize: 14)
        statusDot.setContentHuggingPriority(.required, for: .horizontal)
        statusValue.font = .systemFont(ofSize: 14, weight: .bold)
        statusValue.setContentHuggingPriority(.required, for: .horizontal)
        statusValue.setContentCompressionResistancePriority(.required, for: .horizontal)

        let statusTitleRow = NSStackView(views: [statusDot, statusValue])
        statusTitleRow.orientation = .horizontal
        statusTitleRow.spacing = 6
        statusTitleRow.alignment = .centerY
        statusTitleRow.setContentHuggingPriority(.required, for: .horizontal)
        statusTitleRow.setContentCompressionResistancePriority(.required, for: .horizontal)

        statusDescription.font = .systemFont(ofSize: 11)
        statusDescription.textColor = .secondaryLabelColor
        configureWrappingLabel(statusDescription, maximumNumberOfLines: 2)
        statusDescription.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let statusSection = NSStackView(views: [statusTitleRow, statusDescription])
        statusSection.orientation = .vertical
        statusSection.spacing = 8
        statusSection.alignment = .leading
        statusSection.translatesAutoresizingMaskIntoConstraints = false
        statusSection.setContentHuggingPriority(.required, for: .vertical)

        // Settings Section
        autoStartSwitch.target = self
        autoStartSwitch.action = #selector(toggleAutoStart)
        autoStartSwitch.controlSize = .small

        configureRowLabel(languageLabel)
        languagePopup.target = self
        languagePopup.action = #selector(languageChanged)
        languagePopup.controlSize = .small

        for policySwitch in [
            restoreMinimizedSwitch, reopenWindowsSwitch, commandNFallbackSwitch,
        ] {
            policySwitch.target = self
            policySwitch.action = #selector(toggleRestorePolicy)
            policySwitch.controlSize = .small
        }

        let autoStartRow = createRow(label: autoStartLabel, value: autoStartSwitch)
        let restoreMinimizedRow = createRow(
            label: restoreMinimizedLabel, value: restoreMinimizedSwitch)
        let reopenWindowsRow = createRow(label: reopenWindowsLabel, value: reopenWindowsSwitch)
        let commandNFallbackRow = createRow(
            label: commandNFallbackLabel, value: commandNFallbackSwitch)
        let languageRow = createRow(label: languageLabel, value: languagePopup)

        let settingsSection = createRowsStack(views: [
            autoStartRow,
            restoreMinimizedRow,
            reopenWindowsRow,
            commandNFallbackRow,
            languageRow,
        ])
        settingsSection.spacing = ControlPanelLayout.settingsRowSpacing
        settingsSection.setContentHuggingPriority(.required, for: .vertical)

        // Separator
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false

        let cardBottomSpacer = NSView()
        cardBottomSpacer.translatesAutoresizingMaskIntoConstraints = false
        cardBottomSpacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        cardBottomSpacer.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        let overallStack = NSStackView(views: [
            statusSection,
            separator,
            settingsSection,
            cardBottomSpacer,
        ])
        overallStack.orientation = .vertical
        overallStack.spacing = 10
        overallStack.alignment = .leading
        overallStack.distribution = .fill
        overallStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            separator.widthAnchor.constraint(equalTo: overallStack.widthAnchor),
            statusSection.widthAnchor.constraint(equalTo: overallStack.widthAnchor),
            statusSection.heightAnchor.constraint(
                greaterThanOrEqualToConstant: ControlPanelLayout.statusSectionMinHeight),
            statusTitleRow.widthAnchor.constraint(lessThanOrEqualTo: statusSection.widthAnchor),
            statusDescription.widthAnchor.constraint(equalTo: statusSection.widthAnchor),
            settingsSection.widthAnchor.constraint(equalTo: overallStack.widthAnchor),
            cardBottomSpacer.widthAnchor.constraint(equalTo: overallStack.widthAnchor),
            cardBottomSpacer.heightAnchor.constraint(
                lessThanOrEqualToConstant: ControlPanelLayout.settingsBottomSpacerMaxHeight),
        ])

        let card = makeCard(containing: overallStack)
        card.setContentHuggingPriority(.defaultHigh, for: .vertical)
        card.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

        // Configure buttons row (outside the card)
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let buttonsRow = NSStackView(views: [startButton, stopButton, spacer, refreshButton])
        buttonsRow.orientation = .horizontal
        buttonsRow.spacing = 8
        buttonsRow.alignment = .centerY
        buttonsRow.translatesAutoresizingMaskIntoConstraints = false
        buttonsRow.setContentHuggingPriority(.required, for: .vertical)
        buttonsRow.setContentCompressionResistancePriority(.required, for: .vertical)

        let settingsStack = makePageStack(card: card, bottomRow: buttonsRow)

        NSLayoutConstraint.activate([
            card.widthAnchor.constraint(equalTo: settingsStack.widthAnchor),
            buttonsRow.widthAnchor.constraint(equalTo: settingsStack.widthAnchor),
        ])

        return settingsStack
    }

    private func makeExcludedAppsCard() -> NSView {
        configureButton(chooseExcludedAppButton, action: #selector(chooseExcludedApp))
        configureButton(removeExcludedButton, action: #selector(removeExcludedBundleID))

        configureExcludedAppsTable()

        excludedBundleIDScrollView.translatesAutoresizingMaskIntoConstraints = false
        excludedBundleIDScrollView.setContentHuggingPriority(.defaultLow, for: .vertical)

        let rows = createRowsStack(views: [excludedBundleIDScrollView])
        let card = makeCard(containing: rows)

        let appRow = NSStackView(views: [chooseExcludedAppButton, removeExcludedButton])
        appRow.orientation = .horizontal
        appRow.alignment = .centerY
        appRow.spacing = 12
        appRow.translatesAutoresizingMaskIntoConstraints = false
        appRow.setContentHuggingPriority(.defaultHigh, for: .vertical)

        let exclusionsStack = makePageStack(card: card, bottomRow: appRow)

        NSLayoutConstraint.activate([
            excludedBundleIDScrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
            excludedBundleIDScrollView.widthAnchor.constraint(equalTo: rows.widthAnchor),
            card.widthAnchor.constraint(equalTo: exclusionsStack.widthAnchor),
            appRow.widthAnchor.constraint(equalTo: exclusionsStack.widthAnchor),
        ])

        return exclusionsStack
    }

    private func makeRecentActionsCard() -> NSView {
        recentActionsValue.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        recentActionsValue.textColor = .labelColor
        configureWrappingLabel(recentActionsValue, maximumNumberOfLines: 15)
        recentActionsValue.translatesAutoresizingMaskIntoConstraints = false
        recentActionsValue.setContentHuggingPriority(.defaultLow, for: .vertical)

        let rows = createRowsStack(views: [recentActionsValue])
        let card = makeCard(containing: rows)
        card.setContentHuggingPriority(.defaultHigh, for: .vertical)

        // Clear button (outside the card)
        configureButton(clearLogsButton, action: #selector(clearLogsClicked))

        let logButtonsRow = NSStackView(views: [clearLogsButton])
        logButtonsRow.orientation = .horizontal
        logButtonsRow.alignment = .centerY
        logButtonsRow.translatesAutoresizingMaskIntoConstraints = false
        logButtonsRow.setContentHuggingPriority(.defaultHigh, for: .vertical)

        let logsStack = makePageStack(card: card, bottomRow: logButtonsRow)

        NSLayoutConstraint.activate([
            recentActionsValue.heightAnchor.constraint(greaterThanOrEqualToConstant: 180),
            recentActionsValue.widthAnchor.constraint(equalTo: rows.widthAnchor),
            card.widthAnchor.constraint(equalTo: logsStack.widthAnchor),
            logButtonsRow.widthAnchor.constraint(equalTo: logsStack.widthAnchor),
        ])
        return logsStack
    }

    private func makeTabItem(tab: ControlPanelTab, view: NSView) -> NSTabViewItem {
        let item = NSTabViewItem(identifier: tab.identifier)
        let container = NSView()
        container.autoresizingMask = [.width, .height]
        container.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 0),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 0),
            view.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 0),
        ])
        item.view = container
        return item
    }

    private func refreshTabLayout() {
        tabView.layoutSubtreeIfNeeded()
        tabView.selectedTabViewItem?.view?.layoutSubtreeIfNeeded()
        window.contentView?.layoutSubtreeIfNeeded()
    }

    private func updateTabLabels() {
        guard tabView.tabViewItems.count >= ControlPanelTab.allCases.count else { return }
        for tab in ControlPanelTab.allCases {
            let title = localized(tab.localizationKey)
            tabView.tabViewItems[tab.rawValue].label = title
            tabSegmentedControl.setLabel(title, forSegment: tab.rawValue)
        }
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

    private func configureExcludedAppsTable() {
        if excludedBundleIDTable.tableColumns.isEmpty {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("bundleID"))
            column.resizingMask = .autoresizingMask
            excludedBundleIDTable.addTableColumn(column)
        }
        excludedBundleIDTable.headerView = nil
        excludedBundleIDTable.delegate = self
        excludedBundleIDTable.dataSource = self
        excludedBundleIDTable.rowHeight = 24
        excludedBundleIDTable.intercellSpacing = NSSize(width: 0, height: 0)
        excludedBundleIDTable.selectionHighlightStyle = .regular
        if #available(macOS 11.0, *) {
            excludedBundleIDTable.style = .plain
        }
        excludedBundleIDTable.usesAlternatingRowBackgroundColors = false
        excludedBundleIDTable.backgroundColor = .clear

        excludedBundleIDScrollView.documentView = excludedBundleIDTable
        excludedBundleIDScrollView.hasVerticalScroller = true
        excludedBundleIDScrollView.borderType = .noBorder
        excludedBundleIDScrollView.drawsBackground = false
        excludedBundleIDScrollView.translatesAutoresizingMaskIntoConstraints = false
    }

    func selectedExcludedBundleID() -> String? {
        let selectedRow = excludedBundleIDTable.selectedRow
        guard excludedBundleIDsSnapshot.indices.contains(selectedRow) else { return nil }
        return excludedBundleIDsSnapshot[selectedRow]
    }

    func updateExcludedAppSelection() {
        let selectedBundleID = selectedExcludedBundleID()
        removeExcludedButton.isEnabled =
            selectedBundleID.map { !defaultExcludedBundleIDs.contains($0) } ?? false
    }

    private func makeCard(
        containing view: NSView,
        top: CGFloat = ControlPanelLayout.cardVerticalInset,
        bottom: CGFloat = ControlPanelLayout.cardVerticalInset
    ) -> NSBox {
        let card = makeCard()
        card.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(
                equalTo: card.leadingAnchor, constant: ControlPanelLayout.cardHorizontalInset),
            view.trailingAnchor.constraint(
                equalTo: card.trailingAnchor, constant: -ControlPanelLayout.cardHorizontalInset),
            view.topAnchor.constraint(equalTo: card.topAnchor, constant: top),
            view.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -bottom),
        ])
        return card
    }

    private func makeCard() -> NSBox {
        let card = NSBox()
        card.boxType = .custom
        card.cornerRadius = ControlPanelLayout.cornerRadius
        card.borderWidth = 1.0
        card.borderColor = NSColor.separatorColor.withAlphaComponent(0.2)
        card.fillColor = NSColor.controlBackgroundColor.withAlphaComponent(0.6)
        card.translatesAutoresizingMaskIntoConstraints = false
        card.widthAnchor.constraint(greaterThanOrEqualToConstant: ControlPanelLayout.cardMinWidth)
            .isActive = true
        return card
    }

    private func makePageStack(card: NSView, bottomRow: NSView) -> NSStackView {
        let vSpacer = NSView()
        vSpacer.translatesAutoresizingMaskIntoConstraints = false
        vSpacer.setContentHuggingPriority(.required, for: .vertical)
        vSpacer.setContentCompressionResistancePriority(.required, for: .vertical)

        card.setContentHuggingPriority(.defaultLow, for: .vertical)
        card.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        bottomRow.setContentHuggingPriority(.required, for: .vertical)
        bottomRow.setContentCompressionResistancePriority(.required, for: .vertical)

        let stack = NSStackView(views: [card, vSpacer, bottomRow])
        stack.orientation = .vertical
        stack.spacing = 0
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.setCustomSpacing(ControlPanelLayout.cardButtonSpacing, after: card)
        stack.setCustomSpacing(0, after: vSpacer)

        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: ControlPanelLayout.pageCardHeight),
            vSpacer.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])

        return stack
    }

    private func createRow(label: NSTextField, value: NSView) -> NSStackView {
        configureRowLabel(label)

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let row = NSStackView(views: [label, spacer, value])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = ControlPanelLayout.rowSpacing
        row.translatesAutoresizingMaskIntoConstraints = false
        return row
    }

    private func configureButton(
        _ button: NSButton,
        action: Selector,
        minWidth: CGFloat? = nil
    ) {
        button.bezelStyle = .rounded
        button.target = self
        button.action = action
        button.heightAnchor.constraint(equalToConstant: ControlPanelLayout.buttonHeight).isActive =
            true
        if let minWidth {
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: minWidth).isActive = true
        }
    }

    private func configureRowLabel(_ label: NSTextField) {
        label.font = .systemFont(ofSize: 13)
        label.textColor = .labelColor
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    private func createRowsStack(views: [NSView]) -> NSStackView {
        let rows = NSStackView(views: views)
        rows.orientation = .vertical
        rows.spacing = 12
        rows.alignment = .leading
        rows.translatesAutoresizingMaskIntoConstraints = false
        for view in views {
            view.widthAnchor.constraint(equalTo: rows.widthAnchor).isActive = true
        }
        return rows
    }

    private func localizedAction(_ record: RecentActionRecord) -> String {
        switch record.action {
        case .skipped:
            return localized("recent.action.skipped")
        case .unminimized:
            return localized("recent.action.unminimized")
        case .reopened:
            return localized("recent.action.reopened")
        case .cmdN:
            return localized("recent.action.cmdN")
        case .failed:
            return localized("recent.action.failed")
        }
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
        label.preferredMaxLayoutWidth = 440
    }
}

extension ControlPanelDelegate: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        excludedBundleIDsSnapshot.count
    }

    func tableView(
        _ tableView: NSTableView,
        viewFor tableColumn: NSTableColumn?,
        row: Int
    ) -> NSView? {
        guard excludedBundleIDsSnapshot.indices.contains(row) else { return nil }

        let bundleID = excludedBundleIDsSnapshot[row]
        let identifier = NSUserInterfaceItemIdentifier("ExcludedBundleIDCell")
        let cellView =
            tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView
            ?? NSTableCellView()
        cellView.identifier = identifier

        let textField: NSTextField
        if let existingTextField = cellView.textField {
            textField = existingTextField
        } else {
            textField = NSTextField(labelWithString: "")
            textField.font = .systemFont(ofSize: 12)
            textField.alignment = .left
            textField.lineBreakMode = .byTruncatingMiddle
            textField.isEditable = false
            textField.isBordered = false
            textField.drawsBackground = false
            textField.translatesAutoresizingMaskIntoConstraints = false
            cellView.addSubview(textField)
            cellView.textField = textField

            NSLayoutConstraint.activate([
                textField.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
                textField.leadingAnchor.constraint(
                    equalTo: cellView.leadingAnchor,
                    constant: ControlPanelLayout.selectionTextHorizontalInset
                ),
                textField.trailingAnchor.constraint(
                    equalTo: cellView.trailingAnchor,
                    constant: -ControlPanelLayout.selectionTextHorizontalInset
                ),
            ])
        }

        textField.textColor =
            defaultExcludedBundleIDs.contains(bundleID) ? .secondaryLabelColor : .labelColor
        textField.stringValue = bundleID
        return cellView
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        updateExcludedAppSelection()
    }

    func tableView(
        _ tableView: NSTableView,
        rowViewForRow row: Int
    ) -> NSTableRowView? {
        RoundedSelectionTableRowView()
    }
}
