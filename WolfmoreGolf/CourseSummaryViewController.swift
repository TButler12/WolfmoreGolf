//
//  CourseSummaryViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 12/2/25.
//
import UIKit

final class CourseSummaryViewController: UITableViewController {
    // MARK: - Sorting

    private enum SortMode {
        case hole       // 1–18
        case difficulty // score vs par (hardest first)
        case money      // biggest average winner $
    }

    private var sortMode: SortMode = .hole

    // Segmented control in the nav bar to pick sort
    private lazy var sortControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Hole", "Score", "$"])
        sc.selectedSegmentIndex = 0
        sc.addTarget(self,
                     action: #selector(sortModeChanged(_:)),
                     for: .valueChanged)
        return sc
    }()

    // One row per hole
    private struct Row {
        let holeIndex: Int      // 0-based
        let par: Int

        let avgScore: Double    // raw avg strokes
        let avgVsPar: Double    // avgScore - par
        let scoreRank: Int      // 1 = easiest vs par

        let avgWinnerMoney: Double
        let moneyRank: Int      // 1 = best $ hole

        let rounds: Int         // approx # of rounds contributing

        // Wolf / Non-Wolf / Tie percentages for this hole
        let wolfWinPct: Double
        let nonWolfWinPct: Double
        let tieWinPct: Double

        // Umbie counts (approx games)
        let wolfUmbies: Int     // approx # games Umbie by Wolf
        let nonWolfUmbies: Int  // approx # games Umbie by non-Wolf
    }

    private var rows: [Row] = []

    // Overall Wolf / Non-Wolf / Tie win % across this course
    private var overallWolfWinPct: Double = 0
    private var overallNonWolfWinPct: Double = 0
    private var overallTieWinPct: Double = 0

    // Same tracking logic you use elsewhere
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

        title = "Course Summary"
        navigationItem.titleView = sortControl

        view.backgroundColor = .systemBackground
        tableView.backgroundColor = .systemBackground

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80

        buildRows()
        updateEmptyBackgroundIfNeeded()
    }

    // MARK: - Apply sorting

    private func applySort() {
        switch sortMode {
        case .hole:
            rows.sort { $0.holeIndex < $1.holeIndex }

        case .difficulty:
            // Hardest first = most over par (highest avgVsPar)
            rows.sort {
                if $0.avgVsPar == $1.avgVsPar {
                    return $0.holeIndex < $1.holeIndex
                }
                return $0.avgVsPar > $1.avgVsPar
            }

        case .money:
            // Biggest average winner $ first
            rows.sort {
                if $0.avgWinnerMoney == $1.avgWinnerMoney {
                    return $0.holeIndex < $1.holeIndex
                }
                return $0.avgWinnerMoney > $1.avgWinnerMoney
            }
        }

        tableView.reloadData()
    }

    // MARK: - Build data

    private func buildRows() {
        let courseID = trackingCourseID

        // All rounds that were tagged as this course
        let allRounds = RoundStore.shared.rounds.filter { $0.courseID == courseID }
        guard !allRounds.isEmpty else {
            rows = []
            tableView.reloadData()
            return
        }

        // How many holes? (usually 18)
        let holeCount = allRounds.map { $0.moneyPerHole.count }.max() ?? 0
        guard holeCount > 0 else {
            rows = []
            tableView.reloadData()
            return
        }

        // --- Pars for this course (fallback = all 4s) ---
        var pars = Array(repeating: 4, count: holeCount)
        if let uuid = UUID(uuidString: courseID),
           let course = CourseLibrary.shared.get(id: uuid) {
            let coursePars = Array(course.pars.prefix(holeCount))
            if !coursePars.isEmpty { pars = coursePars }
        }

        // Approximate group size = distinct players on this course
        let allPlayerNames = Set(allRounds.map { $0.playerName.lowercased() })
        let playersPerRound = max(1, allPlayerNames.count)
        let playersPerRoundDouble = Double(playersPerRound)

        // Aggregates (per hole)
        var totalWinMoney        = Array(repeating: 0.0, count: holeCount)
        var winRoundsPerHole     = Array(repeating: 0,   count: holeCount)

        var proxWins             = Array(repeating: 0,   count: holeCount)
        var playerRoundsPerHole  = Array(repeating: 0,   count: holeCount)

        var scoreSum             = Array(repeating: 0,   count: holeCount)
        var scoreCount           = Array(repeating: 0,   count: holeCount)

        // Wolf call aggregates (per player-sample)
        var wolfHolesSamples     = Array(repeating: 0,   count: holeCount)
        var wolfWinSamples       = Array(repeating: 0,   count: holeCount)
        var tieSamples           = Array(repeating: 0,   count: holeCount)

        // Umbie samples
        var wolfUmbieSamples     = Array(repeating: 0,   count: holeCount)
        var nonWolfUmbieSamples  = Array(repeating: 0,   count: holeCount)

        for round in allRounds {
            // Base usable length on money/prox arrays (most stable)
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

                // Prox for this player on this hole
                if round.proxPerHole[h] {
                    proxWins[h] += 1
                }

                // Scores
                if h < round.scorePerHole.count, let s = round.scorePerHole[h] {
                    scoreSum[h]   += s
                    scoreCount[h] += 1
                }

                // Wolf call + result (per player-sample)
                if h < round.wolfCalledPerHole.count,
                   round.wolfCalledPerHole[h] {
                    wolfHolesSamples[h] += 1

                    if h < round.wolfTeamWonPerHole.count,
                       round.wolfTeamWonPerHole[h] {
                        // Wolf side won this game-hole (for this player-sample)
                        wolfWinSamples[h] += 1
                    } else {
                        // Wolf was called but Wolf side did NOT win.
                        // Approximate ties as "no money moved" for this player.
                        if delta == 0 {
                            tieSamples[h] += 1
                        }
                        // Non-Wolf wins are inferred later as residual holes.
                    }
                }

                // Umbie by Wolf vs Non-Wolf (per player-sample)
                if h < round.umbieWonPerHole.count,
                   round.umbieWonPerHole[h] {

                    if h < round.wolfTeamWonPerHole.count,
                       round.wolfTeamWonPerHole[h] {
                        // Umbie and Wolf side won
                        wolfUmbieSamples[h] += 1
                    } else {
                        // Umbie and non-Wolf side (or tie) won
                        nonWolfUmbieSamples[h] += 1
                    }
                }

                // This player has data on this hole
                playerRoundsPerHole[h] += 1
            }
        }

        // Convert player-samples → approximate group rounds per hole
        let groupRoundsPerHole: [Int] = playerRoundsPerHole.map { samples in
            max(1, samples / playersPerRound)
        }

        // --- Derived arrays ---

        let avgMoneyPerHole: [Double] = (0..<holeCount).map { i in
            guard winRoundsPerHole[i] > 0 else { return 0 }
            return totalWinMoney[i] / Double(winRoundsPerHole[i])
        }

        let avgScorePerHole: [Double] = (0..<holeCount).map { i in
            guard scoreCount[i] > 0 else { return Double(pars[i]) }
            return Double(scoreSum[i]) / Double(scoreCount[i])
        }

        let avgVsParPerHole: [Double] = (0..<holeCount).map { i in
            avgScorePerHole[i] - Double(pars[i])
        }

        // Wolf / Non-Wolf / Tie % per hole
        let wolfWinPctPerHole: [Double] = (0..<holeCount).map { i in
            let wolfCallsAsHoles = Double(wolfHolesSamples[i]) / playersPerRoundDouble
            guard wolfCallsAsHoles > 0 else { return 0 }

            let wolfWinsAsHoles = Double(wolfWinSamples[i]) / playersPerRoundDouble
            let tiesAsHoles     = Double(tieSamples[i]) / playersPerRoundDouble
            let nonWolfAsHoles  = max(0.0, wolfCallsAsHoles - wolfWinsAsHoles - tiesAsHoles)

            let totalHolesWithWolf = wolfCallsAsHoles
            guard totalHolesWithWolf > 0 else { return 0 }

            return (wolfWinsAsHoles / totalHolesWithWolf) * 100.0
        }

        let nonWolfWinPctPerHole: [Double] = (0..<holeCount).map { i in
            let wolfCallsAsHoles = Double(wolfHolesSamples[i]) / playersPerRoundDouble
            guard wolfCallsAsHoles > 0 else { return 0 }

            let wolfWinsAsHoles = Double(wolfWinSamples[i]) / playersPerRoundDouble
            let tiesAsHoles     = Double(tieSamples[i]) / playersPerRoundDouble
            let nonWolfAsHoles  = max(0.0, wolfCallsAsHoles - wolfWinsAsHoles - tiesAsHoles)

            let totalHolesWithWolf = wolfCallsAsHoles
            guard totalHolesWithWolf > 0 else { return 0 }

            return (nonWolfAsHoles / totalHolesWithWolf) * 100.0
        }

        let tieWinPctPerHole: [Double] = (0..<holeCount).map { i in
            let wolfCallsAsHoles = Double(wolfHolesSamples[i]) / playersPerRoundDouble
            guard wolfCallsAsHoles > 0 else { return 0 }

            let tiesAsHoles = Double(tieSamples[i]) / playersPerRoundDouble
            let totalHolesWithWolf = wolfCallsAsHoles
            guard totalHolesWithWolf > 0 else { return 0 }

            return (tiesAsHoles / totalHolesWithWolf) * 100.0
        }

        // Approximate Umbie counts per hole (convert from player samples → games)
        let wolfUmbiesPerHole: [Int] = (0..<holeCount).map { i in
            let samples = wolfUmbieSamples[i]
            guard samples > 0 else { return 0 }
            let approxGames = Double(samples) / playersPerRoundDouble
            return max(1, Int(approxGames.rounded()))
        }

        let nonWolfUmbiesPerHole: [Int] = (0..<holeCount).map { i in
            let samples = nonWolfUmbieSamples[i]
            guard samples > 0 else { return 0 }
            let approxGames = Double(samples) / playersPerRoundDouble
            return max(1, Int(approxGames.rounded()))
        }

        // Overall Wolf / Non-Wolf / Tie % across the course
        let totalWolfCallsSamples = wolfHolesSamples.reduce(0, +)
        let totalWolfWinsSamples  = wolfWinSamples.reduce(0, +)
        let totalTieSamples       = tieSamples.reduce(0, +)

        let totalWolfCallsAsHoles = Double(totalWolfCallsSamples) / playersPerRoundDouble
        let totalWolfWinsAsHoles  = Double(totalWolfWinsSamples) / playersPerRoundDouble
        let totalTiesAsHoles      = Double(totalTieSamples) / playersPerRoundDouble
        let totalNonWolfAsHoles   = max(0.0, totalWolfCallsAsHoles - totalWolfWinsAsHoles - totalTiesAsHoles)

        if totalWolfCallsAsHoles > 0 {
            overallWolfWinPct    = (totalWolfWinsAsHoles  / totalWolfCallsAsHoles) * 100.0
            overallNonWolfWinPct = (totalNonWolfAsHoles   / totalWolfCallsAsHoles) * 100.0
            overallTieWinPct     = (totalTiesAsHoles      / totalWolfCallsAsHoles) * 100.0
        } else {
            overallWolfWinPct = 0
            overallNonWolfWinPct = 0
            overallTieWinPct = 0
        }

        // Show it under the nav bar title
        navigationItem.prompt = String(
            format: "Wolf %.0f%% • Non-Wolf %.0f%% • Tie %.0f%%",
            overallWolfWinPct, overallNonWolfWinPct, overallTieWinPct
        )

        // Helper: convert an array of values into per-hole ranks
        func ranks(for values: [Double], descending: Bool) -> [Int] {
            let indices = Array(0..<values.count)
            let sorted = indices.sorted { a, b in
                descending ? (values[a] > values[b]) : (values[a] < values[b])
            }
            var result = Array(repeating: 0, count: values.count)
            for (pos, idx) in sorted.enumerated() {
                result[idx] = pos + 1
            }
            return result
        }

        let moneyRanks = ranks(for: avgMoneyPerHole, descending: true)   // 1 = best $ hole
        let scoreRanks = ranks(for: avgVsParPerHole, descending: false)  // 1 = easiest vs par

        // Build table rows
        var newRows: [Row] = []
        for h in 0..<holeCount {
            newRows.append(Row(
                holeIndex: h,
                par: pars[h],
                avgScore: avgScorePerHole[h],
                avgVsPar: avgVsParPerHole[h],
                scoreRank: scoreRanks[h],
                avgWinnerMoney: avgMoneyPerHole[h],
                moneyRank: moneyRanks[h],
                rounds: groupRoundsPerHole[h],
                wolfWinPct: wolfWinPctPerHole[h],
                nonWolfWinPct: nonWolfWinPctPerHole[h],
                tieWinPct: tieWinPctPerHole[h],
                wolfUmbies: wolfUmbiesPerHole[h],
                nonWolfUmbies: nonWolfUmbiesPerHole[h]
            ))
        }

        rows = newRows
        applySort()
    }

    @objc private func sortModeChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            sortMode = .hole
        case 1:
            sortMode = .difficulty
        case 2:
            sortMode = .money
        default:
            sortMode = .hole
        }
        applySort()
    }

    private func updateEmptyBackgroundIfNeeded() {
        if rows.isEmpty {
            let label = UILabel()
            label.textAlignment = .center
            label.numberOfLines = 0
            label.textColor = .secondaryLabel
            label.text = """
            No course stats yet.

            • Make sure a Home / Tracking Course is set in Course Setup.
            • Use Track Friends on your home course.
            • Play and save rounds to build course stats.
            """
            tableView.backgroundView = label
        } else {
            tableView.backgroundView = nil
        }
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // In Interface Builder: UITableViewCell, style = Subtitle, ID = "CourseSummaryCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: "CourseSummaryCell",
                                                 for: indexPath)
        let r = rows[indexPath.row]

        let delta = r.avgVsPar
        let sign  = delta >= 0 ? "+" : "−"

        cell.textLabel?.text = "Hole \(r.holeIndex + 1) • Par \(r.par)"
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = String(
            format:
            """
            Avg score %.1f (%@%.1f vs par, rank %d)
            Avg winner $%.1f (rank %d)
            Wolf %.0f%% • NW %.0f%% • Tie %.0f%%
            Umbies W:%d / NW:%d
            Based on %d rounds
            """,
            r.avgScore,
            sign, abs(delta), r.scoreRank,
            r.avgWinnerMoney, r.moneyRank,
            r.wolfWinPct, r.nonWolfWinPct, r.tieWinPct,
            r.wolfUmbies, r.nonWolfUmbies,
            r.rounds
        )

        return cell
    }

    // MARK: - Actions

    @IBAction private func closeTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
}
