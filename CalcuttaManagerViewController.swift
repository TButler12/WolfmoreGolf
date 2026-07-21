import UIKit

final class CalcuttaManagerViewController: UIViewController {

    private var event: CalcuttaEvent
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    init(event: CalcuttaEvent) {
        self.event = event
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = event.name
        view.backgroundColor = .systemGroupedBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Share", style: .plain, target: self, action: #selector(shareTapped))

        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        refreshTableHeader()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let saved = CalcuttaStore.shared.events.first(where: { $0.id == event.id }) {
            event = saved
            title = event.name
        }
        tableView.reloadData()
        refreshTableHeader()
    }

    // MARK: - Table header (pot total)

    private func refreshTableHeader() {
        let container = UIView()
        container.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 64)

        let potLabel = UILabel()
        potLabel.text = "Total Pot: \(calcuttaFormatMoney(event.totalPot))"
        potLabel.font = .systemFont(ofSize: 24, weight: .bold)
        potLabel.textAlignment = .center
        potLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(potLabel)
        NSLayoutConstraint.activate([
            potLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            potLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
        tableView.tableHeaderView = container
    }

    // MARK: - Sections

    private enum Section: Int, CaseIterable {
        case teams, payouts, leaderboard

        var header: String {
            switch self {
            case .teams:       return "Teams  (max 30)"
            case .payouts:     return "Payouts"
            case .leaderboard: return "Leaderboard"
            }
        }
    }

    // MARK: - Helpers

    private func save() { CalcuttaStore.shared.save(event) }

    private func syncLeaderboard() {
        let teamNames = Set(event.teams.map { $0.teamName })
        event.day1Board.removeAll { !teamNames.contains($0.teamName) }
        event.day2Board.removeAll { !teamNames.contains($0.teamName) }
    }

    // Teams sorted by (D1+D2) descending; unscored teams at bottom
    private func combinedSort() -> [(team: CalcuttaTeam, d1: Int?, d2: Int?)] {
        event.teams.map { team in
            let d1 = event.day1Board.first(where: { $0.teamName == team.teamName })?.points
            let d2 = event.day2Board.first(where: { $0.teamName == team.teamName })?.points
            return (team, d1, d2)
        }.sorted { a, b in
            let aHas = a.d1 != nil || a.d2 != nil
            let bHas = b.d1 != nil || b.d2 != nil
            if aHas != bHas { return aHas }
            return ((a.d1 ?? 0) + (a.d2 ?? 0)) > ((b.d1 ?? 0) + (b.d2 ?? 0))
        }
    }

    // True when at least one scored team is missing a Day 2 entry — payouts not yet final.
    private var day2IsIncomplete: Bool {
        let scored = combinedSort().filter { $0.d1 != nil || $0.d2 != nil }
        guard !scored.isEmpty else { return false }
        return scored.contains { $0.d2 == nil }
    }

    // Tie-aware payout: splits combined payout for tied positions evenly.
    // BOW-labeled rows are excluded from rank-based assignment entirely.
    // Appends "(est.)" when Day 2 scores are still incomplete.
    private func payoutForTeam(at position: Int, in sorted: [(team: CalcuttaTeam, d1: Int?, d2: Int?)]) -> String? {
        guard position < sorted.count else { return nil }
        let item = sorted[position]
        guard item.d1 != nil || item.d2 != nil else { return nil }
        let myTotal = (item.d1 ?? 0) + (item.d2 ?? 0)

        let scored = sorted.filter { $0.d1 != nil || $0.d2 != nil }
        // Rank of first team in this tie group (0-based)
        let firstRank = scored.filter { ($0.d1 ?? 0) + ($0.d2 ?? 0) > myTotal }.count
        // How many teams share this total
        let tieCount  = scored.filter { ($0.d1 ?? 0) + ($0.d2 ?? 0) == myTotal }.count

        // Payout rows that represent ranked positions (skip BOW)
        let rankedRows = event.payoutRows.filter {
            !$0.label.localizedCaseInsensitiveContains("BOW")
        }

        // Which of the tied positions fall within the paid range?
        let paidPositions = (firstRank..<(firstRank + tieCount)).filter { $0 < rankedRows.count }
        guard !paidPositions.isEmpty else { return nil }

        let combined = paidPositions.reduce(0.0) {
            $0 + event.totalPot * rankedRows[$1].percentage / 100.0
        }
        let split = combined / Double(tieCount)
        guard split > 0 else { return nil }

        let est = day2IsIncomplete ? " (est.)" : ""
        return tieCount > 1 ? "\(calcuttaFormatMoney(split)) ea.\(est)" : "\(calcuttaFormatMoney(split))\(est)"
    }

    private func updateBoard(_ board: inout [CalcuttaLeaderboardEntry], teamName: String, points: Int?) {
        if let idx = board.firstIndex(where: { $0.teamName == teamName }) {
            if let points { board[idx].points = points } else { board.remove(at: idx) }
        } else if let points {
            board.append(CalcuttaLeaderboardEntry(teamName: teamName, points: points))
        }
    }

    // MARK: - Team actions

    private func addTeam() {
        guard event.teams.count < 30 else { return }
        let vc = CalcuttaTeamEditorViewController(eventID: event.id, team: nil, nextOrder: event.teams.count)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func editTeam(at index: Int) {
        let vc = CalcuttaTeamEditorViewController(eventID: event.id, team: event.teams[index], nextOrder: index)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func quickBid(at index: Int) {
        let team = event.teams[index]
        let ac = UIAlertController(title: "Set Bid — \(team.teamName)", message: nil, preferredStyle: .alert)
        ac.addTextField { tf in
            tf.placeholder = "Bid amount ($)"
            tf.keyboardType = .decimalPad
            tf.text = team.bidAmount > 0
                ? (team.bidAmount.truncatingRemainder(dividingBy: 1) == 0
                   ? String(Int(team.bidAmount)) : String(team.bidAmount))
                : ""
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak ac] _ in
            guard let self else { return }
            let text = ac?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            self.event.teams[index].bidAmount = Double(text) ?? 0
            self.save()
            self.tableView.reloadRows(at: [IndexPath(row: index, section: Section.teams.rawValue)], with: .none)
            self.refreshTableHeader()
        })
        present(ac, animated: true)
    }

    // MARK: - Payout actions

    private func addPayout() { presentPayoutEditor(index: nil) }
    private func editPayout(at index: Int) { presentPayoutEditor(index: index) }

    private func presentPayoutEditor(index: Int?) {
        let existing = index.map { event.payoutRows[$0] }
        let isNew = existing == nil
        let ac = UIAlertController(
            title: isNew ? "Add Payout Position" : "Edit Payout Position",
            message: nil, preferredStyle: .alert)

        ac.addTextField { tf in
            tf.placeholder = "Label (e.g. 1st, 2nd, BOW)"
            tf.text = existing?.label
            tf.autocapitalizationType = .words
            tf.autocorrectionType = .no
        }
        ac.addTextField { tf in
            tf.placeholder = "Percentage (0–100)"
            tf.text = existing.map { pct in
                pct.percentage.truncatingRemainder(dividingBy: 1) == 0
                    ? String(Int(pct.percentage)) : String(pct.percentage)
            }
            tf.keyboardType = .decimalPad
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let idx = index {
            ac.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                self?.event.payoutRows.remove(at: idx)
                self?.save()
                self?.tableView.reloadSections([Section.payouts.rawValue], with: .automatic)
            })
        }

        ac.addAction(UIAlertAction(title: isNew ? "Add" : "Save", style: .default) { [weak self, weak ac] _ in
            guard let self else { return }
            let label = (ac?.textFields?[0].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let pctStr = (ac?.textFields?[1].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !label.isEmpty, let pct = Double(pctStr), pct > 0 else { return }
            if let idx = index {
                self.event.payoutRows[idx].label = label
                self.event.payoutRows[idx].percentage = pct
            } else {
                self.event.payoutRows.append(CalcuttaPayoutRow(label: label, percentage: pct))
            }
            self.save()
            self.tableView.reloadSections([Section.payouts.rawValue], with: .automatic)
            self.refreshTableHeader()
        })

        present(ac, animated: true)
    }

    // MARK: - Leaderboard actions

    private func editCombinedEntry(teamName: String) {
        let d1 = event.day1Board.first(where: { $0.teamName == teamName })?.points
        let d2 = event.day2Board.first(where: { $0.teamName == teamName })?.points

        let ac = UIAlertController(title: teamName, message: "Stableford points", preferredStyle: .alert)
        ac.addTextField { tf in
            tf.placeholder = "Day 1 points"
            tf.keyboardType = .numberPad
            if let d1 { tf.text = "\(d1)" }
        }
        ac.addTextField { tf in
            tf.placeholder = "Day 2 points"
            tf.keyboardType = .numberPad
            if let d2 { tf.text = "\(d2)" }
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak ac] _ in
            guard let self else { return }
            let newD1 = Int((ac?.textFields?[0].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines))
            let newD2 = Int((ac?.textFields?[1].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines))
            self.updateBoard(&self.event.day1Board, teamName: teamName, points: newD1)
            self.updateBoard(&self.event.day2Board, teamName: teamName, points: newD2)
            self.save()
            self.tableView.reloadSections([Section.leaderboard.rawValue], with: .automatic)
        })
        present(ac, animated: true)
    }

