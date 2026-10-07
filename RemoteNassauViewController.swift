
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
        title = sameCourse ? "Nassau Results (Same Course)" : "Nassau Results"

        #if DEBUG
        if let g = GameManager.shared.currentGame {
            debugLocalPlayerMatch(in: g)
        }
        #endif

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

        frontLabel.text   = "Front: \(nassauText(for: result.frontScore))"
        backLabel.text    = "Back: \(nassauText(for: result.backScore))"
        overallLabel.text = "Overall: \(nassauText(for: result.overallScore))"
        totalLabel.text   = "Total Outcome: \(nassauText(for: result.totalOutcome)) (\(moneyText(for: result.dollarOutcome)))"

        styledResultLabel(frontLabel,   value: result.frontScore)
        styledResultLabel(backLabel,    value: result.backScore)
        styledResultLabel(overallLabel, value: result.overallScore)
        styledResultLabel(totalLabel,   value: result.totalOutcome)

        tableView.reloadData()
    }

    private var displayedHoles: [RemoteHoleResult] {
        result.holeResults
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
        case .playerA:  return myRound.playerName
        case .playerB:  return opponentRound.playerName
        case .tie:      return "Tie"
        case .noResult: return "-"
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

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

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

        let opponentRevealed = hole.grossA != nil
        let grossAText = hole.grossA.map(String.init) ?? "-"
        let netAText   = hole.netA.map(String.init)   ?? "-"
        let grossBText: String
        let netBText: String
        let winnerDisplay: String
        if opponentRevealed {
            grossBText   = hole.grossB.map(String.init) ?? "-"
            netBText     = hole.netB.map(String.init)   ?? "-"
            winnerDisplay = winnerText(for: hole.winner)
        } else {
            grossBText   = hole.grossB != nil ? "✓" : "-"
            netBText     = "-"
            winnerDisplay = "-"
        }

        if hole.holeNumberA == hole.holeNumberB {
            content.text = "Hole \(hole.holeNumberA): Gross \(grossAText) - \(grossBText)"
        } else {
            let rank = (indexPath.row % 9) + 1
            content.text = "HC\(rank): Hole \(hole.holeNumberA) vs Hole \(hole.holeNumberB): Gross \(grossAText) - \(grossBText)"
        }

        content.secondaryText = """
        Net: \(netAText) - \(netBText)   Strokes: \(hole.strokesA) - \(hole.strokesB)
        Winner: \(winnerDisplay)
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

    #if DEBUG
    private func debugLocalPlayerMatch(in g: GameData) {
        print("ProfileStore.name =", ProfileStore.name ?? "nil")
        print("Round players =", g.playerNames)
        print("Resolved myPlayerIndex =", myPlayerIndex(in: g) as Any)
    }
    #endif

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
        let me   = myRound.playerName
        let them = opponentRound.playerName

        func segmentLine(_ label: String, _ score: Int) -> String {
            if score > 0 { return "\(label): \(me) wins" }
            if score < 0 { return "\(label): \(them) wins" }
            return "\(label): Tied"
        }

        let moneyLine: String
        if result.dollarOutcome > 0 {
            moneyLine = "\(them) owes \(me): $\(result.dollarOutcome)"
        } else if result.dollarOutcome < 0 {
            moneyLine = "\(me) owes \(them): $\(abs(result.dollarOutcome))"
        } else {
            moneyLine = "All square — no money owed"
        }

        return """
        WolfMore Nassau Results
        \(me) vs \(them)
        \(me) @ \(myRound.courseName)
        \(them) @ \(opponentRound.courseName)
        \(segmentLine("Front", result.frontScore))
        \(segmentLine("Back", result.backScore))
        \(segmentLine("Overall", result.overallScore))
        \(moneyLine)
        """
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                      didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
    }
}
