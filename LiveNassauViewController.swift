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
        let refreshBtn = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(refreshTapped)
        )
        let scorecardBtn = UIBarButtonItem(
            title: "Scorecard",
            style: .plain,
            target: self,
            action: #selector(scorecardTapped)
        )
        navigationItem.rightBarButtonItems = [refreshBtn, scorecardBtn]

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
        if let g = GameManager.shared.currentGame,
           let matchId = match?.id,
           let slot = g.remoteNassauLocalSlotMap?[matchId],
           slot < g.playerNames.count {
            let n = g.playerNames[slot].trimmingCharacters(in: .whitespacesAndNewlines)
            if !n.isEmpty { return n }
        }
        return (ProfileStore.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSameCourse: Bool {
        let aName = (match?.courseA ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let bName = (match?.courseB ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !aName.isEmpty && !bName.isEmpty else { return false }

        // Prefer UUID comparison via CourseLibrary to avoid false matches from name variants
        let norm = { (s: String) in s.lowercased() }
        if let profA = CourseLibrary.shared.courses.first(where: { norm($0.name) == norm(aName) }),
           let profB = CourseLibrary.shared.courses.first(where: { norm($0.name) == norm(bName) }) {
            return profA.id == profB.id
        }

        return norm(aName) == norm(bName)
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

    private func runningStatus(from pairs: [PairedHole]) -> [Int] {
        NassauPressDetector.runningStatus(from: pairs)
    }

    private typealias PressInfo = NassauPressDetector.Press

    private func detectPresses(
        pairs: [PairedHole],
        holeOffset: Int,
        segmentEndPos: Int,
        trigger: Int,
        stake: Double
    ) -> [PressInfo] {
        NassauPressDetector.detectLegacy(pairs: pairs, holeOffset: holeOffset,
                                         segmentEndPos: segmentEndPos, trigger: trigger, stake: stake)
    }

    // press_v2: each active segment watches its own score; unlimited, no press on last hole.
    private func detectPressesV2(
        pairs: [PairedHole],
        holeOffset: Int,
        segmentEndPos: Int,
        trigger: Int,
        stake: Double
    ) -> [PressInfo] {
        NassauPressDetector.detectV2(pairs: pairs, holeOffset: holeOffset,
                                     segmentEndPos: segmentEndPos, trigger: trigger, stake: stake)
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

    // Short result for popup press lines — omits player name to prevent wrapping.
    private func pressResultText(status: [Int], complete: Bool) -> String {
        let final = status.last ?? 0
        if complete {
            if final > 0 { return "won \(final) up" }
            if final < 0 { return "\(abs(final)) down" }
            return "Halved"
        } else {
            if final > 0 { return "\(final) up" }
            if final < 0 { return "\(abs(final)) down" }
            return "All Square"
        }
    }

    // Hole-range label: "#13–18" normally, "#18" for a 1-hole press.
    private func holeRangeLabel(posLabel: String, startPos: Int, endPos: Int) -> String {
        startPos == endPos ? "\(posLabel)\(startPos)" : "\(posLabel)\(startPos)–\(endPos)"
    }

    private func segmentMoney(status: [Int], complete: Bool, stake: Double) -> Double {
        NassauPressDetector.segmentMoney(status: status, complete: complete, stake: stake)
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
            let posLabel = isSameCourse ? "H" : "#"
            let isV2     = match?.games?.contains("press_v2") == true
            let frontPresses = isV2
                ? detectPressesV2(pairs: frontPairs, holeOffset: 0, segmentEndPos: 9,
                                  trigger: trigger, stake: stake)
                : detectPresses  (pairs: frontPairs, holeOffset: 0, segmentEndPos: 9,
                                  trigger: trigger, stake: stake)
            let backPresses  = isV2
                ? detectPressesV2(pairs: backPairs, holeOffset: 9, segmentEndPos: 18,
                                  trigger: trigger, stake: stake)
                : detectPresses  (pairs: backPairs, holeOffset: 9, segmentEndPos: 18,
                                  trigger: trigger, stake: stake)
            for (i, p) in (frontPresses + backPresses).enumerated() {
                let pressComplete = p.endPos <= 9 ? isFrontComplete : isBackComplete
                let label = "Press \(i + 1) · \(holeRangeLabel(posLabel: posLabel, startPos: p.startPos, endPos: p.endPos))"
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

        func makePairedHole(rank: Int, o: HoleScoreRecord?, p: HoleScoreRecord?,
                            knownHostIdx: Int? = nil, knownOppIdx: Int? = nil) -> PairedHole {
            // Indices must be resolved before HC lookups so each player uses their own course's HC.
            let hostIdx = o?.hole ?? knownHostIdx ?? rank
            let oppIdx  = p?.hole ?? knownOppIdx  ?? rank
            // Per-player stroke indices: score record's holeHc first (works without profile),
            // then CourseProfile (authoritative for unscored holes), then slot rank fallback.
            let rawHostSI = o?.holeHc ?? ownerProfile?.hcs[safe: hostIdx] ?? (rank + 1)
            let rawOppSI  = p?.holeHc ?? oppProfile?.hcs[safe: oppIdx]   ?? (rank + 1)
            let hostSI = max(1, min(STANDARD_HOLES, rawHostSI == 0 ? STANDARD_HOLES : rawHostSI))
            let oppSI  = max(1, min(STANDARD_HOLES, rawOppSI  == 0 ? STANDARD_HOLES : rawOppSI))
            let hostStrokes = NassauEngine.pops(for: hostDelta, strokeIndex: hostSI)
            let oppStrokes  = NassauEngine.pops(for: oppDelta,  strokeIndex: oppSI)
            let hostNet: Int? = o.map { $0.grossScore - hostStrokes }
            let oppNet:  Int? = p.map { $0.grossScore - oppStrokes  }
            let hostPar = o.flatMap { ownerProfile?.pars[safe: $0.hole] }
                       ?? knownHostIdx.flatMap { ownerProfile?.pars[safe: $0] }
            let oppPar  = p.flatMap { oppProfile?.pars[safe: $0.hole] }
                       ?? knownOppIdx.flatMap { oppProfile?.pars[safe: $0] }
            return PairedHole(
                hcRank: rank + 1,
                hostPhysicalHole: hostIdx + 1,
                hostScore: o?.grossScore,
                hostNetScore: hostNet,
                hostStrokes: hostStrokes,
                hostPar: hostPar,
                opponentPhysicalHole: oppIdx + 1,
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
            let range = front ? (0..<9) : (9..<STANDARD_HOLES)

            // Prefer stored pairing from DB (written by joiner at join time).
            // Stored as [courseA_idx, courseB_idx]; swap indices when viewing as joiner.
            if match?.games?.contains("pairing_v2") == true,
               RemoteNassauPairing.isValidStoredPairing(match?.pairing) {
                let allPairs  = match!.pairing!
                let slotRange = front ? (0..<9) : (9..<18)
                return slotRange.map { rank in
                    let pair     = allPairs[rank]
                    let ownerIdx = amHost ? pair[0] : pair[1]
                    let oppIdx   = amHost ? pair[1] : pair[0]
                    let o = ownerScores.first { $0.hole == ownerIdx }
                    let p = oppScores.first   { $0.hole == oppIdx   }
                    return makePairedHole(rank: rank, o: o, p: p,
                                         knownHostIdx: ownerIdx, knownOppIdx: oppIdx)
                }
            }

            // Fixed-slot path: always 9 slots ranked by HC from CourseProfile
            if let ownerProf = ownerProfile, let oppProf = oppProfile {
                // v2: par-first pairing ordered by HC-sum (fallback when stored pairing unavailable)
                if match?.games?.contains("pairing_v2") == true {
                    let pairs = RemoteNassauPairing.parFirstPairedIndices(
                        parsA: ownerProf.pars, hcsA: ownerProf.hcs,
                        parsB: oppProf.pars,   hcsB: oppProf.hcs,
                        range: range
                    )
                    return pairs.enumerated().map { (rank, pair) in
                        let o = ownerScores.first { $0.hole == pair.indexA }
                        let p = oppScores.first   { $0.hole == pair.indexB }
                        return makePairedHole(rank: rank, o: o, p: p,
                                              knownHostIdx: pair.indexA, knownOppIdx: pair.indexB)
                    }
                }
                // v1: sort each course independently by HC
                let ownerOrder = RemoteNassauPairing.hcSortedIndices(hcs: ownerProf.hcs, range: range)
                let oppOrder   = RemoteNassauPairing.hcSortedIndices(hcs: oppProf.hcs,   range: range)
                return (0..<9).map { rank in
                    let ownerIdx = ownerOrder[rank]
                    let oppIdx   = oppOrder[rank]
                    let o = ownerScores.first { $0.hole == ownerIdx }
                    let p = oppScores.first   { $0.hole == oppIdx   }
                    return makePairedHole(rank: rank, o: o, p: p)
                }
            }

            // Fallback: reconstruct HC order from per-hole HC values in received scores.
            // Unplayed holes get HC=999 so they sort to the end but still occupy fixed slots.
            var ownerHcArray = Array(repeating: 999, count: STANDARD_HOLES)
            var oppHcArray   = Array(repeating: 999, count: STANDARD_HOLES)
            for s in ownerScores { if let hc = s.holeHc { ownerHcArray[s.hole] = hc } }
            for s in oppScores   { if let hc = s.holeHc { oppHcArray[s.hole]   = hc } }

            let hasHcData = ownerHcArray.contains { $0 != 999 } || oppHcArray.contains { $0 != 999 }
            if hasHcData {
                let ownerOrder = RemoteNassauPairing.hcSortedIndices(hcs: ownerHcArray, range: range)
                let oppOrder   = RemoteNassauPairing.hcSortedIndices(hcs: oppHcArray,   range: range)
                return (0..<9).map { rank in
                    let ownerIdx = ownerOrder[rank]
                    let oppIdx   = oppOrder[rank]
                    let o = ownerScores.first { $0.hole == ownerIdx }
                    let p = oppScores.first   { $0.hole == oppIdx   }
                    return makePairedHole(rank: rank, o: o, p: p)
                }
            }

            // True fallback: no HC data at all — 9 fixed slots in physical hole order
            return range.map { h in
                let o = ownerScores.first { $0.hole == h }
                let p = oppScores.first   { $0.hole == h }
                return makePairedHole(rank: h - range.lowerBound, o: o, p: p)
            }
        }
    }

    // MARK: - Final result

    @objc private func scorecardTapped() {
        guard let section = pairings.first else { return }
        let front = buildPairedHoles(ownerName: section.ownerName, opponentName: section.opponentName, front: true)
        let back  = buildPairedHoles(ownerName: section.ownerName, opponentName: section.opponentName, front: false)
        let config = scorecardConfig(ownerName: section.ownerName, opponentName: section.opponentName,
                                     pairs: front + back, title: "Scorecard")
        navigationController?.pushViewController(NassauScorecardViewController(config: config), animated: true)
    }

    // Builds a ScorecardConfig from match settings + pre-built pairs.
    private func scorecardConfig(ownerName: String, opponentName: String,
                                 pairs: [PairedHole], title: String) -> ScorecardConfig {
        let stake     = match?.stake ?? 1.0
        let trigger   = match?.trigger ?? 2
        let pressMode = match.flatMap { NassauPressMode(rawValue: $0.pressMode ?? "") } ?? .auto
        let isV2      = match?.games?.contains("press_v2") == true
        let ownerCourse    = amHost ? (match?.courseA ?? "") : (match?.courseB ?? "")
        let opponentCourse = amHost ? (match?.courseB ?? "") : (match?.courseA ?? "")
        return ScorecardConfig(
            ownerName: ownerName.isEmpty    ? "You" : ownerName,
            opponentName: opponentName.isEmpty ? "Opp" : opponentName,
            ownerCourse:    ownerCourse,
            opponentCourse: opponentCourse,
            pairs: pairs,
            stake: stake, trigger: trigger,
            pressMode: pressMode, isV2: isV2,
            isSameCourse: isSameCourse,
            posLabel: isSameCourse ? "H" : "#",
            title: title
        )
    }

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
            lines.append("  18 Holes: \(segmentResultText(status: overallStatus, complete: isOverallComplete, t1: t1, t2: t2))")

            var totalMoney = segmentMoney(status: frontStatus,   complete: isFrontComplete,   stake: stake)
                           + segmentMoney(status: backStatus,    complete: isBackComplete,    stake: stake)
                           + segmentMoney(status: overallStatus, complete: isOverallComplete, stake: stake)

            if pressMode == .auto {
                let isV2 = match?.games?.contains("press_v2") == true
                let frontPresses = isV2
                    ? detectPressesV2(pairs: frontPairs, holeOffset: 0, segmentEndPos: 9,
                                      trigger: trigger, stake: stake)
                    : detectPresses  (pairs: frontPairs, holeOffset: 0, segmentEndPos: 9,
                                      trigger: trigger, stake: stake)
                let backPresses  = isV2
                    ? detectPressesV2(pairs: backPairs, holeOffset: 9, segmentEndPos: 18,
                                      trigger: trigger, stake: stake)
                    : detectPresses  (pairs: backPairs, holeOffset: 9, segmentEndPos: 18,
                                      trigger: trigger, stake: stake)
                for (i, p) in (frontPresses + backPresses).enumerated() {
                    let pressComplete = p.endPos <= 9 ? isFrontComplete : isBackComplete
                    let label = "Press \(i + 1) · \(holeRangeLabel(posLabel: posLabel, startPos: p.startPos, endPos: p.endPos))"
                    lines.append("  \(label): \(pressResultText(status: p.runningStatus, complete: pressComplete))")
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
        let pairs  = buildPairedHoles(ownerName: section.ownerName, opponentName: section.opponentName, front: front)
        let title  = front ? "Front 9" : "Back 9"
        let config = scorecardConfig(ownerName: section.ownerName, opponentName: section.opponentName,
                                     pairs: pairs, title: title)
        navigationController?.pushViewController(NassauScorecardViewController(config: config), animated: true)
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
