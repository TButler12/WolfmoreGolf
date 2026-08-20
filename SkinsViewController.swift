//
//  SkinsViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 4/3/26.
//

import UIKit

final class SkinsViewController: UIViewController {

    var gameData: GameData?

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let wolfGreen = UIColor(red: 0.10, green: 0.33, blue: 0.18, alpha: 1.0)
    private let goldColor = UIColor(red: 0.78, green: 0.635, blue: 0.188, alpha: 1.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Skins"
        view.backgroundColor = .systemBackground
        setupUI()
        loadGame()
        refresh()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadGame()
        refresh()
    }

    // MARK: - Setup

    private func setupUI() {
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(settingsTapped))
        ]

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32)
        ])
    }

    // MARK: - Shared card helpers

    private func wrapInCard(_ content: UIView) -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 12
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14)
        ])
        return card
    }

    private func makeInfoGrid(_ pairs: [(label: String, value: String)]) -> UIView {
        let outerStack = UIStackView()
        outerStack.axis = .vertical
        outerStack.spacing = 12

        var index = 0
        while index < pairs.count {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 8

            let left = makeInfoCell(label: pairs[index].label, value: pairs[index].value)
            rowStack.addArrangedSubview(left)

            if index + 1 < pairs.count {
                let right = makeInfoCell(label: pairs[index + 1].label, value: pairs[index + 1].value)
                rowStack.addArrangedSubview(right)
            }

            outerStack.addArrangedSubview(rowStack)
            index += 2
        }

        return outerStack
    }

    private func makeInfoCell(label: String, value: String) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 2

        let labelView = UILabel()
        labelView.text = label.uppercased()
        labelView.font = .systemFont(ofSize: 10, weight: .semibold)
        labelView.textColor = .secondaryLabel

        let valueView = UILabel()
        valueView.text = value
        valueView.font = .systemFont(ofSize: 16, weight: .bold)
        valueView.textColor = .label

        container.addArrangedSubview(labelView)
        container.addArrangedSubview(valueView)

        return container
    }

    private func makeSectionHeader(_ title: String) -> UILabel {
        let label = UILabel()
        label.text = title.uppercased()
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }

    // MARK: - Data loading

    func presentSettingsFromContainer() {
        loadGame()
        settingsTapped()
    }

    private func loadGame() {
        // Always pull the freshest game so HC changes and committed scores are reflected.
        if let live = GameManager.shared.currentGame {
            gameData = live
        }

        guard var data = gameData else { return }

        if data.skinsState == nil {
            data.skinsState = SkinsEngine.makeDefaultState()
            GameManager.shared.currentGame = data
            GameManager.shared.saveCurrent()
        }

        gameData = data
    }

    // MARK: - Refresh

    private func refresh() {
        guard var data = gameData,
              var skins = data.skinsState else {
            contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            let label = UILabel()
            label.text = "No skins game available."
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            contentStack.addArrangedSubview(label)
            return
        }

        SkinsEngine.recalculate(state: &skins, gameData: data)
        data.skinsState = skins

        gameData = data
        GameManager.shared.currentGame = data
        GameManager.shared.saveCurrent()

        buildSkinsUI(state: skins, data: data)
    }

    private func buildSkinsUI(state: SkinsState, data: GameData) {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // MARK: Settings card
        let settings = state.settings
        let modeText = (settings.mode == .automatic) ? "Automatic" : "Manual"
        let scoringText = (settings.scoringMode == .gross) ? "Gross" : "Net"
        let carryText = settings.carryoversEnabled ? "On" : "Off"
        let skinValueText = formatMoney(settings.skinValue)

        var gridPairs: [(label: String, value: String)] = [
            (label: "MODE", value: modeText),
            (label: "SCORING", value: scoringText),
            (label: "CARRYOVERS", value: carryText),
            (label: "SKIN VALUE", value: "$\(skinValueText)")
        ]

        if let pot = settings.potAmount, pot > 0 {
            gridPairs.append((label: "POT", value: "$\(formatMoneyFull(pot))"))
        }

        let settingsGrid = makeInfoGrid(gridPairs)
        contentStack.addArrangedSubview(wrapInCard(settingsGrid))

        // MARK: TOTALS section
        let totalsHeader = makeSectionHeader("TOTALS")
        let totalsHeaderWrapper = UIView()
        totalsHeader.translatesAutoresizingMaskIntoConstraints = false
        totalsHeaderWrapper.addSubview(totalsHeader)
        NSLayoutConstraint.activate([
            totalsHeader.topAnchor.constraint(equalTo: totalsHeaderWrapper.topAnchor, constant: 4),
            totalsHeader.bottomAnchor.constraint(equalTo: totalsHeaderWrapper.bottomAnchor),
            totalsHeader.leadingAnchor.constraint(equalTo: totalsHeaderWrapper.leadingAnchor),
            totalsHeader.trailingAnchor.constraint(equalTo: totalsHeaderWrapper.trailingAnchor)
        ])
        contentStack.addArrangedSubview(totalsHeaderWrapper)

        let activeIncludedIndexes = (0..<min(data.playerActivated.count, state.playerIncluded.count)).filter {
            data.playerActivated[$0] && state.playerIncluded[$0]
        }

        let totalsInner = UIStackView()
        totalsInner.axis = .vertical
        totalsInner.spacing = 8

        // Column headers
        let headerRow = makeTotalsRow(
            name: "PLAYER",
            nameFont: .systemFont(ofSize: 11, weight: .semibold),
            nameColor: .secondaryLabel,
            skinsText: "SKINS",
            skinsFont: .systemFont(ofSize: 11, weight: .semibold),
            skinsColor: .secondaryLabel,
            moneyText: "MONEY",
            moneyFont: .systemFont(ofSize: 11, weight: .semibold),
            moneyColor: .secondaryLabel
        )
        totalsInner.addArrangedSubview(headerRow)

        // Separator after headers
        let headerSep = UIView()
        headerSep.backgroundColor = .separator
        headerSep.translatesAutoresizingMaskIntoConstraints = false
        totalsInner.addArrangedSubview(headerSep)
        headerSep.heightAnchor.constraint(equalToConstant: 0.5).isActive = true

        if activeIncludedIndexes.isEmpty {
            let noPlayers = UILabel()
            noPlayers.text = "No players included."
            noPlayers.font = .systemFont(ofSize: 14, weight: .regular)
            noPlayers.textColor = .secondaryLabel
            noPlayers.textAlignment = .center
            totalsInner.addArrangedSubview(noPlayers)
        } else {
            for (i, idx) in activeIncludedIndexes.enumerated() {
                let name = displayName(for: idx, data: data)
                let skinsCount = state.skinsWonByPlayer.indices.contains(idx) ? state.skinsWonByPlayer[idx] : 0
                let moneyVal = state.moneyWonByPlayer.indices.contains(idx) ? state.moneyWonByPlayer[idx] : 0.0

                let (moneyText, moneyColor) = formatMoneyDisplay(moneyVal, potAmount: settings.potAmount)

                let playerRow = makeTotalsRow(
                    name: name,
                    nameFont: .systemFont(ofSize: 15, weight: .medium),
                    nameColor: .label,
                    skinsText: "\(skinsCount)",
                    skinsFont: .systemFont(ofSize: 15, weight: .regular),
                    skinsColor: .secondaryLabel,
                    moneyText: moneyText,
                    moneyFont: .systemFont(ofSize: 15, weight: .semibold),
                    moneyColor: moneyColor
                )
                totalsInner.addArrangedSubview(playerRow)

                if i < activeIncludedIndexes.count - 1 {
                    let rowSep = UIView()
                    rowSep.backgroundColor = .separator
                    rowSep.translatesAutoresizingMaskIntoConstraints = false
                    totalsInner.addArrangedSubview(rowSep)
                    rowSep.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
                }
            }
        }

        contentStack.addArrangedSubview(wrapInCard(totalsInner))

        // MARK: BY HOLE section
        let byHoleHeader = makeSectionHeader("BY HOLE")
        let byHoleHeaderWrapper = UIView()
        byHoleHeader.translatesAutoresizingMaskIntoConstraints = false
        byHoleHeaderWrapper.addSubview(byHoleHeader)
        NSLayoutConstraint.activate([
            byHoleHeader.topAnchor.constraint(equalTo: byHoleHeaderWrapper.topAnchor, constant: 4),
            byHoleHeader.bottomAnchor.constraint(equalTo: byHoleHeaderWrapper.bottomAnchor),
            byHoleHeader.leadingAnchor.constraint(equalTo: byHoleHeaderWrapper.leadingAnchor),
            byHoleHeader.trailingAnchor.constraint(equalTo: byHoleHeaderWrapper.trailingAnchor)
        ])
        contentStack.addArrangedSubview(byHoleHeaderWrapper)

        // Horizontal chip scroll view
        let chipScrollView = UIScrollView()
        chipScrollView.showsHorizontalScrollIndicator = false
        chipScrollView.translatesAutoresizingMaskIntoConstraints = false

        let chipStack = UIStackView()
        chipStack.axis = .horizontal
        chipStack.spacing = 8
        chipStack.translatesAutoresizingMaskIntoConstraints = false
        chipScrollView.addSubview(chipStack)

        NSLayoutConstraint.activate([
            chipStack.topAnchor.constraint(equalTo: chipScrollView.contentLayoutGuide.topAnchor, constant: 8),
            chipStack.bottomAnchor.constraint(equalTo: chipScrollView.contentLayoutGuide.bottomAnchor, constant: -8),
            chipStack.leadingAnchor.constraint(equalTo: chipScrollView.contentLayoutGuide.leadingAnchor, constant: 8),
            chipStack.trailingAnchor.constraint(equalTo: chipScrollView.contentLayoutGuide.trailingAnchor, constant: -8),
            chipStack.heightAnchor.constraint(equalTo: chipScrollView.frameLayoutGuide.heightAnchor, constant: -16)
        ])

        for holeIndex in 0..<18 {
            let chip = makeHoleChip(holeIndex: holeIndex, state: state, data: data)
            chipStack.addArrangedSubview(chip)
            chip.widthAnchor.constraint(equalToConstant: 38).isActive = true
            chip.heightAnchor.constraint(equalToConstant: 38).isActive = true
        }

        chipScrollView.heightAnchor.constraint(equalToConstant: 54).isActive = true

        let chipCardInner = UIStackView()
        chipCardInner.axis = .vertical
        chipCardInner.spacing = 8
        chipCardInner.addArrangedSubview(chipScrollView)

        let hintLabel = UILabel()
        hintLabel.text = "Gold chips mark holes with a completed skin. Scroll for holes 13–18."
        hintLabel.font = .systemFont(ofSize: 12, weight: .regular)
        hintLabel.textColor = .secondaryLabel
        hintLabel.numberOfLines = 0
        chipCardInner.addArrangedSubview(hintLabel)

        contentStack.addArrangedSubview(wrapInCard(chipCardInner))
    }

    // MARK: - Totals row builder

    private func makeTotalsRow(
        name: String, nameFont: UIFont, nameColor: UIColor,
        skinsText: String, skinsFont: UIFont, skinsColor: UIColor,
        moneyText: String, moneyFont: UIFont, moneyColor: UIColor
    ) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8

        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = nameFont
        nameLabel.textColor = nameColor
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let skinsLabel = UILabel()
        skinsLabel.text = skinsText
        skinsLabel.font = skinsFont
        skinsLabel.textColor = skinsColor
        skinsLabel.textAlignment = .center
        skinsLabel.setContentHuggingPriority(.required, for: .horizontal)
        skinsLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let moneyLabel = UILabel()
        moneyLabel.text = moneyText
        moneyLabel.font = moneyFont
        moneyLabel.textColor = moneyColor
        moneyLabel.textAlignment = .right
        moneyLabel.setContentHuggingPriority(.required, for: .horizontal)
        moneyLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        row.addArrangedSubview(nameLabel)
        row.addArrangedSubview(skinsLabel)
        row.addArrangedSubview(moneyLabel)

        return row
    }

    // MARK: - Hole chip builder

    private func makeHoleChip(holeIndex: Int, state: SkinsState, data: GameData) -> UIView {
        let chip = UIView()
        chip.layer.cornerRadius = 19
        chip.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "\(holeIndex + 1)"
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        chip.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: chip.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: chip.centerYAnchor)
        ])

        // Find result for this hole
        let result = state.resultsByHole.first { $0.holeIndex == holeIndex }
        let isCommitted = data.holeCommitted[safe: holeIndex] == true

        if let result = result, !result.winningPlayerIndexes.isEmpty {
            // Gold: hole has a winner
            chip.backgroundColor = goldColor
            label.textColor = .white
        } else if let result = result, result.carriedToNextHole {
            // Blue carryover
            chip.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.25)
            label.textColor = .systemBlue
        } else if isCommitted {
            // Played, no skin
            chip.backgroundColor = .systemGray5
            label.textColor = .secondaryLabel
        } else {
            // Not yet played
            chip.backgroundColor = .systemGray6
            label.textColor = .secondaryLabel
        }

        return chip
    }

    // MARK: - Money formatting

    private func formatMoney(_ value: Double) -> String {
        if value == floor(value) {
            return String(Int(value))
        } else {
            return String(format: "%.2f", value)
        }
    }

    private func formatMoneyFull(_ value: Double) -> String {
        return String(format: "%.2f", value)
    }

    private func formatMoneyDisplay(_ value: Double, potAmount: Double?) -> (String, UIColor) {
        if let pot = potAmount, pot > 0 {
            if value > 0 {
                let formatted = String(format: "%.2f", value)
                return ("+$\(formatted)", .systemGreen)
            } else {
                return ("$0", .secondaryLabel)
            }
        } else {
            if value == 0 {
                return ("$0", .secondaryLabel)
            } else if value > 0 {
                let str = value == floor(value) ? "$\(Int(value))" : String(format: "$%.2f", value)
                return ("+\(str)", .systemGreen)
            } else {
                let abs = Swift.abs(value)
                let str = abs == floor(abs) ? "$\(Int(abs))" : String(format: "$%.2f", abs)
                return ("-\(str)", .systemRed)
            }
        }
    }

    // MARK: - Settings actions

    @objc private func settingsTapped() {
        guard var data = gameData,
              var skins = data.skinsState else { return }

        let ac = UIAlertController(title: "Skins Settings", message: nil, preferredStyle: .actionSheet)

        // SKIN VALUE
        ac.addAction(UIAlertAction(title: "Set Skin Value ($\(skins.settings.skinValue))", style: .default) { _ in
            let prompt = UIAlertController(title: "Skin Value", message: "Enter amount per skin", preferredStyle: .alert)

            prompt.addTextField {
                $0.keyboardType = .decimalPad
                $0.text = String(format: "%.2f", skins.settings.skinValue)
            }

            prompt.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            prompt.addAction(UIAlertAction(title: "Save", style: .default) { _ in
                if let text = prompt.textFields?.first?.text,
                   let value = Double(text) {
                    skins.settings.skinValue = value
                    self.saveUpdatedState(skins, into: data)
                }
            })

            self.present(prompt, animated: true)
        })

        // CARRYOVERS
        ac.addAction(UIAlertAction(
            title: "Carryovers: \(skins.settings.carryoversEnabled ? "On" : "Off")",
            style: .default
        ) { _ in
            skins.settings.carryoversEnabled.toggle()
            self.saveUpdatedState(skins, into: data)
        })

        // PLAYER INCLUDE / EXCLUDE
        ac.addAction(UIAlertAction(title: "Edit Players In", style: .default) { _ in
            self.showPlayersInPicker()
        })
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: 80, width: 1, height: 1)
        }

        present(ac, animated: true)
    }

    private func showPlayersInPicker() {
        guard let data = gameData,
              let skins = data.skinsState else { return }

        let activeIndexes = data.playerActivated.enumerated().compactMap { $0.element ? $0.offset : nil }

        let ac = UIAlertController(
            title: "Players In",
            message: "Tap to add or remove players",
            preferredStyle: .actionSheet
        )

        for idx in activeIndexes {
            let name = displayName(for: idx, data: data)
            let included = skins.playerIncluded[idx]
            let title = "\(included ? "✓ " : "")\(name)"

            ac.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                guard let self,
                      var updatedData = self.gameData,
                      var updatedSkins = updatedData.skinsState else { return }

                updatedSkins.playerIncluded[idx].toggle()
                updatedData.skinsState = updatedSkins

                self.gameData = updatedData
                GameManager.shared.currentGame = updatedData
                GameManager.shared.saveCurrent()

                self.refresh()

                DispatchQueue.main.async {
                    self.showPlayersInPicker()
                }
            })
        }

        ac.addAction(UIAlertAction(title: "Done", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: 90, width: 1, height: 1)
        }

        present(ac, animated: true)
    }

    private func saveUpdatedState(_ state: SkinsState, into data: GameData) {
        var updated = data
        updated.skinsState = state

        gameData = updated
        GameManager.shared.currentGame = updated
        GameManager.shared.saveCurrent()

        refresh()
    }

    private func displayName(for index: Int, data: GameData) -> String {
        guard index < data.playerNames.count else { return "Player \(index + 1)" }
        let name = data.playerNames[index].trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Player \(index + 1)" : name
    }
}
