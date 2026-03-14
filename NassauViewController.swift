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
        renderSummary()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadGame()
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

        if workingGame.nassauState == nil {
            GameManager.shared.update { g in
                // Nassau defaults
                g.nassauState = NassauEngine.makeDefaultState(
                    playerNames: g.playerNames,
                    activeFlags: g.playerActivated
                )
                g.recalculateNassauIfNeeded()
            }
            workingGame = GameManager.shared.currentGame ?? workingGame
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

        if let lastHole = lastCommittedHoleNumber() {
            lines.append("Through Hole: \(lastHole)")
        } else if let game = GameManager.shared.currentGame {
            lines.append("Current Hole: \(game.hole + 1)")
        } else {
            lines.append("Through Hole: —")
        }

        lines.append("")
        
        if !nassau.oneVsOneMatches.isEmpty {
            lines.append("1 vs 1 MATCHES")
            lines.append("------------------------------")
            for match in nassau.oneVsOneMatches {
                lines.append(matchBlock(for: match))
                lines.append("")
            }
        }
        if !nassau.twoVsTwoMatches.isEmpty {
            lines.append("2 vs 2 MATCHES")
            lines.append("------------------------------")
            for match in nassau.twoVsTwoMatches {
                lines.append(matchBlock(for: match))
                lines.append("")
            }
        }

        if nassau.oneVsOneMatches.isEmpty && nassau.twoVsTwoMatches.isEmpty {
            lines.append("No Nassau matches configured.")
        }

        textView.text = lines.joined(separator: "\n")
        gameData = workingGame
    }
    private func lastCommittedHoleNumber() -> Int? {
        for i in stride(from: holeCommitted.count - 1, through: 0, by: -1) {
            if holeCommitted[i] { return i + 1 }
        }
        return nil
    }
    private func matchBlock(for match: NassauMatch) -> String {
        var lines: [String] = []

        lines.append(match.title)
        lines.append("  Mode: \(match.scoringMode == .net ? "Net" : "Gross")")
        lines.append("  Front: \(statusText(match.frontStatusByHole))")
        lines.append("  Back:  \(statusText(match.backStatusByHole))")
        lines.append("  Total: \(statusText(match.overallStatusByHole))")
        lines.append("  Presses: \(match.presses.count)")

        if !match.presses.isEmpty {
            for (index, press) in match.presses.enumerated() {
                let startDisplay = press.startHole + 1
                let endDisplay = press.endHole + 1
                let pressStatus = statusText(press.runningStatus)
                lines.append("    Press \(index + 1): H\(startDisplay)-\(endDisplay)  \(pressStatus)")
            }
        }

        return lines.joined(separator: "\n")
    }

    private func statusText(_ values: [Int]) -> String {
        guard let last = values.last else { return "AS" }
        if last > 0 { return "\(last) Up" }
        if last < 0 { return "\(-last) Down" }
        return "All Square"
    }

    private func formatStake(_ value: Double) -> String {
        if value == floor(value) {
            return String(Int(value))
        } else {
            return String(format: "%.2f", value)
        }
    }
}
