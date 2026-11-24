import UIKit

/// Full-field leaderboard for a club event.
/// Tabs: Teams (Net) | Teams (Gross, if enabled) | Skins
/// Skins tab has a Gross / Net sub-segment and a 18-hole detail section.
final class ClubEventLeaderboardViewController: UITableViewController {

    // MARK: - Public entry point

    enum InitialTab { case teamNet, teamGross, skins }

    // MARK: - Private types

    private enum TabKind { case teamNet, teamGross, skins }
    private struct TabItem { let kind: TabKind; let title: String }

    private struct TeamEntry {
        let teamName:    String
        let netToPar:    Int
        let grossToPar:  Int
        let holesPlayed: Int
        let isMine:      Bool
        let netByHole:   [Int: Int]
        let grossByHole: [Int: Int]
    }

    private struct RankedEntry {
        let rank:           String
        let entry:          TeamEntry
        let tiebreakReason: String?
        var payout:         Double? = nil
    }

    private struct SkinWinner {
        let playerID:   UUID
        let count:      Int
        let totalValue: Double
    }

    // MARK: - Init params

    private let tournamentId:  UUID
    private let eventName:     String
    private let coursePars:    [Int]
    private let courseHCs:     [Int]
    private let myGroupCode:   String
    private let initialTab:    InitialTab
    private let isOrganizer:   Bool
    private let eventStatus:   String
    private var holeCount: Int { courseHCs.count }
    private var isEventFinished: Bool { eventStatus == "finished" }

    // MARK: - Loaded data

    private var netTeamEntries:    [TeamEntry] = []
    private var grossTeamEntries:  [TeamEntry] = []
    private var rankedNetEntries:   [RankedEntry] = []
    private var rankedGrossEntries: [RankedEntry] = []
    private var startedCount:      Int = 0
    private var skinsResults:      [FieldSkinsEngine.SkinResult] = []
    private var playerById:        [UUID: ClubEventPlayer] = [:]
    private var scoresByPlayer:    [UUID: [Int: (gross: Int, pickedUp: Bool)]] = [:]
    private var rules:             ClubEventRules?
    private var totalGroupCount:   Int    = 0
    private var groupsPostedPerHole: [Int: Int] = [:]
    private var grossTotalPot:     Double = 0
    private var netTotalPot:       Double = 0
    private var skinPlayerCount:   Int    = 0
    private var teamNetPot:        Double = 0
    private var teamGrossPot:      Double = 0

    // MARK: - Tab state

    private var tabs:            [TabItem] = []
    private var selectedTabKind: TabKind   = .teamNet
    private var skinsSegment:    Int       = 0  // 0 = Gross, 1 = Net

    private var isLoading       = false
    private let tabControl      = UISegmentedControl()
    private var cachedSummaryRows: [SummaryRow]?

    // MARK: - Init

