import UIKit

final class TournamentSettingsViewController: UIViewController {

    private let stakeLabel       = UILabel()
    private let stakeField       = UITextField()
    private let potAmountLabel   = UILabel()
    private let potAmountField   = UITextField()
    private let potNoteLabel     = UILabel()
    private let carryoversLabel  = UILabel()
    private let carryoversSegment = UISegmentedControl(items: ["On", "Off"])
    private let saveButton       = UIButton(type: .system)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edit Tournament Settings"
        view.backgroundColor = .systemBackground
        setupUI()
        loadSettings()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    // MARK: - UI

    private func setupUI() {
        let bar = UIToolbar()
        bar.sizeToFit()
        bar.items = [
            .flexibleSpace(),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
        ]

        configureLabel(stakeLabel,      text: "Stake Per Skin ($)")
        configureLabel(potAmountLabel,  text: "Skins Pot ($)  —  optional")
        configureLabel(carryoversLabel, text: "Carryovers")

        stakeField.borderStyle   = .roundedRect
        stakeField.keyboardType  = .decimalPad
        stakeField.textAlignment = .center
        stakeField.font          = UIFont.preferredFont(forTextStyle: .body)
        stakeField.placeholder   = "0.00"
        stakeField.inputAccessoryView = bar

        potAmountField.borderStyle   = .roundedRect
        potAmountField.keyboardType  = .decimalPad
        potAmountField.textAlignment = .center
        potAmountField.font          = UIFont.preferredFont(forTextStyle: .body)
        potAmountField.placeholder   = "e.g. 100"
        potAmountField.inputAccessoryView = bar
        potAmountField.addTarget(self, action: #selector(potFieldChanged), for: .editingChanged)

        potNoteLabel.text          = "If set, total pot is split by skins won. Overrides per-skin stake."
        potNoteLabel.font          = UIFont.preferredFont(forTextStyle: .caption1)
        potNoteLabel.textColor     = .secondaryLabel
        potNoteLabel.numberOfLines = 0
        potNoteLabel.textAlignment = .center

        saveButton.configuration = wmStyledButton(title: "Save", style: .primary)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        let views: [UIView] = [
            stakeLabel, stakeField,
            potAmountLabel, potAmountField, potNoteLabel,
            carryoversLabel, carryoversSegment,
            saveButton
        ]
        views.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            stakeLabel.topAnchor.constraint(equalTo: guide.topAnchor, constant: 32),
            stakeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            stakeField.topAnchor.constraint(equalTo: stakeLabel.bottomAnchor, constant: 8),
            stakeField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stakeField.widthAnchor.constraint(equalToConstant: 120),
            stakeField.heightAnchor.constraint(equalToConstant: 34),

            potAmountLabel.topAnchor.constraint(equalTo: stakeField.bottomAnchor, constant: 28),
            potAmountLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            potAmountField.topAnchor.constraint(equalTo: potAmountLabel.bottomAnchor, constant: 8),
            potAmountField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            potAmountField.widthAnchor.constraint(equalToConstant: 120),
            potAmountField.heightAnchor.constraint(equalToConstant: 34),

            potNoteLabel.topAnchor.constraint(equalTo: potAmountField.bottomAnchor, constant: 6),
            potNoteLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            potNoteLabel.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),

            carryoversLabel.topAnchor.constraint(equalTo: potNoteLabel.bottomAnchor, constant: 28),
            carryoversLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            carryoversSegment.topAnchor.constraint(equalTo: carryoversLabel.bottomAnchor, constant: 8),
            carryoversSegment.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            carryoversSegment.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),

            saveButton.topAnchor.constraint(equalTo: carryoversSegment.bottomAnchor, constant: 40),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    private func configureLabel(_ label: UILabel, text: String) {
        label.text          = text
        label.font          = UIFont.preferredFont(forTextStyle: .headline)
        label.textColor     = .label
        label.textAlignment = .center
    }

    // MARK: - Data

    private func loadSettings() {
        guard let g = GameManager.shared.currentGame else { return }
        carryoversSegment.selectedSegmentIndex = (g.tournamentCarryTies == true) ? 0 : 1
        if let pot = g.tournamentPotAmount, pot > 0 {
            potAmountField.text    = String(format: "%.2f", pot)
            stakeField.isEnabled   = false
            stakeField.alpha       = 0.35
        }
        if let skinValue = g.skinsState?.settings.skinValue, skinValue > 0 {
            stakeField.text = String(format: "%.2f", skinValue)
        }
    }

    @objc private func potFieldChanged() {
        let hasPot = !(potAmountField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        stakeField.isEnabled = !hasPot
        stakeField.alpha     = hasPot ? 0.35 : 1.0
    }

    // MARK: - Save

    @objc private func saveTapped() {
        dismissKeyboard()
        guard let g = GameManager.shared.currentGame,
              let code = g.tournamentCode,
              g.tournamentIsOrganizer else { return }

        let carryTies = (carryoversSegment.selectedSegmentIndex == 0)

        let potText  = potAmountField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let potAmount: Double? = Double(potText).flatMap { $0 > 0 ? $0 : nil }

        let stakeText = stakeField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let stake: Double? = Double(stakeText).flatMap { $0 > 0 ? $0 : nil }

        let spinner = UIAlertController(title: nil, message: "Saving…", preferredStyle: .alert)
        present(spinner, animated: true)

        Task {
            do {
                try await SupabaseService.shared.updateTournamentSettings(
                    code: code,
                    carryTies: carryTies,
                    potAmount: potAmount,
                    stake: stake
                )
                GameManager.shared.update { g in
                    g.tournamentCarryTies = carryTies
                    g.tournamentPotAmount = potAmount
                    if let s = stake {
                        var skins = g.skinsState ?? SkinsEngine.makeDefaultState()
                        skins.settings.skinValue = s
                        g.skinsState = skins
                    }
                }
                GameManager.shared.saveCurrent()
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        NotificationCenter.default.post(name: .reloadUI, object: nil)
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        let ac = UIAlertController(
                            title: "Save Failed",
                            message: error.localizedDescription,
                            preferredStyle: .alert
                        )
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ac, animated: true)
                    }
                }
            }
        }
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }
}