    private func editBowWinner() {
        let ac = UIAlertController(title: "BOW Winner", message: "Best of Worst", preferredStyle: .alert)
        ac.addTextField { [weak self] tf in
            tf.placeholder = "Team name"
            tf.text = self?.event.bowWinner
            tf.autocapitalizationType = .words
            tf.autocorrectionType = .no
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak ac] _ in
            guard let self else { return }
            self.event.bowWinner = (ac?.textFields?.first?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            self.save()
            let bowRow = IndexPath(row: self.event.teams.count, section: Section.leaderboard.rawValue)
            self.tableView.reloadRows(at: [bowRow], with: .none)
        })
        present(ac, animated: true)
    }

    // MARK: - Share

    @objc private func shareTapped() {
        let text = buildShareText()
        let ac = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let pop = ac.popoverPresentationController { pop.barButtonItem = navigationItem.rightBarButtonItem }
        present(ac, animated: true)
    }

    private func buildShareText() -> String {
        var lines: [String] = []
        lines.append("🏌️ CALCUTTA: \(event.name)")
        lines.append("💰 Total Pot: \(calcuttaFormatMoney(event.totalPot))")

        // Teams & Bids
        lines.append("")
        lines.append("TEAMS & BIDS")
        lines.append(String(repeating: "─", count: 30))
        for (i, team) in event.teams.enumerated() {
            lines.append("\(i + 1). \(team.teamName) — \(calcuttaFormatMoney(team.bidAmount))")
            if team.useCaptainOnly {
                if !team.captain.isEmpty { lines.append("Capt: \(team.captain)") }
            } else {
                let filled = team.players.filter { !$0.isEmpty }
                if !filled.isEmpty { lines.append(filled.joined(separator: " / ")) }
            }
        }
        if event.teams.isEmpty { lines.append("(No teams added yet)") }

        // Payouts
        lines.append("")
        lines.append("PAYOUT STRUCTURE")
        lines.append(String(repeating: "─", count: 30))
        let pot = event.totalPot
        var totalPct: Double = 0
        for row in event.payoutRows {
            let amount = pot * row.percentage / 100.0
            lines.append("\(row.label) (\(formatPct(row.percentage))%) = \(calcuttaFormatMoney(amount))")
            totalPct += row.percentage
        }
        if event.payoutRows.isEmpty {
            lines.append("(No payouts configured)")
        } else {
            let remaining = 100.0 - totalPct
            if remaining > 0.01 {
                lines.append("Undistributed: \(formatPct(remaining))% = \(calcuttaFormatMoney(pot * remaining / 100.0))")
            }
        }

        // Leaderboard
        let sorted = combinedSort().filter { $0.d1 != nil || $0.d2 != nil }
        if !sorted.isEmpty {
            lines.append("")
            lines.append("LEADERBOARD")
            lines.append(String(repeating: "─", count: 30))
            for (position, item) in sorted.enumerated() {
                let myTotal = (item.d1 ?? 0) + (item.d2 ?? 0)
                let rankNum = sorted.filter { ($0.d1 ?? 0) + ($0.d2 ?? 0) > myTotal }.count + 1
                lines.append("\(rankNum). \(item.team.teamName) — \(myTotal) pts")
                let d1s = item.d1.map(String.init) ?? "—"
                let d2s = item.d2.map(String.init) ?? "—"
                var breakdown = "Day 1: \(d1s)  /  Day 2: \(d2s)"
                if let payout = payoutForTeam(at: position, in: sorted) { breakdown += "  \(payout)" }
                lines.append(breakdown)
            }
        }

        // BOW Winner
        let bow = event.bowWinner.trimmingCharacters(in: .whitespacesAndNewlines)
        if !bow.isEmpty {
            lines.append("")
            lines.append("BOW WINNER")
            lines.append(String(repeating: "─", count: 30))
            lines.append(bow)
        }

        lines.append("")
        lines.append("Sent from WolfMore Golf")
        lines.append("https://apps.apple.com/us/app/wolfmore-golf/id6755116882")
        return lines.joined(separator: "\n")
    }

    private func formatPct(_ pct: Double) -> String {
        pct.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(pct)) : String(pct)
    }
}

