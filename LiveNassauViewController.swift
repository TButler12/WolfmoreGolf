import UIKit

final class LiveNassauViewController: UIViewController {

    var match: MatchRecord?

    // MARK: - State

    // Scores received from Supabase; replayed on each rebuild to stay in sync with local game
    private var receivedScores: [HoleScoreRecord] = []

    // MARK: - Table model

    private struct SegmentRow {
        let title: String
        let statusLine: String   // "McTommy 2 up" / "All Square"
        let moneyLine: String    // "McTommy +$4" / "Halved — Even"
        let isComplete: Bool
    }
    private var rows: [SegmentRow] = []
    private var sectionTitle = "Standings"

    // MARK: - UI

    private let statusLabel    = UILabel()
    private let tableView      = UITableView(frame: .zero, style: .insetGrouped)
    private var finalButton: UIButton?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        print("DEBUG LiveNassau viewDidLoad - match: \(match?.id ?? "nil")")
        view.backgroundColor = .systemBackground
        title = match.map { "Live · \($0.code)" } ?? "Live Match"
        setupUI()
        fetchPriorScores()
        subscribeToScores()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let id = match?.id {
            SupabaseService.shared.unsubscribeFromHoleScores(matchId: id)
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
        statusLabel.text = "Connecting…"
        statusLabel.textColor = .systemYellow
        statusLabel.font = .systemFont(ofSize: 13, weight: .medium)
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SegCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        var cfg = UIButton.Configuration.filled()
        cfg.title = "View Final Result"
        cfg.cornerStyle = .large
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 32, bottom: 14, trailing: 32)
        let btn = UIButton(configuration: cfg)
        btn.addTarget(self, action: #selector(finalResultTapped), for: .touchUpInside)
        btn.isHidden = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(btn)
        finalButton = btn

        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 4),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: btn.topAnchor, constant: -12),

            btn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            btn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            btn.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            btn.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40),
        ])
    }

    // MARK: - Data loading

    private func fetchPriorScores() {
        print("DEBUG fetchPriorScores starting - matchId: \(match?.id ?? "nil")")
        guard let matchId = match?.id else {
            rebuildStandings()
            return
        }
        Task {
            do {
                let prior = try await SupabaseService.shared.fetchHoleScores(matchId: matchId)
                await MainActor.run {
                    print("DEBUG fetchPriorScores: loaded \(prior.count) records")
                    self.receivedScores = prior
                    self.rebuildStandings()
                    self.setStatus(live: true)
                }
            } catch {
                await MainActor.run {
                    self.rebuildStandings()
                    self.setStatus(live: false)
                }
            }
        }
    }

    private func subscribeToScores() {
        guard let matchId = match?.id else { return }
        SupabaseService.shared.subscribeToHoleScores(matchId: matchId) { [weak self] record in
            guard let self else { return }
            print("DEBUG score received: hole=\(record.hole) player=\(record.playerName ?? "nil")")
            // Deduplicate: keep latest score per (player, hole); prefer name match, fall back to slot
            self.receivedScores.removeAll {
                if let rn = record.playerName, !rn.isEmpty,
                   let en = $0.playerName, !en.isEmpty {
                    return en.lowercased() == rn.lowercased() && $0.hole == record.hole
                }
                return $0.playerSlot == record.playerSlot && $0.hole == record.hole
            }
            self.receivedScores.append(record)
            self.rebuildStandings()
            self.setStatus(live: true)
        }
        // Optimistically mark Live after subscription is sent
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self, self.statusLabel.text == "Connecting…" else { return }
            self.setStatus(live: true)
        }
    }

    // MARK: - Standings calculation

    // Build a synthetic 2-player GameData: owner at slot 0, remote opponent at slot 1.
    // This avoids depending on the local game's player roster, which won't include the remote player.
    private func buildSyntheticRemoteGame() -> GameData? {
        guard let localGame = GameManager.shared.currentGame else { return nil }

        let myName = (ProfileStore.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let myNameLower = myName.lowercased()

        // Opponent name: prefer match record, fall back to received score names
        let opponentName: String = {
            if let host = match?.hostName?.trimmingCharacters(in: .whitespacesAndNewlines), !host.isEmpty,
               let opp  = match?.opponentName?.trimmingCharacters(in: .whitespacesAndNewlines), !opp.isEmpty {
                return host.lowercased() == myNameLower ? opp : host
            }
            for record in receivedScores {
                guard let pn = record.playerName else { continue }
                let trimmed = pn.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty, trimmed.lowercased() != myNameLower else { continue }
                return trimmed
            }
            return "Opponent"
        }()

        var g = GameData()
        g.playerNames[0]     = myName.isEmpty ? "Me" : myName
        g.playerNames[1]     = opponentName
        g.playerActivated[0] = true
        g.playerActivated[1] = true

        // Only use scores that have been submitted to Supabase (via Update Scores button).
        // Owner scores come back through receivedScores just like the opponent's.
        for s in receivedScores {
            guard s.hole >= 0, s.hole < STANDARD_HOLES else { continue }
            let isOwner: Bool
            if let pn = s.playerName, !pn.isEmpty {
                isOwner = !myNameLower.isEmpty &&
                          pn.trimmingCharacters(in: .whitespacesAndNewlines)
                            .lowercased() == myNameLower
            } else {
                isOwner = s.playerSlot == (localGame.playerNames.firstIndex {
                    !myName.isEmpty &&
                    $0.trimmingCharacters(in: .whitespacesAndNewlines)
                      .localizedCaseInsensitiveCompare(myName) == .orderedSame
                } ?? -1)
            }
            g.scores[isOwner ? 0 : 1][s.hole] = s.grossScore
        }

        // A hole is committed when both players have a score
        for h in 0..<STANDARD_HOLES {
            g.holeCommitted[h] = g.scores[0][h] != nil && g.scores[1][h] != nil
        }

        // Nassau state with match settings applied
        var state = NassauEngine.makeDefaultState(
            playerNames: g.playerNames,
            activeFlags: g.playerActivated
        )
        if let stake = match?.stake { state.settings.baseStake = stake }
        if let pm = match?.pressMode, let mode = NassauPressMode(rawValue: pm) {
            state.settings.pressMode = mode
        }
        if let trigger = match?.trigger { state.settings.autoPressTriggerDown = trigger }

        g.nassauState = state
        return g
    }

    private func rebuildStandings() {
        print("DEBUG rebuildStandings called: \(receivedScores.count) scores")
        guard var g = buildSyntheticRemoteGame() else {
            rows = []
            tableView.reloadData()
            return
        }

        print("DEBUG rebuildStandings: remoteScores=\(receivedScores.count) committed=\(g.holeCommitted.filter { $0 }.count)")

        guard var state = g.nassauState else {
            rows = []
            tableView.reloadData()
            return
        }

        NassauEngine.recalculate(state: &state, gameData: g)
        g.nassauState = state

        let primaryMatch = state.oneVsOneMatches.first ?? state.twoVsTwoMatches.first
        guard let m = primaryMatch else {
            rows = []
            sectionTitle = "No match configured"
            tableView.reloadData()
            return
        }

        let t1 = g.playerNames[0].isEmpty ? "P1" : g.playerNames[0]
        let t2 = g.playerNames[1].isEmpty ? "P2" : g.playerNames[1]
        sectionTitle = "\(t1) vs \(t2)"

        rows = [
            makeRow("Front 9",  status: m.frontStatusByHole,   t1: t1, t2: t2,
                    complete: NassauEngine.isFrontComplete(gameData: g),   stake: m.stake),
            makeRow("Back 9",   status: m.backStatusByHole,    t1: t1, t2: t2,
                    complete: NassauEngine.isBackComplete(gameData: g),    stake: m.stake),
            makeRow("18 Holes", status: m.overallStatusByHole, t1: t1, t2: t2,
                    complete: NassauEngine.isOverallComplete(gameData: g), stake: m.stake),
        ]

        for (i, press) in m.presses.enumerated() {
            let label = "Press \(i + 1) · H\(press.startHole)-\(press.endHole)"
            rows.append(makeRow(label, status: press.runningStatus, t1: t1, t2: t2,
                                complete: NassauEngine.isPressComplete(press, gameData: g),
                                stake: press.stake))
        }

        tableView.reloadData()
        finalButton?.isHidden = !NassauEngine.isOverallComplete(gameData: g)
    }

    private func makeRow(
        _ title: String,
        status: [Int],
        t1: String, t2: String,
        complete: Bool,
        stake: Double
    ) -> SegmentRow {
        let final = status.last ?? 0
        let statusLine: String
        let moneyLine: String

        if final > 0 {
            statusLine = "\(t1) \(final) up"
            moneyLine  = complete ? "\(t1) +\(money(stake))" : "\(t1) leads"
        } else if final < 0 {
            statusLine = "\(t2) \(abs(final)) up"
            moneyLine  = complete ? "\(t2) +\(money(stake))" : "\(t2) leads"
        } else {
            statusLine = status.isEmpty ? "Not started" : "All Square"
            moneyLine  = complete ? "Halved — Even" : "All Square"
        }

        return SegmentRow(title: title, statusLine: statusLine, moneyLine: moneyLine, isComplete: complete)
    }

    // MARK: - Final result

    @objc private func finalResultTapped() {
        guard let g = buildSyntheticRemoteGame(),
              var state = g.nassauState else { return }

        NassauEngine.recalculate(state: &state, gameData: g)

        let summaries = NassauEngine.finalSummaries(
            state: state,
            playerNames: g.playerNames,
            gameData: g
        )

        let body = summaries.map { s -> String in
            var lines = [s.matchTitle]
            if let f = s.front9    { lines.append("  Front 9: \(f.resultText)") }
            if let b = s.back9     { lines.append("  Back 9:  \(b.resultText)") }
            if let o = s.overall18 { lines.append("  18 Hole: \(o.resultText)") }
            for p in s.presses     { lines.append("  \(p.title): \(p.resultText)") }
            lines.append("  Net: \(s.totalMoneyText)")
            return lines.joined(separator: "\n")
        }.joined(separator: "\n\n")

        let ac = UIAlertController(
            title: "Final Result",
            message: body.isEmpty ? "No results available." : body,
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "Done", style: .default))
        present(ac, animated: true)
    }

    // MARK: - Connection status

    private func setStatus(live: Bool) {
        statusLabel.text      = live ? "● Live" : "● Reconnecting…"
        statusLabel.textColor = live ? .systemGreen : .systemYellow
    }

    // MARK: - Helpers

    private func money(_ value: Double) -> String {
        value == floor(value) ? "$\(Int(value))" : String(format: "$%.2f", value)
    }
}

// MARK: - UITableViewDataSource

extension LiveNassauViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sectionTitle
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row  = rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "SegCell", for: indexPath)
        var content = cell.defaultContentConfiguration()

        content.text = row.title
        content.textProperties.font = .systemFont(ofSize: 17, weight: .semibold)

        content.secondaryText = "\(row.statusLine)\n\(row.moneyLine)"
        content.secondaryTextProperties.numberOfLines = 2
        content.secondaryTextProperties.color = row.isComplete ? .label : .secondaryLabel

        if !row.isComplete {
            cell.accessoryType = .none
        } else {
            cell.accessoryType = .checkmark
        }

        cell.contentConfiguration = content
        cell.selectionStyle = .none
        return cell
    }
}

// MARK: - UITableViewDelegate

extension LiveNassauViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
