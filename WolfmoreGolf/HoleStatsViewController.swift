
//  HoleStatsViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 11/18/25.
//

import UIKit

final class HoleStatsViewController: UITableViewController {

    // MARK: - Properties

    /// 0-based index (0 = Hole 1)
    var holeIndex: Int = 0

    private struct Row {
        let name: String
        let avgMoney: Double
        let proxPct: Double
        let rounds: Int
    }

    struct HoleOverview {
        let avgMoney: Double
        let proxPct: Double
        let avgScore: Double
        let avgVsPar: Double

        let wolfWinPct: Double
        let nonWolfWinPct: Double
        let tieWinPct: Double

        let moneyRank: Int
        let proxRank: Int
        let scoreRank: Int
        let wolfRank: Int
        let nonWolfRank: Int
        let tieRank: Int

        let maxWin: Double
        let maxWinRank: Int

        let rounds: Int          // approximate # of games on this hole
        let holeCount: Int
    }

    private var rows: [Row] = []
    private var overview: HoleOverview?

    /// Same “home / tracking course” logic as elsewhere
    private var trackingCourseID: String {
        let stored = ProfileStore.homeCourseID
        if !stored.isEmpty { return stored }

        if let b = CourseLibrary.shared.biltmore() {
            return b.id.uuidString
        }

        return "HOME-COURSE"
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Hole \(holeIndex + 1) Stats"

        view.backgroundColor = .systemBackground
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = .none

        // Let cells size themselves (overview row will grow for all the text)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
   // give each row some breathing room

        buildRows()
        updateEmptyBackgroundIfNeeded()
    }

    var trackToggled: ((Bool) -> Void)?

    // MARK: - Build Data

    private func buildRows() {
        let courseID = trackingCourseID

        // Only friends tracked for the tracking course
        let trackedFriends = FriendStore.shared.friends.filter {
            FriendTrackStore.shared.isTracked($0.id, on: courseID)
        }

        // Build course-wide “Hole vs All Holes” overview
        buildOverview(for: trackedFriends, courseID: courseID)

        var built: [Row] = []

        // Per-friend stats for THIS hole
        for friend in trackedFriends {
            let rds = RoundStore.shared.rounds.filter { r in
                r.courseID == courseID &&
                r.playerName.caseInsensitiveCompare(friend.name) == .orderedSame &&
                r.moneyPerHole.indices.contains(holeIndex) &&
                r.proxPerHole.indices.contains(holeIndex)
            }

            guard !rds.isEmpty else { continue }

            let totalRounds = rds.count

            let totalMoney = rds.reduce(0) { acc, round in
                acc + round.moneyPerHole[holeIndex]
            }
            let avgMoney = Double(totalMoney) / Double(totalRounds)

            let proxWins = rds.filter { $0.proxPerHole[holeIndex] }.count
            let proxPct = totalRounds > 0
                ? Double(proxWins) / Double(totalRounds) * 100.0
                : 0.0

            built.append(Row(
                name: friend.name,
                avgMoney: avgMoney,
                proxPct: proxPct,
                rounds: totalRounds
            ))
        }

        rows = built.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }

