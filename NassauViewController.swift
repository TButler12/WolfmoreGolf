import UIKit

final class NassauViewController: UIViewController {

    var gameData: GameData?

    private let textView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        title = "Nassau"

        setupUI()
        loadGame()
        updateNavButtons()
        renderSummary()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadGame()
        updateNavButtons()
        renderSummary()
    }

    private func setupUI() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.isSelectable = false
        textView.isScrollEnabled = true

        textView.backgroundColor = .secondarySystemBackground
        textView.layer.cornerRadius = 16
        textView.clipsToBounds = true

        textView.font = .systemFont(ofSize: 18, weight: .semibold)
        textView.textColor = .label
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 16, bottom: 30, right: 16)

        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }
    private func loadGame() {
        gameData = GameManager.shared.currentGame
    }

    private func renderSummary() {
        guard var workingGame = gameData ?? GameManager.shared.currentGame else {
            textView.text = "No game data available."
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
                g.nassauState = NassauEngine.makeDefaultState(
                    playerNames: g.playerNames,
                    activeFlags: g.playerActivated
                )
                g.recalculateNassauIfNeeded()
            }

            workingGame = GameManager.shared.currentGame ?? workingGame
        } else {
            if var state = workingGame.nassauState {
                NassauEngine.recalculate(state: &state, gameData: workingGame)
                workingGame.nassauState = state
            }
        }

        guard let nassau = workingGame.nassauState else {
            textView.text = "Nassau is not enabled for this round."
            return
        }

        var lines: [String] = []

        lines.append("NASSAU")
        lines.append("Stake: $\(formatStake(nassau.defaultStake))")
        lines.append("Press Mode: \(pressModeText(nassau.settings.pressMode))")
        lines.append("Trigger: \(nassau.autoPressTriggerDown) down")

        if let lastHole = NassauEngine.lastCommittedHoleNumber(gameData: workingGame) {
            lines.append("Through Hole: \(lastHole)")
        } else {
            lines.append("Current Hole: \(workingGame.hole + 1)")
        }

        lines.append("")

        if !nassau.oneVsOneMatches.isEmpty {
            lines.append("1 vs 1 MATCHES")
            lines.append("------------------------------")
            for match in nassau.oneVsOneMatches {
                lines.append(matchBlock(for: match, game: workingGame))
                lines.append("")
            }
        }

        if !nassau.twoVsTwoMatches.isEmpty {
            lines.append("2 vs 2 MATCHES")
            lines.append("------------------------------")
            for match in nassau.twoVsTwoMatches {
                lines.append(matchBlock(for: match, game: workingGame))
                lines.append("")
            }
        }

        if nassau.oneVsOneMatches.isEmpty && nassau.twoVsTwoMatches.isEmpty {
            lines.append("No Nassau matches configured.")
        }

        textView.text = lines.joined(separator: "\n")
        gameData = workingGame
    }

    private func cleanResult(_ text: String, label: String) -> String {
        let lower = text.lowercased()

        if lower.contains("halved") {
            return "\(label): Halved"
        }

        if lower.contains("all square") {
            return "\(label): All Square"
        }

        if let range = text.range(of: " won ") {
            let winner = String(text[..<range.lowerBound])
            return "\(label): \(winner) won \(label)"
        }

        return "\(label): \(text)"
    }

    private func cleanPressStatus(_ text: String) -> String {
        if text == "AS" || text.lowercased().contains("square") {
            return "All Square"
        }

        return text
    }
    private func updateNavButtons() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Matches",
            style: .plain,
            target: self,
            action: #selector(editMatchesTapped)
        )

        guard let state = gameData?.nassauState else {
            navigationItem.rightBarButtonItem = nil
            return
        }

        if state.settings.pressMode == .manual {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "Add Press",
                style: .plain,
                target: self,
                action: #selector(addPressTapped)
            )
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

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
            self?.renderSummary()
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
                self?.renderSummary()

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
                self?.renderSummary()

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
    
    @objc private func addPressTapped() {
        guard let game = gameData,
              let state = game.nassauState,
              state.settings.pressMode == .manual else { return }

        let ac = UIAlertController(
            title: "Add Press",
            message: "Choose a match",
            preferredStyle: .actionSheet
        )

        for (index, match) in state.oneVsOneMatches.enumerated() {
            ac.addAction(UIAlertAction(title: match.title, style: .default) { [weak self] _ in
                self?.showSegmentPicker(matchIndex: index, isTwoVsTwo: false)
            })
        }

        for (index, match) in state.twoVsTwoMatches.enumerated() {
            ac.addAction(UIAlertAction(title: match.title, style: .default) { [weak self] _ in
                self?.showSegmentPicker(matchIndex: index, isTwoVsTwo: true)
            })
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.barButtonItem = navigationItem.rightBarButtonItem
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

        if state.settings.pressMode == .manual {
            ac.addAction(UIAlertAction(title: "Add Manual Press", style: .default) { [weak self] _ in
                self?.addPressTapped()
            })
        }

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
            self?.renderSummary()
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
            self?.renderSummary()
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

        ac.addAction(UIAlertAction(title: "Manual\(state.settings.pressMode == .manual ? " ✓" : "")", style: .default) { [weak self] _ in
            self?.setPressMode(.manual)
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
        renderSummary()
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
            self?.renderSummary()
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
        renderSummary()
    }

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
    private func matchBlock(for match: NassauMatch, game: GameData) -> String {
        let playerNames = game.playerNames

        let frontResult = NassauEngine.frontResultText(
            for: match,
            playerNames: playerNames,
            gameData: game
        )

        let backResult = NassauEngine.backResultText(
            for: match,
            playerNames: playerNames,
            gameData: game
        )

        let overallResult = NassauEngine.overallResultText(
            for: match,
            playerNames: playerNames,
            gameData: game
        )

        let netMoney = NassauEngine.netNassauMoneyText(
            for: match,
            playerNames: playerNames,
            gameData: game
        )

        var lines: [String] = []

        lines.append(match.title)
        lines.append("  \(cleanResult(frontResult, label: "Front 9"))")
        lines.append("  \(cleanResult(backResult, label: "Back 9"))")
        lines.append("  \(cleanResult(overallResult, label: "18"))")

        if !match.presses.isEmpty {
            lines.append("")
            lines.append("  Presses: \(match.presses.count)")

            for (index, press) in match.presses.enumerated() {
                let pressStatus = NassauEngine.runningStatusText(press.runningStatus)
                lines.append("    \(index + 1). H\(press.startHole)-\(press.endHole)  \(cleanPressStatus(pressStatus))")
            }
        }

        lines.append("")
        lines.append("  NET: \(netMoney)")
        lines.append("  -------------------------")

        return lines.joined(separator: "\n")
    }
}
