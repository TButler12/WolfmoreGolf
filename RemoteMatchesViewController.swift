//
//  RemoteMatchesViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 4/15/26.
//

import UIKit

final class RemoteMatchesViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var matches: [RemoteMatch] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Remote Matches"
        view.backgroundColor = .systemBackground
        setupTableView()
        loadMatches()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadMatches()
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MatchCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadMatches() {
        matches = RemoteMatchStore.shared.all()
        tableView.reloadData()
    }

    private func showAlert(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    // MARK: - Apply Round

    private func applyRound(to match: RemoteMatch) {
        guard let g = GameManager.shared.currentGame else {
            showAlert(title: "No Active Game", message: "Start or load a game first, then return here to apply your round.")
            return
        }

        let profileName = (ProfileStore.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !profileName.isEmpty else {
            showAlert(title: "Profile Not Set", message: "Set your name in Profile settings first.")
            return
        }

        guard let playerIndex = g.playerNames.firstIndex(where: {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedCaseInsensitiveCompare(profileName) == .orderedSame
        }) else {
            showAlert(title: "Name Mismatch", message: "Your profile name (\(profileName)) wasn't found in the current game roster.")
            return
        }

        var updated = match
        updated.myRound = SharedRoundBuilder.make(from: g, playerIndex: playerIndex)
        updated.roundApplied = true
        RemoteMatchStore.shared.update(updated)
        loadMatches()

        guard let result = updated.result else {
            showAlert(title: "Could Not Calculate", message: "Make sure your round has scores entered, then try again.")
            return
        }

        openMatch(updated, result: result)
    }

    // MARK: - Open Results

    private func openMatch(_ match: RemoteMatch, result: RemoteNassauResult) {
        guard let opponentRound = match.opponentRound else { return }
        let vc = RemoteNassauViewController()
        vc.myRound = match.myRound
        vc.opponentRound = opponentRound
        vc.result = result
        vc.compareMode = match.compareMode
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension RemoteMatchesViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        matches.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        matches.isEmpty ? "No Remote Matches Yet" : "Your Matches"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let match = matches[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "MatchCell", for: indexPath)
        var content = cell.defaultContentConfiguration()

        content.text = match.opponentName
        content.textProperties.font = .systemFont(ofSize: 18, weight: .medium)
        content.secondaryTextProperties.color = .secondaryLabel
        content.secondaryTextProperties.numberOfLines = 2

        if match.roundApplied {
            let myCourse  = match.myRound.courseName
            let oppCourse = match.opponentRound?.courseName ?? "..."
            let myCompleted  = match.myRound.scores.compactMap { $0 }.count
            let oppCompleted = match.opponentRound?.scores.compactMap { $0 }.count ?? 0
            let myHoleText  = myCompleted  >= STANDARD_HOLES ? "F" : "H\(myCompleted + 1)"
            let oppHoleText = match.opponentRound == nil
                ? "..."
                : (oppCompleted >= STANDARD_HOLES ? "F" : "H\(oppCompleted + 1)")
            content.secondaryText = "\(myCourse) (\(myHoleText)) vs \(oppCourse) (\(oppHoleText))\n\(match.statusText) • $\(match.stakePerBet)"
            cell.accessoryType = .disclosureIndicator
        } else {
            let modeLabel: String
            switch match.compareMode {
            case .holeByHole:    modeLabel = "Hole by Hole"
            case .frontBackByHC: modeLabel = "Front/Back 9 by HC"
            case .all18ByHC:     modeLabel = "18 Holes by HC"
            }
            content.secondaryText = "Accepted vs \(match.opponentName) • \(modeLabel) • $\(match.stakePerBet)\nPlay your round, then tap to apply scores"
            cell.accessoryType = .none
        }

        cell.contentConfiguration = content
        return cell
    }
}

// MARK: - UITableViewDelegate

extension RemoteMatchesViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let match = matches[indexPath.row]

        if !match.roundApplied {
            let ac = UIAlertController(
                title: "Apply Your Round",
                message: "This will snapshot your current game scores and calculate results against \(match.opponentName).",
                preferredStyle: .actionSheet
            )
            ac.addAction(UIAlertAction(title: "Apply Round & Calculate Results", style: .default) { [weak self] _ in
                self?.applyRound(to: match)
            })
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            if let pop = ac.popoverPresentationController, let cell = tableView.cellForRow(at: indexPath) {
                pop.sourceView = cell
                pop.sourceRect = cell.bounds
            }
            present(ac, animated: true)
            return
        }

        guard let result = match.result else {
            showAlert(title: "Error", message: "Could not calculate Remote Nassau result.")
            return
        }

        openMatch(match, result: result)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let match = matches[indexPath.row]

        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            RemoteMatchStore.shared.remove(matchID: match.id)
            self?.loadMatches()
            completion(true)
        }

        return UISwipeActionsConfiguration(actions: [delete])
    }
}
