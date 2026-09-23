import UIKit

final class TeeGameSetupViewController: UIViewController {

    // MARK: - UI

    private let scrollView  = UIScrollView()
    private let contentView = UIView()

    private let nameField        = UITextField()
    private let gameTypeControl  = UISegmentedControl(items: ["Wolf", "Skins", "Stableford", "Scramble"])
    private let stakeField       = UITextField()
    private let potField         = UITextField()
    private let carryTiesControl = UISegmentedControl(items: ["No Carry", "Carry Ties"])
    private let createButton     = UIButton(type: .system)

    private let wolfScoringControl  = UISegmentedControl(items: ["6-Point", "Wolf 2pt", "LowBall"])
    private let wolfRow             = UIView()
    private let wolfStakeField      = UITextField()
    private let wolfStakeRow        = UIView()
    private let stakeRow            = UIView()
    private let potRow              = UIView()
    private let carryRow            = UIView()
    private let stablefordRow       = UIView()
    private let stablefordToggleRow = UIView()
    private let scrambleRow         = UIView()

    private let stakeLabel   = UILabel()
    private let potLabel     = UILabel()
    private let carryLabel   = UILabel()

    private let teamTeeRow   = UIView()
    private weak var teamTeeToggleSwitch: UISwitch?
    private weak var teamTeeConfigBtn: UIButton?
    private weak var teamTeeSummaryLabel: UILabel?
    private var pendingTeamTeeSettings = TeamTeeSettings()