    init(tournamentId: UUID, eventName: String,
         coursePars: [Int], courseHCs: [Int], myGroupCode: String,
         initialTab: InitialTab = .teamNet, isOrganizer: Bool = false,
         eventStatus: String = "active") {
        self.tournamentId = tournamentId
        self.eventName    = eventName
        self.coursePars   = coursePars
        self.courseHCs    = courseHCs
        self.myGroupCode  = myGroupCode
        self.initialTab   = initialTab
        self.isOrganizer  = isOrganizer
        self.eventStatus  = eventStatus
        super.init(style: .insetGrouped)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Leaderboard"
        view.backgroundColor = .systemGroupedBackground
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SkinSummaryCell")
        tableView.estimatedRowHeight = 50

        tabControl.addTarget(self, action: #selector(tabChanged), for: .valueChanged)
        buildTabs(rules: nil)  // give control non-zero size before data loads
        navigationItem.titleView = tabControl

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navigationItem.standardAppearance   = navAppearance
        navigationItem.scrollEdgeAppearance = navAppearance

        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(load), for: .valueChanged)
        tableView.refreshControl = refresh

        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        let footerLabel = UILabel()
        footerLabel.text = "Build \(build)"
        footerLabel.font = .preferredFont(forTextStyle: .caption2)
        footerLabel.textColor = .tertiaryLabel
        footerLabel.textAlignment = .center
        footerLabel.frame = CGRect(x: 0, y: 0, width: 0, height: 28)
        tableView.tableFooterView = footerLabel

        load()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Scoring screen hides the nav bar; always restore it here so tabs and
        // title are visible regardless of which VC we were pushed from.
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Load

    @objc private func load() {
        guard !isLoading else { return }
        isLoading = true
        Task {
            do {
                async let playersTask = SupabaseService.shared.fetchClubEventRoster(tournamentId: tournamentId)
                async let scoresTask  = SupabaseService.shared.fetchClubEventAllScores(tournamentId: tournamentId)
                async let teamsTask   = SupabaseService.shared.fetchClubEventTeams(tournamentId: tournamentId)
                async let rulesTask   = SupabaseService.shared.fetchClubEventRules(tournamentId: tournamentId)
                let (allPlayers, allScores, allTeams) = try await (playersTask, scoresTask, teamsTask)
                let memberships = try await SupabaseService.shared.fetchClubEventTeamMemberships(
                    teamIds: allTeams.map { $0.id })
                let fetchedRules = try? await rulesTask

                let result = Self.buildData(
                    players: allPlayers, scores: allScores, teams: allTeams,
                    memberships: memberships, pars: coursePars, hcs: courseHCs,
                    myGroupCode: myGroupCode, rules: fetchedRules)

                await MainActor.run {
                    self.isLoading           = false
                    self.rules               = fetchedRules
                    self.netTeamEntries      = result.netEntries
                    self.grossTeamEntries    = result.grossEntries
                    let hc = self.courseHCs.count
                    var ranked  = Self.computeRanks(result.netEntries,   useGross: false, holeCount: hc)
                    var rankedG = Self.computeRanks(result.grossEntries, useGross: true,  holeCount: hc)
                    if let r = fetchedRules, r.teamPlacesPaid > 0, !r.placePcts.isEmpty {
                        ranked  = Self.applyPayouts(to: ranked,  pot: result.teamNetPot,
                                                    placePcts: r.placePcts, placesPaid: r.teamPlacesPaid)
                        rankedG = Self.applyPayouts(to: rankedG, pot: result.teamGrossPot,
                                                    placePcts: r.placePcts, placesPaid: r.teamPlacesPaid)
                    }
                    self.rankedNetEntries    = ranked
                    self.rankedGrossEntries  = rankedG
                    self.startedCount        = result.netEntries.filter { $0.holesPlayed > 0 }.count
                    self.skinsResults        = result.skins
                    self.cachedSummaryRows   = nil
                    self.playerById          = result.playerById
                    self.scoresByPlayer      = result.scoresByPlayer
                    self.totalGroupCount     = result.totalGroupCount
                    self.groupsPostedPerHole = result.groupsPostedPerHole
                    self.grossTotalPot       = result.grossTotalPot
                    self.netTotalPot         = result.netTotalPot
                    self.skinPlayerCount     = result.skinPlayerCount
                    self.teamNetPot          = result.teamNetPot
                    self.teamGrossPot        = result.teamGrossPot
                    self.buildTabs(rules: fetchedRules)
                    self.tableView.refreshControl?.endRefreshing()
                    self.tableView.reloadData()
                    self.printSkinsDebug()
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.tableView.refreshControl?.endRefreshing()
                    let ac = UIAlertController(title: "Error", message: error.localizedDescription,
                                              preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(ac, animated: true)
                }
            }
        }
    }

    // MARK: - Data computation (background-safe)

    private struct ComputedData {
        let netEntries:       [TeamEntry]
        let grossEntries:     [TeamEntry]
        let skins:            [FieldSkinsEngine.SkinResult]
        let playerById:       [UUID: ClubEventPlayer]
        let scoresByPlayer:   [UUID: [Int: (gross: Int, pickedUp: Bool)]]
        let totalGroupCount:  Int
        let groupsPostedPerHole: [Int: Int]
        let grossTotalPot:    Double
        let netTotalPot:      Double
        let skinPlayerCount:  Int
        let teamNetPot:       Double
        let teamGrossPot:     Double
    }

    private static func buildData(
        players: [ClubEventPlayer],
        scores:  [ClubEventHoleScore],
        teams:   [ClubEventTeam],
        memberships: [ClubEventTeamMembership],
        pars: [Int], hcs: [Int],
        myGroupCode: String,
        rules: ClubEventRules?
    ) -> ComputedData {

        let playerById = Dictionary(uniqueKeysWithValues: players.map { ($0.id, $0) })

        var scoresByPlayer: [UUID: [Int: (gross: Int, pickedUp: Bool)]] = [:]
        for s in scores {
            if scoresByPlayer[s.tournamentPlayerId] == nil { scoresByPlayer[s.tournamentPlayerId] = [:] }
            scoresByPlayer[s.tournamentPlayerId]![s.holeNumber] =
                (s.grossScore ?? 0, s.netScoreType == "picked_up")
        }

        var membersByTeam: [UUID: [UUID]] = [:]
        for m in memberships { membersByTeam[m.teamId, default: []].append(m.tournamentPlayerId) }

        // Per-group posted holes: a hole is "posted" once any member has a score for it
        var postedByGroup: [String: Set<Int>] = [:]
        for player in players {
            guard let gc = player.groupCode, !gc.isEmpty else { continue }
            for (hole, data) in scoresByPlayer[player.id] ?? [:] where data.gross > 0 || data.pickedUp {
                postedByGroup[gc, default: []].insert(hole)
            }
        }

        let standingTeams = teams

        let holeCount = hcs.count

        func strokes(hc18: Int, hcRank: Int) -> Int {
            var hc = max(0, hc18)
            if holeCount == 9 { hc = Int((Double(hc) / 2.0).rounded()) }
            return hc / holeCount + (hcRank <= hc % holeCount ? 1 : 0)
        }

        func entry(for team: ClubEventTeam) -> TeamEntry {
            let members = (membersByTeam[team.id] ?? []).compactMap { playerById[$0] }
            var totalNet = 0, totalGross = 0, holesPlayed = 0
            var netByHole:   [Int: Int] = [:]
            var grossByHole: [Int: Int] = [:]
            for hole in 1...holeCount {
                let hcRank = hcs[hole - 1]
                var bestNet: Int?, bestGross: Int?
                for p in members {
                    guard let d = scoresByPlayer[p.id]?[hole],
                          !d.pickedUp, d.gross > 0 else { continue }
                    let net     = d.gross - strokes(hc18: Int(p.handicap.rounded()), hcRank: hcRank)
                    if bestNet   == nil || net    < bestNet!   { bestNet   = net    }
                    if bestGross == nil || d.gross < bestGross! { bestGross = d.gross }
                }
                if let n = bestNet, let g = bestGross {
                    let netRelPar   = n - pars[hole - 1]
                    let grossRelPar = g - pars[hole - 1]
                    totalNet   += netRelPar
                    totalGross += grossRelPar
                    holesPlayed += 1
                    netByHole[hole]   = netRelPar
                    grossByHole[hole] = grossRelPar
                }
            }
            let isMine  = !myGroupCode.isEmpty && team.teamName.hasPrefix(myGroupCode)
            let display = teamDisplay((membersByTeam[team.id] ?? []).compactMap { playerById[$0] })
            return TeamEntry(teamName: display, netToPar: totalNet, grossToPar: totalGross,
                             holesPlayed: holesPlayed, isMine: isMine,
                             netByHole: netByHole, grossByHole: grossByHole)
        }

        let raw        = standingTeams.map { entry(for: $0) }
        let started    = raw.filter { $0.holesPlayed > 0 }
        let notStarted = raw.filter { $0.holesPlayed == 0 }

        let netEntries = started.sorted {
            $0.netToPar != $1.netToPar ? $0.netToPar < $1.netToPar : $0.holesPlayed > $1.holesPlayed
        } + notStarted

        let grossEntries = started.sorted {
            $0.grossToPar != $1.grossToPar ? $0.grossToPar < $1.grossToPar : $0.holesPlayed > $1.holesPlayed
        } + notStarted

        // Groups per hole
        let allGroupCodes = Set(players.compactMap { p -> String? in
            guard let gc = p.groupCode, !gc.isEmpty else { return nil }
            return gc
        })
        let totalGroupCount = allGroupCodes.count
        var groupsPostedPerHole: [Int: Int] = [:]
        for (_, posted) in postedByGroup {
            for hole in posted { groupsPostedPerHole[hole, default: 0] += 1 }
        }

        // --- Pots ---
        let pots: EventPots
        if let r = rules {
            pots = PayoutCalculator.pots(rules: r, players: players)
        } else {
            pots = EventPots(teamNet: 0, teamGross: 0, grossSkins: 0, netSkins: 0)
        }
        let activeCount  = players.filter { $0.groupCode != nil && !$0.isWithdrawn }.count
        let potGrossPerHole = holeCount > 0 ? pots.grossSkins / Double(holeCount) : 0
        let potNetPerHole   = holeCount > 0 ? pots.netSkins   / Double(holeCount) : 0

        // --- Skins ---
        let skinInputs = buildClubEventSkinInputs(
            players: players, scoresByPlayer: scoresByPlayer,
            postedByGroup: postedByGroup, holeCount: holeCount)

        let skinSettings = FieldSkinsEngine.Settings(
            holeHandicapRanks: hcs,
            allowance:  rules?.handicapAllowance ?? 1.0,
            carryoverEnabled: rules?.skinsCarryover ?? false,
            potGrossPerHole: potGrossPerHole,
            potNetPerHole:   potNetPerHole)

        let skins = skinInputs.isEmpty ? [] : FieldSkinsEngine.compute(players: skinInputs, settings: skinSettings)

        return ComputedData(netEntries: netEntries, grossEntries: grossEntries,
                            skins: skins, playerById: playerById, scoresByPlayer: scoresByPlayer,
                            totalGroupCount: totalGroupCount, groupsPostedPerHole: groupsPostedPerHole,
                            grossTotalPot: pots.grossSkins, netTotalPot: pots.netSkins,
                            skinPlayerCount: activeCount,
                            teamNetPot: pots.teamNet, teamGrossPot: pots.teamGross)
    }

    private static func teamDisplay(_ players: [ClubEventPlayer]) -> String {
        guard !players.isEmpty else { return "—" }
        return players.map { p -> String in
            let last = p.playerName.components(separatedBy: " ").last ?? p.playerName
            return p.isWithdrawn ? "\(last) (WD)" : last
        }.sorted().joined(separator: " / ")
    }

    // MARK: - Ranking

    private static func computeRanks(_ entries: [TeamEntry], useGross: Bool, holeCount: Int = 18) -> [RankedEntry] {
        let started    = entries.filter { $0.holesPlayed > 0 }
        let notStarted = entries.filter { $0.holesPlayed == 0 }

        let sorted = started.sorted {
            let as_ = useGross ? $0.grossToPar : $0.netToPar
            let bs_ = useGross ? $1.grossToPar : $1.netToPar
            if as_ != bs_ { return as_ < bs_ }
            return $0.holesPlayed > $1.holesPlayed
        }

        var result: [RankedEntry] = []
        var i = 0
        while i < sorted.count {
            let curScore = useGross ? sorted[i].grossToPar : sorted[i].netToPar
            var j = i
            while j < sorted.count {
                let s = useGross ? sorted[j].grossToPar : sorted[j].netToPar
                if s != curScore { break }
                j += 1
            }
            let group    = Array(sorted[i..<j])
            let baseRank = i + 1

            if group.count == 1 {
                result.append(RankedEntry(rank: "\(baseRank)", entry: group[0], tiebreakReason: nil))
            } else {
                let allFinished = group.allSatisfy { $0.holesPlayed == holeCount }
                if !allFinished {
                    for e in group {
                        result.append(RankedEntry(rank: "T\(baseRank)", entry: e, tiebreakReason: nil))
                    }
                } else {
                    result.append(contentsOf: rankWithTiebreak(group, baseRank: baseRank, useGross: useGross, holeCount: holeCount))
                }
            }
            i = j
        }

        for e in notStarted {
            result.append(RankedEntry(rank: "—", entry: e, tiebreakReason: nil))
        }
        return result
    }

    private static func rankWithTiebreak(_ group: [TeamEntry], baseRank: Int, useGross: Bool, holeCount: Int = 18) -> [RankedEntry] {
        struct Step { let label: String; let startHole: Int; let endHole: Int }
        let steps: [Step] = holeCount == 9 ? [
            Step(label: "back 6",  startHole: 4, endHole: 9),
            Step(label: "back 3",  startHole: 7, endHole: 9),
            Step(label: "hole 9",  startHole: 9, endHole: 9),
        ] : [
            Step(label: "back 9",  startHole: 10, endHole: 18),
            Step(label: "back 6",  startHole: 13, endHole: 18),
            Step(label: "back 3",  startHole: 16, endHole: 18),
            Step(label: "hole 18", startHole: 18, endHole: 18),
        ]

        func stepScore(_ entry: TeamEntry, _ step: Step) -> Int {
            let byHole = useGross ? entry.grossByHole : entry.netByHole
            return (step.startHole...step.endHole).reduce(0) { $0 + (byHole[$1] ?? 0) }
        }

        var remaining  = group
        var results:   [RankedEntry] = []
        var rankOffset = 0

        for step in steps {
            guard remaining.count > 1 else { break }
            let scored   = remaining.map { (entry: $0, score: stepScore($0, step)) }
            let minScore = scored.map { $0.score }.min()!
            let winners  = scored.filter { $0.score == minScore }.map { $0.entry }
            let losers   = scored.filter { $0.score != minScore }.map { $0.entry }

            if !losers.isEmpty {
                let reason = "won on \(step.label)"
                for (idx, w) in winners.enumerated() {
                    let rank = baseRank + rankOffset + idx
                    results.append(RankedEntry(
                        rank: winners.count > 1 ? "T\(rank)" : "\(rank)",
                        entry: w,
                        tiebreakReason: winners.count == 1 ? reason : nil))
                }
                rankOffset += winners.count
                remaining   = losers
            }
        }

        for e in remaining {
            results.append(RankedEntry(rank: "T\(baseRank + rankOffset)", entry: e, tiebreakReason: nil))
            rankOffset += 1
        }
        return results
    }

    private static func applyPayouts(
        to ranked: [RankedEntry],
        pot: Double,
        placePcts: [Double],
        placesPaid: Int
    ) -> [RankedEntry] {
        guard pot > 0, placesPaid > 0, !placePcts.isEmpty else { return ranked }
        var out = ranked
        var i = 0
        while i < out.count {
            guard out[i].rank != "—" else { i += 1; continue }
            let rankStr = out[i].rank.hasPrefix("T") ? String(out[i].rank.dropFirst()) : out[i].rank
            guard let baseRank = Int(rankStr), baseRank >= 1, baseRank <= placesPaid else {
                i += 1; continue
            }
            var j = i + 1
            while j < out.count {
                let r = out[j].rank.hasPrefix("T") ? String(out[j].rank.dropFirst()) : out[j].rank
                guard r == rankStr else { break }
                j += 1
            }
            let groupSize = j - i
            var combinedPct = 0.0
            for place in baseRank...(baseRank + groupSize - 1) {
                if place <= placesPaid, place - 1 < placePcts.count {
                    combinedPct += placePcts[place - 1]
                }
            }
            let each = combinedPct > 0 ? pot * (combinedPct / Double(groupSize)) / 100.0 : 0
            for k in i..<j { out[k].payout = each > 0 ? each : nil }
            i = j
        }
        return out
    }

    // MARK: - Tabs

    private func buildTabs(rules: ClubEventRules?) {
        var items = [TabItem(kind: .teamNet, title: "Teams (Net)")]
        if rules?.grossLeaderboard == true {
            items.append(TabItem(kind: .teamGross, title: "Teams (Gross)"))
        }
        items.append(TabItem(kind: .skins, title: "Skins"))
        tabs = items

        tabControl.removeAllSegments()
        for (i, t) in tabs.enumerated() {
            tabControl.insertSegment(withTitle: t.title, at: i, animated: false)
        }
        let targetKind: TabKind
        switch initialTab {
        case .teamNet:   targetKind = .teamNet
        case .teamGross: targetKind = rules?.grossLeaderboard == true ? .teamGross : .teamNet
        case .skins:     targetKind = .skins
        }
        let idx = tabs.firstIndex { $0.kind == targetKind } ?? 0
        tabControl.selectedSegmentIndex = idx
        selectedTabKind = tabs[idx].kind
    }

    @objc private func tabChanged() {
        let idx = tabControl.selectedSegmentIndex
        guard idx >= 0, idx < tabs.count else { return }
        selectedTabKind = tabs[idx].kind
        tableView.reloadData()
    }

    @objc private func skinsSegmentChanged(_ sender: UISegmentedControl) {
        skinsSegment = sender.selectedSegmentIndex
        cachedSummaryRows = nil
        tableView.reloadSections(IndexSet([1, 2]), with: .none)
    }

    // MARK: - Skins helpers

    private var usingGrossSkins: Bool {
        guard let r = rules else { return true }
        if !r.grossSkinsEnabled { return false }
        if !r.netSkinsEnabled   { return true  }
        return skinsSegment == 0
    }

    private var showSkinsSegment: Bool {
        (rules?.grossSkinsEnabled ?? false) && (rules?.netSkinsEnabled ?? false)
    }

    private var currentTotalPot: Double { usingGrossSkins ? grossTotalPot : netTotalPot }

    private func finalSkinsWinners() -> [SkinWinner] {
        guard isEventFinished else { return [] }
        var counts: [UUID: Int] = [:]
        var values: [UUID: Double] = [:]
        for r in skinsResults {
            let w    = usingGrossSkins ? r.grossWinner        : r.netWinner
            let prov = usingGrossSkins ? r.grossIsProvisional : r.netIsProvisional
            let pot  = usingGrossSkins ? r.grossPot           : r.netPot
            if let winner = w, !prov {
                counts[winner, default: 0] += 1
                values[winner, default: 0] += pot
            }
        }
        return counts.map { SkinWinner(playerID: $0.key, count: $0.value, totalValue: values[$0.key] ?? 0) }
            .sorted { skinWinnerOrder($0, $1) }
    }

    private func leadingSkinsWinners() -> [SkinWinner] {
        var counts: [UUID: Int] = [:]
        for r in skinsResults {
            let w    = usingGrossSkins ? r.grossWinner        : r.netWinner
            let prov = usingGrossSkins ? r.grossIsProvisional : r.netIsProvisional
            if let winner = w, prov { counts[winner, default: 0] += 1 }
        }
        return counts.map { SkinWinner(playerID: $0.key, count: $0.value, totalValue: 0) }
            .sorted { skinWinnerOrder($0, $1) }
    }

    private func skinWinnerOrder(_ a: SkinWinner, _ b: SkinWinner) -> Bool {
        if a.count != b.count { return a.count > b.count }
        let na = playerById[a.playerID]?.playerName ?? ""
        let nb = playerById[b.playerID]?.playerName ?? ""
        if na != nb { return na < nb }
        return a.playerID.uuidString < b.playerID.uuidString
    }

    private struct SummaryRow {
        let playerID: UUID?
        let primary: String
        let secondary: String
        let primaryColor: UIColor
        let secondaryColor: UIColor
    }

    private func skinsSummaryRows() -> [SummaryRow] {
        if let cached = cachedSummaryRows { return cached }

        let final   = finalSkinsWinners()
        let leading = leadingSkinsWinners()

        let rows: [SummaryRow]

        if final.isEmpty && leading.isEmpty {
            rows = [SummaryRow(playerID: nil, primary: "No skins yet",
                               secondary: "", primaryColor: .secondaryLabel, secondaryColor: .secondaryLabel)]
        } else if final.isEmpty {
            let desc = leading.prefix(3).map { w -> String in
                let last = playerById[w.playerID]?.playerName.components(separatedBy: " ").last ?? "?"
                return "\(last) (\(w.count))"
            }.joined(separator: ", ")
            rows = [SummaryRow(playerID: nil, primary: "No skins final yet",
                               secondary: "Leading: \(desc)",
                               primaryColor: .secondaryLabel, secondaryColor: .secondaryLabel)]
        } else {
            let totalSkinsWon = final.reduce(0) { $0 + $1.count }
            let perSkin = totalSkinsWon > 0 ? currentTotalPot / Double(totalSkinsWon) : 0
            var built = final.map { w -> SummaryRow in
                let name = playerById[w.playerID]?.playerName ?? "Unknown"
                var sec  = "\(w.count) skin\(w.count == 1 ? "" : "s")"
                if isOrganizer && currentTotalPot > 0 {
                    sec += "  ·  \(fmtPot(perSkin * Double(w.count)))"
                }
                return SummaryRow(playerID: w.playerID, primary: name, secondary: sec,
                                  primaryColor: .label, secondaryColor: .systemGreen)
            }
            if !leading.isEmpty {
                let desc = leading.prefix(3).map { w -> String in
                    let last = playerById[w.playerID]?.playerName.components(separatedBy: " ").last ?? "?"
                    return "\(last) (\(w.count))"
                }.joined(separator: ", ")
                built.append(SummaryRow(playerID: nil, primary: "Also leading", secondary: desc,
                                        primaryColor: .secondaryLabel, secondaryColor: .secondaryLabel))
            }
            rows = built
        }

        cachedSummaryRows = rows
        return rows
    }

    // MARK: - Formatting

    private func fmtNet(_ n: Int) -> String {
        n == 0 ? "E" : n > 0 ? "+\(n)" : "\(n)"
    }

    private func fmtPot(_ v: Double) -> String {
        guard v > 0 else { return "" }
        return v == Double(Int(v)) ? "$\(Int(v))" : String(format: "$%.2f", v)
    }

    private func scoreDisplay(playerId: UUID, hole: Int, net: Bool) -> Int? {
        guard let d = scoresByPlayer[playerId]?[hole], !d.pickedUp, d.gross > 0 else { return nil }
        guard net else { return d.gross }
        guard let player = playerById[playerId] else { return d.gross }
        let hcRank  = courseHCs[hole - 1]
        let hc18    = Int(player.handicap.rounded())
        let hc      = holeCount == 9 ? Int((Double(hc18) / 2.0).rounded()) : hc18
        let strokes = hc / holeCount + (hcRank <= hc % holeCount ? 1 : 0)
        return d.gross - strokes
    }

    // MARK: - Table DataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        selectedTabKind == .skins ? 3 : 1
    }

    override func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch selectedTabKind {
        case .teamNet:   return max(1, rankedNetEntries.count)
        case .teamGross: return max(1, rankedGrossEntries.count)
        case .skins:
            switch section {
            case 0: return showSkinsSegment ? 1 : 0
            case 1:
                let potRows = isOrganizer && currentTotalPot > 0 ? 1 : 0
                return potRows + skinsSummaryRows().count
            case 2: return holeCount
            default: return 0
            }
        }
    }