// MARK: - UITableViewDataSource

extension CalcuttaManagerViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section(rawValue: section)?.header
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .teams:       return event.teams.count + 1
        case .payouts:     return event.payoutRows.count + 1
        case .leaderboard: return event.teams.isEmpty ? 1 : event.teams.count + 1  // +1 for BOW row
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {

        case .teams:
            if indexPath.row < event.teams.count {
                let team = event.teams[indexPath.row]
                let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
                cell.textLabel?.text = "\(team.teamName)   \(calcuttaFormatMoney(team.bidAmount))"
                if team.useCaptainOnly {
                    cell.detailTextLabel?.text = team.captain.isEmpty ? nil : "Capt: \(team.captain)"
                } else {
                    let filled = team.players.filter { !$0.isEmpty }
                    cell.detailTextLabel?.text = filled.isEmpty ? nil : filled.joined(separator: " / ")
                }
                cell.accessoryType = .detailDisclosureButton
                return cell
            } else {
                let cell = UITableViewCell()
                let atMax = event.teams.count >= 30
                cell.textLabel?.text = atMax ? "Maximum 30 teams reached" : "＋ Add Team"
                cell.textLabel?.textColor = atMax ? .tertiaryLabel : .systemBlue
                cell.selectionStyle = atMax ? .none : .default
                return cell
            }

        case .payouts:
            if indexPath.row < event.payoutRows.count {
                let row = event.payoutRows[indexPath.row]
                let amount = event.totalPot * row.percentage / 100.0
                let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
                cell.textLabel?.text = "\(row.label)  (\(formatPct(row.percentage))%)"
                cell.detailTextLabel?.text = calcuttaFormatMoney(amount)
                cell.accessoryType = .disclosureIndicator
                return cell
            } else {
                let cell = UITableViewCell()
                cell.textLabel?.text = "＋ Add Position"
                cell.textLabel?.textColor = .systemBlue
                return cell
            }

        case .leaderboard:
            if event.teams.isEmpty {
                let cell = UITableViewCell()
                cell.textLabel?.text = "Add teams first"
                cell.textLabel?.textColor = .secondaryLabel
                cell.selectionStyle = .none
                return cell
            }
            // BOW Winner row (last row)
            if indexPath.row == event.teams.count {
                let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
                cell.textLabel?.text = "BOW Winner"
                cell.textLabel?.font = .systemFont(ofSize: 17, weight: .medium)
                let winner = event.bowWinner.trimmingCharacters(in: .whitespacesAndNewlines)
                cell.detailTextLabel?.text = winner.isEmpty ? "—" : winner
                cell.detailTextLabel?.textColor = winner.isEmpty ? .tertiaryLabel : .label
                cell.accessoryType = .disclosureIndicator
                return cell
            }
            // Team leaderboard row
            let sorted = combinedSort()
            let item = sorted[indexPath.row]
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell.textLabel?.text = item.team.teamName
            let hasAny = item.d1 != nil || item.d2 != nil
            if hasAny {
                let d1s = item.d1.map(String.init) ?? "—"
                let d2s = item.d2.map(String.init) ?? "—"
                let total = (item.d1 ?? 0) + (item.d2 ?? 0)
                var detail = "D1: \(d1s)  ·  D2: \(d2s)  =  \(total) pts"
                if let payout = payoutForTeam(at: indexPath.row, in: sorted) { detail += "  \(payout)" }
                cell.detailTextLabel?.text = detail
                cell.detailTextLabel?.textColor = .secondaryLabel
            } else {
                cell.detailTextLabel?.text = "—"
                cell.detailTextLabel?.textColor = .tertiaryLabel
            }
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        switch Section(rawValue: indexPath.section)! {
        case .teams:       return indexPath.row < event.teams.count
        case .payouts:     return indexPath.row < event.payoutRows.count
        case .leaderboard: return false
        }
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        switch Section(rawValue: indexPath.section)! {
        case .teams:
            event.teams.remove(at: indexPath.row)
            syncLeaderboard()
            save()
            tableView.reloadData()
            refreshTableHeader()
        case .payouts:
            event.payoutRows.remove(at: indexPath.row)
            save()
            tableView.reloadSections([Section.payouts.rawValue], with: .automatic)
        case .leaderboard:
            break
        }
    }
}

