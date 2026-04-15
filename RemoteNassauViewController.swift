
//
//  RemoteNassauViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 4/10/26.
//
import UIKit

final class RemoteNassauViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var myRound: SharedRound!
    var opponentRound: SharedRound!
    var result: RemoteNassauResult!
    var compareMode: RemoteCompareMode = .holeByHole
    private let matchupLabel = UILabel()
    private let frontLabel = UILabel()
    private let backLabel = UILabel()
    private let overallLabel = UILabel()
    private let totalLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        switch compareMode {
        case .holeByHole:
            title = "Hole by Hole"
        case .frontBackByHC:
            title = "Front / Back 9 by HC"
        case .all18ByHC:
            title = "18 Holes by HC"
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

        matchupLabel.translatesAutoresizingMaskIntoConstraints = false
        summaryStack.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(matchupLabel)
        view.addSubview(summaryStack)
        view.addSubview(tableView)

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
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func populateUI() {
        matchupLabel.text = "\(myRound.playerName) vs \(opponentRound.playerName)"

        frontLabel.text = "Front: \(nassauText(for: result.frontScore))"
        backLabel.text = "Back: \(nassauText(for: result.backScore))"
        overallLabel.text = "Overall: \(nassauText(for: result.overallScore))"
        totalLabel.text = "Total Outcome: \(nassauText(for: result.totalOutcome)) (\(moneyText(for: result.dollarOutcome)))"

        styledResultLabel(frontLabel, value: result.frontScore)
        styledResultLabel(backLabel, value: result.backScore)
        styledResultLabel(overallLabel, value: result.overallScore)
        styledResultLabel(totalLabel, value: result.totalOutcome)

        tableView.reloadData()
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
        result?.holeResults.count ?? 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "Hole-by-hole"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let hole = displayedHoles[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "HoleCell", for: indexPath)

        var content = cell.defaultContentConfiguration()

        let grossAText = hole.grossA.map { "\($0)" } ?? "-"
        let grossBText = hole.grossB.map { "\($0)" } ?? "-"

        let netAText = hole.netA.map { "\($0)" } ?? "-"
        let netBText = hole.netB.map { "\($0)" } ?? "-"

        let prefix: String
        if compareMode == .frontBackByHC {
            prefix = indexPath.row < 9 ? "F9 • " : "B9 • "
        } else {
            prefix = ""
        }

        let hcText: String
        switch compareMode {
        case .holeByHole:
            hcText = ""
        case .frontBackByHC, .all18ByHC:
            hcText = " • HC \(hole.holeHandicapA)"
        }

        content.text = "\(prefix)Hole \(hole.holeNumber)\(hcText): Gross \(grossAText) - \(grossBText)"
        content.secondaryText = """
        Net: \(netAText) - \(netBText)   Strokes: \(hole.strokesA) - \(hole.strokesB)
        Winner: \(winnerText(for: hole.winner))
        """

        content.textProperties.font = .systemFont(ofSize: 18, weight: .medium)
        content.secondaryTextProperties.font = .systemFont(ofSize: 15, weight: .regular)
        content.secondaryTextProperties.color = .secondaryLabel
        content.secondaryTextProperties.numberOfLines = 0

        cell.contentConfiguration = content
        cell.selectionStyle = .none

        return cell
    }
    private var displayedHoles: [RemoteHoleResult] {
        guard let myRound, let opponentRound else {
            return result.holeResults
        }

        switch compareMode {
        case .holeByHole:
            return result.holeResults

        case .frontBackByHC:
            let front = RemoteNassauScorer.sortedFront9ByHCA(playerA: myRound, playerB: opponentRound)
            let back = RemoteNassauScorer.sortedBack9ByHCA(playerA: myRound, playerB: opponentRound)
            return front + back

        case .all18ByHC:
            return RemoteNassauScorer.sortedAll18ByHCA(playerA: myRound, playerB: opponentRound)
        }
    }
    
    private func myPlayerIndex(in g: GameData) -> Int? {
        let myName = (ProfileStore.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !myName.isEmpty else { return nil }

        return g.playerNames.firstIndex {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedCaseInsensitiveCompare(myName) == .orderedSame
        }
    }
    private func debugLocalPlayerMatch(in g: GameData) {
        print("ProfileStore.name =", ProfileStore.name ?? "nil")
        print("Round players =", g.playerNames)
        print("Resolved myPlayerIndex =", myPlayerIndex(in: g) as Any)
    }
}
