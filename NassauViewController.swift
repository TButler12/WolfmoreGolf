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
        updateManualPressButton()
        renderSummary()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadGame()
        updateManualPressButton()
        renderSummary()
    }

    private func setupUI() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.font = .monospacedSystemFont(ofSize: 17, weight: .regular)
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 8, bottom: 24, right: 8)

        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
            (workingGame.nassauState?.isEnabled == true &&
             workingGame.nassauState?.oneVsOneMatches.isEmpty == true &&
             workingGame.nassauState?.twoVsTwoMatches.isEmpty == true)
           ) {

            GameManager.shared.update { g in
                g.nassauState = NassauEngine.makeDefaultState(
                    playerNames: g.playerNames,
                    activeFlags: g.playerActivated
                )
                g.recalculateNassauIfNeeded()
            }

            workingGame = GameManager.shared.currentGame ?? workingGame
        }else {
            var updatedState = workingGame.nassauState
            if var state = updatedState {
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
        lines.append("Auto Press: \(nassau.autoPressEnabled ? "On" : "Off")")
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

    private func matchBlock(for match: NassauMatch, game: GameData) -> String {
        let playerNames = game.playerNames

        let frontLive = NassauEngine.runningStatusText(match.frontStatusByHole)
        let backLive = NassauEngine.runningStatusText(match.backStatusByHole)
        let totalLive = NassauEngine.runningStatusText(match.overallStatusByHole)

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
        lines.append("  Mode: \(match.scoringMode == .net ? "Net" : "Gross")")
        lines.append("  Front: \(frontLive)")
        lines.append("  Front Result: \(frontResult)")
        lines.append("  Back: \(backLive)")
        lines.append("  Back Result: \(backResult)")
        lines.append("  Total: \(totalLive)")
        lines.append("  18 Result: \(overallResult)")
        lines.append("  Presses: \(match.presses.count)")

        if !match.presses.isEmpty {
            for (index, press) in match.presses.enumerated() {
                let pressStatus = NassauEngine.runningStatusText(press.runningStatus)
                lines.append("    Press \(index + 1): H\(press.startHole)-\(press.endHole)  \(pressStatus)")
            }
        }

        lines.append("  -------------------------")
        lines.append("  NET NASSAU Status: \(netMoney)")
        lines.append("  -------------------------")

        return lines.joined(separator: "\n")
    }

    private func statusText(_ values: [Int]) -> String {
        NassauEngine.runningStatusText(values)
    }

    private func formatStake(_ value: Double) -> String {
        if value == floor(value) {
            return String(Int(value))
        } else {
            return String(format: "%.2f", value)
        }
    }
    @objc private func addPressTapped() {
        guard let game = gameData,
              let state = game.nassauState,
              state.settings.pressMode == .manual else { return }

        let ac = UIAlertController(title: "Add Press", message: "Choose a match", preferredStyle: .actionSheet)

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
    private func showSegmentPicker(matchIndex: Int, isTwoVsTwo: Bool) {
        guard let game = GameManager.shared.currentGame,
              let state = game.nassauState else { return }

        let currentHole1Based = game.hole + 1

        let match: NassauMatch = isTwoVsTwo
            ? state.twoVsTwoMatches[matchIndex]
            : state.oneVsOneMatches[matchIndex]

        let ac = UIAlertController(title: match.title, message: "Choose press segment", preferredStyle: .actionSheet)

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
        updateManualPressButton()
        renderSummary()
    }
    private func updateManualPressButton() {
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
}
