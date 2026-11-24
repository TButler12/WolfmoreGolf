import UIKit

/// Pre-submit review of the group's 18-hole scorecard. Scorer confirms gross entries
/// per hole, then taps Submit Card to lock the group's results.
final class ClubEventReviewSubmitViewController: UITableViewController {

    static let darkGreen = UIColor(red: 0.118, green: 0.227, blue: 0.165, alpha: 1.0)

    private let tournamentId: UUID
    private let groupCode:    String
    private let players:      [ClubEventGroupPlayer]
    private let entries:      [UUID: [Int: ClubEventScoringViewController.HoleEntry]]
    private let coursePars:   [Int]
    private let courseHCs:    [Int]

    private var holeCount: Int { coursePars.count }
    private var teamOrder: [String] {
        ["A", "B"].filter { team in players.contains { $0.teams.contains(team) } }
    }

    init(tournamentId: UUID,
         groupCode: String,
         players: [ClubEventGroupPlayer],
         entries: [UUID: [Int: ClubEventScoringViewController.HoleEntry]],
         coursePars: [Int],
         courseHCs:  [Int]) {
        self.tournamentId = tournamentId
        self.groupCode    = groupCode
        self.players      = players
        self.entries      = entries
        self.coursePars   = coursePars
        self.courseHCs    = courseHCs
        super.init(style: .insetGrouped)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Review & Submit"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.largeTitleDisplayMode = .never
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }

    private var hasAnyMissing: Bool {
        for team in teamOrder {
            let teamPlayers = players.filter { $0.teams.contains(team) }
            for hole in 1...holeCount {
                let anyScored = teamPlayers.contains {
                    let e = entries[$0.id]?[hole]
                    return (e?.gross ?? 0) > 0 || e?.pickedUp == true
                }
                if !anyScored { return true }
            }
        }
        return false
    }

    private var pickedUpSummary: [(name: String, holes: [Int])] {
        players.compactMap { p in
            let holes = (1...holeCount).filter { entries[p.id]?[$0]?.pickedUp == true }
            return holes.isEmpty ? nil : (p.name, holes)
        }
    }

    private var hasPickedUp: Bool { !pickedUpSummary.isEmpty }

    // section layout: [team sections...] [picked-up summary?] [submit]
    private var submitSection: Int { teamOrder.count + (hasPickedUp ? 1 : 0) }
    private var pickedUpSection: Int { teamOrder.count }

    override func numberOfSections(in tableView: UITableView) -> Int {
        teamOrder.count + (hasPickedUp ? 1 : 0) + 1
    }

    override func tableView(_ tv: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section < teamOrder.count {
            let team = teamOrder[section]
            let names = players.filter { $0.teams.contains(team) }
                .map { lastName(of: $0.name) }
                .sorted()
                .joined(separator: " / ")
            return names.uppercased()
        }
        if hasPickedUp && section == pickedUpSection { return "PICKED UP" }
        return nil
    }

