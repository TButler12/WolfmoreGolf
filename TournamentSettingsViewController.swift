import UIKit

// Encoding scheme for tournamentScoringType when game_type = "skins":
//   "net"            — net skins only (absolute HC)
//   "gross"          — gross skins only
//   "both"           — both, 50/50 pot split
//   "both:NN"        — both, NN% to gross / (100-NN)% to net  e.g. "both:75"
//   "both_combined"  — both, equal value per skin (combined pool ÷ total skins)
final class TournamentSettingsViewController: UIViewController {

    // MARK: - Controls

    private let stakeLabel        = UILabel()
    private let stakeField        = UITextField()
    private let potAmountLabel    = UILabel()
    private let potAmountField    = UITextField()
    private let potNoteLabel      = UILabel()
    private let carryoversLabel   = UILabel()
    private let carryoversSegment = UISegmentedControl(items: ["On", "Off"])
    private let scoringLabel      = UILabel()
    private let scoringSegment    = UISegmentedControl(items: ["Net (Handicap)", "Gross", "Both"])

    // Sub-section shown only when scoring = "Both"
    private let splitLabel        = UILabel()
    private let splitSegment      = UISegmentedControl(items: ["50/50", "Custom %", "Combined Pool"])
    private let grossPctLabel     = UILabel()
    private let grossPctField     = UITextField()  // shown only when Custom %

    private let saveButton        = UIButton(type: .system)

    // Constraint pair — only one active at a time depending on "Both" visibility
    private var saveTopToScoring:   NSLayoutConstraint!
    private var saveTopToSplit:     NSLayoutConstraint!
    private var saveTopToCustomPct: NSLayoutConstraint!

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
        configureLabel(scoringLabel,    text: "Skins Scoring")
        configureLabel(splitLabel,      text: "Pot Distribution")
        configureLabel(grossPctLabel,   text: "% to Gross Skins")

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

        grossPctField.borderStyle   = .roundedRect
        grossPctField.keyboardType  = .numberPad
        grossPctField.textAlignment = .center
        grossPctField.font          = UIFont.preferredFont(forTextStyle: .body)
        grossPctField.placeholder   = "e.g. 75"
        grossPctField.inputAccessoryView = bar

        scoringSegment.addTarget(self, action: #selector(scoringChanged), for: .valueChanged)
        splitSegment.addTarget(self, action: #selector(splitChanged), for: .valueChanged)

        saveButton.configuration = wmStyledButton(title: "Save", style: .primary)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        let allViews: [UIView] = [
            stakeLabel, stakeField,
            potAmountLabel, potAmountField, potNoteLabel,
            carryoversLabel, carryoversSegment,
            scoringLabel, scoringSegment,
            splitLabel, splitSegment,
            grossPctLabel, grossPctField,
            saveButton
        ]
        allViews.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        let guide = view.safeAreaLayoutGuide

        // Three mutually exclusive saveButton top anchors; exactly one is active at a time.
        saveTopToScoring   = saveButton.topAnchor.constraint(equalTo: scoringSegment.bottomAnchor,  constant: 40)
        saveTopToSplit     = saveButton.topAnchor.constraint(equalTo: splitSegment.bottomAnchor,    constant: 40)
        saveTopToCustomPct = saveButton.topAnchor.constraint(equalTo: grossPctField.bottomAnchor,   constant: 40)
        saveTopToScoring.isActive = true  // default until "Both" is chosen

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

            scoringLabel.topAnchor.constraint(equalTo: carryoversSegment.bottomAnchor, constant: 28),
            scoringLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            scoringSegment.topAnchor.constraint(equalTo: scoringLabel.bottomAnchor, constant: 8),
            scoringSegment.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            scoringSegment.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),

            // Split sub-section (hidden until "Both" selected)
            splitLabel.topAnchor.constraint(equalTo: scoringSegment.bottomAnchor, constant: 28),
            splitLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            splitSegment.topAnchor.constraint(equalTo: splitLabel.bottomAnchor, constant: 8),
            splitSegment.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            splitSegment.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),

