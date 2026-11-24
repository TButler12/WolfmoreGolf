import UIKit

/// Organizer home screen — shows event header, code, leaderboard preview,
/// roster entry point, group status, and lock-results action.
final class ClubEventOrganizerHomeViewController: UITableViewController {

    static let darkGreen = UIColor(red: 0.118, green: 0.227, blue: 0.165, alpha: 1.0)
    static let teal      = UIColor(red: 0.10,  green: 0.42,  blue: 0.42,  alpha: 1.0)

    private var event:       ClubEventRecord
    private var roster:      [ClubEventPlayer]        = []
    private var scores:      [ClubEventHoleScore]     = []
    private var teams:       [ClubEventTeam]          = []
    private var memberships: [ClubEventTeamMembership] = []

    private struct GroupInfo {
        let code: String
        let players: [ClubEventPlayer]
        let maxHole: Int       // highest hole number with any score in this group
        let allSubmitted: Bool
    }

    private struct MiniTeamEntry {
        let rank: Int
        let teamName: String
        let netToPar: Int
        let holesPlayed: Int
    }

    private struct PlayerPayout {
        let playerID: UUID
        let name: String
        var teamNet:    Double = 0
        var teamGross:  Double = 0
        var grossSkins: Double = 0
        var netSkins:   Double = 0
        var total: Double { teamNet + teamGross + grossSkins + netSkins }
    }

    private var groups:          [GroupInfo]      = []
    private var unassigned:      Int              = 0
    private var miniLeaderboard: [MiniTeamEntry]  = []
    private var rules:           ClubEventRules?
    private var skinsResults:    [FieldSkinsEngine.SkinResult] = []
    private var computedPayouts: [PlayerPayout]   = []

    private var skinsEnabled: Bool {
        (rules?.grossSkinsEnabled ?? false) || (rules?.netSkinsEnabled ?? false)
    }