    override func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < teamOrder.count { return holeCount }
        if hasPickedUp && section == pickedUpSection { return pickedUpSummary.count }
        return 1
    }

    override func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == submitSection { return submitCell() }
        if hasPickedUp && indexPath.section == pickedUpSection {
            return pickedUpSummaryCell(indexPath.row)
        }
        let team = teamOrder[indexPath.section]
        let teamPlayers = players.filter { $0.teams.contains(team) }
        let hole = indexPath.row + 1
        return holeCell(team: team, teamPlayers: teamPlayers, hole: hole)
    }

    private func pickedUpSummaryCell(_ row: Int) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.selectionStyle = .none
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        let entry = pickedUpSummary[row]
        let holeList = entry.holes.map { "hole \($0)" }.joined(separator: ", ")
        var cfg = cell.defaultContentConfiguration()
        cfg.text = entry.name
        cfg.secondaryText = "P on \(holeList)"
        cfg.secondaryTextProperties.color = .systemOrange
        cell.contentConfiguration = cfg
        return cell
    }

    private func holeCell(team: String, teamPlayers: [ClubEventGroupPlayer], hole: Int) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.selectionStyle = .none
        cell.accessoryType = .none

        let holeLabel = UILabel()
        holeLabel.text = "Hole \(hole)  ·  Par \(coursePars[hole - 1])"
        holeLabel.font = .preferredFont(forTextStyle: .caption1)
        holeLabel.adjustsFontForContentSizeCategory = true
        holeLabel.textColor = .secondaryLabel
        holeLabel.translatesAutoresizingMaskIntoConstraints = false

        let scoresLabel = UILabel()
        scoresLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .regular)
        scoresLabel.numberOfLines = 0
        scoresLabel.translatesAutoresizingMaskIntoConstraints = false

        var parts: [String] = []
        var anyScored = false
        var bestNet: Int?
        let holeHC = courseHCs[hole - 1]

        for p in teamPlayers {
            let e = entries[p.id]?[hole] ?? ClubEventScoringViewController.HoleEntry()
            let strokes = strokesOnHole(playerHC: p.handicap, holeHCRank: holeHC)
            if e.pickedUp {
                parts.append("\(lastName(of: p.name)): P")
                anyScored = true
            } else if e.gross > 0 {
                let net = e.gross - strokes
                parts.append("\(lastName(of: p.name)): \(e.gross) (net \(net))")
                anyScored = true
                if bestNet == nil || net < bestNet! { bestNet = net }
            } else {
                parts.append("\(lastName(of: p.name)): —")
            }
        }
        scoresLabel.text = parts.joined(separator: "\n")

        let summary = UILabel()
        summary.font = .preferredFont(forTextStyle: .caption1)
        summary.adjustsFontForContentSizeCategory = true
        summary.translatesAutoresizingMaskIntoConstraints = false
        if teamPlayers.count <= 1 {
            summary.text = anyScored ? "" : "Missing score"
            summary.textColor = anyScored ? .clear : .systemOrange
        } else if let b = bestNet {
            let diff = b - coursePars[hole - 1]
            let s = diff == 0 ? "E" : (diff > 0 ? "+\(diff)" : "\(diff)")
            summary.text = "Best net: \(b) (\(s))"
            summary.textColor = .systemGreen
        } else if anyScored {
            summary.text = ""
            summary.textColor = .clear
        } else {
            summary.text = "Missing score"
            summary.textColor = .systemOrange
        }

        cell.contentView.addSubview(holeLabel)
        cell.contentView.addSubview(scoresLabel)
        cell.contentView.addSubview(summary)
        NSLayoutConstraint.activate([
            holeLabel.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
            holeLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            holeLabel.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),

            scoresLabel.topAnchor.constraint(equalTo: holeLabel.bottomAnchor, constant: 4),
            scoresLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            scoresLabel.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),

            summary.topAnchor.constraint(equalTo: scoresLabel.bottomAnchor, constant: 4),
            summary.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            summary.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            summary.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),
        ])
        return cell
    }

    private func submitCell() -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.selectionStyle = .none
        cell.accessoryType = .none

        var cfg = UIButton.Configuration.filled()
        cfg.baseBackgroundColor = Self.darkGreen
        cfg.baseForegroundColor = .white
        cfg.cornerStyle = .large
        cfg.title = "Submit Card"
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        let btn = UIButton(configuration: cfg)
        btn.isEnabled = !hasAnyMissing
        btn.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false

        cell.contentView.addSubview(btn)
        NSLayoutConstraint.activate([
            btn.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            btn.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            btn.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
            btn.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -12),
            btn.heightAnchor.constraint(greaterThanOrEqualToConstant: 52),
        ])

        if hasAnyMissing {
            let hint = UILabel()
            hint.text = "Fill in all \(holeCount) holes before submitting."
            hint.font = .preferredFont(forTextStyle: .footnote)
            hint.adjustsFontForContentSizeCategory = true
            hint.textColor = .systemOrange
            hint.textAlignment = .center
            hint.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(hint)
            NSLayoutConstraint.activate([
                hint.topAnchor.constraint(equalTo: btn.bottomAnchor, constant: 6),
                hint.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                hint.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                hint.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -12),
            ])
        }
        return cell
    }

    @objc private func submitTapped() {
        let ac = UIAlertController(
            title: "Submit Card?",
            message: "Once submitted, scores for this group are locked.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Submit", style: .default) { [weak self] _ in
            self?.performSubmit()
        })
        present(ac, animated: true)
    }

    private func performSubmit() {
        let spinner = UIAlertController(title: nil, message: "Submitting…", preferredStyle: .alert)
        present(spinner, animated: true)
        Task {
            do {
                try await SupabaseService.shared.submitClubEventCard(
                    tournamentId: tournamentId, groupCode: groupCode)
                ClubEventSessionStore.shared.clear()
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        let done = UIAlertController(
                            title: "Card Submitted",
                            message: "Thank you! Your group's results are recorded.",
                            preferredStyle: .alert
                        )
                        done.addAction(UIAlertAction(title: "Done", style: .default) { _ in
                            self.navigationController?.popToRootViewController(animated: true)
                        })
                        self.present(done, animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        let ac = UIAlertController(
                            title: "Submit Failed",
                            message: error.localizedDescription,
                            preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ac, animated: true)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func lastName(of name: String) -> String {
        name.components(separatedBy: " ").last ?? name
    }

    private func strokesOnHole(playerHC: Double, holeHCRank: Int) -> Int {
        var hc = max(0, Int(playerHC.rounded()))
        if holeCount == 9 { hc = Int((Double(hc) / 2.0).rounded()) }
        return hc / holeCount + (holeHCRank <= hc % holeCount ? 1 : 0)
    }
}