// MARK: - UITableViewDelegate

extension CalcuttaManagerViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch Section(rawValue: indexPath.section)! {
        case .teams:
            if indexPath.row < event.teams.count {
                quickBid(at: indexPath.row)
            } else if event.teams.count < 30 {
                addTeam()
            }
        case .payouts:
            if indexPath.row < event.payoutRows.count {
                editPayout(at: indexPath.row)
            } else {
                addPayout()
            }
        case .leaderboard:
            guard !event.teams.isEmpty else { return }
            if indexPath.row == event.teams.count {
                editBowWinner()
            } else {
                let teamName = combinedSort()[indexPath.row].team.teamName
                editCombinedEntry(teamName: teamName)
            }
        }
    }

    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        guard Section(rawValue: indexPath.section) == .teams,
              indexPath.row < event.teams.count else { return }
        editTeam(at: indexPath.row)
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section == Section.payouts.rawValue, !event.payoutRows.isEmpty else { return nil }
        let totalPct = event.payoutRows.reduce(0) { $0 + $1.percentage }
        let remaining = 100.0 - totalPct
        if abs(remaining) < 0.01 { return "Fully distributed (100%)" }
        return remaining > 0
            ? "Undistributed: \(formatPct(remaining))%"
            : "⚠️ Over-allocated by \(formatPct(-remaining))%"
    }
}