        tableView.reloadData()
    }

    // MARK: - Overview Builder (Wolf / Non-Wolf / Tie / Max Win)
    /// Returns "games" (each game = array of RoundSummary rows) for a course.
    /// Prefers real gameID grouping, but falls back if your stored gameIDs are wrong (all singletons).
    private func gamesForCourse(_ courseID: String) -> [[RoundSummary]] {
        let rows = RoundStore.shared.rounds.filter { $0.courseID == courseID }
        guard !rows.isEmpty else { return [] }

        let byGameID = Dictionary(grouping: rows, by: \.gameID)

        // Use gameID if it actually groups multiple player-rows together
        if byGameID.values.contains(where: { $0.count > 1 }) {
            return byGameID.values.map { Array($0) }
        }

        // Back-compat fallback for bad historical data (unique gameID per player-row).
        // 30-second bucket is enough to group the 5 player rows from a single save,
        // but won't usually merge two different rounds.
        let byBucket = Dictionary(grouping: rows) { r -> String in
            let bucket = Int(r.date.timeIntervalSince1970 / 30.0) // 30-second bucket
            return "\(r.courseID)|\(bucket)"
        }

        return byBucket.values.map { Array($0) }
    }

    private func buildOverview(for trackedFriends: [Friend], courseID: String) {

        let allRows = RoundStore.shared.rounds.filter { $0.courseID == courseID }
        guard !allRows.isEmpty else { overview = nil; return }

        // determine holeCount robustly (not just moneyPerHole)
        let holeCount = allRows.map {
            max($0.moneyPerHole.count, $0.proxPerHole.count, $0.scorePerHole.count, $0.wolfTeamWonPerHole.count)
        }.max() ?? 0
        guard holeCount > 0 else { overview = nil; return }

        // pars
        var pars = Array(repeating: 4, count: holeCount)
        if let uuid = UUID(uuidString: courseID),
           let course = CourseLibrary.shared.get(id: uuid) {
            let coursePars = Array(course.pars.prefix(holeCount))
            if !coursePars.isEmpty { pars = coursePars }
        }

        // ✅ games (with fallback)
        let games = gamesForCourse(courseID)
        guard !games.isEmpty else { overview = nil; return }

        // helpers
        func moneyAt(_ r: RoundSummary, _ h: Int) -> Int {
            (h < r.moneyPerHole.count) ? r.moneyPerHole[h] : 0
        }
        func scoreAt(_ r: RoundSummary, _ h: Int) -> Int? {
            guard h < r.scorePerHole.count else { return nil }
            return r.scorePerHole[h]
        }
        func holeIsPlayed(in group: [RoundSummary], hole h: Int) -> Bool {
            group.contains { r in
                if scoreAt(r, h) != nil { return true }
                if h < r.moneyPerHole.count { return true }
                if h < r.proxPerHole.count { return true }
                return h < max(r.holesPlayed, 0)
            }
        }

        // aggregates per hole (GAME-based)
        var gamesPlayed      = Array(repeating: 0,   count: holeCount)
        var proxGames        = Array(repeating: 0,   count: holeCount)

        var winnerMoneySum   = Array(repeating: 0.0, count: holeCount)
        var winnerMoneyCount = Array(repeating: 0,   count: holeCount) // games where winner > 0
        var maxWinPerHole    = Array(repeating: 0.0, count: holeCount)

        var scoreSum         = Array(repeating: 0,   count: holeCount)
        var scoreCount       = Array(repeating: 0,   count: holeCount)

        var wolfWins         = Array(repeating: 0,   count: holeCount)
        var nonWolfWins      = Array(repeating: 0,   count: holeCount)
        var ties             = Array(repeating: 0,   count: holeCount)

        // compute per hole using playedGames like CourseSummary
        for h in 0..<holeCount {
            let playedGames = games.filter { holeIsPlayed(in: $0, hole: h) }
            gamesPlayed[h] = playedGames.count
            guard gamesPlayed[h] > 0 else { continue }

            // prox: ANY player in game has prox true
            proxGames[h] = playedGames.filter { group in
                group.contains { r in h < r.proxPerHole.count && r.proxPerHole[h] }
            }.count

            // money: winner per game = max money in game on that hole
            for group in playedGames {
                let winAmt = group.map { Double(moneyAt($0, h)) }.max() ?? 0.0
                if winAmt > 0 {
                    winnerMoneySum[h] += winAmt
                    winnerMoneyCount[h] += 1
                    if winAmt > maxWinPerHole[h] { maxWinPerHole[h] = winAmt }
                }

                // scores: all recorded scores
                for r in group {
                    if let s = scoreAt(r, h) {
                        scoreSum[h] += s
                        scoreCount[h] += 1
                    }
                }

                // wolf/non-wolf/tie from game winner row
                if let winnerRow = group.max(by: { moneyAt($0, h) < moneyAt($1, h) }) {
                    let m = moneyAt(winnerRow, h)
                    if m <= 0 {
                        ties[h] += 1
                    } else if h < winnerRow.wolfTeamWonPerHole.count, winnerRow.wolfTeamWonPerHole[h] {
                        wolfWins[h] += 1
                    } else {
                        nonWolfWins[h] += 1
                    }
                }
            }
        }

        func safeDiv(_ a: Double, _ b: Double) -> Double { b == 0 ? 0 : (a / b) }

        let avgMoneyPerHole: [Double] = (0..<holeCount).map { i in
            safeDiv(winnerMoneySum[i], Double(winnerMoneyCount[i]))
        }

        let avgScorePerHole: [Double] = (0..<holeCount).map { i in
            safeDiv(Double(scoreSum[i]), Double(scoreCount[i]))
        }

        let avgVsParPerHole: [Double] = (0..<holeCount).map { i in
            avgScorePerHole[i] - Double(pars[i])
        }

        let proxPctPerHole: [Double] = (0..<holeCount).map { i in
            safeDiv(Double(proxGames[i]) * 100.0, Double(gamesPlayed[i]))
        }

        let wolfWinPctPerHole: [Double] = (0..<holeCount).map { i in
            safeDiv(Double(wolfWins[i]) * 100.0, Double(gamesPlayed[i]))
        }

        let nonWolfWinPctPerHole: [Double] = (0..<holeCount).map { i in
            safeDiv(Double(nonWolfWins[i]) * 100.0, Double(gamesPlayed[i]))
        }

        let tieWinPctPerHole: [Double] = (0..<holeCount).map { i in
            safeDiv(Double(ties[i]) * 100.0, Double(gamesPlayed[i]))
        }

        func rank(of index: Int, using values: [Double], descending: Bool = true) -> Int {
            let valid = values.enumerated().filter { $0.element > 0 }
            guard !valid.isEmpty else { return 0 }
            let sorted = valid.sorted { a, b in descending ? a.element > b.element : a.element < b.element }
            return (sorted.firstIndex { $0.offset == index } ?? 0) + 1
        }

        let h = holeIndex
        guard h < holeCount else { overview = nil; return }

        overview = HoleOverview(
            avgMoney:      avgMoneyPerHole[h],
            proxPct:       proxPctPerHole[h],
            avgScore:      avgScorePerHole[h],
            avgVsPar:      avgVsParPerHole[h],

            wolfWinPct:    wolfWinPctPerHole[h],
            nonWolfWinPct: nonWolfWinPctPerHole[h],
            tieWinPct:     tieWinPctPerHole[h],

            moneyRank:     rank(of: h, using: avgMoneyPerHole,      descending: true),
            proxRank:      rank(of: h, using: proxPctPerHole,       descending: true),
            scoreRank:     rank(of: h, using: avgVsParPerHole,      descending: false),
            wolfRank:      rank(of: h, using: wolfWinPctPerHole,    descending: true),
            nonWolfRank:   rank(of: h, using: nonWolfWinPctPerHole, descending: true),
            tieRank:       rank(of: h, using: tieWinPctPerHole,     descending: true),

            maxWin:        maxWinPerHole[h],
            maxWinRank:    rank(of: h, using: maxWinPerHole,        descending: true),

            rounds:        gamesPlayed[h],     // ✅ matches CourseSummary now
            holeCount:     holeCount
        )
    }


    // MARK: - Empty Background

    private func updateEmptyBackgroundIfNeeded() {
        if rows.isEmpty && overview == nil {
            let label = UILabel()
            label.textAlignment = .center
            label.numberOfLines = 0
            label.textColor = .secondaryLabel
            label.text =
            """
            No hole stats for your home course yet.

            • Make sure a Home / Tracking Course is set in Course Setup.
            • Use Track Friends to choose who to track.
            • Play and save rounds on that course to build stats.
            """
            tableView.backgroundView = label
        } else {
            tableView.backgroundView = nil
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        overview == nil ? 1 : 2
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        if overview != nil && section == 0 {
            return 1    // overview row
        }
        return rows.count
    }

    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
        if overview != nil && section == 0 {
            return "Hole vs All Holes"
        }
        return rows.isEmpty ? nil : "By Player"
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "HoleStatsCell",
                                                 for: indexPath)
        cell.backgroundColor = .clear   // so grouped bg shows around the "cards"

        // Section 0 = course-wide overview
        if let o = overview, indexPath.section == 0 {
            cell.textLabel?.text = "Hole \(holeIndex + 1) vs \(o.holeCount) holes"
            cell.detailTextLabel?.numberOfLines = 0

            let delta = o.avgVsPar
            let sign  = delta >= 0 ? "+" : "−"

            cell.detailTextLabel?.text = String(
                format:
                """
                Avg winner $%.1f (rank %d)
                Biggest win $%.0f (rank %d)
                Prox %.0f%% (rank %d)
                Avg score %.1f (%@%.1f vs par, rank %d)
                Wolf win %.0f%% (rank %d)
                Non-Wolf win %.0f%% (rank %d)
                Tie %.0f%% (rank %d)
                Based on %d rounds
                """,
                o.avgMoney,      o.moneyRank,
                o.maxWin,        o.maxWinRank,
                o.proxPct,       o.proxRank,
                o.avgScore,      sign, abs(delta), o.scoreRank,
                o.wolfWinPct,    o.wolfRank,
                o.nonWolfWinPct, o.nonWolfRank,
                o.tieWinPct,     o.tieRank,
                o.rounds
            )

            return cell
        }

        // Section 1 (or only section) = per-friend rows
        let r = rows[indexPath.row]
        let roundsText = r.rounds == 1 ? "1 round" : "\(r.rounds) rounds"

        cell.textLabel?.text = r.name
        cell.detailTextLabel?.numberOfLines = 1
        cell.detailTextLabel?.text = String(
            format: "Avg $%.1f • Prox %.0f%% • %@",
            r.avgMoney,
            r.proxPct,
            roundsText
        )

        return cell
    }

    // MARK: - Actions

    @IBAction private func closeTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @IBAction private func trackButtonTapped(_ sender: UIButton) {
        sender.isSelected.toggle()
        trackToggled?(sender.isSelected)
    }
}