    init(event: ClubEventRecord) {
        self.event = event
        super.init(style: .insetGrouped)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = event.name
        view.backgroundColor = .systemGroupedBackground
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(reload)),
            UIBarButtonItem(image: UIImage(systemName: "gearshape"),
                            style: .plain, target: self, action: #selector(settingsTapped)),
        ]

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.estimatedRowHeight = 60

        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(reload), for: .valueChanged)
        tableView.refreshControl = rc
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    // MARK: - Load

    @objc private func reload() {
        Task {
            do {
                async let rosterTask = SupabaseService.shared.fetchClubEventRoster(tournamentId: event.id)
                async let scoresTask = SupabaseService.shared.fetchClubEventAllScores(tournamentId: event.id)
                async let eventTask  = SupabaseService.shared.fetchClubEvent(code: event.code)
                async let teamsTask  = SupabaseService.shared.fetchClubEventTeams(tournamentId: event.id)
                async let rulesTask  = SupabaseService.shared.fetchClubEventRules(tournamentId: event.id)
                let (rosterR, scoresR, teamsR) = try await (rosterTask, scoresTask, teamsTask)
                let membershipsR = (try? await SupabaseService.shared.fetchClubEventTeamMemberships(
                    teamIds: teamsR.map { $0.id })) ?? []
                let eventR      = try? await eventTask
                let fetchedRules = try? await rulesTask
                await MainActor.run {
                    self.roster      = rosterR
                    self.scores      = scoresR
                    self.teams       = teamsR
                    self.memberships = membershipsR
                    self.rules       = fetchedRules
                    if let e = eventR { self.event = e }
                    self.rebuildGroups()
                    self.rebuildMiniLeaderboard()
                    self.rebuildSkins()
                    self.rebuildPayouts()
                    self.tableView.refreshControl?.endRefreshing()
                    self.tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.tableView.refreshControl?.endRefreshing()
                    print("⚠️ Organizer reload failed: \(error)")
                }
            }
        }
    }

    // MARK: - Rebuild

    private func rebuildGroups() {
        var maxHoleByPlayer: [UUID: Int] = [:]
        for s in scores where (s.grossScore ?? 0) > 0 || s.netScoreType == "picked_up" {
            maxHoleByPlayer[s.tournamentPlayerId] = max(
                maxHoleByPlayer[s.tournamentPlayerId] ?? 0, s.holeNumber)
        }
        let byGroup = Dictionary(grouping: roster) { $0.groupCode ?? "" }
        var out: [GroupInfo] = []
        for (code, players) in byGroup where !code.isEmpty {
            let sorted = players.sorted { $0.playerName < $1.playerName }
            let maxHole     = sorted.compactMap { maxHoleByPlayer[$0.id] }.max() ?? 0
            let allSubmitted = !sorted.isEmpty && sorted.allSatisfy { $0.cardSubmitted }
            out.append(GroupInfo(code: code, players: sorted, maxHole: maxHole, allSubmitted: allSubmitted))
        }
        groups     = out.sorted { $0.code < $1.code }
        unassigned = roster.filter { ($0.groupCode ?? "").isEmpty }.count
    }

    private func rebuildMiniLeaderboard() {
        let (pars, hcs) = courseParsAndHCs()
        let holeCount   = pars.count
        let playerById  = Dictionary(uniqueKeysWithValues: roster.map { ($0.id, $0) })

        var membersByTeam: [UUID: [UUID]] = [:]
        for m in memberships { membersByTeam[m.teamId, default: []].append(m.tournamentPlayerId) }

        var scoresByPlayer: [UUID: [Int: (gross: Int, pickedUp: Bool)]] = [:]
        for s in scores {
            if scoresByPlayer[s.tournamentPlayerId] == nil { scoresByPlayer[s.tournamentPlayerId] = [:] }
            scoresByPlayer[s.tournamentPlayerId]![s.holeNumber] =
                (s.grossScore ?? 0, s.netScoreType == "picked_up")
        }

        let computed: [(name: String, net: Int, holes: Int)] = teams.map { team in
            let members = (membersByTeam[team.id] ?? []).compactMap { playerById[$0] }
            var totalNet = 0, holesWithScore = 0
            for hole in 1...holeCount {
                let hcRank = hcs[hole - 1]
                var bestNet: Int?
                for player in members {
                    guard let d = scoresByPlayer[player.id]?[hole],
                          !d.pickedUp, d.gross > 0 else { continue }
                    let strokes = strokesOnHole(hc: Int(player.handicap.rounded()), hcRank: hcRank,
                                                holeCount: holeCount)
                    let net = d.gross - strokes
                    if bestNet == nil || net < bestNet! { bestNet = net }
                }
                if let net = bestNet { totalNet += net - pars[hole - 1]; holesWithScore += 1 }
            }
            return (name: teamDisplayName(members), net: totalNet, holes: holesWithScore)
        }.sorted {
            if $0.net != $1.net { return $0.net < $1.net }
            return $0.holes > $1.holes
        }

        miniLeaderboard = computed.enumerated().map { i, e in
            MiniTeamEntry(rank: i + 1, teamName: e.name, netToPar: e.net, holesPlayed: e.holes)
        }
    }

    private func rebuildSkins() {
        guard let r = rules, r.grossSkinsEnabled || r.netSkinsEnabled else { skinsResults = []; return }
        let (_, hcs) = courseParsAndHCs()
        let holeCount = hcs.count

        var scoresByPlayer: [UUID: [Int: (gross: Int, pickedUp: Bool)]] = [:]
        for s in scores {
            if scoresByPlayer[s.tournamentPlayerId] == nil { scoresByPlayer[s.tournamentPlayerId] = [:] }
            scoresByPlayer[s.tournamentPlayerId]![s.holeNumber] =
                (s.grossScore ?? 0, s.netScoreType == "picked_up")
        }

        var postedByGroup: [String: Set<Int>] = [:]
        for player in roster {
            guard let gc = player.groupCode, !gc.isEmpty else { continue }
            for (hole, data) in scoresByPlayer[player.id] ?? [:] where data.gross > 0 || data.pickedUp {
                postedByGroup[gc, default: []].insert(hole)
            }
        }

        let inputs = buildClubEventSkinInputs(
            players: roster, scoresByPlayer: scoresByPlayer,
            postedByGroup: postedByGroup, holeCount: holeCount)

        let pots = PayoutCalculator.pots(rules: r, players: roster, memberships: memberships)
        let settings = FieldSkinsEngine.Settings(
            holeHandicapRanks: hcs,
            allowance:         r.handicapAllowance,
            carryoverEnabled:  r.skinsCarryover,
            potGrossPerHole:   holeCount > 0 ? pots.grossSkins / Double(holeCount) : 0,
            potNetPerHole:     holeCount > 0 ? pots.netSkins   / Double(holeCount) : 0)

        skinsResults = inputs.isEmpty ? [] : FieldSkinsEngine.compute(players: inputs, settings: settings)
    }

    private func rebuildPayouts() {
        guard let r = rules else { computedPayouts = []; return }
        let pots = PayoutCalculator.pots(rules: r, players: roster, memberships: memberships)
        guard pots.teamNet > 0 || pots.teamGross > 0 || pots.grossSkins > 0 || pots.netSkins > 0 else {
            computedPayouts = []; return
        }

        let (pars, hcs) = courseParsAndHCs()
        let holeCount = pars.count
        let playerById = Dictionary(uniqueKeysWithValues: roster.map { ($0.id, $0) })

        var membersByTeam: [UUID: [UUID]] = [:]
        for m in memberships { membersByTeam[m.teamId, default: []].append(m.tournamentPlayerId) }

        var scoresByPlayer: [UUID: [Int: (gross: Int, pickedUp: Bool)]] = [:]
        for s in scores {
            if scoresByPlayer[s.tournamentPlayerId] == nil { scoresByPlayer[s.tournamentPlayerId] = [:] }
            scoresByPlayer[s.tournamentPlayerId]![s.holeNumber] = (s.grossScore ?? 0, s.netScoreType == "picked_up")
        }

        func strokes(hc18: Int, hcRank: Int) -> Int {
            var hc = max(0, hc18)
            if holeCount == 9 { hc = Int((Double(hc) / 2.0).rounded()) }
            return hc / holeCount + (hcRank <= hc % holeCount ? 1 : 0)
        }

        struct TeamScore { let teamId: UUID; let memberIds: [UUID]; let netToPar: Int; let holesPlayed: Int }

        let teamScores: [TeamScore] = teams.compactMap { team in
            let ids = membersByTeam[team.id] ?? []
            guard !ids.isEmpty else { return nil }
            var totalNet = 0, holes = 0
            for hole in 1...holeCount {
                let hcRank = hcs[hole - 1]
                var best: Int?
                for pid in ids {
                    guard let p = playerById[pid],
                          let d = scoresByPlayer[pid]?[hole],
                          !d.pickedUp, d.gross > 0 else { continue }
                    let net = d.gross - strokes(hc18: Int(p.handicap.rounded()), hcRank: hcRank)
                    if best == nil || net < best! { best = net }
                }
                if let n = best { totalNet += n - pars[hole - 1]; holes += 1 }
            }
            return TeamScore(teamId: team.id, memberIds: ids, netToPar: totalNet, holesPlayed: holes)
        }

        // Rank started teams (net), apply place_pcts with tie splitting
        let started = teamScores.filter { $0.holesPlayed > 0 }
            .sorted { $0.netToPar != $1.netToPar ? $0.netToPar < $1.netToPar : $0.holesPlayed > $1.holesPlayed }
        let placesPaid = r.teamPlacesPaid
        let pcts = r.placePcts
        var teamNetPayouts: [UUID: Double] = [:]
        var i = 0
        while i < started.count {
            let baseRank = i + 1
            guard baseRank <= placesPaid else { break }
            var j = i + 1
            while j < started.count && started[j].netToPar == started[i].netToPar { j += 1 }
            let groupSize = j - i
            var combinedPct = 0.0
            for place in baseRank...(baseRank + groupSize - 1) {
                if place <= placesPaid, place - 1 < pcts.count { combinedPct += pcts[place - 1] }
            }
            let each = pots.teamNet * (combinedPct / Double(groupSize)) / 100.0
            for k in i..<j { if each > 0 { teamNetPayouts[started[k].teamId] = each } }
            i = j
        }

        var byPlayer: [UUID: PlayerPayout] = [:]
        func ensure(_ id: UUID) {
            guard byPlayer[id] == nil else { return }
            byPlayer[id] = PlayerPayout(playerID: id, name: playerById[id]?.playerName ?? "Unknown")
        }

        for ts in teamScores {
            guard let payout = teamNetPayouts[ts.teamId], !ts.memberIds.isEmpty else { continue }
            let share = payout / Double(ts.memberIds.count)
            for pid in ts.memberIds {
                ensure(pid)
                var p = byPlayer[pid]!; p.teamNet += share; byPlayer[pid] = p
            }
        }

        // Skins payouts
        var grossCounts: [UUID: Int] = [:]
        var netCounts:   [UUID: Int] = [:]
        for result in skinsResults {
            if let w = result.grossWinner, !result.grossIsProvisional { grossCounts[w, default: 0] += 1 }
            if let w = result.netWinner,   !result.netIsProvisional   { netCounts[w,   default: 0] += 1 }
        }
        let grossWon  = grossCounts.values.reduce(0, +)
        let netWon    = netCounts.values.reduce(0, +)
        let perGross  = grossWon > 0 ? pots.grossSkins / Double(grossWon) : 0
        let perNet    = netWon   > 0 ? pots.netSkins   / Double(netWon)   : 0
        for (pid, count) in grossCounts {
            ensure(pid)
            var p = byPlayer[pid]!; p.grossSkins += perGross * Double(count); byPlayer[pid] = p
        }
        for (pid, count) in netCounts {
            ensure(pid)
            var p = byPlayer[pid]!; p.netSkins += perNet * Double(count); byPlayer[pid] = p
        }

        computedPayouts = byPlayer.values.filter { $0.total > 0 }.sorted { $0.total > $1.total }
    }

    // MARK: - Helpers

    private func strokesOnHole(hc: Int, hcRank: Int, holeCount: Int = 18) -> Int {
        var effHC = max(0, hc)
        if holeCount == 9 { effHC = Int((Double(effHC) / 2.0).rounded()) }
        return effHC / holeCount + (hcRank <= effHC % holeCount ? 1 : 0)
    }

    private func lastName(of name: String) -> String {
        name.components(separatedBy: " ").last ?? name
    }

    private func teamDisplayName(_ players: [ClubEventPlayer]) -> String {
        guard !players.isEmpty else { return "—" }
        return players.map { lastName(of: $0.playerName) }.sorted().joined(separator: " / ")
    }

    private func courseParsAndHCs() -> ([Int], [Int]) {
        if let name = event.courseName,
           let course = CourseLibrary.shared.courses.first(where: {
               $0.name.caseInsensitiveCompare(name) == .orderedSame
           }),
           !course.pars.isEmpty, course.pars.count == course.hcs.count {
            return (course.pars, course.hcs)
        }
        return (Array(repeating: 4, count: 18), Array(1...18))
    }

    // MARK: - Sections

    private enum Section: CaseIterable {
        case header, code, leaderboard, payouts, roster, groups, results
    }

    private var visibleSections: [Section] {
        var out: [Section] = [.header, .code, .leaderboard]
        if !computedPayouts.isEmpty { out.append(.payouts) }
        out.append(contentsOf: [.roster, .groups, .results])
        return out
    }

    override func numberOfSections(in tableView: UITableView) -> Int { visibleSections.count }

    override func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < visibleSections.count else { return 0 }
        switch visibleSections[section] {
        case .header:  return 1
        case .code:    return 1
        case .leaderboard:
            if miniLeaderboard.isEmpty { return 1 }
            var n = min(5, miniLeaderboard.count) + 1  // entries + Full Leaderboard button
            if skinsEnabled { n += 1 }
            return n
        case .payouts: return computedPayouts.count
        case .roster:  return 1
        case .groups:
            return groups.isEmpty ? 1 : groups.count + (unassigned > 0 ? 1 : 0)
        case .results:
            // Change Log + submission status (when active) + Lock / Results Locked
            var n = 1 // Change Log always present
            n += (!groups.isEmpty && event.status != "finished") ? 2 : 1
            return n
        }
    }

    override func tableView(_ tv: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section < visibleSections.count else { return nil }
        switch visibleSections[section] {
        case .header:      return nil
        case .code:        return "EVENT CODE"
        case .leaderboard: return "LEADERBOARD"
        case .payouts:     return "PAYOUTS"
        case .roster:      return "ROSTER"
        case .groups:      return "GROUPS"
        case .results:     return "RESULTS"
        }
    }

    override func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section < visibleSections.count else { return UITableViewCell() }
        switch visibleSections[indexPath.section] {
        case .header:      return headerCell()
        case .code:        return codeCell()
        case .leaderboard: return leaderboardCell(row: indexPath.row)
        case .payouts:     return payoutsCell(row: indexPath.row)
        case .roster:      return rosterCell()
        case .groups:      return groupsCell(row: indexPath.row)
        case .results:     return resultsCell(row: indexPath.row)
        }
    }

    override func tableView(_ tv: UITableView, didSelectRowAt indexPath: IndexPath) {
        tv.deselectRow(at: indexPath, animated: true)
        guard indexPath.section < visibleSections.count else { return }
        switch visibleSections[indexPath.section] {
        case .leaderboard:
            let buttonRow = miniLeaderboard.isEmpty ? -1 : min(5, miniLeaderboard.count)
            let skinsRow  = (!miniLeaderboard.isEmpty && skinsEnabled) ? buttonRow + 1 : -1
            if indexPath.row == buttonRow { fullLeaderboardTapped() }
            else if indexPath.row == skinsRow { openLeaderboardOnSkinsTab() }
        case .roster:
            navigationController?.pushViewController(
                ClubEventRosterViewController(event: event), animated: true)
        case .groups:
            guard !groups.isEmpty, indexPath.row < groups.count else { return }
            let g = groups[indexPath.row]
            let summary = ClubEventGroupManageViewController.GroupSummary(
                code: g.code, players: g.players)
            navigationController?.pushViewController(
                ClubEventGroupManageViewController(event: event, group: summary, fullRoster: roster),
                animated: true)
        case .results:
            // Row 0: Change Log; row 1 (active+groups): submission count; row 1 or 2: Lock
            if indexPath.row == 0 {
                navigationController?.pushViewController(
                    ClubEventChangeLogViewController(tournamentId: event.id), animated: true)
            } else if !groups.isEmpty && event.status != "finished" && indexPath.row == 2 {
                confirmLockResults()
            }
        default: break
        }
    }

    // MARK: - Header cell

    private func headerCell() -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.contentConfiguration = nil
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.selectionStyle = .none
        cell.accessoryType  = .none

        let nameLabel = UILabel()
        nameLabel.text = event.name
        nameLabel.font = .preferredFont(forTextStyle: .title2)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.numberOfLines = 0
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let detailLabel = UILabel()
        var details: [String] = []
        if let c = event.courseName, !c.isEmpty {
            let (pars, _) = courseParsAndHCs()
            let suffix = pars.count == 9 ? " · 9 holes" : ""
            details.append(c + suffix)
        }
        detailLabel.text = details.joined(separator: " · ")
        detailLabel.font = .preferredFont(forTextStyle: .subheadline)
        detailLabel.adjustsFontForContentSizeCategory = true
        detailLabel.textColor = .secondaryLabel
        detailLabel.numberOfLines = 0
        detailLabel.translatesAutoresizingMaskIntoConstraints = false

        cell.contentView.addSubview(nameLabel)
        cell.contentView.addSubview(detailLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            detailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            detailLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            detailLabel.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            detailLabel.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -12),
        ])
        return cell
    }

    // MARK: - Code cell

    private func codeCell() -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.contentConfiguration = nil
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.selectionStyle = .none
        cell.accessoryType  = .none

        let codeLabel = UILabel()
        codeLabel.text = event.code
        codeLabel.font = .monospacedSystemFont(ofSize: 36, weight: .bold)
        codeLabel.textColor = Self.darkGreen
        codeLabel.textAlignment = .center
        codeLabel.translatesAutoresizingMaskIntoConstraints = false

        var shareCfg = UIButton.Configuration.plain()
        shareCfg.title = "Share…"
        shareCfg.image = UIImage(systemName: "square.and.arrow.up")
        shareCfg.imagePadding = 6
        shareCfg.baseForegroundColor = Self.teal
        let shareBtn = UIButton(configuration: shareCfg)
        shareBtn.addTarget(self, action: #selector(shareCode), for: .touchUpInside)
        shareBtn.translatesAutoresizingMaskIntoConstraints = false

        var qrCfg = UIButton.Configuration.plain()
        qrCfg.title = "QR Code"
        qrCfg.image = UIImage(systemName: "qrcode")
        qrCfg.imagePadding = 6
        qrCfg.baseForegroundColor = Self.teal
        let qrBtn = UIButton(configuration: qrCfg)
        qrBtn.addTarget(self, action: #selector(showQRCode), for: .touchUpInside)
        qrBtn.translatesAutoresizingMaskIntoConstraints = false

        let btnStack = UIStackView(arrangedSubviews: [shareBtn, qrBtn])
        btnStack.axis = .horizontal
        btnStack.distribution = .fillEqually
        btnStack.translatesAutoresizingMaskIntoConstraints = false

        cell.contentView.addSubview(codeLabel)
        cell.contentView.addSubview(btnStack)
        NSLayoutConstraint.activate([
            codeLabel.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
            codeLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            codeLabel.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            btnStack.topAnchor.constraint(equalTo: codeLabel.bottomAnchor, constant: 4),
            btnStack.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            btnStack.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            btnStack.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),
        ])
        return cell
    }

    @objc private func shareCode() {
        let link = ShareLinks.joinClubEvent(code: event.code)
        let text = ShareLinks.clubEventShareText(eventName: event.name,
                                                  courseName: event.courseName,
                                                  code: event.code)
        let ac = UIActivityViewController(activityItems: [text, link], applicationActivities: nil)
        ac.popoverPresentationController?.sourceView = view
        present(ac, animated: true)
    }

    @objc private func showQRCode() {
        let vc = ClubEventQRViewController(code: event.code)
        present(vc, animated: true)
    }

    // MARK: - Leaderboard cell

    private func leaderboardCell(row: Int) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.contentConfiguration = nil
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        if miniLeaderboard.isEmpty {
            var cfg = cell.defaultContentConfiguration()
            cfg.text = "No scores yet"
            cfg.textProperties.color = .secondaryLabel
            cell.contentConfiguration = cfg
            cell.selectionStyle = .none
            cell.accessoryType  = .none
            return cell
        }

        let buttonRow = min(5, miniLeaderboard.count)
        let skinsRow  = skinsEnabled ? buttonRow + 1 : -1

        if row == buttonRow {
            var cfg = cell.defaultContentConfiguration()
            cfg.text = "Full Leaderboard"
            cfg.image = UIImage(systemName: "list.number")
            cfg.imageProperties.tintColor = Self.teal
            cell.contentConfiguration = cfg
            cell.accessoryType  = .disclosureIndicator
            cell.selectionStyle = .default
            return cell
        }

        if row == skinsRow {
            var cfg = cell.defaultContentConfiguration()
            cfg.image = UIImage(systemName: "diamond.fill")
            cfg.imageProperties.tintColor = Self.teal
            cfg.text = "Skins"
            let grossWon = skinsResults.filter { $0.grossWinner != nil && !$0.grossIsProvisional }.count
            let netWon   = skinsResults.filter { $0.netWinner   != nil && !$0.netIsProvisional   }.count
            var parts: [String] = []
            if rules?.grossSkinsEnabled == true { parts.append("Gross: \(grossWon) won") }
            if rules?.netSkinsEnabled   == true { parts.append("Net: \(netWon) won") }
            cfg.secondaryText = parts.joined(separator: "  ·  ")
            cfg.secondaryTextProperties.color = Self.teal
            cell.contentConfiguration = cfg
            cell.accessoryType  = .disclosureIndicator
            cell.selectionStyle = .default
            return cell
        }

        let entry = miniLeaderboard[row]
        var cfg = cell.defaultContentConfiguration()
        let net  = entry.netToPar == 0 ? "E"
                 : entry.netToPar  > 0 ? "+\(entry.netToPar)"
                 :                       "\(entry.netToPar)"
        let thru = entry.holesPlayed > 0 ? "thru \(entry.holesPlayed)" : "—"
        cfg.text          = "\(entry.rank). \(entry.teamName)"
        cfg.secondaryText = "\(net)  ·  \(thru)"
        cfg.secondaryTextProperties.color = entry.netToPar < 0 ? .systemRed
                                          : entry.netToPar > 0 ? .secondaryLabel
                                          : .label
        cell.contentConfiguration = cfg
        cell.selectionStyle = .none
        cell.accessoryType  = .none
        return cell
    }

    private func fmtPot(_ v: Double) -> String {
        guard v > 0 else { return "" }
        return v == Double(Int(v)) ? "$\(Int(v))" : String(format: "$%.2f", v)
    }

    private func payoutsCell(row: Int) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.contentConfiguration = nil
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.selectionStyle = .none
        cell.accessoryType  = .none
        guard row < computedPayouts.count else { return cell }
        let p = computedPayouts[row]
        var cfg = cell.defaultContentConfiguration()
        cfg.text = p.name
        cfg.textProperties.font = UIFontMetrics(forTextStyle: .body)
            .scaledFont(for: .systemFont(ofSize: 16, weight: .regular))
        var parts: [String] = []
        if p.teamNet    > 0 { parts.append("Net \(fmtPot(p.teamNet))") }
        if p.teamGross  > 0 { parts.append("Gross \(fmtPot(p.teamGross))") }
        if p.grossSkins > 0 { parts.append("Gross Skins \(fmtPot(p.grossSkins))") }
        if p.netSkins   > 0 { parts.append("Net Skins \(fmtPot(p.netSkins))") }
        cfg.secondaryText = parts.joined(separator: "  ·  ")
        cfg.secondaryTextProperties.color = Self.teal

        // Right-aligned total
        let totalLabel = UILabel()
        totalLabel.text = fmtPot(p.total)
        totalLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 16, weight: .semibold))
        totalLabel.textColor = Self.darkGreen
        totalLabel.setContentHuggingPriority(.required, for: .horizontal)
        totalLabel.translatesAutoresizingMaskIntoConstraints = false

        cell.contentConfiguration = cfg
        cell.contentView.addSubview(totalLabel)
        NSLayoutConstraint.activate([
            totalLabel.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            totalLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
        ])
        return cell
    }

    private func fullLeaderboardTapped() {
        let (pars, hcs) = courseParsAndHCs()
        let vc = ClubEventLeaderboardViewController(
            tournamentId: event.id,
            eventName:    event.name,
            coursePars:   pars,
            courseHCs:    hcs,
            myGroupCode:  "",
            isOrganizer:  true,
            eventStatus:  event.status
        )
        navigationController?.pushViewController(vc, animated: true)
    }

    private func openLeaderboardOnSkinsTab() {
        let (pars, hcs) = courseParsAndHCs()
        let vc = ClubEventLeaderboardViewController(
            tournamentId: event.id,
            eventName:    event.name,
            coursePars:   pars,
            courseHCs:    hcs,
            myGroupCode:  "",
            initialTab:   .skins,
            isOrganizer:  true,
            eventStatus:  event.status
        )
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Roster cell

    private func rosterCell() -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.contentConfiguration = nil
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        var cfg = cell.defaultContentConfiguration()
        let n = roster.count
        cfg.text = n == 0 ? "Roster" : "Roster · \(n) \(n == 1 ? "player" : "players")"
        if unassigned > 0 {
            cfg.secondaryText = "\(unassigned) unassigned"
            cfg.secondaryTextProperties.color = .systemOrange
        }
        cfg.image = UIImage(systemName: "person.2.fill")
        cfg.imageProperties.tintColor = Self.teal
        cell.contentConfiguration = cfg
        cell.accessoryType  = .disclosureIndicator
        cell.selectionStyle = .default
        return cell
    }

    // MARK: - Groups cell

    private func groupsCell(row: Int) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.contentConfiguration = nil
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        if groups.isEmpty {
            var cfg = cell.defaultContentConfiguration()
            cfg.text = "No groups yet"
            cfg.secondaryText = "Groups appear here when scorers set up."
            cfg.textProperties.color = .secondaryLabel
            cell.contentConfiguration = cfg
            cell.accessoryType  = .none
            cell.selectionStyle = .none
            return cell
        }

        if row < groups.count {
            let g = groups[row]
            cell.accessoryType  = (event.status == "finished") ? .none : .disclosureIndicator
            cell.selectionStyle = (event.status == "finished") ? .none : .default

            let playersLabel = UILabel()
            playersLabel.text = g.players.map { $0.playerName }.joined(separator: "  ·  ")
            playersLabel.font = .preferredFont(forTextStyle: .subheadline)
            playersLabel.adjustsFontForContentSizeCategory = true
            playersLabel.numberOfLines = 0
            playersLabel.translatesAutoresizingMaskIntoConstraints = false

            let codeLabel = UILabel()
            codeLabel.text = "Group \(g.code)"
            codeLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
            codeLabel.textColor = .secondaryLabel
            codeLabel.translatesAutoresizingMaskIntoConstraints = false

            let statusLabel = UILabel()
            if g.allSubmitted {
                statusLabel.text      = "✓ Submitted"
                statusLabel.textColor = .systemGreen
            } else if g.maxHole == 0 {
                statusLabel.text      = "Not started"
                statusLabel.textColor = .secondaryLabel
            } else {
                statusLabel.text      = "Thru \(g.maxHole)"
                statusLabel.textColor = .label
            }
            statusLabel.font = .preferredFont(forTextStyle: .caption1)
            statusLabel.adjustsFontForContentSizeCategory = true
            statusLabel.translatesAutoresizingMaskIntoConstraints = false
            statusLabel.setContentHuggingPriority(.required, for: .horizontal)
            statusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

            cell.contentView.addSubview(playersLabel)
            cell.contentView.addSubview(codeLabel)
            cell.contentView.addSubview(statusLabel)
            NSLayoutConstraint.activate([
                statusLabel.centerYAnchor.constraint(equalTo: playersLabel.centerYAnchor),
                statusLabel.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),

                playersLabel.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 10),
                playersLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                playersLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusLabel.leadingAnchor, constant: -8),

                codeLabel.topAnchor.constraint(equalTo: playersLabel.bottomAnchor, constant: 3),
                codeLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                codeLabel.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                codeLabel.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -10),
            ])
            return cell
        }

        // Unassigned row
        var cfg = cell.defaultContentConfiguration()
        cfg.text = "\(unassigned) unassigned player\(unassigned == 1 ? "" : "s")"
        cfg.textProperties.color = .systemOrange
        cell.contentConfiguration = cfg
        return cell
    }

    // MARK: - Results cell

    private func resultsCell(row: Int) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.contentConfiguration = nil
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        // Row 0: Change Log (always present)
        if row == 0 {
            var cfg = cell.defaultContentConfiguration()
            cfg.text  = "Change Log"
            cfg.image = UIImage(systemName: "clock.arrow.circlepath")
            cfg.imageProperties.tintColor = Self.teal
            cell.contentConfiguration = cfg
            cell.accessoryType  = .disclosureIndicator
            cell.selectionStyle = .default
            return cell
        }

        // Row 1 when groups exist and event is active: submission count
        if row == 1 && !groups.isEmpty && event.status != "finished" {
            let submitted = groups.filter { $0.allSubmitted }.count
            let total     = groups.count
            var cfg = cell.defaultContentConfiguration()
            cfg.text = "\(submitted) of \(total) group\(total == 1 ? "" : "s") submitted"
            cfg.textProperties.color = submitted == total ? .systemGreen : .secondaryLabel
            cell.contentConfiguration = cfg
            cell.selectionStyle = .none
            cell.accessoryType  = .none
            return cell
        }

        // Lock Results / Results Locked row
        var cfg = cell.defaultContentConfiguration()
        if event.status == "finished" {
            cfg.text = "Results Locked"
            cfg.secondaryText = "Event is finished."
            cfg.image = UIImage(systemName: "lock.fill")
            cfg.imageProperties.tintColor = .systemGreen
            cell.selectionStyle = .none
            cell.accessoryType  = .none
        } else if groups.isEmpty {
            cfg.text = "Lock Results"
            cfg.secondaryText = "Available after groups are set up"
            cfg.textProperties.color = .tertiaryLabel
            cfg.image = UIImage(systemName: "lock")
            cfg.imageProperties.tintColor = .tertiaryLabel
            cell.selectionStyle = .none
            cell.accessoryType  = .none
        } else {
            cfg.text = "Lock Results"
            cfg.image = UIImage(systemName: "lock")
            cfg.imageProperties.tintColor = Self.darkGreen
            cell.selectionStyle = .default
            cell.accessoryType  = .disclosureIndicator
        }
        cell.contentConfiguration = cfg
        return cell
    }

    private func confirmLockResults() {
        let submitted = groups.filter { $0.allSubmitted }.count
        let unsub     = groups.count - submitted
        let message = unsub == 0
            ? "Scorers will no longer be able to edit scores for this event."
            : "\(unsub) group\(unsub == 1 ? " hasn't" : "s haven't") submitted yet. Lock anyway?"
        let ac = UIAlertController(title: "Lock Results?", message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Lock", style: .destructive) { [weak self] _ in
            self?.lockResults()
        })
        present(ac, animated: true)
    }

    private func lockResults() {
        let spinner = UIAlertController(title: nil, message: "Locking…", preferredStyle: .alert)
        present(spinner, animated: true)
        Task {
            do {
                try await SupabaseService.shared.lockClubEvent(tournamentId: event.id)
                await MainActor.run {
                    spinner.dismiss(animated: false) { self.reload() }
                }
            } catch {
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        let ac = UIAlertController(title: "Could Not Lock",
                                                   message: error.localizedDescription,
                                                   preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ac, animated: true)
                    }
                }
            }
        }
    }

    @objc private func settingsTapped() {
        let activeIds = Set(roster.filter { $0.groupCode != nil && !$0.isWithdrawn }.map(\.id))
        let activeCount = activeIds.count
        let teamEnrollmentCount = memberships.filter { activeIds.contains($0.tournamentPlayerId) }.count
        let vc = ClubEventSettingsViewController(
            event: event, rules: rules,
            activePlayerCount: activeCount,
            teamEnrollmentCount: teamEnrollmentCount)
        vc.onSaved = { [weak self] in self?.reload() }
        navigationController?.pushViewController(vc, animated: true)
    }
}