    override func tableView(_ tv: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch selectedTabKind {
        case .teamNet, .teamGross: return eventName
        case .skins:
            switch section {
            case 0: return "Skins are final once every group has finished the hole."
            case 1: return isEventFinished ? "SKINS WON" : "SKINS LEADING"
            case 2: return "HOLE BY HOLE"
            default: return nil
            }
        }
    }

    override func tableView(_ tv: UITableView, titleForFooterInSection section: Int) -> String? {
        guard selectedTabKind == .skins else { return nil }
        switch section {
        case 1: return isOrganizer && currentTotalPot > 0 ? "Value per skin changes until results are locked." : nil
        default: return nil
        }
    }

    override func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch selectedTabKind {
        case .teamNet:   return teamCell(indexPath, ranked: rankedNetEntries,   useGross: false)
        case .teamGross: return teamCell(indexPath, ranked: rankedGrossEntries, useGross: true)
        case .skins:
            switch indexPath.section {
            case 0: return skinsSegmentCell()
            case 1:
                let hasPot = isOrganizer && currentTotalPot > 0
                if hasPot && indexPath.row == 0 { return skinsPotInfoCell() }
                return skinsSummaryCell(summaryIndex: indexPath.row - (hasPot ? 1 : 0))
            case 2: return skinsHoleCell(hole: indexPath.row + 1)
            default: return UITableViewCell()
            }
        }
    }

    // MARK: - Team cell

    private func teamCell(_ indexPath: IndexPath, ranked: [RankedEntry], useGross: Bool) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.contentConfiguration = nil
        cell.selectionStyle = .none

        guard !ranked.isEmpty else {
            var cfg = cell.defaultContentConfiguration()
            cfg.text = "No scores yet"
            cfg.textProperties.color = .secondaryLabel
            cell.contentConfiguration = cfg
            cell.backgroundColor = .systemBackground
            return cell
        }

        let re    = ranked[indexPath.row]
        let entry = re.entry
        var cfg   = cell.defaultContentConfiguration()

        cfg.textProperties.numberOfLines = 0
        cfg.secondaryTextProperties.numberOfLines = 0
        cfg.textProperties.adjustsFontForContentSizeCategory = true
        cfg.secondaryTextProperties.adjustsFontForContentSizeCategory = true

        if entry.holesPlayed == 0 {
            cfg.text = entry.teamName + (entry.isMine ? "  ★" : "")
            cfg.secondaryText = "Not started"
            cfg.textProperties.font           = UIFontMetrics(forTextStyle: .body)
                .scaledFont(for: .systemFont(ofSize: 16, weight: entry.isMine ? .semibold : .regular))
            cfg.secondaryTextProperties.font  = .preferredFont(forTextStyle: .footnote)
            cfg.secondaryTextProperties.color = .tertiaryLabel
        } else {
            let score = useGross ? entry.grossToPar : entry.netToPar
            let net   = fmtNet(score)
            let thru  = entry.holesPlayed < holeCount ? "thru \(entry.holesPlayed)" : "F"
            var secondary = "\(net)  ·  \(thru)"
            if let reason = re.tiebreakReason { secondary += "  ·  \(reason)" }
            if isOrganizer, let payout = re.payout, payout > 0 { secondary += "  ·  \(fmtPot(payout))" }
            cfg.text          = "\(re.rank). \(entry.teamName)\(entry.isMine ? "  ★" : "")"
            cfg.secondaryText = secondary
            cfg.textProperties.font           = UIFontMetrics(forTextStyle: .body)
                .scaledFont(for: .systemFont(ofSize: 16, weight: entry.isMine ? .semibold : .regular))
            cfg.secondaryTextProperties.font  = UIFontMetrics(forTextStyle: .subheadline)
                .scaledFont(for: .systemFont(ofSize: 14, weight: .medium))
            cfg.secondaryTextProperties.color = score < 0 ? .systemRed : score > 0 ? .secondaryLabel : .label
        }
        cell.contentConfiguration = cfg
        cell.backgroundColor = entry.isMine
            ? UIColor.systemYellow.withAlphaComponent(0.10)
            : .systemBackground
        return cell
    }

    // MARK: - Skins: segment selector cell

    private func skinsSegmentCell() -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.contentConfiguration = nil
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.selectionStyle = .none
        cell.backgroundColor = .systemBackground

        let seg = UISegmentedControl(items: ["Gross Skins", "Net Skins"])
        seg.selectedSegmentIndex = skinsSegment
        seg.addTarget(self, action: #selector(skinsSegmentChanged(_:)), for: .valueChanged)
        seg.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(seg)
        NSLayoutConstraint.activate([
            seg.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 10),
            seg.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -10),
            seg.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            seg.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
        ])
        return cell
    }

    // MARK: - Skins: pot info cell

    private func skinsPotInfoCell() -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.contentConfiguration = nil
        cell.selectionStyle = .none
        cell.backgroundColor = .systemBackground

        let total = currentTotalPot
        let final = finalSkinsWinners()
        let skinsWon = final.reduce(0) { $0 + $1.count }

        var cfg = cell.defaultContentConfiguration()
        cfg.text = usingGrossSkins ? "Gross pot \(fmtPot(total))" : "Net pot \(fmtPot(total))"
        if skinsWon > 0 {
            let perSkin = total / Double(skinsWon)
            let verb = isEventFinished ? "decided" : "leading"
            cfg.secondaryText = "\(skinsWon) skin\(skinsWon == 1 ? "" : "s") \(verb) so far  ·  \(fmtPot(perSkin)) each"
        } else {
            cfg.secondaryText = total > 0 ? "—" : "No skins decided yet"
        }
        cfg.textProperties.font           = UIFontMetrics(forTextStyle: .subheadline)
            .scaledFont(for: .systemFont(ofSize: 14, weight: .medium))
        cfg.secondaryTextProperties.font  = UIFontMetrics(forTextStyle: .footnote)
            .scaledFont(for: .systemFont(ofSize: 13))
        cfg.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = cfg
        return cell
    }

    // MARK: - Skins: summary cell

    private func skinsSummaryCell(summaryIndex: Int) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SkinSummaryCell")!
        cell.contentConfiguration = nil
        cell.selectionStyle = .none
        cell.backgroundColor = .systemBackground

        var cfg = cell.defaultContentConfiguration()
        let rows = skinsSummaryRows()
        guard summaryIndex < rows.count else {
            cfg.text = "—"
            cfg.secondaryText = nil
            cfg.textProperties.color = .label
            cfg.secondaryTextProperties.color = .secondaryLabel
            cell.contentConfiguration = cfg
            return cell
        }
        let row = rows[summaryIndex]
        cfg.text                           = row.primary
        cfg.textProperties.color           = row.primaryColor
        cfg.secondaryText                  = row.secondary.isEmpty ? nil : row.secondary
        cfg.secondaryTextProperties.color  = row.secondaryColor
        cell.contentConfiguration = cfg
        return cell
    }

    // MARK: - Skins: hole cell

    private func skinsHoleCell(hole: Int) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.contentConfiguration = nil
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.selectionStyle = .none
        cell.backgroundColor = .systemBackground

        var cfg = cell.defaultContentConfiguration()
        let par = hole <= coursePars.count ? coursePars[hole - 1] : 4

        guard hole - 1 < skinsResults.count else {
            cfg.text = "Hole \(hole)  ·  Par \(par)"
            cfg.secondaryText = "—"
            cfg.secondaryTextProperties.color = .secondaryLabel
            cell.contentConfiguration = cfg
            return cell
        }

        let result  = skinsResults[hole - 1]
        let winner  = usingGrossSkins ? result.grossWinner  : result.netWinner
        let tied    = usingGrossSkins ? result.grossTied    : result.netTied
        let prov    = (usingGrossSkins ? result.grossIsProvisional : result.netIsProvisional) || !isEventFinished
        let pot     = usingGrossSkins ? result.grossPot     : result.netPot
        let carried = usingGrossSkins ? result.grossCarriedFrom : result.netCarriedFrom

        cfg.text = "Hole \(hole)  ·  Par \(par)"

        // Carryover suffix for status text
        let carryText: String
        if carried.isEmpty {
            carryText = ""
        } else if carried.count == 1 {
            carryText = "  ·  carry from hole \(carried[0])"
        } else {
            carryText = "  ·  carry from holes \(carried.map { "\($0)" }.joined(separator: ", "))"
        }

        let statusText: String
        let statusColor: UIColor

        if !tied.isEmpty {
            statusText  = "Tied, no skin\(carryText)"
            statusColor = .secondaryLabel
        } else if let w = winner {
            let last     = playerById[w]?.playerName.components(separatedBy: " ").last ?? "?"
            let score    = scoreDisplay(playerId: w, hole: hole, net: !usingGrossSkins)
            let scoreStr = score.map { " \($0)" } ?? ""
            if prov {
                let notPosted = totalGroupCount - (groupsPostedPerHole[hole] ?? 0)
                let groupsStr = notPosted == 1 ? "1 group still to play" : "\(notPosted) groups still to play"
                let potStr    = isOrganizer && pot > 0 ? "  ·  \(fmtPot(pot)) if it holds" : ""
                statusText    = "\(last)\(scoreStr)  ·  Leading  ·  \(groupsStr)\(potStr)\(carryText)"
                statusColor   = .secondaryLabel
            } else {
                let potStr  = isOrganizer && pot > 0 ? "  ·  Won \(fmtPot(pot))" : "  ·  Won"
                statusText  = "\(last)\(scoreStr)\(potStr)\(carryText)"
                statusColor = UIColor(red: 0.10, green: 0.42, blue: 0.42, alpha: 1.0)
            }
        } else {
            statusText  = "—"
            statusColor = .secondaryLabel
        }

        cfg.secondaryText = statusText
        cfg.secondaryTextProperties.color = statusColor
        cell.contentConfiguration = cfg
        return cell
    }

    // MARK: - Debug

    private func printSkinsDebug() {
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        print("=== SKINS \(eventName) build \(build) ===")
        for r in skinsResults {
            let gName  = playerById[r.grossWinner ?? UUID()]?.playerName ?? "—"
            let nName  = playerById[r.netWinner   ?? UUID()]?.playerName ?? "—"
            let gTied  = r.grossTied.isEmpty ? "" : " (tied)"
            let nTied  = r.netTied.isEmpty   ? "" : " (tied)"
            let gProv  = r.grossIsProvisional ? " prov" : " ✓"
            let nProv  = r.netIsProvisional   ? " prov" : " ✓"
            let gStr   = r.grossWinner != nil ? "\(gName)\(gProv)" : "—\(gTied)"
            let nStr   = r.netWinner   != nil ? "\(nName)\(nProv)" : "—\(nTied)"
            print("  H\(r.holeNumber): gross \(gStr)  |  net \(nStr)")
        }
        print("=================================")
    }
}
