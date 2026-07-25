import UIKit

// Encoding scheme for tournamentScoringType when game_type = "skins":
//   "net"            — net skins only (absolute HC)
//   "gross"          — gross skins only
//   "both"           — both, 50/50 pot split
//   "both:NN"        — both, NN% to gross / (100-NN)% to net  e.g. "both:75"
//   "both_combined"  — both, equal value per skin (combined pool ÷ total skins)
final class TournamentSettingsViewController: UIViewController {

    private var isWolfTournament: Bool {
        GameManager.shared.currentGame?.tournamentGameType == "wolf"
    }

    // MARK: - Controls

    private let wolfStakeField  = UITextField()

    private let skinsModeSegment = UISegmentedControl(items: ["Stake Per Skin", "Pot"])
    private let stakeField       = UITextField()
    private let potAmountField   = UITextField()
    private let potNoteLabel     = UILabel()
    private let carryoversSegment = UISegmentedControl(items: ["On", "Off"])
    private let scoringSegment   = UISegmentedControl(items: ["Net (Handicap)", "Gross", "Both"])

    // Sub-section shown only when scoring = "Both"
    private let splitSegment     = UISegmentedControl(items: ["50/50", "Custom %", "Combined Pool"])
    private let grossPctField    = UITextField()

    private let saveButton = UIButton(type: .system)

