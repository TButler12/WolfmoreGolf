//
//  SkinsSettingsViewController.swift
//  WolfmoreGolf
//

import UIKit

final class SkinsSettingsViewController: UIViewController {

    var gameData: GameData?

    private let skinValueLabel = UILabel()
    private let skinValueField = UITextField()
    private let carryoversLabel = UILabel()
    private let carryoversSegment = UISegmentedControl(items: ["On", "Off"])
    private let editPlayersButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Skins Settings"
        view.backgroundColor = .systemBackground

        if gameData == nil {
            gameData = GameManager.shared.currentGame
        }
        ensureSkinsState()

        setupUI()
        loadSettings()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    // MARK: - Setup

    private func ensureSkinsState() {
        guard var data = gameData else { return }
        if data.skinsState == nil {
            data.skinsState = SkinsEngine.makeDefaultState()
            gameData = data
            GameManager.shared.currentGame = data
            GameManager.shared.saveCurrent()
        }
    }

    private func setupUI() {
        configureLabel(skinValueLabel, text: "Skin Value")
        configureLabel(carryoversLabel, text: "Carryovers")

        skinValueField.borderStyle = .roundedRect
        skinValueField.keyboardType = .decimalPad
        skinValueField.textAlignment = .center
        skinValueField.font = UIFont.preferredFont(forTextStyle: .body)
        skinValueField.placeholder = "0.00"
        skinValueField.delegate = self

        let bar = UIToolbar()
        bar.sizeToFit()
        bar.items = [.flexibleSpace(), UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))]
        skinValueField.inputAccessoryView = bar

        editPlayersButton.configuration = {
            var cfg = UIButton.Configuration.filled()
            cfg.title = "Edit Players In"
            cfg.baseBackgroundColor = .systemGray5
            cfg.baseForegroundColor = .label
            cfg.cornerStyle = .capsule
            cfg.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)
            return cfg
        }()
        editPlayersButton.addTarget(self, action: #selector(editPlayersTapped), for: .touchUpInside)

        saveButton.configuration = wmStyledButton(title: "Save", style: .primary)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        let views: [UIView] = [skinValueLabel, skinValueField,
                               carryoversLabel, carryoversSegment, editPlayersButton, saveButton]
        views.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        let guide = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            skinValueLabel.topAnchor.constraint(equalTo: guide.topAnchor, constant: 32),
            skinValueLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            skinValueField.topAnchor.constraint(equalTo: skinValueLabel.bottomAnchor, constant: 8),
            skinValueField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            skinValueField.widthAnchor.constraint(equalToConstant: 120),
            skinValueField.heightAnchor.constraint(equalToConstant: 34),

            carryoversLabel.topAnchor.constraint(equalTo: skinValueField.bottomAnchor, constant: 28),
            carryoversLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            carryoversSegment.topAnchor.constraint(equalTo: carryoversLabel.bottomAnchor, constant: 8),
            carryoversSegment.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            carryoversSegment.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),

            editPlayersButton.topAnchor.constraint(equalTo: carryoversSegment.bottomAnchor, constant: 36),
            editPlayersButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            saveButton.topAnchor.constraint(equalTo: editPlayersButton.bottomAnchor, constant: 24),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    private func configureLabel(_ label: UILabel, text: String) {
        label.text = text
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.textColor = .label
        label.textAlignment = .center
    }

    // MARK: - Data

    private func loadSettings() {
        guard let skins = gameData?.skinsState else { return }
        skinValueField.text = String(format: "%.2f", skins.settings.skinValue)
        carryoversSegment.selectedSegmentIndex = skins.settings.carryoversEnabled ? 0 : 1
    }

    @objc private func saveTapped() {
        dismissKeyboard()
        guard var data = gameData, var skins = data.skinsState else { return }

        skins.settings.mode = .automatic
        if let text = skinValueField.text, let value = Double(text) {
            skins.settings.skinValue = max(0, value)
        }
        skins.settings.carryoversEnabled = (carryoversSegment.selectedSegmentIndex == 0)

        data.skinsState = skins
        gameData = data
        GameManager.shared.currentGame = data
        GameManager.shared.saveCurrent()

        navigationController?.popViewController(animated: true)
    }

    // MARK: - Edit Players

    @objc private func editPlayersTapped() {
        guard let data = gameData, let skins = data.skinsState else { return }
        showPlayersInPicker(data: data, skins: skins)
    }

    private func showPlayersInPicker(data: GameData, skins: SkinsState) {
        let activeIndexes = data.playerActivated.enumerated().compactMap { $0.element ? $0.offset : nil }

        let ac = UIAlertController(title: "Players In", message: "Tap to add or remove players", preferredStyle: .actionSheet)

        for idx in activeIndexes {
            let name = playerName(for: idx, in: data)
            let title = "\(skins.playerIncluded[idx] ? "✓ " : "")\(name)"
            ac.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                guard let self, var d = self.gameData, var s = d.skinsState else { return }
                s.playerIncluded[idx].toggle()
                d.skinsState = s
                self.gameData = d
                GameManager.shared.currentGame = d
                GameManager.shared.saveCurrent()
                DispatchQueue.main.async { self.showPlayersInPicker(data: d, skins: s) }
            })
        }

        ac.addAction(UIAlertAction(title: "Done", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.sourceView = editPlayersButton
            pop.sourceRect = editPlayersButton.bounds
        }
        present(ac, animated: true)
    }

    private func playerName(for index: Int, in data: GameData) -> String {
        guard index < data.playerNames.count else { return "Player \(index + 1)" }
        let name = data.playerNames[index].trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Player \(index + 1)" : name
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }
}

extension SkinsSettingsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
