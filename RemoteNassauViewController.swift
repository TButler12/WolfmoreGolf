
//  RemoteNassauViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 4/10/26.
//

import UIKit
import MessageUI

final class RemoteNassauViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MFMessageComposeViewControllerDelegate {

    var myRound: SharedRound!
    var opponentRound: SharedRound!
    var result: RemoteNassauResult!
    var compareMode: RemoteCompareMode = .holeByHole
    var sameCourse: Bool = false

    private let matchupLabel = UILabel()
    private let frontLabel = UILabel()
    private let backLabel = UILabel()
    private let overallLabel = UILabel()
    private let totalLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let sendResultsButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        if sameCourse {
            title = "Hole by Hole (Same Course)"
        } else {
            switch compareMode {
            case .holeByHole:    title = "Hole by Hole"
            case .frontBackByHC: title = "Front / Back 9 by HC"
            case .all18ByHC:     title = "18 Holes by HC"
            }
        }

        if let g = GameManager.shared.currentGame {
            debugLocalPlayerMatch(in: g)
        }

        setupUI()
        populateUI()
    }

    private func setupUI() {
        matchupLabel.font = .boldSystemFont(ofSize: 24)
        matchupLabel.textAlignment = .center
        matchupLabel.numberOfLines = 0

        frontLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        backLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        overallLabel.font = .systemFont(ofSize: 20, weight: .bold)
        totalLabel.font = .systemFont(ofSize: 20, weight: .bold)

        let summaryStack = UIStackView(arrangedSubviews: [frontLabel, backLabel, overallLabel, totalLabel])
        summaryStack.axis = .vertical
        summaryStack.spacing = 12

        var btnCfg = UIButton.Configuration.filled()
        btnCfg.title = "Send Results"
        btnCfg.cornerStyle = .large
        btnCfg.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 32, bottom: 14, trailing: 32)
        sendResultsButton.configuration = btnCfg
        sendResultsButton.addTarget(self, action: #selector(sendResultsTapped), for: .touchUpInside)

        matchupLabel.translatesAutoresizingMaskIntoConstraints = false
        summaryStack.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        sendResultsButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(matchupLabel)
        view.addSubview(summaryStack)
        view.addSubview(tableView)
        view.addSubview(sendResultsButton)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HoleCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 96

        NSLayoutConstraint.activate([
            matchupLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            matchupLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            matchupLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            summaryStack.topAnchor.constraint(equalTo: matchupLabel.bottomAnchor, constant: 20),
            summaryStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            summaryStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            tableView.topAnchor.constraint(equalTo: summaryStack.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: sendResultsButton.topAnchor, constant: -16),

            sendResultsButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            sendResultsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sendResultsButton.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            sendResultsButton.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40),
        ])
    }

    private func populateUI() {
        matchupLabel.text = "\(myRound.playerName) vs \(opponentRound.playerName)"

        let holes = displayedHoles
        let front = Array(holes.prefix(9))
        let back = Array(holes.suffix(9))

        let frontScore = scoreSlice(front)
        let backScore = scoreSlice(back)
        let overallScore = scoreSlice(holes)

        let totalOutcome = frontScore + backScore + overallScore
        let dollarOutcome = totalOutcome * result.stakePerBet

        frontLabel.text = "Front: \(nassauText(for: frontScore))"
        backLabel.text = "Back: \(nassauText(for: backScore))"
        overallLabel.text = "Overall: \(nassauText(for: overallScore))"
        totalLabel.text = "Total Outcome: \(nassauText(for: totalOutcome)) (\(moneyText(for: dollarOutcome)))"

        styledResultLabel(frontLabel, value: frontScore)
        styledResultLabel(backLabel, value: backScore)
        styledResultLabel(overallLabel, value: overallScore)
        styledResultLabel(totalLabel, value: totalOutcome)

        tableView.reloadData()
    }
    private var displayedHoles: [RemoteHoleResult] {
        guard myRound != nil, opponentRound != nil else {
            return result.holeResults
        }

        // Same course: always use natural hole-number order — no HC alignment needed
        if sameCourse || compareMode == .holeByHole {
            return result.holeResults.sorted { $0.holeNumberA < $1.holeNumberA }
        }

        switch compareMode {
        case .holeByHole:
            return result.holeResults.sorted { $0.holeNumberA < $1.holeNumberA }
        case .frontBackByHC:
            let front = RemoteNassauScorer.sortedFront9ByHCA(playerA: myRound, playerB: opponentRound)
            let back  = RemoteNassauScorer.sortedBack9ByHCA(playerA: myRound, playerB: opponentRound)
            return front + back
        case .all18ByHC:
            return RemoteNassauScorer.sortedAll18ByHCA(playerA: myRound, playerB: opponentRound)
        }
    }

    private func moneyText(for value: Int) -> String {
        if value > 0 { return "+$\(value)" }
        if value < 0 { return "-$\(abs(value))" }
        return "$0"
    }

    private func nassauText(for value: Int) -> String {
        if value > 0 { return "\(value) up" }
        if value < 0 { return "\(-value) down" }
        return "All square"
    }

    private func winnerText(for winner: RemoteHoleWinner) -> String {
        switch winner {
        case .playerA:
            return myRound.playerName
        case .playerB:
            return opponentRound.playerName
        case .tie:
            return "Tie"
        case .noResult:
            return "-"
        }
    }

    private func styledResultLabel(_ label: UILabel, value: Int) {
        if value > 0 {
            label.textColor = .systemGreen
        } else if value < 0 {
            label.textColor = .systemRed
        } else {
            label.textColor = .label
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displayedHoles.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "Hole-by-hole"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let hole = displayedHoles[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "HoleCell", for: indexPath)

        var content = cell.defaultContentConfiguration()

        let grossAText = hole.grossA.map(String.init) ?? "-"
        let grossBText = hole.grossB.map(String.init) ?? "-"
        let netAText = hole.netA.map(String.init) ?? "-"
        let netBText = hole.netB.map(String.init) ?? "-"

        let prefix: String
        switch compareMode {
        case .frontBackByHC:
            prefix = indexPath.row < 9 ? "F9 • " : "B9 • "
        case .holeByHole, .all18ByHC:
            prefix = ""
        }

        let displayHC: Int
        switch compareMode {
        case .frontBackByHC:
            displayHC = hole.holeHandicapA
        case .all18ByHC:
            displayHC = hole.holeHandicapA
        case .holeByHole:
            displayHC = hole.holeHandicapA
        }

        switch compareMode {
        case .holeByHole:
            content.text = "Hole \(hole.holeNumberA): Gross \(grossAText) - \(grossBText)"

        case .frontBackByHC:
            content.text = "\(prefix)HC \(displayHC): Hole \(hole.holeNumberA) vs Hole \(hole.holeNumberB): Gross \(grossAText) - \(grossBText)"

        case .all18ByHC:
            let isFront = indexPath.row < 9
            let prefix = isFront ? "F9" : "B9"

            // HC 1–9 for front, 10–18 for back
            let displayHC = isFront
                ? (indexPath.row + 1)
                : (indexPath.row + 1)

            content.text = "\(prefix) • HC \(displayHC): Hole \(hole.holeNumberA) vs Hole \(hole.holeNumberB): Gross \(grossAText) - \(grossBText)"
        }

        content.secondaryText = """
        Net: \(netAText) - \(netBText)   Strokes: \(hole.strokesA) - \(hole.strokesB)
        Winner: \(winnerText(for: hole.winner))
        """

        content.textProperties.font = .systemFont(ofSize: 18, weight: .semibold)
        content.secondaryTextProperties.color = .secondaryLabel
        content.secondaryTextProperties.numberOfLines = 2

        cell.contentConfiguration = content
        cell.selectionStyle = .none
        return cell
    }

    private func myPlayerIndex(in g: GameData) -> Int? {
        let myName = (ProfileStore.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !myName.isEmpty else { return nil }

        return g.playerNames.firstIndex {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedCaseInsensitiveCompare(myName) == .orderedSame
        }
    }
    private func scoreSlice(_ holes: [RemoteHoleResult]) -> Int {
        var total = 0

        for hole in holes {
            switch hole.winner {
            case .playerA: total += 1
            case .playerB: total -= 1
            case .tie, .noResult: break
            }
        }

        if total > 0 { return 1 }
        if total < 0 { return -1 }
        return 0
    }
    private func debugLocalPlayerMatch(in g: GameData) {
        print("ProfileStore.name =", ProfileStore.name ?? "nil")
        print("Round players =", g.playerNames)
        print("Resolved myPlayerIndex =", myPlayerIndex(in: g) as Any)
    }

    // MARK: - Send Results

    @objc private func sendResultsTapped() {
        let message = buildResultsSummary()

        if MFMessageComposeViewController.canSendText() {
            let composer = MFMessageComposeViewController()
            composer.messageComposeDelegate = self
            composer.body = message
            present(composer, animated: true)
        } else {
            UIPasteboard.general.string = message
            let ac = UIAlertController(
                title: "Results Copied",
                message: "Messages isn't available on this device. The results summary was copied to the clipboard.",
                preferredStyle: .alert
            )
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }

    private func buildResultsSummary() -> String {
        let holes = displayedHoles
        let front = Array(holes.prefix(9))
        let back  = Array(holes.suffix(9))

        let frontScore   = scoreSlice(front)
        let backScore    = scoreSlice(back)
        let overallScore = scoreSlice(holes)
        let totalOutcome = frontScore + backScore + overallScore
        let dollars      = totalOutcome * result.stakePerBet

        let me   = myRound.playerName
        let them = opponentRound.playerName

        func segmentLine(_ label: String, _ score: Int) -> String {
            if score > 0 { return "\(label): \(me) wins" }
            if score < 0 { return "\(label): \(them) wins" }
            return "\(label): Tied"
        }

        let moneyLine: String
        if dollars > 0 {
            moneyLine = "\(them) owes \(me): $\(dollars)"
        } else if dollars < 0 {
            moneyLine = "\(me) owes \(them): $\(abs(dollars))"
        } else {
            moneyLine = "All square — no money owed"
        }

        let modeLabel: String
        switch compareMode {
        case .holeByHole:    modeLabel = "Hole by Hole"
        case .frontBackByHC: modeLabel = "Front/Back 9 by HC"
        case .all18ByHC:     modeLabel = "18 Holes by HC"
        }

        return """
        WolfMore Nassau Results
        \(me) vs \(them)
        Mode: \(modeLabel)
        \(me) @ \(myRound.courseName)
        \(them) @ \(opponentRound.courseName)
        \(segmentLine("Front", frontScore))
        \(segmentLine("Back", backScore))
        \(segmentLine("Overall", overallScore))
        \(moneyLine)
        """
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                      didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
    }
}
