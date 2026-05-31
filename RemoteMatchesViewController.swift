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
        isLoading = false
        loadMatches()
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MatchCell.self, forCellReuseIdentifier: MatchCell.reuseID)
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
                    // Newest first so the most recent match is always at the top
                    self.matches = fetched.sorted {
                        let d0 = Self.parseSupabaseDate($0.createdAt ?? "") ?? .distantPast
                        let d1 = Self.parseSupabaseDate($1.createdAt ?? "") ?? .distantPast
                        return d0 > d1
                    }
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

    private func archiveMatch(at indexPath: IndexPath) {
        let match = matches[indexPath.row]
        Task {
            do {
                try await SupabaseService.shared.archiveMatch(id: match.id)
                await MainActor.run {
                    guard indexPath.row < self.matches.count else { return }
                    self.matches.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .automatic)
                }
            } catch {
                await MainActor.run {
                    self.showAlert(title: "Could not delete match", message: error.localizedDescription)
                }
            }
        }
    }

    private func isActiveMatch(_ match: MatchRecord) -> Bool {
        guard let ids = GameManager.shared.currentGame?.remoteMatchIds, !ids.isEmpty else {
            guard let activeId = GameManager.shared.currentGame?.remoteMatchId else { return false }
            return match.id == activeId
        }
        return ids.contains(match.id)
    }

    // Supabase returns timestamps like "2026-05-30T14:22:33.123456+00:00".
    // Try progressively looser parsers until one succeeds.
    static func parseSupabaseDate(_ raw: String) -> Date? {
        let iso = ISO8601DateFormatter()
        // 1) with fractional seconds + timezone offset (most common Supabase format)
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: raw) { return d }
        // 2) without fractional seconds
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: raw) { return d }
        // 3) DateFormatter fallback for "+00:00" offset variants
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        for fmt in ["yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ",
                    "yyyy-MM-dd'T'HH:mm:ssZZZZZ"] {
            df.dateFormat = fmt
            if let d = df.date(from: raw) { return d }
        }
        return nil
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
        let cell = tableView.dequeueReusableCell(withIdentifier: MatchCell.reuseID, for: indexPath) as! MatchCell
        cell.configure(with: matches[indexPath.row], current: isActiveMatch(matches[indexPath.row]))
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

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            self?.archiveMatch(at: indexPath)
            done(true)
        }
        action.backgroundColor = .systemRed
        return UISwipeActionsConfiguration(actions: [action])
    }
}

// MARK: - MatchCell

private final class MatchCell: UITableViewCell {

    static let reuseID = "MatchCell"

    private let borderBar  = UIView()
    private let codeLabel  = UILabel()
    private let detailLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        borderBar.translatesAutoresizingMaskIntoConstraints = false
        borderBar.layer.cornerRadius = 2
        contentView.addSubview(borderBar)

        codeLabel.font = .systemFont(ofSize: 18, weight: .medium)
        codeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(codeLabel)

        detailLabel.font = .systemFont(ofSize: 13)
        detailLabel.numberOfLines = 2
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(detailLabel)

        NSLayoutConstraint.activate([
            borderBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            borderBar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            borderBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            borderBar.widthAnchor.constraint(equalToConstant: 4),

            codeLabel.leadingAnchor.constraint(equalTo: borderBar.trailingAnchor, constant: 12),
            codeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            codeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),

            detailLabel.leadingAnchor.constraint(equalTo: codeLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: codeLabel.trailingAnchor),
            detailLabel.topAnchor.constraint(equalTo: codeLabel.bottomAnchor, constant: 2),
            detailLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        ])

        accessoryType = .disclosureIndicator
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with match: MatchRecord, current: Bool) {
        codeLabel.text = "Code: \(match.code)"
        codeLabel.textColor = current ? .label : .tertiaryLabel

        let host = match.hostName?.trimmingCharacters(in: .whitespacesAndNewlines)
                     .nilIfEmpty ?? match.courseA ?? "Unknown"
        var details: [String] = ["Host: \(host)"]
        if let opp = match.opponentName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty {
            details.append("vs \(opp)")
        }
        if let raw = match.createdAt,
           let date = RemoteMatchesViewController.parseSupabaseDate(raw) {
            details.append(Self.relativeTime(from: date))
        }
        detailLabel.text = details.joined(separator: " · ")
        detailLabel.textColor = current ? .secondaryLabel : .tertiaryLabel

        borderBar.backgroundColor = current ? .systemGreen : .systemGray3
    }

    private static func relativeTime(from date: Date) -> String {
        let secs = Int(Date().timeIntervalSince(date))
        if secs < 60  { return "just now" }
        if secs < 3600 { return "\(secs / 60)m ago" }
        if secs < 86400 { return "\(secs / 3600)h ago" }
        return "\(secs / 86400)d ago"
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
