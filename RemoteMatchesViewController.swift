//
//  RemoteMatchesViewController.swift
//  WolfmoreGolf
//
import UIKit

final class RemoteMatchesViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var matches: [MatchRecord] = []
    private var isLoading = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Remote Matches"
        view.backgroundColor = .systemBackground
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isLoading = false   // reset so viewWillAppear always triggers a fresh fetch
        loadMatches()
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MatchCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 64

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func loadMatches() {
        guard !isLoading else { return }
        isLoading = true
        Task {
            do {
                let fetched = try await SupabaseService.shared.fetchActiveMatches()
                await MainActor.run {
                    self.matches = fetched
                    self.isLoading = false
                    self.tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.showAlert(title: "Load Failed", message: error.localizedDescription)
                }
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension RemoteMatchesViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        matches.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        isLoading ? "Loading…" : (matches.isEmpty ? "No Active Matches" : "Active Matches")
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let match = matches[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "MatchCell", for: indexPath)
        var content = cell.defaultContentConfiguration()

        content.text = "Code: \(match.code)"
        content.textProperties.font = .systemFont(ofSize: 18, weight: .medium)

        var details: [String] = ["Status: \(match.status.capitalized)"]
        if let courseA = match.courseA, !courseA.isEmpty {
            details.append("Host: \(courseA)")
        }
        if let courseB = match.courseB, !courseB.isEmpty {
            details.append("Guest: \(courseB)")
        }
        content.secondaryText = details.joined(separator: " · ")
        content.secondaryTextProperties.color = .secondaryLabel

        cell.accessoryType = .disclosureIndicator
        cell.contentConfiguration = content
        return cell
    }
}

// MARK: - UITableViewDelegate

extension RemoteMatchesViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let match = matches[indexPath.row]
        let vc = LiveNassauViewController()
        vc.match = match
        navigationController?.pushViewController(vc, animated: true)
    }
}