    // Stack rows that toggle visibility
    private var stakeRow:       UIView!
    private var potLabeledRow:  UIView!
    private var splitRow:       UIView!
    private var grossPctRow:    UIView!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edit Tournament Settings"
        view.backgroundColor = .systemGroupedBackground

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        setupUI()
        loadSettings()
    }

    // MARK: - UI

    private func setupUI() {
        let bar = UIToolbar()
        bar.sizeToFit()
        bar.items = [
            .flexibleSpace(),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
        ]

        for tf in [wolfStakeField, stakeField, potAmountField, grossPctField] {
            tf.borderStyle   = .roundedRect
            tf.textAlignment = .center
            tf.font          = .systemFont(ofSize: 17)
            tf.inputAccessoryView = bar
        }
        wolfStakeField.keyboardType  = .decimalPad
        wolfStakeField.placeholder   = "0.00"
        stakeField.keyboardType      = .decimalPad
        stakeField.placeholder       = "0.00"
        potAmountField.keyboardType  = .decimalPad
        potAmountField.placeholder   = "e.g. 100"
        potAmountField.heightAnchor.constraint(equalToConstant: 38).isActive = true
        grossPctField.keyboardType   = .numberPad
        grossPctField.placeholder    = "e.g. 75"

        potNoteLabel.text          = "Total pot is split among all skins won."
        potNoteLabel.font          = .systemFont(ofSize: 13)
        potNoteLabel.textColor     = .secondaryLabel
        potNoteLabel.numberOfLines = 0
        potNoteLabel.textAlignment = .center

        skinsModeSegment.addTarget(self, action: #selector(skinsModeChanged), for: .valueChanged)
        carryoversSegment.addTarget(self, action: #selector(scoringChanged), for: .valueChanged)
        scoringSegment.addTarget(self, action: #selector(scoringChanged), for: .valueChanged)
        splitSegment.addTarget(self, action: #selector(scoringChanged), for: .valueChanged)

        saveButton.configuration = wmStyledButton(title: "Save", style: .primary)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let outerStack = UIStackView()
        outerStack.axis    = .vertical
        outerStack.spacing = 20
        outerStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(outerStack)
        NSLayoutConstraint.activate([
            outerStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            outerStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            outerStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            outerStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32),
            outerStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),
        ])

        // Wolf card
        if isWolfTournament {
            let wolfCard = makeCard(header: "WOLF GAME", tint: wolfGreen)
            let wolfInner = wolfCard.viewWithTag(99)!
            let wolfContent = makeFieldRow(label: "Wolf Game Stake ($)", field: wolfStakeField)
            wolfInner.addSubview(wolfContent)
            wolfContent.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                wolfContent.topAnchor.constraint(equalTo: wolfInner.topAnchor),
                wolfContent.leadingAnchor.constraint(equalTo: wolfInner.leadingAnchor),
                wolfContent.trailingAnchor.constraint(equalTo: wolfInner.trailingAnchor),
                wolfContent.bottomAnchor.constraint(equalTo: wolfInner.bottomAnchor),
            ])
            outerStack.addArrangedSubview(wolfCard)
        }

        // Skins card
        let skinsCard  = makeCard(header: "SKINS", tint: UIColor(red: 0.20, green: 0.50, blue: 0.85, alpha: 1.0))
        let skinsInner = skinsCard.viewWithTag(99)!

        // Skins mode toggle
        let modeLabel = makeFieldLabel("Skins Mode")
        stakeRow      = makeFieldRow(label: "Amount Per Skin ($)", field: stakeField)
        let potContent = makeVStack([potAmountField, potNoteLabel], spacing: 6)
        potLabeledRow  = makeLabeledRow(label: "Total Pot ($)", content: potContent)

        splitRow   = makeLabeledRow(label: "Pot Distribution", content: splitSegment)
        grossPctRow = makeFieldRow(label: "% to Gross Skins", field: grossPctField)

        let carryRow   = makeLabeledRow(label: "Carryovers", content: carryoversSegment)
        let scoringRow = makeLabeledRow(label: "Skins Scoring", content: scoringSegment)

        let skinsStack = UIStackView(arrangedSubviews: [
            modeLabel,
            skinsModeSegment,
            stakeRow,
            potLabeledRow,
            makeSeparator(),
            carryRow,
            scoringRow,
            splitRow,
            grossPctRow,
        ])
        skinsStack.axis    = .vertical
        skinsStack.spacing = 16
        skinsStack.translatesAutoresizingMaskIntoConstraints = false
        skinsInner.addSubview(skinsStack)
        NSLayoutConstraint.activate([
            skinsStack.topAnchor.constraint(equalTo: skinsInner.topAnchor),
            skinsStack.leadingAnchor.constraint(equalTo: skinsInner.leadingAnchor),
            skinsStack.trailingAnchor.constraint(equalTo: skinsInner.trailingAnchor),
            skinsStack.bottomAnchor.constraint(equalTo: skinsInner.bottomAnchor),
        ])
        outerStack.addArrangedSubview(skinsCard)

        // Save
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        outerStack.addArrangedSubview(saveButton)
    }

    // MARK: - Card builder

    private var wolfGreen: UIColor { UIColor(red: 0.10, green: 0.33, blue: 0.18, alpha: 1.0) }

    private func makeCard(header: String, tint: UIColor) -> UIView {
        let card = UIView()
        card.backgroundColor    = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 14
        card.layer.shadowColor  = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.06
        card.layer.shadowOffset  = CGSize(width: 0, height: 2)
        card.layer.shadowRadius  = 6

        // Header bar
        let headerBg = UIView()
        headerBg.backgroundColor    = tint.withAlphaComponent(0.12)
        headerBg.layer.cornerRadius = 14
        headerBg.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        headerBg.translatesAutoresizingMaskIntoConstraints = false

        let headerLabel = UILabel()
        headerLabel.text      = header
        headerLabel.font      = .systemFont(ofSize: 12, weight: .bold)
        headerLabel.textColor = tint
        headerLabel.translatesAutoresizingMaskIntoConstraints = false

        let sep = UIView()
        sep.backgroundColor = tint.withAlphaComponent(0.25)
        sep.translatesAutoresizingMaskIntoConstraints = false

        // Content container (tagged so we can find it)
        let content = UIView()
        content.tag = 99
        content.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(headerBg)
        headerBg.addSubview(headerLabel)
        card.addSubview(sep)
        card.addSubview(content)

        NSLayoutConstraint.activate([
            headerBg.topAnchor.constraint(equalTo: card.topAnchor),
            headerBg.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            headerBg.trailingAnchor.constraint(equalTo: card.trailingAnchor),

            headerLabel.topAnchor.constraint(equalTo: headerBg.topAnchor, constant: 10),
            headerLabel.bottomAnchor.constraint(equalTo: headerBg.bottomAnchor, constant: -10),
            headerLabel.leadingAnchor.constraint(equalTo: headerBg.leadingAnchor, constant: 16),

            sep.topAnchor.constraint(equalTo: headerBg.bottomAnchor),
            sep.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            sep.heightAnchor.constraint(equalToConstant: 1),

            content.topAnchor.constraint(equalTo: sep.bottomAnchor, constant: 20),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),
        ])
        return card
    }

    private func makeFieldLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text      = text
        l.font      = .systemFont(ofSize: 15, weight: .semibold)
        l.textColor = .label
        return l
    }

    private func makeFieldRow(label: String, field: UITextField) -> UIView {
        let lbl = makeFieldLabel(label)
        field.translatesAutoresizingMaskIntoConstraints = false
        let stack = UIStackView(arrangedSubviews: [lbl, field])
        stack.axis    = .vertical
        stack.spacing = 8
        field.heightAnchor.constraint(equalToConstant: 38).isActive = true
        return stack
    }

    private func makeLabeledRow(label: String, content: UIView) -> UIView {
        let lbl = makeFieldLabel(label)
        let stack = UIStackView(arrangedSubviews: [lbl, content])
        stack.axis    = .vertical
        stack.spacing = 8
        return stack
    }

    private func makeVStack(_ views: [UIView], spacing: CGFloat) -> UIView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis    = .vertical
        stack.spacing = spacing
        return stack
    }

    private func makeSeparator() -> UIView {
        let v = UIView()
        v.backgroundColor = .separator
        v.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return v
    }

    // MARK: - Visibility

    @objc private func skinsModeChanged() { updateVisibility() }
    @objc private func scoringChanged()   { updateVisibility() }

    private func updateVisibility() {
        let isPot    = skinsModeSegment.selectedSegmentIndex == 1
        let isBoth   = scoringSegment.selectedSegmentIndex == 2
        let isCustom = isBoth && splitSegment.selectedSegmentIndex == 1

        stakeRow.isHidden      = isPot
        potLabeledRow.isHidden = !isPot

        splitRow.isHidden    = !isBoth
        grossPctRow.isHidden = !isCustom
    }

    // MARK: - Data

    private func loadSettings() {
        guard let g = GameManager.shared.currentGame else { return }

        if isWolfTournament {
            let ws = g.wolfStake ?? (g.gameHoleDollarsArray.first ?? 0)
            if ws > 0 { wolfStakeField.text = String(format: "%.2f", ws) }
        }

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

        if let pot = g.tournamentPotAmount, pot > 0 {
            potAmountField.text = String(format: "%.2f", pot)
            skinsModeSegment.selectedSegmentIndex = 1
        } else {
            skinsModeSegment.selectedSegmentIndex = 0
            if let skinValue = g.skinsState?.settings.skinValue, skinValue > 0 {
                stakeField.text = String(format: "%.2f", skinValue)
            }
        }

        updateVisibility()
    }

    // MARK: - Save

    @objc private func saveTapped() {
        dismissKeyboard()
        guard let g = GameManager.shared.currentGame,
              let code = g.tournamentCode,
              g.tournamentIsOrganizer else { return }

        let wolfStakeText = wolfStakeField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let wolfStake: Double? = isWolfTournament
            ? Double(wolfStakeText).flatMap { $0 > 0 ? $0 : nil }
            : nil

        let isPot = skinsModeSegment.selectedSegmentIndex == 1
        let stakeText = stakeField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let skinsStake: Double? = isPot ? nil : Double(stakeText).flatMap { $0 > 0 ? $0 : nil }
        let potText = potAmountField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let potAmount: Double? = isPot ? Double(potText).flatMap { $0 > 0 ? $0 : nil } : nil

        let carryTies = (carryoversSegment.selectedSegmentIndex == 0)

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
                    code:      code,
                    carryTies: carryTies,
                    potAmount: potAmount,
                    stake:     skinsStake,
                    wolfStake: wolfStake,
                    scoring:   scoring
                )
                GameManager.shared.update { g in
                    g.tournamentCarryTies   = carryTies
                    g.tournamentPotAmount   = potAmount
                    g.tournamentScoringType = scoring
                    if let ws = wolfStake {
                        g.wolfStake = ws
                        g.gameHoleDollarsArray = Array(repeating: ws, count: STANDARD_HOLES)
                    }
                    if let s = skinsStake {
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
