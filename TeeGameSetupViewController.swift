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

    private let stakeRow            = UIView()
    private let potRow              = UIView()
    private let carryRow            = UIView()
    private let stablefordRow       = UIView()
    private let stablefordToggleRow = UIView()
    private let scrambleRow         = UIView()

    private let stakeLabel   = UILabel()
    private let potLabel     = UILabel()
    private let carryLabel   = UILabel()

    private let baselineControl   = UISegmentedControl(items: ["Par", "Bogey"])
    private let teamCountControl  = UISegmentedControl(items: ["Best 2", "Best 3", "All 4"])
    private let stablefordSwitch  = UISwitch()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Create Tee Game"
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
        let sfStack = UIStackView(arrangedSubviews: [
            labeled("Scoring Baseline", control: baselineControl),
            labeled("Scores That Count Per Hole", control: teamCountControl),
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
        let isScramble   = gameTypeControl.selectedSegmentIndex == 3
        let isSkins      = gameTypeControl.selectedSegmentIndex == 1
        let isStableford = gameTypeControl.selectedSegmentIndex == 2
        stakeRow.isHidden            = !isSkins
        potRow.isHidden              = !isSkins
        carryRow.isHidden            = !isSkins
        stablefordToggleRow.isHidden = isStableford || isScramble
        stablefordRow.isHidden       = (!isStableford && !stablefordSwitch.isOn) || isScramble
        scrambleRow.isHidden         = !isScramble
    }

    @objc private func stablefordSwitchChanged() {
        stablefordRow.isHidden = !stablefordSwitch.isOn
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
        let name        = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let gameIdx     = gameTypeControl.selectedSegmentIndex
        let stakeText   = stakeField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let potText     = potField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let carryIdx    = carryTiesControl.selectedSegmentIndex
        let courseName  = GameManager.shared.currentGame?.course.name ?? ""

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

        var sfBaseline: String? = nil
        var sfTeamCount: Int? = nil
        var sfEnabled: Bool? = nil

        if gameType == "stableford" {
            // Pure Stableford format — baseline and team count always apply.
            sfBaseline  = baselineControl.selectedSegmentIndex == 1 ? "bogey" : "par"
            switch teamCountControl.selectedSegmentIndex {
            case 0:  sfTeamCount = 2
            case 2:  sfTeamCount = 4
            default: sfTeamCount = 3
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
                    stablefordEnabled: sfEnabled
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
                            if record.gameType == "skins", let stake = record.stake {
                                var skins = g.skinsState ?? SkinsEngine.makeDefaultState()
                                skins.settings.skinValue = stake
                                g.skinsState = skins
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
        entryVC.submit = { [weak self] vc, teamName, playerNames in
            guard let self else { return }
            let spinner = UIAlertController(title: nil, message: "Setting up team…", preferredStyle: .alert)
            vc.present(spinner, animated: true)
            Task { [weak self] in
                guard let self else { return }
                do {
                    _ = try await SupabaseService.shared.findOrCreateScrambleTeam(
                        tournamentCode: code, teamName: teamName, playerNames: playerNames)
                    await MainActor.run {
                        GameManager.shared.update { g in
                            g.scrambleTeamName   = teamName
                            g.playerNames[0]     = teamName
                            for i in g.playerActivated.indices { g.playerActivated[i] = false }
                            g.playerActivated[0] = true
                            // Wipe previous round's scores so the new game starts clean.
                            g.scores = Array(repeating: Array(repeating: nil, count: STANDARD_HOLES), count: MAX_PLAYERS)
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

    private func showSuccess(code: String) {
        let ac = UIAlertController(
            title: "Tournament Created!",
            message: "Share this code with your group:\n\n\(code)\n\nThey can join from the Tee Games screen.",
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
