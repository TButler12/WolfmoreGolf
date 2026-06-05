import UIKit

final class LiveNassauViewController: UIViewController {

    var match: MatchRecord?

    // MARK: - State

    private var receivedScores: [HoleScoreRecord] = []

    // MARK: - Table model

    private struct SegmentRow {
        let title: String
        let statusLine: String
        let moneyLine: String
        let isComplete: Bool
        let moneyDelta: Double   // signed from owner's perspective; 0 if incomplete or tied
    }

    private struct PairingSection {
        let title: String
        let rows: [SegmentRow]
        let isOverallComplete: Bool
        let ownerName: String
        let opponentName: String
        var totalMoneyLine: String {
            let total = rows.reduce(0) { $0 + $1.moneyDelta }
            if total > 0 { return "Total: \(ownerName) +\(formatMoney(total))" }
            if total < 0 { return "Total: \(opponentName) +\(formatMoney(-total))" }
            return "Total: Even"
        }
        private func formatMoney(_ v: Double) -> String {
            v == floor(v) ? "$\(Int(v))" : String(format: "$%.2f", v)
        }
    }

    private var pairings: [PairingSection] = []

    // MARK: - UI

    private let statusLabel = UILabel()
    private let tableView   = UITableView(frame: .zero, style: .insetGrouped)
    private var finalButton: UIButton?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = match.map { "Live · \($0.code)" } ?? "Live Match"
        print("DEBUG isSameCourse: \(isSameCourse) courseA: \(match?.courseA ?? "nil") courseB: \(match?.courseB ?? "nil")")
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(refreshTapped)
        )

        statusLabel.text          = "Connecting…"
        statusLabel.textColor     = .systemYellow
        statusLabel.font          = .systemFont(ofSize: 13, weight: .medium)
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        tableView.dataSource          = self
        tableView.delegate            = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SegCell")
        tableView.rowHeight           = UITableView.automaticDimension
        tableView.estimatedRowHeight  = 72
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        var cfg = UIButton.Configuration.filled()
        cfg.title          = "View Final Result"
        cfg.cornerStyle    = .large
        cfg.contentInsets  = NSDirectionalEdgeInsets(top: 14, leading: 32, bottom: 14, trailing: 32)
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
        guard let matchId = match?.id else {
            rebuildStandings()
            return
        }
        Task {
            do {
                let prior = try await SupabaseService.shared.fetchHoleScores(matchId: matchId)
                await MainActor.run {
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

        let scoreCallback: (HoleScoreRecord) -> Void = { [weak self] record in
            guard let self else { return }
            // Deduplicate: keep latest score per (player, hole)
            self.receivedScores.removeAll {
                if let rn = record.playerName, !rn.isEmpty,
                   let en = $0.playerName,    !en.isEmpty {
                    return en.lowercased() == rn.lowercased() && $0.hole == record.hole
                }
                return $0.playerSlot == record.playerSlot && $0.hole == record.hole
            }
            self.receivedScores.append(record)
            self.rebuildStandings()
            self.setStatus(live: true)
        }

        SupabaseService.shared.subscribeToHoleScores(matchId: matchId, onScore: scoreCallback)
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            SupabaseService.shared.subscribeToHoleScoreUpdates(matchId: matchId, onScore: scoreCallback)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self, self.statusLabel.text == "Connecting…" else { return }
            self.setStatus(live: true)
        }
    }

    // MARK: - Identity helpers

    private var myName: String {
        (ProfileStore.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSameCourse: Bool {
        // Primary: explicit course names stored on the MatchRecord
        let a = (match?.courseA ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let b = (match?.courseB ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !a.isEmpty && !b.isEmpty {
            return a == b
        }

        // Build per-player (hole → holeHc) maps from received scores
        var hcByPlayer: [String: [Int: Int]] = [:]
        for s in receivedScores {
            guard let pn = s.playerName?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                  !pn.isEmpty, let hc = s.holeHc else { continue }
            if hcByPlayer[pn] == nil { hcByPlayer[pn] = [:] }
            hcByPlayer[pn]![s.hole] = hc
        }
        guard hcByPlayer.count >= 2 else { return false }
        let players = Array(hcByPlayer.values)

        // Fallback 1: any shared holes with matching HC values → same course
        let common = Set(players[0].keys).intersection(Set(players[1].keys))
        if !common.isEmpty && common.allSatisfy({ players[0][$0] == players[1][$0] }) {
            return true
        }

        // Fallback 2: each player's (hole → hc) pairs match the same known course in CourseLibrary.
        // Works even when players haven't played any common hole numbers yet.
        let coursesPerPlayer: [Set<String>] = hcByPlayer.values.map { hcMap in
            let matching = CourseLibrary.shared.courses.filter { course in
                hcMap.allSatisfy { hole, hc in
                    guard hole >= 0, hole < course.hcs.count else { return false }
                    return course.hcs[hole] == hc
                }
            }
            return Set(matching.map { $0.name })
        }
        guard let first = coursesPerPlayer.first else { return false }
        let sharedCourses = coursesPerPlayer.dropFirst().reduce(first) { $0.intersection($1) }
        return !sharedCourses.isEmpty
    }

    private var amHost: Bool {
        let hostRaw = match?.hostName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !hostRaw.isEmpty && hostRaw.lowercased() == myName.lowercased()
    }

    // All distinct opponent names: opponentNames array → legacy opponentName → received scores.
    private func collectOpponentNames() -> [String] {
        let myLower = myName.lowercased()
        var names: [String] = []

        if let arr = match?.opponentNames {
            for n in arr {
                let t = n.trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty && !names.contains(t) { names.append(t) }
            }
        }
        if let single = match?.opponentName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !single.isEmpty, !names.contains(single) {
            names.append(single)
        }
        for record in receivedScores {
            guard let pn = record.playerName else { continue }
            let t = pn.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty && t.lowercased() != myLower && !names.contains(t) { names.append(t) }
        }
        return names
    }

    // MARK: - Standings calculation

    // Build a 2-player synthetic GameData for one specific owner/opponent pairing.
    // Scores from other players in receivedScores are ignored for this pairing.
    private func buildSyntheticGame(ownerName: String, opponentName: String) -> GameData? {
        guard !ownerName.isEmpty else { return nil }
        let ownerLower    = ownerName.lowercased()
        let opponentLower = opponentName.lowercased()

        var g = GameData()
        g.playerNames[0]     = ownerName
        g.playerNames[1]     = opponentName.isEmpty ? "Opponent" : opponentName
        g.playerActivated[0] = true
        g.playerActivated[1] = true

        func hcRank(_ s: HoleScoreRecord) -> Int { s.holeHc ?? (s.hole + 1) }

        var ownerScores: [HoleScoreRecord] = []
        var oppScores:   [HoleScoreRecord] = []
        for s in receivedScores {
            guard s.hole >= 0, s.hole < STANDARD_HOLES,
                  let pn = s.playerName, !pn.isEmpty else { continue }
            let pnLower = pn.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if      pnLower == ownerLower    { ownerScores.append(s) }
            else if pnLower == opponentLower { oppScores.append(s)   }
        }

        g.hcPlayers[0] = ownerScores.first?.playerHc ?? 0
        g.hcPlayers[1] = oppScores.first?.playerHc   ?? 0

        var holeHCs = Array(repeating: STANDARD_HOLES, count: STANDARD_HOLES)

        // Pair by physical hole number when any holes overlap; otherwise HC-sort positionally.
        let ownerHoleSet  = Set(ownerScores.map { $0.hole })
        let oppHoleSet    = Set(oppScores.map   { $0.hole })
        let holesOverlap  = !ownerHoleSet.intersection(oppHoleSet).isEmpty

        if holesOverlap {
            // Same-course path: match each score to its physical hole slot
            for s in ownerScores {
                guard s.hole >= 0, s.hole < STANDARD_HOLES else { continue }
                g.scores[0][s.hole] = s.grossScore
                holeHCs[s.hole] = hcRank(s)
            }
            for s in oppScores {
                guard s.hole >= 0, s.hole < STANDARD_HOLES else { continue }
                g.scores[1][s.hole] = s.grossScore
            }
            for i in 0..<STANDARD_HOLES {
                g.holeCommitted[i] = g.scores[0][i] != nil && g.scores[1][i] != nil
            }
        } else {
            // Different-course path: HC-sort each player independently, zip positionally
            let ownerFront = ownerScores.filter { $0.hole <= 8 }.sorted { hcRank($0) < hcRank($1) }
            let ownerBack  = ownerScores.filter { $0.hole >= 9 }.sorted { hcRank($0) < hcRank($1) }
            let oppFront   = oppScores.filter   { $0.hole <= 8 }.sorted { hcRank($0) < hcRank($1) }
            let oppBack    = oppScores.filter   { $0.hole >= 9 }.sorted { hcRank($0) < hcRank($1) }

            for (i, (o, p)) in zip(ownerFront, oppFront).enumerated() {
                g.scores[0][i] = o.grossScore
                g.scores[1][i] = p.grossScore
                g.holeCommitted[i] = true
            }
            for (i, (o, p)) in zip(ownerBack, oppBack).enumerated() {
                g.scores[0][i + 9] = o.grossScore
                g.scores[1][i + 9] = p.grossScore
                g.holeCommitted[i + 9] = true
            }
            for (i, s) in ownerFront.enumerated() { holeHCs[i]     = hcRank(s) }
            for (i, s) in ownerBack.enumerated()  { holeHCs[i + 9] = hcRank(s) }
        }

        g.course.holeHandicaps = holeHCs

        var state = NassauEngine.makeDefaultState(playerNames: g.playerNames, activeFlags: g.playerActivated)
        if let stake   = match?.stake                                                     { state.settings.baseStake = stake }
        if let pm      = match?.pressMode, let mode = NassauPressMode(rawValue: pm)       { state.settings.pressMode = mode }
        if let trigger = match?.trigger                                                    { state.settings.autoPressTriggerDown = trigger }
        g.nassauState = state
        return g
    }

    private func buildPairingSection(ownerName: String, opponentName: String) -> PairingSection? {
        guard let g = buildSyntheticGame(ownerName: ownerName, opponentName: opponentName),
              var state = g.nassauState else { return nil }

        NassauEngine.recalculate(state: &state, gameData: g)

        let t1 = g.playerNames[0].isEmpty ? "P1" : g.playerNames[0]
        let t2 = g.playerNames[1].isEmpty ? "P2" : g.playerNames[1]

        guard let m = state.oneVsOneMatches.first ?? state.twoVsTwoMatches.first else { return nil }

        var rows: [SegmentRow] = [
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

        return PairingSection(title: "\(t1) vs \(t2)", rows: rows,
                              isOverallComplete: NassauEngine.isOverallComplete(gameData: g),
                              ownerName: ownerName, opponentName: opponentName)
    }

    private func rebuildStandings() {
        let hostRaw = match?.hostName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if amHost {
            // Host: one section per opponent
            let me        = myName.isEmpty ? hostRaw : myName
            let opponents = collectOpponentNames()
            pairings = opponents.compactMap { buildPairingSection(ownerName: me, opponentName: $0) }
        } else {
            // Opponent: single 1v1 against the host
            let me   = myName.isEmpty ? "Me" : myName
            let host = hostRaw.isEmpty ? "Host" : hostRaw
            pairings = buildPairingSection(ownerName: me, opponentName: host).map { [$0] } ?? []
        }

        tableView.reloadData()
        finalButton?.isHidden = pairings.isEmpty || !pairings.allSatisfy { $0.isOverallComplete }
    }

    private func makeRow(
        _ title: String,
        status: [Int],
        t1: String, t2: String,
        complete: Bool,
        stake: Double
    ) -> SegmentRow {
        let last = status.last ?? 0
        let statusLine: String
        let moneyLine: String
        let moneyDelta: Double

        if last > 0 {
            statusLine = "\(t1) \(last) up"
            moneyLine  = complete ? "\(t1) +\(money(stake))" : "\(t1) leads"
            moneyDelta = complete ? stake : 0
        } else if last < 0 {
            statusLine = "\(t2) \(abs(last)) up"
            moneyLine  = complete ? "\(t2) +\(money(stake))" : "\(t2) leads"
            moneyDelta = complete ? -stake : 0
        } else {
            statusLine = status.isEmpty ? "Not started" : "All Square"
            moneyLine  = complete ? "Halved — Even" : "All Square"
            moneyDelta = 0
        }

        return SegmentRow(title: title, statusLine: statusLine, moneyLine: moneyLine,
                          isComplete: complete, moneyDelta: moneyDelta)
    }

    // MARK: - Scorecard detail

    // Builds HC-paired hole data for Front 9 (front=true) or Back 9 (front=false).
    // Mirrors buildSyntheticGame: sort each player's scores hardest-first, then zip
    // positionally so "HC Pos 1" = each player's hardest submitted hole.
    // Using positional zipping (not a shared HC rank key) handles the case where
    // players are on different holes or one player is missing holeHc data.
    func buildPairedHoles(ownerName: String, opponentName: String, front: Bool) -> [PairedHole] {
        let ownerLower    = ownerName.lowercased()
        let opponentLower = opponentName.lowercased()
        func hcRank(_ s: HoleScoreRecord) -> Int { s.holeHc ?? (s.hole + 1) }

        var ownerScores: [HoleScoreRecord] = []
        var oppScores:   [HoleScoreRecord] = []

        for s in receivedScores {
            guard s.hole >= 0, s.hole < STANDARD_HOLES,
                  let pn = s.playerName, !pn.isEmpty else { continue }
            let inRange = front ? (s.hole <= 8) : (s.hole >= 9)
            guard inRange else { continue }
            let pnLower = pn.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if      pnLower == ownerLower    { ownerScores.append(s) }
            else if pnLower == opponentLower { oppScores.append(s)   }
        }

        let hostHc    = ownerScores.first?.playerHc ?? 0
        let oppHc     = oppScores.first?.playerHc   ?? 0
        let baseHC    = min(hostHc, oppHc)
        let hostDelta = max(0, hostHc - baseHC)
        let oppDelta  = max(0, oppHc  - baseHC)

        func makePairedHole(rank: Int, o: HoleScoreRecord?, p: HoleScoreRecord?) -> PairedHole {
            let rawSI = o?.holeHc ?? p?.holeHc ?? (rank + 1)
            let si    = max(1, min(STANDARD_HOLES, rawSI == 0 ? STANDARD_HOLES : rawSI))
            let hostStrokes = NassauEngine.pops(for: hostDelta, strokeIndex: si)
            let oppStrokes  = NassauEngine.pops(for: oppDelta,  strokeIndex: si)
            let hostNet: Int? = o.map { $0.grossScore - hostStrokes }
            let oppNet:  Int? = p.map { $0.grossScore - oppStrokes  }
            let net: Int = {
                guard let hn = hostNet, let on = oppNet else { return 0 }
                return on - hn
            }()
            return PairedHole(
                hcRank: rank + 1,
                hostPhysicalHole: (o?.hole ?? rank) + 1,
                hostScore: o?.grossScore,
                hostNetScore: hostNet,
                hostStrokes: hostStrokes,
                opponentPhysicalHole: (p?.hole ?? rank) + 1,
                opponentScore: p?.grossScore,
                opponentNetScore: oppNet,
                opponentStrokes: oppStrokes,
                netResult: net
            )
        }

        // Pair by hole number if any holes overlap; otherwise fall back to HC-sort
        let ownerHoleSet = Set(ownerScores.map { $0.hole })
        let oppHoleSet   = Set(oppScores.map   { $0.hole })
        let overlap      = ownerHoleSet.intersection(oppHoleSet)

        if !overlap.isEmpty {
            // Same physical holes present — pair by hole number for the entire front/back range
            let range = front ? (0..<9) : (9..<STANDARD_HOLES)
            return range.compactMap { h -> PairedHole? in
                let o = ownerScores.first { $0.hole == h }
                let p = oppScores.first   { $0.hole == h }
                guard o != nil || p != nil else { return nil }
                print("DEBUG pairing: local H\(h + 1) vs remote H\(h + 1)")
                return makePairedHole(rank: h, o: o, p: p)
            }
        }

        // No overlapping holes — different courses, HC-sort positionally
        let sortedOwner = ownerScores.sorted { hcRank($0) < hcRank($1) }
        let sortedOpp   = oppScores.sorted   { hcRank($0) < hcRank($1) }

        let count = max(sortedOwner.count, sortedOpp.count)
        return (0..<count).map { i in
            let o = sortedOwner[safe: i]
            let p = sortedOpp[safe: i]
            print("DEBUG pairing: local H\((o?.hole ?? -1) + 1) vs remote H\((p?.hole ?? -1) + 1)")
            return makePairedHole(rank: i, o: o, p: p)
        }
    }

    // MARK: - Final result

    @objc private func finalResultTapped() {
        let hostRaw = match?.hostName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let pairingArgs: [(owner: String, opponent: String)]

        if amHost {
            let me = myName.isEmpty ? hostRaw : myName
            pairingArgs = collectOpponentNames().map { (owner: me, opponent: $0) }
        } else {
            let me   = myName.isEmpty ? "Me" : myName
            let host = hostRaw.isEmpty ? "Host" : hostRaw
            pairingArgs = [(owner: me, opponent: host)]
        }

        var bodyParts: [String] = []
        for pair in pairingArgs {
            guard let g = buildSyntheticGame(ownerName: pair.owner, opponentName: pair.opponent),
                  var state = g.nassauState else { continue }
            NassauEngine.recalculate(state: &state, gameData: g)
            let summaries = NassauEngine.finalSummaries(state: state, playerNames: g.playerNames, gameData: g)
            for s in summaries {
                var lines = [s.matchTitle]
                if let f = s.front9    { lines.append("  Front 9: \(f.resultText)") }
                if let b = s.back9     { lines.append("  Back 9:  \(b.resultText)") }
                if let o = s.overall18 { lines.append("  18 Hole: \(o.resultText)") }
                for p in s.presses     { lines.append("  \(p.title): \(p.resultText)") }
                lines.append("  Net: \(s.totalMoneyText)")
                bodyParts.append(lines.joined(separator: "\n"))
            }
        }

        let body = bodyParts.joined(separator: "\n\n")
        let ac = UIAlertController(
            title: "Final Result",
            message: body.isEmpty ? "No results available." : body,
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "Done", style: .default))
        present(ac, animated: true)
    }

    // MARK: - Refresh

    @objc private func refreshTapped() {
        setStatus(live: false)
        Task { await refreshScores() }
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

    func numberOfSections(in tableView: UITableView) -> Int {
        max(pairings.count, 1)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < pairings.count else { return 0 }
        return pairings[section].rows.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section < pairings.count else { return "Standings" }
        return pairings[section].title
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section < pairings.count else { return nil }
        return pairings[section].totalMoneyLine
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row  = pairings[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "SegCell", for: indexPath)
        var content = cell.defaultContentConfiguration()

        content.text = row.title
        content.textProperties.font = .systemFont(ofSize: 17, weight: .semibold)

        content.secondaryText = "\(row.statusLine)\n\(row.moneyLine)"
        content.secondaryTextProperties.numberOfLines = 2
        content.secondaryTextProperties.color = row.isComplete ? .label : .secondaryLabel

        cell.accessoryType      = row.isComplete ? .checkmark : .none
        cell.contentConfiguration = content
        cell.selectionStyle     = .none
        return cell
    }
}

// MARK: - UITableViewDelegate

extension LiveNassauViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Rows 0 (Front 9) and 1 (Back 9) drill into the scorecard
        guard indexPath.section < pairings.count,
              indexPath.row == 0 || indexPath.row == 1 else { return }
        let section = pairings[indexPath.section]
        let front   = indexPath.row == 0
        let pairs   = buildPairedHoles(ownerName: section.ownerName, opponentName: section.opponentName, front: front)
        let vc      = NassauScorecardViewController()
        vc.segmentTitle = front ? "Front 9" : "Back 9"
        vc.ownerName    = section.ownerName.isEmpty    ? "Player 1" : section.ownerName
        vc.opponentName = section.opponentName.isEmpty ? "Player 2" : section.opponentName
        vc.pairedHoles  = pairs
        vc.refreshProvider = { [weak self] in
            guard let self else { return pairs }
            await self.refreshScores()
            return self.buildPairedHoles(ownerName: section.ownerName,
                                         opponentName: section.opponentName,
                                         front: front)
        }
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension LiveNassauViewController {
    /// Re-fetches the match record and all hole scores; rebuilds standings on main actor.
    @discardableResult
    func refreshScores() async -> Bool {
        guard let matchId = match?.id else { return false }
        do {
            async let freshMatch  = SupabaseService.shared.fetchMatch(id: matchId)
            async let freshScores = SupabaseService.shared.fetchHoleScores(matchId: matchId)
            let (m, s) = try await (freshMatch, freshScores)
            await MainActor.run {
                self.match = m
                self.receivedScores = s
                self.rebuildStandings()
                self.setStatus(live: true)
            }
            return true
        } catch {
            await MainActor.run { self.setStatus(live: false) }
            return false
        }
    }
}
