//
//  SkinsViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 4/3/26.
//

import UIKit

final class SkinsViewController: UIViewController {

    var gameData: GameData?

    private let textView = UITextView()

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

    private func setupUI() {
        navigationItem.rightBarButtonItems = [
           // UIBarButtonItem(title: "Manual", style: .plain, target: self, action: #selector(manualTapped)),
            UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(settingsTapped))
        ]

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.font = .monospacedSystemFont(ofSize: 18, weight: .medium)
        textView.textColor = .label
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 10, bottom: 24, right: 10)

        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    func presentSettingsFromContainer() {
        loadGame()
        settingsTapped()
    }
    private func loadGame() {
        if gameData == nil {
            gameData = GameManager.shared.currentGame
        }

        guard var data = gameData else { return }

        if data.skinsState == nil {
            data.skinsState = SkinsEngine.makeDefaultState()
            GameManager.shared.currentGame = data
            GameManager.shared.saveCurrent()
        }

        gameData = data
    }

    private func refresh() {
        guard var data = gameData,
              var skins = data.skinsState else {
            textView.text = "No skins game available."
            return
        }

        SkinsEngine.recalculate(state: &skins, gameData: data)
        data.skinsState = skins

        gameData = data
        GameManager.shared.currentGame = data
        GameManager.shared.saveCurrent()

        textView.attributedText = buildStyledSummary(
            SkinsEngine.summaryText(state: skins, gameData: data)
        )
    }
    private func buildStyledSummary(_ text: String) -> NSAttributedString {
        let result = NSMutableAttributedString()

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 4
        paragraph.paragraphSpacing = 10

        let baseFont = UIFont.monospacedSystemFont(ofSize: 18, weight: .medium)
        let boldFont = UIFont.monospacedSystemFont(ofSize: 20, weight: .bold)
        let sectionFont = UIFont.monospacedSystemFont(ofSize: 22, weight: .heavy)

        let lines = text.components(separatedBy: "\n")

        for line in lines {

            let attr: [NSAttributedString.Key: Any]

            if line.contains("SKINS") || line.contains("TOTALS") || line.contains("BY HOLE") {
                attr = [
                    .font: sectionFont,
                    .paragraphStyle: paragraph
                ]
            }
            else if line.contains(":") {
                attr = [
                    .font: boldFont,
                    .paragraphStyle: paragraph
                ]
            }
            else {
                attr = [
                    .font: baseFont,
                    .paragraphStyle: paragraph
                ]
            }

            result.append(NSAttributedString(string: line + "\n", attributes: attr))
        }

        return result
    }
    @objc private func settingsTapped() {
        guard var data = gameData,
              var skins = data.skinsState else { return }

        let ac = UIAlertController(title: "Skins Settings", message: nil, preferredStyle: .actionSheet)

        // MODE
        ac.addAction(UIAlertAction(
            title: "Mode: \(skins.settings.mode == .automatic ? "Automatic" : "Manual")",
            style: .default
        ) { _ in
            skins.settings.mode = (skins.settings.mode == .automatic) ? .manual : .automatic
            self.saveUpdatedState(skins, into: data)
        })

        // SKIN VALUE 💰
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

        // CARRYOVERS 🔁
        ac.addAction(UIAlertAction(
            title: "Carryovers: \(skins.settings.carryoversEnabled ? "On" : "Off")",
            style: .default
        ) { _ in
            skins.settings.carryoversEnabled.toggle()
            self.saveUpdatedState(skins, into: data)
        })

        // PLAYER INCLUDE / EXCLUDE 👥
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
    @objc private func manualTapped() {
        guard var data = gameData,
              var skins = data.skinsState else { return }

        let hole = max(0, min(17, data.hole))
        let activeIndexes = data.playerActivated.enumerated().compactMap { $0.element ? $0.offset : nil }

        let ac = UIAlertController(
            title: "Manual Skins Result",
            message: "Hole \(hole + 1)",
            preferredStyle: .actionSheet
        )

        for idx in activeIndexes {
            let name = displayName(for: idx, data: data)
            ac.addAction(UIAlertAction(title: "\(name) wins", style: .default) { _ in
                skins.manualOverridesByHole[hole] = ManualSkinsHoleDecision(
                    winnerIndexes: [idx],
                    shouldCarryOver: false,
                    awardedSkinCount: nil
                )
                self.saveUpdatedState(skins, into: data)
            })
        }

        ac.addAction(UIAlertAction(title: "Carryover", style: .default) { _ in
            skins.manualOverridesByHole[hole] = ManualSkinsHoleDecision(
                winnerIndexes: [],
                shouldCarryOver: true,
                awardedSkinCount: nil
            )
            self.saveUpdatedState(skins, into: data)
        })

        ac.addAction(UIAlertAction(title: "No Skin", style: .default) { _ in
            skins.manualOverridesByHole[hole] = ManualSkinsHoleDecision(
                winnerIndexes: [],
                shouldCarryOver: false,
                awardedSkinCount: 0
            )
            self.saveUpdatedState(skins, into: data)
        })

        ac.addAction(UIAlertAction(title: "Clear Manual Override", style: .destructive) { _ in
            skins.manualOverridesByHole[hole] = nil
            self.saveUpdatedState(skins, into: data)
        })

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.barButtonItem = navigationItem.rightBarButtonItems?.first
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