    private let baselineControl   = UISegmentedControl(items: ["Par", "Bogey"])
    private let teamCountControl  = UISegmentedControl(items: ["Best 2", "Best 3", "All 4"])
    private let stablefordSwitch  = UISwitch()
    private let sfModeControl       = UISegmentedControl(items: ["Standard", "Modified"])
    private weak var sfModifiedStack: UIStackView?
    private var sfStepperValues     = [0: 8, 1: 4, 2: 2, 3: 0, 4: -1, 5: -3]  // 0=dblEagle, 1=eagle, 2=birdie, 3=par, 4=bogey, 5=dblBogey

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Create Tournament"
        view.backgroundColor = .systemBackground
        setupTapToDismiss()
        setupScrollView()
        setupFields()
        setupCreateButton()
        gameTypeChanged()
    }

    // MARK: - Keyboard dismissal

    private func setupTapToDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func makeNumberPadToolbar() -> UIToolbar {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        toolbar.sizeToFit()
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done   = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.items = [spacer, done]
        return toolbar
    }

    // MARK: - Layout

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])
    }

    private func setupFields() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 28),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
        ])

        // Tournament name
        let infoLabel = UILabel()
        infoLabel.text = "Tournament mode tracks scores across all groups with a live leaderboard."
        infoLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        infoLabel.textColor = .secondaryLabel
        infoLabel.numberOfLines = 0
        stack.addArrangedSubview(infoLabel)

        stack.addArrangedSubview(labeled("Tournament Name", field: nameField))
        nameField.placeholder = "e.g. Wolf Tourney"
        nameField.borderStyle = .roundedRect
        nameField.autocapitalizationType = .words
        nameField.clearButtonMode = .whileEditing
        nameField.returnKeyType = .done
        nameField.addTarget(self, action: #selector(dismissKeyboard), for: .editingDidEndOnExit)

        // Game type
        let formatRow = labeled("Format", control: gameTypeControl)
        stack.addArrangedSubview(formatRow)
        gameTypeControl.selectedSegmentIndex = 0
        gameTypeControl.addTarget(self, action: #selector(gameTypeChanged), for: .valueChanged)

        // Wolf Scoring Options (Wolf format only)
        wolfScoringControl.selectedSegmentIndex = 0
        let wolfInner = labeled("Wolf Scoring", control: wolfScoringControl)
        wolfInner.translatesAutoresizingMaskIntoConstraints = false
        wolfRow.translatesAutoresizingMaskIntoConstraints = false
        wolfRow.addSubview(wolfInner)
        NSLayoutConstraint.activate([
            wolfInner.topAnchor.constraint(equalTo: wolfRow.topAnchor),
            wolfInner.leadingAnchor.constraint(equalTo: wolfRow.leadingAnchor),
            wolfInner.trailingAnchor.constraint(equalTo: wolfRow.trailingAnchor),
            wolfInner.bottomAnchor.constraint(equalTo: wolfRow.bottomAnchor),
        ])
        stack.addArrangedSubview(wolfRow)

        // Base Stake (Wolf format only)
        let wolfStakeLabel = UILabel()
        wolfStakeLabel.text = "Base Stake ($ per hole)"
        wolfStakeLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        wolfStakeLabel.textColor = .secondaryLabel
        wolfStakeField.placeholder = "e.g. 2"
        wolfStakeField.borderStyle = .roundedRect
        wolfStakeField.keyboardType = .decimalPad
        wolfStakeField.inputAccessoryView = makeNumberPadToolbar()
        let wolfStakeStack = UIStackView(arrangedSubviews: [wolfStakeLabel, wolfStakeField])
        wolfStakeStack.axis = .vertical
        wolfStakeStack.spacing = 6
        wolfStakeRow.translatesAutoresizingMaskIntoConstraints = false
        wolfStakeRow.addSubview(wolfStakeStack)
        wolfStakeStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            wolfStakeStack.topAnchor.constraint(equalTo: wolfStakeRow.topAnchor),
            wolfStakeStack.leadingAnchor.constraint(equalTo: wolfStakeRow.leadingAnchor),
            wolfStakeStack.trailingAnchor.constraint(equalTo: wolfStakeRow.trailingAnchor),
            wolfStakeStack.bottomAnchor.constraint(equalTo: wolfStakeRow.bottomAnchor),
        ])
        wolfStakeRow.isHidden = true
        stack.addArrangedSubview(wolfStakeRow)

        // "Also track Stableford points" toggle (Wolf/Skins only — hidden for pure Stableford format)
        let sfToggleLabel = UILabel()
        sfToggleLabel.text = "Also track Stableford points"
        sfToggleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        sfToggleLabel.textColor = .secondaryLabel
        sfToggleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        stablefordSwitch.addTarget(self, action: #selector(stablefordSwitchChanged), for: .valueChanged)
        let sfToggleInner = UIStackView(arrangedSubviews: [sfToggleLabel, stablefordSwitch])
        sfToggleInner.axis = .horizontal
        sfToggleInner.alignment = .center
        sfToggleInner.spacing = 8
        stablefordToggleRow.translatesAutoresizingMaskIntoConstraints = false
        stablefordToggleRow.addSubview(sfToggleInner)
        sfToggleInner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sfToggleInner.topAnchor.constraint(equalTo: stablefordToggleRow.topAnchor),
            sfToggleInner.leadingAnchor.constraint(equalTo: stablefordToggleRow.leadingAnchor),
            sfToggleInner.trailingAnchor.constraint(equalTo: stablefordToggleRow.trailingAnchor),
            sfToggleInner.bottomAnchor.constraint(equalTo: stablefordToggleRow.bottomAnchor),
        ])
        stablefordToggleRow.isHidden = true
        stack.addArrangedSubview(stablefordToggleRow)

        // Stake (Skins only, disabled when pot mode is set)
        stakeLabel.text = "Stake ($ per skin)"
        stakeLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        stakeLabel.textColor = .secondaryLabel
        stakeField.placeholder = "e.g. 5"
        stakeField.borderStyle = .roundedRect
        stakeField.keyboardType = .numberPad
        stakeField.inputAccessoryView = makeNumberPadToolbar()
        let stakeStack = UIStackView(arrangedSubviews: [stakeLabel, stakeField])
        stakeStack.axis = .vertical
        stakeStack.spacing = 6
        stakeRow.translatesAutoresizingMaskIntoConstraints = false
        stakeRow.addSubview(stakeStack)
        stakeStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stakeStack.topAnchor.constraint(equalTo: stakeRow.topAnchor),
            stakeStack.leadingAnchor.constraint(equalTo: stakeRow.leadingAnchor),
            stakeStack.trailingAnchor.constraint(equalTo: stakeRow.trailingAnchor),
            stakeStack.bottomAnchor.constraint(equalTo: stakeRow.bottomAnchor),
        ])
        stack.addArrangedSubview(stakeRow)

        // Pot amount (Skins only, optional — overrides per-skin stake)
        potLabel.text = "Skins Pot ($)  —  total divided by skins won"
        potLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        potLabel.textColor = .secondaryLabel
        potField.placeholder = "e.g. 100  (optional)"
        potField.borderStyle = .roundedRect
        potField.keyboardType = .numberPad
        potField.inputAccessoryView = makeNumberPadToolbar()
        potField.addTarget(self, action: #selector(potFieldChanged), for: .editingChanged)
        let potStack = UIStackView(arrangedSubviews: [potLabel, potField])
        potStack.axis = .vertical
        potStack.spacing = 6
        potRow.translatesAutoresizingMaskIntoConstraints = false
        potRow.addSubview(potStack)
        potStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            potStack.topAnchor.constraint(equalTo: potRow.topAnchor),
            potStack.leadingAnchor.constraint(equalTo: potRow.leadingAnchor),
            potStack.trailingAnchor.constraint(equalTo: potRow.trailingAnchor),
            potStack.bottomAnchor.constraint(equalTo: potRow.bottomAnchor),
        ])
        stack.addArrangedSubview(potRow)

        // Carry ties (Skins only)
        carryLabel.text = "Ties"
        carryLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        carryLabel.textColor = .secondaryLabel
        carryTiesControl.selectedSegmentIndex = 0
        let carryStack = UIStackView(arrangedSubviews: [carryLabel, carryTiesControl])
        carryStack.axis = .vertical
        carryStack.spacing = 6
        carryRow.translatesAutoresizingMaskIntoConstraints = false
        carryRow.addSubview(carryStack)
        carryStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            carryStack.topAnchor.constraint(equalTo: carryRow.topAnchor),
            carryStack.leadingAnchor.constraint(equalTo: carryRow.leadingAnchor),
            carryStack.trailingAnchor.constraint(equalTo: carryRow.trailingAnchor),
            carryStack.bottomAnchor.constraint(equalTo: carryRow.bottomAnchor),
        ])
        stack.addArrangedSubview(carryRow)

        // Stableford rules (Stableford format only)
        baselineControl.selectedSegmentIndex = 0
        teamCountControl.selectedSegmentIndex = 1
        sfModeControl.selectedSegmentIndex = 0
        sfModeControl.addTarget(self, action: #selector(sfModeChanged), for: .valueChanged)

        let modStack = buildModifiedSFStack()
        sfModifiedStack = modStack
        modStack.isHidden = true

        let sfStack = UIStackView(arrangedSubviews: [
            labeled("Scoring Baseline", control: baselineControl),
            labeled("Scores That Count Per Hole", control: teamCountControl),
            labeled("Scoring Mode", control: sfModeControl),
            modStack,
        ])
        sfStack.axis = .vertical
        sfStack.spacing = 16
        stablefordRow.translatesAutoresizingMaskIntoConstraints = false
        stablefordRow.addSubview(sfStack)
        sfStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sfStack.topAnchor.constraint(equalTo: stablefordRow.topAnchor),
            sfStack.leadingAnchor.constraint(equalTo: stablefordRow.leadingAnchor),
            sfStack.trailingAnchor.constraint(equalTo: stablefordRow.trailingAnchor),
            sfStack.bottomAnchor.constraint(equalTo: stablefordRow.bottomAnchor),
        ])
        stablefordRow.isHidden = true
        stack.addArrangedSubview(stablefordRow)

        // Scramble info row (no configuration needed — teams type their name when joining)
        let scrambleInfoLabel = UILabel()
        scrambleInfoLabel.text = "Scorers enter this tournament code, type their team name, and start scoring. No pre-registration required."
        scrambleInfoLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        scrambleInfoLabel.textColor = .secondaryLabel
        scrambleInfoLabel.numberOfLines = 0
        scrambleRow.translatesAutoresizingMaskIntoConstraints = false
        scrambleRow.addSubview(scrambleInfoLabel)
        scrambleInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrambleInfoLabel.topAnchor.constraint(equalTo: scrambleRow.topAnchor),
            scrambleInfoLabel.leadingAnchor.constraint(equalTo: scrambleRow.leadingAnchor),
            scrambleInfoLabel.trailingAnchor.constraint(equalTo: scrambleRow.trailingAnchor),
            scrambleInfoLabel.bottomAnchor.constraint(equalTo: scrambleRow.bottomAnchor),
        ])
        scrambleRow.isHidden = true
        stack.addArrangedSubview(scrambleRow)

        // Team Scoring (Wolf and Skins only)
        let ttLabel = UILabel()
        ttLabel.text = "Also track Team Scoring"
        ttLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        ttLabel.textColor = .secondaryLabel
        ttLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let ttSw = UISwitch()
        ttSw.isOn = false
        ttSw.addTarget(self, action: #selector(teamTeeSwitchChanged), for: .valueChanged)
        teamTeeToggleSwitch = ttSw

        let ttToggleRow = UIStackView(arrangedSubviews: [ttLabel, ttSw])
        ttToggleRow.axis = .horizontal
        ttToggleRow.alignment = .center
        ttToggleRow.spacing = 8

        let ttCfgBtn = UIButton(type: .system)
        ttCfgBtn.setTitle("Configure Count Rules →", for: .normal)
        ttCfgBtn.titleLabel?.font = .systemFont(ofSize: 14)
        ttCfgBtn.contentHorizontalAlignment = .left
        ttCfgBtn.addTarget(self, action: #selector(teamTeeConfigureTapped), for: .touchUpInside)
        ttCfgBtn.isHidden = true
        teamTeeConfigBtn = ttCfgBtn

        let ttNote = UILabel()
        ttNote.text = teamTeeSummaryText()
        ttNote.font = UIFont.preferredFont(forTextStyle: .footnote)
        ttNote.textColor = .secondaryLabel
        ttNote.numberOfLines = 0
        teamTeeSummaryLabel = ttNote

        let ttSection = UIStackView(arrangedSubviews: [ttToggleRow, ttCfgBtn, ttNote])
        ttSection.axis = .vertical
        ttSection.spacing = 8

        teamTeeRow.translatesAutoresizingMaskIntoConstraints = false
        teamTeeRow.addSubview(ttSection)
        ttSection.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            ttSection.topAnchor.constraint(equalTo: teamTeeRow.topAnchor),
            ttSection.leadingAnchor.constraint(equalTo: teamTeeRow.leadingAnchor),
            ttSection.trailingAnchor.constraint(equalTo: teamTeeRow.trailingAnchor),
            ttSection.bottomAnchor.constraint(equalTo: teamTeeRow.bottomAnchor),
        ])
        teamTeeRow.isHidden = true
        stack.addArrangedSubview(teamTeeRow)
    }

    private func setupCreateButton() {
        var cfg = UIButton.Configuration.filled()
        cfg.baseBackgroundColor = UIColor(red: 0.22, green: 0.62, blue: 0.34, alpha: 1.0)
        cfg.baseForegroundColor = .white
        cfg.cornerStyle = .large
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs
            a.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
            return a
        }
        cfg.title = "Create Tournament"
        createButton.configuration = cfg
        createButton.translatesAutoresizingMaskIntoConstraints = false
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        view.addSubview(createButton)

        NSLayoutConstraint.activate([
            createButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
        scrollView.contentInset.bottom = 80
    }

    // MARK: - Helpers

    private func labeled(_ title: String, field: UITextField) -> UIView {
        let label = UILabel()
        label.text = title
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        let stack = UIStackView(arrangedSubviews: [label, field])
        stack.axis = .vertical
        stack.spacing = 6
        return stack
    }

    private func labeled(_ title: String, control: UISegmentedControl) -> UIView {
        let label = UILabel()
        label.text = title
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        let stack = UIStackView(arrangedSubviews: [label, control])
        stack.axis = .vertical
        stack.spacing = 6
        return stack
    }

    // MARK: - Actions

    @objc private func gameTypeChanged() {
        let isWolf       = gameTypeControl.selectedSegmentIndex == 0
        let isScramble   = gameTypeControl.selectedSegmentIndex == 3
        let isSkins      = gameTypeControl.selectedSegmentIndex == 1
        let isStableford = gameTypeControl.selectedSegmentIndex == 2
        wolfRow.isHidden             = !isWolf
        wolfStakeRow.isHidden        = !isWolf
        stakeRow.isHidden            = !isSkins
        potRow.isHidden              = !isSkins
        carryRow.isHidden            = !isSkins
        stablefordToggleRow.isHidden = isStableford || isScramble
        stablefordRow.isHidden       = (!isStableford && !stablefordSwitch.isOn) || isScramble
        scrambleRow.isHidden         = !isScramble
        teamTeeRow.isHidden          = isScramble || isStableford
    }

    @objc private func stablefordSwitchChanged() {
        stablefordRow.isHidden = !stablefordSwitch.isOn
        sfModifiedStack?.isHidden = (sfModeControl.selectedSegmentIndex != 1)
    }

    @objc private func teamTeeSwitchChanged() {
        pendingTeamTeeSettings.isEnabled = teamTeeToggleSwitch?.isOn == true
        teamTeeConfigBtn?.isHidden = !(teamTeeToggleSwitch?.isOn == true)
        teamTeeSummaryLabel?.text = teamTeeSummaryText()
    }

    @objc private func teamTeeConfigureTapped() {
        let g = GameManager.shared.currentGame
        let activePlayers = (0..<MAX_PLAYERS).filter {
            (g?.playerActivated[$0] ?? false) &&
            !(g?.playerNames[$0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        }.count
        let vc = TeamTeeSetupViewController(settings: pendingTeamTeeSettings, maxCount: max(1, activePlayers))
        vc.onSave = { [weak self] updated in
            self?.pendingTeamTeeSettings = updated
            self?.teamTeeSummaryLabel?.text = self?.teamTeeSummaryText()
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    private func teamTeeSummaryText() -> String {
        let g = GameManager.shared.currentGame
        let activePlayers = (0..<MAX_PLAYERS).filter {
            (g?.playerActivated[$0] ?? false) &&
            !(g?.playerNames[$0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        }.count
        let total = max(2, activePlayers)
        let s = pendingTeamTeeSettings
        switch s.countMode {
        case .fixed:
            return "Counts the best \(s.fixedCount) of \(total) net scores on every hole."
        case .byPar:
            return "\(s.par3Count)-\(s.par4Count)-\(s.par5Count) scoring — counts \(s.par3Count) of \(total) on par-3s, \(s.par4Count) of \(total) on par-4s, \(s.par5Count) of \(total) on par-5s."
        }
    }



    @objc private func potFieldChanged() {
        let hasPot = !(potField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        stakeField.isEnabled = !hasPot
        stakeField.alpha     = hasPot ? 0.35 : 1.0
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func createTapped() {
        // Capture all control values before endEditing to avoid any responder-chain side-effects
        let name          = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let gameIdx       = gameTypeControl.selectedSegmentIndex
        let wolfScoringIdx = wolfScoringControl.selectedSegmentIndex
        let stakeText     = stakeField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let potText       = potField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let carryIdx      = carryTiesControl.selectedSegmentIndex
        let courseName    = GameManager.shared.currentGame?.course.name ?? ""

        view.endEditing(true)

        guard !name.isEmpty else {
            showError("Please enter a tournament name.")
            return
        }

        let gameType: String
        switch gameIdx {
        case 0: gameType = "wolf"
        case 1: gameType = "skins"
        case 2: gameType = "stableford"
        default: gameType = "scramble"
        }

        var wolfVariant: String? = nil
        var wolfStake: Double? = nil
        if gameType == "wolf" {
            switch wolfScoringIdx {
            case 1:  wolfVariant = "2pt"
            case 2:  wolfVariant = "lowball"
            default: wolfVariant = "6pt"
            }
            let wolfStakeText = wolfStakeField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !wolfStakeText.isEmpty {
                guard let ws = Double(wolfStakeText), ws > 0 else {
                    showError("Please enter a valid base stake amount.")
                    return
                }
                wolfStake = ws
            }
        }

        let scoringType = "net"
        var stake: Double? = nil
        var potAmount: Double? = nil
        var carryTies: Bool? = nil

        if gameType == "skins" {
            if !potText.isEmpty {
                guard let p = Double(potText), p > 0 else {
                    showError("Please enter a valid pot amount.")
                    return
                }
                potAmount = p
            } else if !stakeText.isEmpty {
                guard let s = Double(stakeText), s > 0 else {
                    showError("Please enter a valid stake amount.")
                    return
                }
                stake = s
            }
            carryTies = (carryIdx == 1)
        }

        let ttSettings: TeamTeeSettings? = (teamTeeToggleSwitch?.isOn == true) ? pendingTeamTeeSettings : nil

        var sfBaseline: String? = nil
        var sfTeamCount: Int? = nil
        var sfEnabled: Bool? = nil
        var sfMode: String? = nil
        var sfModifiedTable: ModifiedStablefordTable? = nil

        if gameType == "stableford" {
            // Pure Stableford format — baseline and team count always apply.
            sfBaseline  = baselineControl.selectedSegmentIndex == 1 ? "bogey" : "par"
            switch teamCountControl.selectedSegmentIndex {
            case 0:  sfTeamCount = 2
            case 2:  sfTeamCount = 4
            default: sfTeamCount = 3
            }
            if sfModeControl.selectedSegmentIndex == 1 {
                sfMode = "modified"
                sfModifiedTable = ModifiedStablefordTable(
                    doubleEagleOrBetter: sfStepperValues[0] ??  8,
                    eagleOrBetter:       sfStepperValues[1] ??  4,
                    birdie:              sfStepperValues[2] ??  2,
                    par:                 sfStepperValues[3] ??  0,
                    bogey:               sfStepperValues[4] ?? -1,
                    doubleBogeyOrWorse:  sfStepperValues[5] ?? -3
                )
            }
        } else if stablefordSwitch.isOn {
            // Hybrid: Wolf/Skins primary format + Stableford overlay.
            sfEnabled   = true
            sfBaseline  = baselineControl.selectedSegmentIndex == 1 ? "bogey" : "par"
            switch teamCountControl.selectedSegmentIndex {
            case 0:  sfTeamCount = 2
            case 2:  sfTeamCount = 4
            default: sfTeamCount = 3
            }
            if sfModeControl.selectedSegmentIndex == 1 {
                sfMode = "modified"
                sfModifiedTable = ModifiedStablefordTable(
                    doubleEagleOrBetter: sfStepperValues[0] ??  8,
                    eagleOrBetter:       sfStepperValues[1] ??  4,
                    birdie:              sfStepperValues[2] ??  2,
                    par:                 sfStepperValues[3] ??  0,
                    bogey:               sfStepperValues[4] ?? -1,
                    doubleBogeyOrWorse:  sfStepperValues[5] ?? -3
                )
            }
        }

        let spinner = UIAlertController(title: nil, message: "Creating tournament…", preferredStyle: .alert)
        present(spinner, animated: true)

        Task {
            do {
                let record = try await SupabaseService.shared.createTournament(
                    name: name,
                    gameType: gameType,
                    scoringType: scoringType,
                    stake: stake,
                    potAmount: potAmount,
                    carryTies: carryTies,
                    courseName: courseName,
                    stablefordBaseline: sfBaseline,
                    stablefordTeamCount: sfTeamCount,
                    stablefordEnabled: sfEnabled,
                    stablefordMode: sfMode,
                    modifiedSfTable: sfModifiedTable,
                    teamTeeSettings: ttSettings,
                    wolfVariant: wolfVariant,
                    wolfStake: wolfStake
                )

                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        GameManager.shared.update { g in
                            g.tournamentCode        = record.code
                            g.groupCode             = record.id
                            g.tournamentMatchId     = UUID().uuidString
                            g.tournamentName        = record.name
                            g.tournamentGameType    = record.gameType
                            g.tournamentScoringType = record.scoring
                            g.tournamentDay         = 1
                            g.tournamentIsCreator   = (record.createdBy == DeviceID.id)
                            g.tournamentIsOrganizer = g.tournamentIsCreator
                            g.tournamentPotAmount       = record.potAmount
                            g.tournamentStablefordEnabled = record.stablefordEnabled
                            g.stablefordBaseline        = StablefordBaseline(rawValue: record.stablefordBaseline ?? "par") ?? .par
                            g.stablefordCountingPlayers = record.stablefordTeamCount ?? 3
                            g.stablefordMode = StablefordMode(rawValue: record.stablefordMode ?? "standard") ?? .standard
                            if g.stablefordMode == .modified {
                                g.modifiedStablefordTable = ModifiedStablefordTable(
                                    doubleEagleOrBetter: record.modifiedSfDoubleEagle  ??  8,
                                    eagleOrBetter:       record.modifiedSfEagle        ??  4,
                                    birdie:              record.modifiedSfBirdie       ??  2,
                                    par:                 record.modifiedSfPar          ??  0,
                                    bogey:               record.modifiedSfBogey        ?? -1,
                                    doubleBogeyOrWorse:  record.modifiedSfDoubleBogey  ?? -3
                                )
                            } else {
                                g.modifiedStablefordTable = ModifiedStablefordTable()
                            }
                            g.teamTeeSettings           = record.teamTeeSettings
                            g.gameType = nil
                            switch record.gameType {
                            case "stableford": g.gameType = .tournament
                            case "wolf":
                                switch record.wolfVariant {
                                case "2pt":       g.gameType = .wolf
                                case "lowball":   g.gameType = .wolfLowBall
                                case "matchplay": g.gameType = .matchPlay
                                default:          g.gameType = .sixPointScotch
                                }
                            default: break
                            }
                            if record.gameType == "skins", let stake = record.stake {
                                var skins = g.skinsState ?? SkinsEngine.makeDefaultState()
                                skins.settings.skinValue = stake
                                g.skinsState = skins
                            } else if record.gameType == "wolf", let ws = record.wolfStake {
                                g.wolfStake = ws
                                g.baseGameStake = Int(ws)
                                g.gameHoleDollarsArray = Array(repeating: ws, count: STANDARD_HOLES)
                                g.holeBaseAmount       = Array(repeating: ws, count: STANDARD_HOLES)
                            }
                        }
                        GameManager.shared.saveCurrent()
                        TournamentHistoryStore.shared.record(
                            code: record.code, name: record.name,
                            gameType: record.gameType, day: 1, isOrganizer: true)
                        NotificationCenter.default.post(name: .reloadUI, object: nil)
                        if gameType == "scramble" {
                            self.showScrambleCreated(code: record.code)
                        } else {
                            self.showSuccess(code: record.code)
                        }
                    }
                }
            } catch {
                print("❌ createTournament error: \(error)")
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.showError("Failed to create tournament.\n\n\(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func showScrambleCreated(code: String) {
        let ac = UIAlertController(
            title: "Scramble Created!",
            message: "Share this code with every scorer:\n\n\(code)\n\nEach scorer enters the code, types their team name, and starts scoring.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "Copy Code", style: .default) { [weak self] _ in
            UIPasteboard.general.string = code
            self?.showScrambleTeamEntry(code: code)
        })
        ac.addAction(UIAlertAction(title: "Done", style: .cancel) { [weak self] _ in
            self?.showScrambleTeamEntry(code: code)
        })
        present(ac, animated: true)
    }

    private func showScrambleTeamEntry(code: String) {
        let entryVC = ScrambleTeamEntryViewController()
        entryVC.allowSkip = true
        entryVC.onSkip = { [weak self] in
            self?.navigationController?.dismiss(animated: true)
        }
        entryVC.submit = { [weak self] vc, teamName, playerNames, startingHole in
            guard let self else { return }
            let spinner = UIAlertController(title: nil, message: "Setting up team…", preferredStyle: .alert)
            vc.present(spinner, animated: true)
            Task { [weak self] in
                guard let self else { return }
                do {
                    _ = try await SupabaseService.shared.findOrCreateScrambleTeam(
                        tournamentCode: code, teamName: teamName, playerNames: playerNames)
                    await MainActor.run {
                        let holeIndex = max(0, min(17, startingHole - 1))
                        GameManager.shared.update { g in
                            g.scrambleTeamName   = teamName
                            g.playerNames[0]     = teamName
                            for i in g.playerActivated.indices { g.playerActivated[i] = false }
                            g.playerActivated[0] = true
                            // Wipe previous round's scores so the new game starts clean.
                            g.scores = Array(repeating: Array(repeating: nil, count: STANDARD_HOLES), count: MAX_PLAYERS)
                            g.hole      = holeIndex
                            g.startHole = holeIndex
                        }
                        GameManager.shared.seedScoresWithParsForActivePlayers()
                        GameManager.shared.saveCurrent()
                        let hostNav = self.navigationController?.presentingViewController as? UINavigationController
                            ?? self.navigationController?.presentingViewController?.navigationController
                        let sb = UIStoryboard(name: "Main", bundle: nil)
                        let game = sb.instantiateViewController(withIdentifier: "GameViewController")
                        spinner.dismiss(animated: false) {
                            self.navigationController?.dismiss(animated: true) {
                                hostNav?.pushViewController(game, animated: true)
                            }
                        }
                    }
                } catch {
                    await MainActor.run {
                        spinner.dismiss(animated: false) {
                            let err = UIAlertController(title: "Error",
                                message: "Couldn't register team.\n\n\(error.localizedDescription)",
                                preferredStyle: .alert)
                            err.addAction(UIAlertAction(title: "OK", style: .default))
                            vc.present(err, animated: true)
                        }
                    }
                }
            }
        }
        navigationController?.pushViewController(entryVC, animated: true)
    }

    // MARK: - Modified Stableford helpers

    private func buildModifiedSFStack() -> UIStackView {
        let labels   = ["Double Eagle+", "Eagle", "Birdie", "Par", "Bogey", "Double Bogey+"]
        let defaults = [8, 4, 2, 0, -1, -3]
        let rows = (0..<6).map { i -> UIView in
            sfStepperValues[i] = defaults[i]
            return makeSFStepperRow(label: labels[i], value: defaults[i], tag: i)
        }
        let stack = UIStackView(arrangedSubviews: rows)
        stack.axis = .vertical
        stack.spacing = 10
        return stack
    }

    private func makeSFStepperRow(label text: String, value: Int, tag: Int) -> UIView {
        let nameLabel = UILabel()
        nameLabel.text = text
        nameLabel.font = .systemFont(ofSize: 14)
        nameLabel.textColor = .secondaryLabel
        nameLabel.setContentHuggingPriority(.required, for: .horizontal)

        let valueLabel = UILabel()
        valueLabel.text = sfPointString(value)
        valueLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .semibold)
        valueLabel.textColor = value >= 0 ? .systemGreen : .systemRed
        valueLabel.textAlignment = .center
        valueLabel.tag = tag + 100
        valueLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true

        let stepper = UIStepper()
        stepper.minimumValue = -10
        stepper.maximumValue = 10
        stepper.stepValue = 1
        stepper.value = Double(value)
        stepper.tag = tag
        stepper.addTarget(self, action: #selector(sfStepperChanged(_:)), for: .valueChanged)

        let row = UIStackView(arrangedSubviews: [nameLabel, valueLabel, stepper])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        return row
    }

    private func sfPointString(_ v: Int) -> String { v > 0 ? "+\(v)" : "\(v)" }

    @objc private func sfModeChanged() {
        let isModified = sfModeControl.selectedSegmentIndex == 1
        sfModifiedStack?.isHidden = !isModified
    }

    @objc private func sfStepperChanged(_ stepper: UIStepper) {
        let v = Int(stepper.value)
        sfStepperValues[stepper.tag] = v
        if let row = stepper.superview as? UIStackView,
           let lbl = row.arrangedSubviews.compactMap({ $0 as? UILabel }).first(where: { $0.tag == stepper.tag + 100 }) {
            lbl.text = sfPointString(v)
            lbl.textColor = v >= 0 ? .systemGreen : .systemRed
        }
    }

    private func showSuccess(code: String) {
        let ac = UIAlertController(
            title: "Tournament Created!",
            message: "Share this code with your group:\n\n\(code)\n\nThey can join from the Tournaments screen.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "Copy Code", style: .default) { [weak self] _ in
            UIPasteboard.general.string = code
            self?.navigationController?.popViewController(animated: true)
        })
        ac.addAction(UIAlertAction(title: "Done", style: .cancel) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(ac, animated: true)
    }

    private func showError(_ message: String) {
        let ac = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}
