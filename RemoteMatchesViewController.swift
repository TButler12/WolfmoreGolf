//
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
}

extension RemoteMatchesViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        matches.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        matches.isEmpty ? "No Remote Matches Yet" : "Your Matches"
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let match = matches[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "MatchCell", for: indexPath)

        var content = cell.defaultContentConfiguration()
        let myCourse = match.myRound.courseName
        let oppCourse = match.opponentRound?.courseName ?? "Waiting..."

        let myCompleted = match.myRound.scores.filter { $0 != nil }.count
        let oppCompleted = match.opponentRound?.scores.filter { $0 != nil }.count ?? 0
        let myHoleText = myCompleted >= 18 ? "F" : "H\(myCompleted + 1)"
        let oppHoleText = match.opponentRound == nil
            ? "Waiting..."
            : (oppCompleted >= 18 ? "F" : "H\(oppCompleted + 1)")
        content.text = "\(match.opponentName)"

        content.secondaryText =
        """
        \(myCourse) (\(myHoleText)) vs \(oppCourse) (\(oppHoleText))
        \(match.statusText) • $\(match.stakePerBet)
        """
        content.textProperties.font = .systemFont(ofSize: 18, weight: .medium)
        content.secondaryTextProperties.color = .secondaryLabel
        content.secondaryTextProperties.numberOfLines = 2

        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator

        return cell
    }
}

extension RemoteMatchesViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let match = matches[indexPath.row]

        guard match.opponentRound != nil else {
            showAlert(title: "Match Not Ready", message: "Waiting for opponent round.")
            return
        }

        guard match.result != nil else {
            showAlert(title: "Error", message: "Could not calculate Remote Nassau result.")
            return
        }

        let ac = UIAlertController(title: "Compare Mode", message: nil, preferredStyle: .actionSheet)

        ac.addAction(UIAlertAction(title: "Hole by Hole", style: .default) { [weak self] _ in
            self?.openMatch(match, mode: .holeByHole)
        })

        ac.addAction(UIAlertAction(title: "Front / Back 9 by HC", style: .default) { [weak self] _ in
            self?.openMatch(match, mode: .frontBackByHC)
        })

        ac.addAction(UIAlertAction(title: "18 Holes by HC", style: .default) { [weak self] _ in
            self?.openMatch(match, mode: .all18ByHC)
        })

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = ac.popoverPresentationController,
           let cell = tableView.cellForRow(at: indexPath) {
            pop.sourceView = cell
            pop.sourceRect = cell.bounds
        }

        present(ac, animated: true)
    }

    private func openMatch(_ match: RemoteMatch, mode: RemoteCompareMode) {
        guard let opponentRound = match.opponentRound,
              let result = match.result else {
            showAlert(title: "Error", message: "Could not calculate Remote Nassau result.")
            return
        }

        let vc = RemoteNassauViewController()
        vc.myRound = match.myRound
        vc.opponentRound = opponentRound
        vc.result = result
        vc.compareMode = mode

        navigationController?.pushViewController(vc, animated: true)
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
