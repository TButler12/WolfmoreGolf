
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

    private func buildOverview(for trackedFriends: [Friend], courseID: String) {
        // Use ALL rounds on this course (friends + you)
        let allRounds = RoundStore.shared.rounds.filter { $0.courseID == courseID }
        guard !allRounds.isEmpty else { overview = nil; return }

        let holeCount = allRounds.map { $0.moneyPerHole.count }.max() ?? 0
        guard holeCount > 0 else { overview = nil; return }

        // Pars for this course (fallback 4s)
        var pars = Array(repeating: 4, count: holeCount)
        if let uuid = UUID(uuidString: courseID),
           let course = CourseLibrary.shared.get(id: uuid) {
            let coursePars = Array(course.pars.prefix(holeCount))
            if !coursePars.isEmpty { pars = coursePars }
        }

        // Approximate group size: assume typical 4-ball once we have 4+ names
        let allPlayerNames = Set(allRounds.map { $0.playerName.lowercased() })
        let approxPlayersPerRound = max(1, min(4, allPlayerNames.count))

        // Aggregates
        var totalWinMoney        = Array(repeating: 0.0, count: holeCount)
        var winSamplesPerHole    = Array(repeating: 0,   count: holeCount)
        var maxWinPerHole        = Array(repeating: 0.0, count: holeCount)

        var proxWins             = Array(repeating: 0,   count: holeCount)
        var playerSamplesPerHole = Array(repeating: 0,   count: holeCount)

        var scoreSum             = Array(repeating: 0,   count: holeCount)
        var scoreCount           = Array(repeating: 0,   count: holeCount)

        // Wolf call aggregates (per sample; ratios still correct)
        var wolfCallSamples      = Array(repeating: 0,   count: holeCount)
        var wolfWinSamples       = Array(repeating: 0,   count: holeCount)
        var tieSamples           = Array(repeating: 0,   count: holeCount)

        // ---- Aggregate across all player-rounds ----
        for round in allRounds {
            let count = min(
                holeCount,
                round.moneyPerHole.count,
                round.proxPerHole.count
            )
            guard count > 0 else { continue }

            for h in 0..<count {
                let delta = round.moneyPerHole[h]

                // Money: only winner dollars (delta > 0)
                if delta > 0 {
                    let win = Double(delta)
                    totalWinMoney[h] += win
                    winSamplesPerHole[h] += 1
                    if win > maxWinPerHole[h] {
                        maxWinPerHole[h] = win     // biggest single win on this hole
                    }
                }

                // Prox winner (one per game)
                if round.proxPerHole[h] {
                    proxWins[h] += 1
                }

                // Scores
                if h < round.scorePerHole.count,
                   let s = round.scorePerHole[h] {
                    scoreSum[h]   += s
                    scoreCount[h] += 1
                }

                // Wolf flags: did a Wolf get called, and who won?
                if h < round.wolfCalledPerHole.count,
                   round.wolfCalledPerHole[h] {

                    wolfCallSamples[h] += 1

                    if h < round.wolfTeamWonPerHole.count,
                       round.wolfTeamWonPerHole[h] {
                        // Wolf side won this game-hole
                        wolfWinSamples[h] += 1
                    } else if delta == 0 {
                        // Wolf called and nobody won money → treat as tie
                        tieSamples[h] += 1
                    }
                    // Non-Wolf wins are inferred as the residual later.
                }

                // Count this player-hole sample
                playerSamplesPerHole[h] += 1
            }
        }

        // ---- Derived numbers ----

        func safeDiv(_ a: Double, _ b: Double) -> Double {
            b == 0 ? 0 : (a / b)
        }

        // Approximate game count per hole from samples
        let groupRoundsPerHole: [Int] = (0..<holeCount).map { i in
            let approxGames = Double(playerSamplesPerHole[i]) / Double(approxPlayersPerRound)
            return max(1, Int(approxGames.rounded()))   // never 0
        }

        // Average money (per winning game, roughly)
        let avgMoneyPerHole: [Double] = (0..<holeCount).map { i in
            safeDiv(totalWinMoney[i], Double(max(1, winSamplesPerHole[i])))
        }

        // Average score & vs par
        let avgScorePerHole: [Double] = (0..<holeCount).map { i in
            safeDiv(Double(scoreSum[i]), Double(scoreCount[i]))
        }

        let avgVsParPerHole: [Double] = (0..<holeCount).map { i in
            avgScorePerHole[i] - Double(pars[i])
        }

        // Prox %: games with a prox winner / approx games (clamp to 100)
        let proxPctPerHole: [Double] = (0..<holeCount).map { i in
            let rounds = Double(max(1, groupRoundsPerHole[i]))
            let pct = safeDiv(Double(proxWins[i]) * 100.0, rounds)
            return min(100.0, max(0.0, pct))
        }

        // Wolf / Non-Wolf / Tie % (based on Wolf-called holes)
        let wolfWinPctPerHole: [Double] = (0..<holeCount).map { i in
            safeDiv(Double(wolfWinSamples[i]) * 100.0, Double(wolfCallSamples[i]))
        }

        let tieWinPctPerHole: [Double] = (0..<holeCount).map { i in
            safeDiv(Double(tieSamples[i]) * 100.0, Double(wolfCallSamples[i]))
        }

        let nonWolfWinPctPerHole: [Double] = (0..<holeCount).map { i in
            let total = Double(wolfCallSamples[i])
            let wolf  = Double(wolfWinSamples[i])
            let tie   = Double(tieSamples[i])
            guard total > 0 else { return 0 }
            let nonWolf = max(0.0, total - wolf - tie)
            return safeDiv(nonWolf * 100.0, total)
        }

        // ---- Ranking helper ----
        func rank(of index: Int, using values: [Double], descending: Bool = true) -> Int {
            // Ignore pure zeros so “no data” doesn’t get rank 1
            let valid = values.enumerated().filter { $0.element > 0 }
            guard !valid.isEmpty else { return 0 }

            let sorted = valid.sorted { a, b in
                descending ? a.element > b.element : a.element < b.element
            }

            return (sorted.firstIndex { $0.offset == index } ?? 0) + 1
        }

        // ---- Compose Overview for THIS hole ----
        let h = holeIndex
        guard h < holeCount else {
            overview = nil
            return
        }

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
            rounds:        groupRoundsPerHole[h],
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
