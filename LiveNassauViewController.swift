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
    private var refreshTimer: Timer?

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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Task { await refreshScores() }
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { await self?.refreshScores() }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        refreshTimer?.invalidate()
        refreshTimer = nil
        if let id = match?.id {
            SupabaseService.shared.unsubscribeFromHoleScores(matchId: id)
            SupabaseService.shared.unsubscribeFromRemoteNassauHoles(matchId: id)
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
                let nassau = try await SupabaseService.shared.fetchRemoteNassauHoles(matchId: matchId)
                let prior: [HoleScoreRecord]
                if nassau.isEmpty {
                    prior = try await SupabaseService.shared.fetchHoleScores(matchId: matchId)
                } else {
                    prior = nassau.map { $0.toHoleScoreRecord() }
                }
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

        SupabaseService.shared.subscribeToRemoteNassauHoles(matchId: matchId, onScore: scoreCallback)
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            SupabaseService.shared.subscribeToRemoteNassauHoleUpdates(matchId: matchId, onScore: scoreCallback)
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

    // Running status from already-computed PairedHole results.
    // Skips uncommitted holes; +1 per owner win, -1 per opponent win.
    private func runningStatus(from pairs: [PairedHole]) -> [Int] {
        var current = 0
        var result: [Int] = []
        for ph in pairs {
            guard ph.hostScore != nil, ph.opponentScore != nil else { continue }
            current += ph.netResult
            result.append(current)
        }
        return result
    }

    private struct PressInfo {
        let startPos: Int    // 1-based overall position (front: 1–9, back: 10–18)
        let endPos: Int
        let stake: Double
        var runningStatus: [Int] = []
    }

    // Matches NassauEngine.buildPressesForSegment: next-hole start, max 3 per segment, no press-on-press.
    private func detectPresses(
        pairs: [PairedHole],
        holeOffset: Int,        // 0 for front, 9 for back
        segmentEndPos: Int,     // 9 for front, 18 for back
        trigger: Int,
        stake: Double
    ) -> [PressInfo] {
        let maxPresses = 3
        var presses: [PressInfo] = []
        var current = 0
        var prevAbs = 0

        for (idx, ph) in pairs.enumerated() {
            guard ph.hostScore != nil, ph.opponentScore != nil else { continue }
            current += ph.netResult
            let pos1Based  = holeOffset + idx + 1
            let currentAbs = abs(current)

            if prevAbs < trigger && currentAbs >= trigger && presses.count < maxPresses {
                let startPos = pos1Based + 1   // next-hole rule
                if startPos <= segmentEndPos {
                    presses.append(PressInfo(startPos: startPos, endPos: segmentEndPos, stake: stake))
                }
            }
            prevAbs = currentAbs
        }

        return presses.map { p in
            var info = p
            let startIdx = max(0, p.startPos - 1 - holeOffset)
            let endIdx   = min(pairs.count - 1, p.endPos - 1 - holeOffset)
            if startIdx <= endIdx {
                info.runningStatus = runningStatus(from: Array(pairs[startIdx...endIdx]))
            }
            return info
        }
    }

    // Result text for a segment or press, matching NassauEngine.summarizeSegment.
    private func segmentResultText(status: [Int], complete: Bool, t1: String, t2: String) -> String {
        let final = status.last ?? 0
        if complete {
            if final > 0 { return "\(t1) won \(final) up" }
            if final < 0 { return "\(t2) won \(abs(final)) up" }
            return "Halved"
        } else {
            if final > 0 { return "\(t1) \(final) up" }
            if final < 0 { return "\(t2) \(abs(final)) up" }
            return "All Square"
        }
    }

    // Signed money delta from owner's perspective; 0 when incomplete or tied.
    private func segmentMoney(status: [Int], complete: Bool, stake: Double) -> Double {
        guard complete, let final = status.last else { return 0 }
        if final > 0 { return  stake }
        if final < 0 { return -stake }
        return 0
    }

    private func buildPairingSection(ownerName: String, opponentName: String) -> PairingSection? {
        let frontPairs = buildPairedHoles(ownerName: ownerName, opponentName: opponentName, front: true)
        let backPairs  = buildPairedHoles(ownerName: ownerName, opponentName: opponentName, front: false)
        guard !frontPairs.isEmpty || !backPairs.isEmpty else { return nil }

        let frontStatus   = runningStatus(from: frontPairs)
        let backStatus    = runningStatus(from: backPairs)
        let overallStatus = runningStatus(from: frontPairs + backPairs)

        let stake     = match?.stake ?? 1.0
        let trigger   = match?.trigger ?? 2
        let pressMode = match.flatMap { NassauPressMode(rawValue: $0.pressMode ?? "") } ?? .auto

        let frontCommitted    = frontPairs.filter { $0.hostScore != nil && $0.opponentScore != nil }.count
        let backCommitted     = backPairs.filter  { $0.hostScore != nil && $0.opponentScore != nil }.count
        let isFrontComplete   = frontCommitted == 9
        let isBackComplete    = backCommitted  == 9
        let isOverallComplete = isFrontComplete && isBackComplete

        let t1 = ownerName.isEmpty    ? "P1" : ownerName
        let t2 = opponentName.isEmpty ? "P2" : opponentName

        var rows: [SegmentRow] = [
            makeRow("Front 9",  status: frontStatus,   t1: t1, t2: t2, complete: isFrontComplete,   stake: stake),
            makeRow("Back 9",   status: backStatus,    t1: t1, t2: t2, complete: isBackComplete,    stake: stake),
            makeRow("18 Holes", status: overallStatus, t1: t1, t2: t2, complete: isOverallComplete, stake: stake),
        ]

        if pressMode == .auto {
            let posLabel     = isSameCourse ? "H" : "#"
            let frontPresses = detectPresses(pairs: frontPairs, holeOffset: 0, segmentEndPos: 9,
                                              trigger: trigger, stake: stake)
            let backPresses  = detectPresses(pairs: backPairs,  holeOffset: 9, segmentEndPos: 18,
                                              trigger: trigger, stake: stake)
            for (i, p) in (frontPresses + backPresses).enumerated() {
                let pressComplete = p.endPos <= 9 ? isFrontComplete : isBackComplete
                let label = "Press \(i + 1) · \(posLabel)\(p.startPos)–\(p.endPos)"
                rows.append(makeRow(label, status: p.runningStatus, t1: t1, t2: t2,
                                    complete: pressComplete, stake: p.stake))
            }
        }

        let courseA = amHost ? (match?.courseA ?? "") : (match?.courseB ?? "")
        let courseB = amHost ? (match?.courseB ?? "") : (match?.courseA ?? "")
        let title: String
        if !courseA.isEmpty && !courseB.isEmpty && courseA.lowercased() != courseB.lowercased() {
            title = "\(t1) (\(courseA)) vs \(t2) (\(courseB))"
        } else {
            title = "\(t1) vs \(t2)"
        }
        return PairingSection(title: title, rows: rows,
                              isOverallComplete: isOverallComplete,
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
    // Same course: pairs by physical hole number. Different courses: sorts each player's
    // scores by HC rank and pairs positionally (hardest vs hardest), so both devices
    // produce identical output from the same receivedScores regardless of who is "owner".
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
        // Slot-based fallback: side A→slot 0, side B→slot 1
        if ownerScores.isEmpty || oppScores.isEmpty {
            // remoteNassauSide is set at create("A")/join("B") time — more reliable than amHost name comparison.
            let mySide  = GameManager.shared.currentGame?.remoteNassauSide ?? (amHost ? "A" : "B")
            let mySlot  = mySide == "A" ? 0 : 1
            let oppSlot = 1 - mySlot
            let inRange: (HoleScoreRecord) -> Bool = { s in
                s.hole >= 0 && s.hole < STANDARD_HOLES && (front ? s.hole <= 8 : s.hole >= 9)
            }
            let slotOwner = receivedScores.filter { $0.playerSlot == mySlot  && inRange($0) }
            let slotOpp   = receivedScores.filter { $0.playerSlot == oppSlot && inRange($0) }
            if ownerScores.isEmpty && !slotOwner.isEmpty { ownerScores = slotOwner }
            if oppScores.isEmpty   && !slotOpp.isEmpty   { oppScores   = slotOpp   }
        }

        let hostHc    = ownerScores.first?.playerHc ?? 0
        let oppHc     = oppScores.first?.playerHc   ?? 0
        let baseHC    = min(hostHc, oppHc)
        let hostDelta = max(0, hostHc - baseHC)
        let oppDelta  = max(0, oppHc  - baseHC)

        // Look up each player's CourseProfile for par-relative hole comparison.
        let ownerCourseName = amHost ? (match?.courseA ?? "") : (match?.courseB ?? "")
        let oppCourseName   = amHost ? (match?.courseB ?? "") : (match?.courseA ?? "")
        func normCourse(_ s: String) -> String { s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        let ownerProfile = CourseLibrary.shared.courses.first { normCourse($0.name) == normCourse(ownerCourseName) }
        let oppProfile   = CourseLibrary.shared.courses.first { normCourse($0.name) == normCourse(oppCourseName)   }

        func makePairedHole(rank: Int, o: HoleScoreRecord?, p: HoleScoreRecord?) -> PairedHole {
            let rawSI = o?.holeHc ?? p?.holeHc ?? (rank + 1)
            let si    = max(1, min(STANDARD_HOLES, rawSI == 0 ? STANDARD_HOLES : rawSI))
            let hostStrokes = NassauEngine.pops(for: hostDelta, strokeIndex: si)
            let oppStrokes  = NassauEngine.pops(for: oppDelta,  strokeIndex: si)
            let hostNet: Int? = o.map { $0.grossScore - hostStrokes }
            let oppNet:  Int? = p.map { $0.grossScore - oppStrokes  }
            let hostPar = o.flatMap { ownerProfile?.pars[safe: $0.hole] }
            let oppPar  = p.flatMap { oppProfile?.pars[safe: $0.hole]   }
            return PairedHole(
                hcRank: rank + 1,
                hostPhysicalHole: (o?.hole ?? rank) + 1,
                hostScore: o?.grossScore,
                hostNetScore: hostNet,
                hostStrokes: hostStrokes,
                hostPar: hostPar,
                opponentPhysicalHole: (p?.hole ?? rank) + 1,
                opponentScore: p?.grossScore,
                opponentNetScore: oppNet,
                opponentStrokes: oppStrokes,
                opponentPar: oppPar,
                netResult: RemoteNassauScorer.holeWinner(netHost: hostNet, netOpp: oppNet,
                                                          parHost: hostPar, parOpp: oppPar)
            )
        }

        if isSameCourse {
            // Same course — match by physical hole number
            let range = front ? (0..<9) : (9..<STANDARD_HOLES)
            return range.compactMap { h -> PairedHole? in
                let o = ownerScores.first { $0.hole == h }
                let p = oppScores.first   { $0.hole == h }
                guard o != nil || p != nil else { return nil }
                return makePairedHole(rank: h, o: o, p: p)
            }
        } else {
            // Different courses — match by HC rank (hardest vs hardest)
            let ownerSorted = ownerScores
                .filter { front ? $0.hole < 9 : $0.hole >= 9 }
                .sorted { hcRank($0) < hcRank($1) }
            let oppSorted = oppScores
                .filter { front ? $0.hole < 9 : $0.hole >= 9 }
                .sorted { hcRank($0) < hcRank($1) }

            let count = max(ownerSorted.count, oppSorted.count)
            return (0..<count).compactMap { i -> PairedHole? in
                let o = i < ownerSorted.count ? ownerSorted[i] : nil
                let p = i < oppSorted.count   ? oppSorted[i]   : nil
                guard o != nil || p != nil else { return nil }
                return makePairedHole(rank: i, o: o, p: p)
            }
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

        let stake     = match?.stake ?? 1.0
        let trigger   = match?.trigger ?? 2
        let pressMode = match.flatMap { NassauPressMode(rawValue: $0.pressMode ?? "") } ?? .auto
        let posLabel  = isSameCourse ? "H" : "#"

        var bodyParts: [String] = []
        for pair in pairingArgs {
            let t1 = pair.owner.isEmpty    ? "P1" : pair.owner
            let t2 = pair.opponent.isEmpty ? "P2" : pair.opponent

            let frontPairs = buildPairedHoles(ownerName: pair.owner, opponentName: pair.opponent, front: true)
            let backPairs  = buildPairedHoles(ownerName: pair.owner, opponentName: pair.opponent, front: false)
            guard !frontPairs.isEmpty || !backPairs.isEmpty else { continue }

            let frontStatus   = runningStatus(from: frontPairs)
            let backStatus    = runningStatus(from: backPairs)
            let overallStatus = runningStatus(from: frontPairs + backPairs)

            let isFrontComplete   = frontPairs.filter { $0.hostScore != nil && $0.opponentScore != nil }.count == 9
            let isBackComplete    = backPairs.filter  { $0.hostScore != nil && $0.opponentScore != nil }.count == 9
            let isOverallComplete = isFrontComplete && isBackComplete

            var lines = ["\(t1) vs \(t2)"]
            lines.append("  Front 9: \(segmentResultText(status: frontStatus,   complete: isFrontComplete,   t1: t1, t2: t2))")
            lines.append("  Back 9:  \(segmentResultText(status: backStatus,    complete: isBackComplete,    t1: t1, t2: t2))")
            lines.append("  18 Hole: \(segmentResultText(status: overallStatus, complete: isOverallComplete, t1: t1, t2: t2))")

            var totalMoney = segmentMoney(status: frontStatus,   complete: isFrontComplete,   stake: stake)
                           + segmentMoney(status: backStatus,    complete: isBackComplete,    stake: stake)
                           + segmentMoney(status: overallStatus, complete: isOverallComplete, stake: stake)

            if pressMode == .auto {
                let frontPresses = detectPresses(pairs: frontPairs, holeOffset: 0, segmentEndPos: 9,
                                                  trigger: trigger, stake: stake)
                let backPresses  = detectPresses(pairs: backPairs,  holeOffset: 9, segmentEndPos: 18,
                                                  trigger: trigger, stake: stake)
                for (i, p) in (frontPresses + backPresses).enumerated() {
                    let pressComplete = p.endPos <= 9 ? isFrontComplete : isBackComplete
                    let label = "Press \(i + 1) · \(posLabel)\(p.startPos)–\(p.endPos)"
                    lines.append("  \(label): \(segmentResultText(status: p.runningStatus, complete: pressComplete, t1: t1, t2: t2))")
                    totalMoney += segmentMoney(status: p.runningStatus, complete: pressComplete, stake: p.stake)
                }
            }

            let netText: String
            if totalMoney > 0      { netText = "\(t1) +\(money(totalMoney))" }
            else if totalMoney < 0 { netText = "\(t2) +\(money(-totalMoney))" }
            else                   { netText = "Even" }
            lines.append("  Net: \(netText)")

            bodyParts.append(lines.joined(separator: "\n"))
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
        let ownerCourse = amHost
            ? (match?.courseA ?? "")
            : (match?.courseB ?? "")
        let opponentCourse = amHost
            ? (match?.courseB ?? "")
            : (match?.courseA ?? "")

        let vc      = NassauScorecardViewController()
        vc.segmentTitle   = front ? "Front 9" : "Back 9"
        vc.ownerName      = section.ownerName.isEmpty    ? "Player 1" : section.ownerName
        vc.opponentName   = section.opponentName.isEmpty ? "Player 2" : section.opponentName
        vc.ownerCourse    = ownerCourse
        vc.opponentCourse = opponentCourse
        vc.pairedHoles    = pairs
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
            async let freshMatch        = SupabaseService.shared.fetchMatch(id: matchId)
            async let nassauHoles       = SupabaseService.shared.fetchRemoteNassauHoles(matchId: matchId)
            async let legacyHoleScores  = SupabaseService.shared.fetchHoleScores(matchId: matchId)
            let (m, nassau, legacy) = try await (freshMatch, nassauHoles, legacyHoleScores)
            // Prefer remote_nassau_hole_scores when populated; fall back to hole_scores for
            // older matches that only have data in the legacy table.
            let scores: [HoleScoreRecord] = nassau.isEmpty
                ? legacy
                : nassau.map { $0.toHoleScoreRecord() }
            await MainActor.run {
                self.match = m
                self.receivedScores = scores
                self.rebuildStandings()
                self.setStatus(live: true)
                print("DEBUG refresh: nassau=\(nassau.count) legacy=\(legacy.count) using=\(scores.count) courseA=\(m.courseA ?? "nil") courseB=\(m.courseB ?? "nil")")
            }
            return true
        } catch {
            await MainActor.run { self.setStatus(live: false) }
            return false
        }
    }
}