            // Custom % sub-section (hidden until "Custom %" selected within Both)
            grossPctLabel.topAnchor.constraint(equalTo: splitSegment.bottomAnchor, constant: 20),
            grossPctLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            grossPctField.topAnchor.constraint(equalTo: grossPctLabel.bottomAnchor, constant: 8),
            grossPctField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            grossPctField.widthAnchor.constraint(equalToConstant: 120),
            grossPctField.heightAnchor.constraint(equalToConstant: 34),

            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    private func configureLabel(_ label: UILabel, text: String) {
        label.text          = text
        label.font          = UIFont.preferredFont(forTextStyle: .headline)
        label.textColor     = .label
        label.textAlignment = .center
    }

    // MARK: - Visibility

    @objc private func scoringChanged() {
        updateSplitVisibility()
    }

    @objc private func splitChanged() {
        updateSplitVisibility()
    }

    private func updateSplitVisibility() {
        let isBoth     = scoringSegment.selectedSegmentIndex == 2
        let isCustom   = isBoth && splitSegment.selectedSegmentIndex == 1
        let isCombined = isBoth && splitSegment.selectedSegmentIndex == 2

        splitLabel.isHidden   = !isBoth
        splitSegment.isHidden = !isBoth
        grossPctLabel.isHidden = !isCustom
        grossPctField.isHidden = !isCustom

        saveTopToScoring.isActive   = !isBoth
        saveTopToSplit.isActive     = isBoth && !isCustom
        saveTopToCustomPct.isActive = isCustom

        // Combined Pool note: stake field becomes the fallback per-skin value
        _ = isCombined  // reserved for future note label if needed
    }

    // MARK: - Data

    private func loadSettings() {
        guard let g = GameManager.shared.currentGame else { return }
        carryoversSegment.selectedSegmentIndex = (g.tournamentCarryTies == true) ? 0 : 1

        let scoring = g.tournamentScoringType ?? "net"
        switch scoring {
        case "gross":
            scoringSegment.selectedSegmentIndex = 1
        case _ where scoring.hasPrefix("both"):
            scoringSegment.selectedSegmentIndex = 2
            if scoring == "both_combined" {
                splitSegment.selectedSegmentIndex = 2
            } else if scoring.hasPrefix("both:"), let pct = Int(scoring.dropFirst("both:".count)) {
                splitSegment.selectedSegmentIndex = 1
                grossPctField.text = "\(pct)"
            } else {
                splitSegment.selectedSegmentIndex = 0
            }
        default:
            scoringSegment.selectedSegmentIndex = 0
        }
        updateSplitVisibility()

        if let pot = g.tournamentPotAmount, pot > 0 {
            potAmountField.text  = String(format: "%.2f", pot)
            stakeField.isEnabled = false
            stakeField.alpha     = 0.35
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
        let potText   = potAmountField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let potAmount: Double? = Double(potText).flatMap { $0 > 0 ? $0 : nil }
        let stakeText = stakeField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let stake: Double? = Double(stakeText).flatMap { $0 > 0 ? $0 : nil }

        let scoring: String
        switch scoringSegment.selectedSegmentIndex {
        case 1: scoring = "gross"
        case 2:
            switch splitSegment.selectedSegmentIndex {
            case 1:
                let raw = Int(grossPctField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") ?? 50
                let pct = max(1, min(99, raw))
                scoring = "both:\(pct)"
            case 2: scoring = "both_combined"
            default: scoring = "both"
            }
        default: scoring = "net"
        }

        let spinner = UIAlertController(title: nil, message: "Saving…", preferredStyle: .alert)
        present(spinner, animated: true)

        Task {
            do {
                try await SupabaseService.shared.updateTournamentSettings(
                    code: code,
                    carryTies: carryTies,
                    potAmount: potAmount,
                    stake: stake,
                    scoring: scoring
                )
                GameManager.shared.update { g in
                    g.tournamentCarryTies   = carryTies
                    g.tournamentPotAmount   = potAmount
                    g.tournamentScoringType = scoring
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
                            preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ac, animated: true)
                    }
                }
            }
        }
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }
}
