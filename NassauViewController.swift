import UIKit

final class NassauViewController: UIViewController {

    var gameData: GameData?

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let wolfGreen = UIColor(red: 0.10, green: 0.33, blue: 0.18, alpha: 1.0)

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        title = "Nassau"

        setupUI()
        loadGame()
        updateNavButtons()
        renderUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadGame()
        updateNavButtons()
        renderUI()
    }

    private func setupUI() {
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

    // MARK: - Helpers

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

        // Layout pairs in rows of 2
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

    // MARK: - Main render

    private func renderUI() {
        print("DEBUG renderUI - playerIncluded: \(GameManager.shared.currentGame?.nassauState?.playerIncluded ?? [])")
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        guard var workingGame = gameData ?? GameManager.shared.currentGame else {
            let empty = UILabel()
            empty.text = "No game data available."
            empty.textColor = .secondaryLabel
            empty.textAlignment = .center
            contentStack.addArrangedSubview(empty)
            return
        }

        let hasRealPlayers = zip(workingGame.playerNames, workingGame.playerActivated).contains { name, active in
            active && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        if hasRealPlayers &&
            (
                workingGame.nassauState == nil ||
                (
                    workingGame.nassauState?.isEnabled == true &&
                    workingGame.nassauState?.oneVsOneMatches.isEmpty == true &&
                    workingGame.nassauState?.twoVsTwoMatches.isEmpty == true
                )
            ) {

            GameManager.shared.update { g in
                let savedIncluded = g.nassauState?.playerIncluded
                print("DEBUG savedIncluded: \(savedIncluded ?? [])")
                var newState = NassauEngine.makeDefaultState(
                    playerNames: g.playerNames,
                    activeFlags: g.playerActivated
                )
                if let saved = savedIncluded {
                    newState.playerIncluded = saved
                    print("DEBUG newState.playerIncluded after restore: \(newState.playerIncluded)")
                    newState.oneVsOneMatches = NassauEngine.makeAllOneVsOneMatches(
                        playerNames: g.playerNames,
                        activeFlags: g.playerActivated,
                        includedFlags: saved,
                        scoringMode: .net,
                        stake: newState.settings.baseStake
                    )
                    newState.twoVsTwoMatches = NassauEngine.makeDefaultTwoVsTwoMatches(
                        playerNames: g.playerNames,
                        activeFlags: g.playerActivated,
                        includedFlags: saved,
                        scoringMode: .net,
                        stake: newState.settings.baseStake
                    )
                }
                g.nassauState = newState
                g.recalculateNassauIfNeeded()
                print("DEBUG final playerIncluded: \(g.nassauState?.playerIncluded ?? [])")
                print("DEBUG 1v1 count: \(g.nassauState?.oneVsOneMatches.count ?? -1)")
                print("DEBUG 2v2 count: \(g.nassauState?.twoVsTwoMatches.count ?? -1)")
            }

            workingGame = GameManager.shared.currentGame ?? workingGame
        } else {
            if var state = workingGame.nassauState {
                let included = state.playerIncluded
                state.oneVsOneMatches = NassauEngine.makeAllOneVsOneMatches(
                    playerNames: workingGame.playerNames,
                    activeFlags: workingGame.playerActivated,
                    includedFlags: included,
                    scoringMode: .net,
                    stake: state.settings.baseStake
                )
                state.twoVsTwoMatches = NassauEngine.makeDefaultTwoVsTwoMatches(
                    playerNames: workingGame.playerNames,
                    activeFlags: workingGame.playerActivated,
                    includedFlags: included,
                    scoringMode: .net,
                    stake: state.settings.baseStake
                )
                NassauEngine.recalculate(state: &state, gameData: workingGame)
                workingGame.nassauState = state
            }
        }

        guard let nassau = workingGame.nassauState else {
            let label = UILabel()
            label.text = "Nassau is not enabled for this round."
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            contentStack.addArrangedSubview(label)
            gameData = workingGame
            return
        }

        // Settings card
        let currentHoleDisplay: String
        if let lastHole = NassauEngine.lastCommittedHoleNumber(gameData: workingGame) {
            currentHoleDisplay = "\(lastHole)"
        } else {
            currentHoleDisplay = "\(workingGame.hole + 1)"
        }

        let triggerText = "\(nassau.settings.autoPressTriggerDown) Down"
        let settingsGrid = makeInfoGrid([
            (label: "STAKE", value: "$\(formatStake(nassau.settings.baseStake))"),
            (label: "PRESS MODE", value: pressModeText(nassau.settings.pressMode)),
            (label: "TRIGGER", value: triggerText),
            (label: "CURRENT HOLE", value: currentHoleDisplay)
        ])
        contentStack.addArrangedSubview(wrapInCard(settingsGrid))

        // 1 vs 1 matches section
        if !nassau.oneVsOneMatches.isEmpty {
            let header = makeSectionHeader("1 VS 1 MATCHES")
            let headerWrapper = UIView()
            headerWrapper.translatesAutoresizingMaskIntoConstraints = false
            headerWrapper.addSubview(header)
            header.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                header.topAnchor.constraint(equalTo: headerWrapper.topAnchor, constant: 4),
                header.bottomAnchor.constraint(equalTo: headerWrapper.bottomAnchor),
                header.leadingAnchor.constraint(equalTo: headerWrapper.leadingAnchor),
                header.trailingAnchor.constraint(equalTo: headerWrapper.trailingAnchor)
            ])
            contentStack.addArrangedSubview(headerWrapper)

            for match in nassau.oneVsOneMatches {
                contentStack.addArrangedSubview(makeMatchCard(for: match, game: workingGame))
            }
        }

        // 2 vs 2 matches section
        if !nassau.twoVsTwoMatches.isEmpty {
            let header = makeSectionHeader("2 VS 2 MATCHES")
            let headerWrapper = UIView()
            headerWrapper.translatesAutoresizingMaskIntoConstraints = false
            headerWrapper.addSubview(header)
            header.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                header.topAnchor.constraint(equalTo: headerWrapper.topAnchor, constant: 4),
                header.bottomAnchor.constraint(equalTo: headerWrapper.bottomAnchor),
                header.leadingAnchor.constraint(equalTo: headerWrapper.leadingAnchor),
                header.trailingAnchor.constraint(equalTo: headerWrapper.trailingAnchor)
            ])
            contentStack.addArrangedSubview(headerWrapper)

            for match in nassau.twoVsTwoMatches {
                contentStack.addArrangedSubview(makeMatchCard(for: match, game: workingGame))
            }
        }

        // Empty state
        if nassau.oneVsOneMatches.isEmpty && nassau.twoVsTwoMatches.isEmpty {
            let label = UILabel()
            label.text = "No Nassau matches configured."
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 15, weight: .regular)
            contentStack.addArrangedSubview(label)
        }

        gameData = workingGame
    }

    // MARK: - Match card builder

    private func makeMatchCard(for match: NassauMatch, game: GameData) -> UIView {
        let inner = UIStackView()
        inner.axis = .vertical
        inner.spacing = 10

        // Title row
        let titleLabel = UILabel()
        titleLabel.text = match.title
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .label
        inner.addArrangedSubview(titleLabel)

        // Pills row (FRONT 9, BACK 9, 18)
        let pillsStack = UIStackView()
        pillsStack.axis = .horizontal
        pillsStack.distribution = .fillEqually
        pillsStack.spacing = 8

        let frontPill = makeSegmentPill(
            name: "FRONT 9",
            resultText: NassauEngine.frontResultText(for: match, playerNames: game.playerNames, gameData: game),
            statusByHole: match.frontStatusByHole
        )
        let backPill = makeSegmentPill(
            name: "BACK 9",
            resultText: NassauEngine.backResultText(for: match, playerNames: game.playerNames, gameData: game),
            statusByHole: match.backStatusByHole
        )
        let overallPill = makeSegmentPill(
            name: "18",
            resultText: NassauEngine.overallResultText(for: match, playerNames: game.playerNames, gameData: game),
            statusByHole: match.overallStatusByHole
        )

        pillsStack.addArrangedSubview(frontPill)
        pillsStack.addArrangedSubview(backPill)
        pillsStack.addArrangedSubview(overallPill)
        inner.addArrangedSubview(pillsStack)

        // Presses row (only if any)
        if match.presses.count > 0 {
            let pressLabel = UILabel()
            pressLabel.text = "Presses: \(match.presses.count)"
            pressLabel.font = .systemFont(ofSize: 12, weight: .regular)
            pressLabel.textColor = .secondaryLabel
            inner.addArrangedSubview(pressLabel)
        }

        // Separator
        let sep = UIView()
        sep.backgroundColor = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        inner.addArrangedSubview(sep)
        sep.heightAnchor.constraint(equalToConstant: 0.5).isActive = true

        // NET row
        let netRow = UIStackView()
        netRow.axis = .horizontal
        netRow.spacing = 8

        let netLabel = UILabel()
        netLabel.text = "NET"
        netLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        netLabel.textColor = .secondaryLabel

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let netValue = UILabel()
        let last = match.overallStatusByHole.last
        if let last = last {
            let raw = NassauEngine.runningStatusText(match.overallStatusByHole)
            let displayText = (raw == "All Square") ? "Even" : raw
            netValue.text = displayText
            if last > 0 {
                netValue.textColor = .systemGreen
            } else if last < 0 {
                netValue.textColor = .systemRed
            } else {
                netValue.textColor = .secondaryLabel
            }
        } else {
            netValue.text = "Even"
            netValue.textColor = .secondaryLabel
        }
        netValue.font = .systemFont(ofSize: 14, weight: .semibold)

        netRow.addArrangedSubview(netLabel)
        netRow.addArrangedSubview(spacer)
        netRow.addArrangedSubview(netValue)
        inner.addArrangedSubview(netRow)

        return wrapInCard(inner)
    }

    private func makeSegmentPill(name: String, resultText: String, statusByHole: [Int]) -> UIView {
        let container = UIView()
        container.backgroundColor = .tertiarySystemBackground
        container.layer.cornerRadius = 8

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -6)
        ])

        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = .systemFont(ofSize: 10, weight: .semibold)
        nameLabel.textColor = .secondaryLabel
        nameLabel.textAlignment = .center

        let statusLabel = UILabel()
        statusLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 2
        statusLabel.adjustsFontSizeToFitWidth = true
        statusLabel.minimumScaleFactor = 0.7

        // Determine status text and color
        let (text, color) = segmentDisplay(resultText: resultText, statusByHole: statusByHole)
        statusLabel.text = text
        statusLabel.textColor = color

        stack.addArrangedSubview(nameLabel)
        stack.addArrangedSubview(statusLabel)

        return container
    }

    private func segmentDisplay(resultText: String, statusByHole: [Int]) -> (String, UIColor) {
        if resultText == "In Progress" {
            guard let last = statusByHole.last else {
                return ("Not Started", .secondaryLabel)
            }
            let running = NassauEngine.runningStatusText(statusByHole)
            if last > 0 {
                return (running, .systemGreen)
            } else if last < 0 {
                return (running, .systemRed)
            } else {
                return (running, .secondaryLabel)
            }
        } else if resultText == "Halved" {
            return ("Halved", .secondaryLabel)
        } else {
            // Settled win
            let running = NassauEngine.runningStatusText(statusByHole)
            if let last = statusByHole.last {
                if last > 0 {
                    return (running, .systemGreen)
                } else if last < 0 {
                    return (running, .systemRed)
                } else {
                    return (running, .secondaryLabel)
                }
            }
            return (running, .secondaryLabel)
        }
    }

    // MARK: - Game loading

    private func loadGame() {
        gameData = GameManager.shared.currentGame
    }

    private func updateNavButtons() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Matches",
            style: .plain,
            target: self,
            action: #selector(editMatchesTapped)
        )

        navigationItem.rightBarButtonItem = nil
    }

    // MARK: - Actions

    @objc private func editMatchesTapped() {
        let ac = UIAlertController(
            title: "Nassau Setup",
            message: "Choose what to edit",
            preferredStyle: .actionSheet
        )

        ac.addAction(UIAlertAction(title: "Edit 1 vs 1 Matches", style: .default) { [weak self] _ in
            self?.showOneVsOnePicker()
        })

        ac.addAction(UIAlertAction(title: "Edit 2 vs 2 Teams", style: .default) { [weak self] _ in
            self?.showTwoVsTwoPicker()
        })

        ac.addAction(UIAlertAction(title: "Reset Default Matches", style: .destructive) { [weak self] _ in
            GameManager.shared.update { g in
                g.nassauState = NassauEngine.makeDefaultState(
                    playerNames: g.playerNames,
                    activeFlags: g.playerActivated
                )
                g.recalculateNassauIfNeeded()
            }
            self?.loadGame()
            self?.updateNavButtons()
            self?.renderUI()
        })

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.barButtonItem = navigationItem.leftBarButtonItem
        }

        present(ac, animated: true)
    }

    private func showOneVsOnePicker() {
        guard let game = GameManager.shared.currentGame,
              let state = game.nassauState else { return }

        let allMatches = NassauEngine.makeAllOneVsOneMatches(
            playerNames: game.playerNames,
            activeFlags: game.playerActivated,
            includedFlags: state.playerIncluded,
            scoringMode: .net,
            stake: state.settings.baseStake
        )

        let ac = UIAlertController(
            title: "1 vs 1 Matches",
            message: "Tap to add or remove a match",
            preferredStyle: .actionSheet
        )

        for match in allMatches {
            let isSelected = state.oneVsOneMatches.contains {
                $0.team1PlayerIndexes == match.team1PlayerIndexes &&
                $0.team2PlayerIndexes == match.team2PlayerIndexes
            }

            let title = "\(isSelected ? "✓ " : "")\(match.title)"

            ac.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                GameManager.shared.update { g in
                    guard var s = g.nassauState else { return }

                    if let idx = s.oneVsOneMatches.firstIndex(where: {
                        $0.team1PlayerIndexes == match.team1PlayerIndexes &&
                        $0.team2PlayerIndexes == match.team2PlayerIndexes
                    }) {
                        s.oneVsOneMatches.remove(at: idx)
                    } else {
                        s.oneVsOneMatches.append(match)
                    }

                    NassauEngine.recalculate(state: &s, gameData: g)
                    g.nassauState = s
                }

                self?.loadGame()
                self?.renderUI()

                DispatchQueue.main.async {
                    self?.showOneVsOnePicker()
                }
            })
        }

        ac.addAction(UIAlertAction(title: "Done", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.barButtonItem = navigationItem.leftBarButtonItem
        }

        present(ac, animated: true)
    }

    private func showTwoVsTwoPicker() {
        guard let game = GameManager.shared.currentGame,
              let state = game.nassauState else { return }

        let allMatches = NassauEngine.makeDefaultTwoVsTwoMatches(
            playerNames: game.playerNames,
            activeFlags: game.playerActivated,
            includedFlags: state.playerIncluded,
            scoringMode: .net,
            stake: state.settings.baseStake
        )

        let ac = UIAlertController(
            title: "2 vs 2 Teams",
            message: "Tap to add or remove a team match",
            preferredStyle: .actionSheet
        )

        for match in allMatches {
            let isSelected = state.twoVsTwoMatches.contains {
                $0.team1PlayerIndexes == match.team1PlayerIndexes &&
                $0.team2PlayerIndexes == match.team2PlayerIndexes
            }

            let title = "\(isSelected ? "✓ " : "")\(match.title)"

            ac.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                GameManager.shared.update { g in
                    guard var s = g.nassauState else { return }

                    if let idx = s.twoVsTwoMatches.firstIndex(where: {
                        $0.team1PlayerIndexes == match.team1PlayerIndexes &&
                        $0.team2PlayerIndexes == match.team2PlayerIndexes
                    }) {
                        s.twoVsTwoMatches.remove(at: idx)
                    } else {
                        s.twoVsTwoMatches.append(match)
                    }

                    NassauEngine.recalculate(state: &s, gameData: g)
                    g.nassauState = s
                }

                self?.loadGame()
                self?.renderUI()

                DispatchQueue.main.async {
                    self?.showTwoVsTwoPicker()
                }
            })
        }

        ac.addAction(UIAlertAction(title: "Done", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.barButtonItem = navigationItem.leftBarButtonItem
        }

        present(ac, animated: true)
    }

    func presentSettingsFromContainer() {
        guard let game = GameManager.shared.currentGame,
              let state = game.nassauState else { return }

        let ac = UIAlertController(
            title: "Nassau Settings",
            message: nil,
            preferredStyle: .actionSheet
        )

        let pressModeTitle: String
        switch state.settings.pressMode {
        case .auto:
            pressModeTitle = "Press Mode: Auto"
        case .manual:
            pressModeTitle = "Press Mode: Manual"
        case .off:
            pressModeTitle = "Press Mode: Off"
        }

        ac.addAction(UIAlertAction(title: "Set Nassau Stake ($\(formatStake(state.settings.baseStake)))", style: .default) { [weak self] _ in
            self?.promptForStake()
        })

        ac.addAction(UIAlertAction(title: pressModeTitle, style: .default) { [weak self] _ in
            self?.showPressModePicker()
        })

        if state.settings.pressMode == .auto {
            ac.addAction(UIAlertAction(title: "Set Trigger (\(state.settings.autoPressTriggerDown) down)", style: .default) { [weak self] _ in
                self?.promptForTrigger()
            })
        }
        ac.addAction(UIAlertAction(title: "Edit 1 vs 1 Matches", style: .default) { [weak self] _ in
            self?.showOneVsOnePicker()
        })

        ac.addAction(UIAlertAction(title: "Edit 2 vs 2 Teams", style: .default) { [weak self] _ in
            self?.showTwoVsTwoPicker()
        })

        ac.addAction(UIAlertAction(title: "Reset Default Matches", style: .destructive) { [weak self] _ in
            GameManager.shared.update { g in
                g.nassauState = NassauEngine.makeDefaultState(
                    playerNames: g.playerNames,
                    activeFlags: g.playerActivated
                )
                g.recalculateNassauIfNeeded()
            }
            self?.loadGame()
            self?.updateNavButtons()
            self?.renderUI()
        })

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: 90, width: 1, height: 1)
        }

        present(ac, animated: true)
    }

    private func promptForStake() {
        guard let game = GameManager.shared.currentGame,
              let state = game.nassauState else { return }

        let ac = UIAlertController(title: "Nassau Stake", message: "Enter base stake", preferredStyle: .alert)

        ac.addTextField {
            $0.keyboardType = .decimalPad
            $0.text = String(format: "%.2f", state.settings.baseStake)
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        ac.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            let value = Double(ac.textFields?.first?.text ?? "") ?? state.settings.baseStake

            GameManager.shared.update { g in
                guard var s = g.nassauState else { return }

                s.settings.baseStake = max(0, value)

                s.oneVsOneMatches = s.oneVsOneMatches.map {
                    var m = $0
                    m.stake = s.settings.baseStake
                    return m
                }

                s.twoVsTwoMatches = s.twoVsTwoMatches.map {
                    var m = $0
                    m.stake = s.settings.baseStake
                    return m
                }

                NassauEngine.recalculate(state: &s, gameData: g)
                g.nassauState = s
            }

            self?.loadGame()
            self?.updateNavButtons()
            self?.renderUI()
        })

        present(ac, animated: true)
    }

    private func showPressModePicker() {
        guard let game = GameManager.shared.currentGame,
              let state = game.nassauState else { return }

        let ac = UIAlertController(title: "Press Mode", message: nil, preferredStyle: .actionSheet)

        ac.addAction(UIAlertAction(title: "Auto\(state.settings.pressMode == .auto ? " ✓" : "")", style: .default) { [weak self] _ in
            self?.setPressMode(.auto)
        })

        ac.addAction(UIAlertAction(title: "Off\(state.settings.pressMode == .off ? " ✓" : "")", style: .default) { [weak self] _ in
            self?.setPressMode(.off)
        })

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: 90, width: 1, height: 1)
        }

        present(ac, animated: true)
    }

    private func setPressMode(_ mode: NassauPressMode) {
        GameManager.shared.update { g in
            guard var s = g.nassauState else { return }
            s.settings.pressMode = mode
            NassauEngine.recalculate(state: &s, gameData: g)
            g.nassauState = s
        }

        loadGame()
        updateNavButtons()
        renderUI()
    }

    private func promptForTrigger() {
        guard let game = GameManager.shared.currentGame,
              let state = game.nassauState else { return }

        let ac = UIAlertController(title: "Auto Press Trigger", message: "Enter holes down", preferredStyle: .alert)

        ac.addTextField {
            $0.keyboardType = .numberPad
            $0.text = String(state.settings.autoPressTriggerDown)
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        ac.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            let value = Int(ac.textFields?.first?.text ?? "") ?? state.settings.autoPressTriggerDown

            GameManager.shared.update { g in
                guard var s = g.nassauState else { return }
                s.settings.autoPressTriggerDown = max(1, value)
                NassauEngine.recalculate(state: &s, gameData: g)
                g.nassauState = s
            }

            self?.loadGame()
            self?.updateNavButtons()
            self?.renderUI()
        })

        present(ac, animated: true)
    }

    private func showSegmentPicker(matchIndex: Int, isTwoVsTwo: Bool) {
        guard let game = GameManager.shared.currentGame,
              let state = game.nassauState else { return }

        let currentHole1Based = game.hole + 1

        let match: NassauMatch = isTwoVsTwo
            ? state.twoVsTwoMatches[matchIndex]
            : state.oneVsOneMatches[matchIndex]

        let ac = UIAlertController(
            title: match.title,
            message: "Choose press segment",
            preferredStyle: .actionSheet
        )

        func addSegmentAction(_ title: String, segment: NassauSegment) {
            let allowed = NassauEngine.canAddManualPress(
                match: match,
                state: state,
                segment: segment,
                currentHole1Based: currentHole1Based
            )

            guard allowed else { return }

            ac.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.applyManualPress(matchIndex: matchIndex, isTwoVsTwo: isTwoVsTwo, segment: segment)
            })
        }

        addSegmentAction("Front 9 Press", segment: .front)
        addSegmentAction("Back 9 Press", segment: .back)

        if state.settings.allowOverallPresses {
            addSegmentAction("18-Hole Press", segment: .overall)
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.barButtonItem = navigationItem.rightBarButtonItem
        }

        present(ac, animated: true)
    }

    private func applyManualPress(matchIndex: Int, isTwoVsTwo: Bool, segment: NassauSegment) {
        GameManager.shared.update { g in
            guard var state = g.nassauState else { return }

            let currentHole1Based = g.hole + 1

            if isTwoVsTwo {
                guard state.twoVsTwoMatches.indices.contains(matchIndex) else { return }

                var match = state.twoVsTwoMatches[matchIndex]
                NassauEngine.addManualPress(
                    to: &match,
                    state: state,
                    segment: segment,
                    currentHole1Based: currentHole1Based
                )
                state.twoVsTwoMatches[matchIndex] = match
            } else {
                guard state.oneVsOneMatches.indices.contains(matchIndex) else { return }

                var match = state.oneVsOneMatches[matchIndex]
                NassauEngine.addManualPress(
                    to: &match,
                    state: state,
                    segment: segment,
                    currentHole1Based: currentHole1Based
                )
                state.oneVsOneMatches[matchIndex] = match
            }

            NassauEngine.recalculate(state: &state, gameData: g)
            g.nassauState = state
        }

        loadGame()
        updateNavButtons()
        renderUI()
    }

    // MARK: - Formatting helpers

    private func pressModeText(_ mode: NassauPressMode) -> String {
        switch mode {
        case .off: return "Off"
        case .auto: return "Auto"
        case .manual: return "Manual"
        }
    }

    private func formatStake(_ value: Double) -> String {
        if value == floor(value) {
            return String(Int(value))
        } else {
            return String(format: "%.2f", value)
        }
    }
}
