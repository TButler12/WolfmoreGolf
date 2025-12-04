//
//
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
        let tieWinPct: Double          // 👈 NEW

        let moneyRank: Int
        let proxRank: Int
        let scoreRank: Int
        let wolfRank: Int
        let nonWolfRank: Int
        let tieRank: Int               // 👈 NEW

        let rounds: Int
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
        tableView.backgroundColor = .systemBackground
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

    // MARK: - Overview Builder (Wolf / Non-Wolf / Tie %)
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

        // Approximate group size
        let allPlayerNames = Set(allRounds.map { $0.playerName.lowercased() })
        let playersPerRound = max(1, allPlayerNames.count)

        // Aggregates
        var totalWinMoney        = Array(repeating: 0.0, count: holeCount)
        var winRoundsPerHole     = Array(repeating: 0,   count: holeCount)
        var proxWins             = Array(repeating: 0,   count: holeCount)
        var playerRoundsPerHole  = Array(repeating: 0,   count: holeCount)
        var scoreSum             = Array(repeating: 0,   count: holeCount)
        var scoreCount           = Array(repeating: 0,   count: holeCount)

        // Wolf call aggregates (per player-sample)
        var wolfCallSamples      = Array(repeating: 0,   count: holeCount)
        var wolfWinSamples       = Array(repeating: 0,   count: holeCount)
        var tieSamples           = Array(repeating: 0,   count: holeCount)

        for round in allRounds {
            let count = min(
                holeCount,
                round.moneyPerHole.count,
                round.proxPerHole.count
            )
            guard count > 0 else { continue }

            for h in 0..<count {
                let delta = round.moneyPerHole[h]

                // Only count *winner* dollars (high-water mark)
                if delta > 0 {
                    totalWinMoney[h] += Double(delta)
                    winRoundsPerHole[h] += 1
                }

                // Prox winner for this player on this hole (one winner per game)
                if round.proxPerHole[h] {
                    proxWins[h] += 1
                }

                // Score
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
                        // Wolf side won this game-hole (sample)
                        wolfWinSamples[h] += 1
                    } else {
                        // Wolf was called but Wolf side did NOT win.
                        // Use delta == 0 as a signal for tie on this sample.
                        if delta == 0 {
                            tieSamples[h] += 1
                        }
                        // Non-Wolf wins will be inferred as the residual.
                    }
                }

                // Count this player-hole sample
                playerRoundsPerHole[h] += 1
            }
        }

        // Convert player-samples → approximate group-rounds (for prox %, money etc)
        let groupRoundsPerHole: [Int] = playerRoundsPerHole.map { samples in
            max(1, samples / playersPerRound)
        }

        // Averages & percentages
        let avgMoneyPerHole: [Double] = (0..<holeCount).map { i in
            guard winRoundsPerHole[i] > 0 else { return 0 }
            return totalWinMoney[i] / Double(winRoundsPerHole[i])
        }

        let proxPctPerHole: [Double] = (0..<holeCount).map { i in
            let rounds = groupRoundsPerHole[i]
            guard rounds > 0 else { return 0 }
            return Double(proxWins[i]) / Double(rounds) * 100.0
        }

        let avgScorePerHole: [Double] = (0..<holeCount).map { i in
            guard scoreCount[i] > 0 else { return 0 }
            return Double(scoreSum[i]) / Double(scoreCount[i])
        }

        let avgVsParPerHole: [Double] = (0..<holeCount).map { i in
            avgScorePerHole[i] - Double(pars[i])
        }

        // Wolf / Non-Wolf / Tie % per hole
        let wolfWinPctPerHole: [Double] = (0..<holeCount).map { i in
            let totalSamples = wolfCallSamples[i]
            guard totalSamples > 0 else { return 0 }
            let total = Double(totalSamples)
            let wolf = Double(wolfWinSamples[i])
            let tie  = Double(tieSamples[i])
            let nonWolf = max(0.0, total - wolf - tie)
            // (We only need wolf here, but keeping pattern parallel)
            return (wolf / total) * 100.0
        }

        let nonWolfWinPctPerHole: [Double] = (0..<holeCount).map { i in
            let totalSamples = wolfCallSamples[i]
            guard totalSamples > 0 else { return 0 }
            let total = Double(totalSamples)
            let wolf = Double(wolfWinSamples[i])
            let tie  = Double(tieSamples[i])
            let nonWolf = max(0.0, total - wolf - tie)
            return (nonWolf / total) * 100.0
        }

        let tieWinPctPerHole: [Double] = (0..<holeCount).map { i in
            let totalSamples = wolfCallSamples[i]
            guard totalSamples > 0 else { return 0 }
            let total = Double(totalSamples)
            let tie  = Double(tieSamples[i])
            return (tie / total) * 100.0
        }

        func rank(of index: Int, using values: [Double], descending: Bool = true) -> Int {
            let order = (0..<values.count).sorted { a, b in
                descending ? values[a] > values[b] : values[a] < values[b]
            }
            return (order.firstIndex(of: index) ?? 0) + 1
        }

        let h = holeIndex
        guard h < holeCount else {
            overview = nil
            return
        }

        overview = HoleOverview(
            avgMoney:   avgMoneyPerHole[h],
            proxPct:    proxPctPerHole[h],
            avgScore:   avgScorePerHole[h],
            avgVsPar:   avgVsParPerHole[h],
            wolfWinPct: wolfWinPctPerHole[h],
            nonWolfWinPct: nonWolfWinPctPerHole[h],
            tieWinPct:  tieWinPctPerHole[h],
            moneyRank:  rank(of: h, using: avgMoneyPerHole,      descending: true),
            proxRank:   rank(of: h, using: proxPctPerHole,       descending: true),
            scoreRank:  rank(of: h, using: avgVsParPerHole,      descending: false),
            wolfRank:   rank(of: h, using: wolfWinPctPerHole,    descending: true),
            nonWolfRank: rank(of: h, using: nonWolfWinPctPerHole, descending: true),
            tieRank:    rank(of: h, using: tieWinPctPerHole,     descending: true),
            rounds:     groupRoundsPerHole[h],
            holeCount:  holeCount
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
                Prox %.0f%% (rank %d)
                Avg score %.1f (%@%.1f vs par, rank %d)
                Wolf win %.0f%% (rank %d)
                Non-Wolf win %.0f%% (rank %d)
                Tie %.0f%% (rank %d)
                Based on %d rounds
                """,
                o.avgMoney,        o.moneyRank,
                o.proxPct,         o.proxRank,
                o.avgScore,        sign, abs(delta), o.scoreRank,
                o.wolfWinPct,      o.wolfRank,
                o.nonWolfWinPct,   o.nonWolfRank,
                o.tieWinPct,       o.tieRank,
                o.rounds
            )
            return cell
        }

        // Section 1 (or only section) = per-friend rows
        let r = rows[indexPath.row]
        let roundsText = r.rounds == 1 ? "1 round" : "\(r.rounds) rounds"

        cell.textLabel?.text = r.name
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
