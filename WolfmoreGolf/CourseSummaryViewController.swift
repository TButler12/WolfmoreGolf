//
//  CourseSummaryViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 12/2/25.
//
import UIKit

final class CourseSummaryViewController: UITableViewController {

    // MARK: - Row model

    private struct HoleRow {
        let holeNumber: Int      // 0-based (0 = Hole 1)
        let par: Int

        let avgMoney: Double
        let proxPct: Double
        let avgScore: Double
        let avgVsPar: Double

        let wolfWinPct: Double
        let nonWolfWinPct: Double
        let tieWinPct: Double

        let maxWin: Double       // biggest single win on that hole

        let moneyRank: Int
        let proxRank: Int
        let scoreRank: Int
        let wolfRank: Int
        let nonWolfRank: Int
        let tieRank: Int
        let maxWinRank: Int
    }

    // MARK: - Properties

    private var rows: [HoleRow] = []

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

        title = "Course Summary"

        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72

        buildRows()
        updateEmptyBackgroundIfNeeded()
    }

    // MARK: - Data builder

    private func buildRows() {
        let courseID = trackingCourseID

        // All rounds on this course (you + friends)
        let allRounds = RoundStore.shared.rounds.filter { $0.courseID == courseID }
        guard !allRounds.isEmpty else {
            rows = []
            tableView.reloadData()
            return
        }

        let holeCount = allRounds.map { $0.moneyPerHole.count }.max() ?? 0
        guard holeCount > 0 else {
            rows = []
            tableView.reloadData()
            return
        }

        // Load pars (default all 4)
        var pars = Array(repeating: 4, count: holeCount)
        if let uuid = UUID(uuidString: courseID),
           let course = CourseLibrary.shared.get(id: uuid) {
            let coursePars = Array(course.pars.prefix(holeCount))
            if !coursePars.isEmpty { pars = coursePars }
        }

        // ---- Aggregates ----

        var totalWinMoney       = Array(repeating: 0.0, count: holeCount)
        var winRoundsPerHole    = Array(repeating: 0,   count: holeCount)
        var proxWins            = Array(repeating: 0,   count: holeCount)
        var playerRoundsPerHole = Array(repeating: 0,   count: holeCount)
        var scoreSum            = Array(repeating: 0,   count: holeCount)
        var scoreCount          = Array(repeating: 0,   count: holeCount)

        var wolfCallSamples     = Array(repeating: 0,   count: holeCount)
        var wolfWinSamples      = Array(repeating: 0,   count: holeCount)
        var tieSamples          = Array(repeating: 0,   count: holeCount)

        var maxWinPerHole       = Array(repeating: 0.0, count: holeCount)

        for round in allRounds {
            let count = min(
                holeCount,
                round.moneyPerHole.count,
                round.proxPerHole.count
            )
            guard count > 0 else { continue }

            for h in 0..<count {
                let delta = round.moneyPerHole[h]   // + = winner, − = loser

                // $ winners (average winner $)
                if delta > 0 {
                    totalWinMoney[h] += Double(delta)
                    winRoundsPerHole[h] += 1

                    // biggest single win
                    if Double(delta) > maxWinPerHole[h] {
                        maxWinPerHole[h] = Double(delta)
                    }
                }

                // Prox (per player-sample)
                if round.proxPerHole[h] {
                    proxWins[h] += 1
                }

                // Scores
                if h < round.scorePerHole.count,
                   let s = round.scorePerHole[h] {
                    scoreSum[h]   += s
                    scoreCount[h] += 1
                }

                // Wolf tracking
                if h < round.wolfCalledPerHole.count,
                   round.wolfCalledPerHole[h] {

                    wolfCallSamples[h] += 1

                    if h < round.wolfTeamWonPerHole.count,
                       round.wolfTeamWonPerHole[h] {
                        wolfWinSamples[h] += 1
                    } else if delta == 0 {
                        tieSamples[h] += 1
                    }
                }

                // Count this player-hole sample
                playerRoundsPerHole[h] += 1
            }
        }

        // ---- Helpers ----

        func safeDiv(_ a: Double, _ b: Double) -> Double {
            b == 0 ? 0 : a / b
        }

        func ranks(for values: [Double], descending: Bool = true) -> [Int] {
            let indices = Array(0..<values.count).sorted { a, b in
                descending ? values[a] > values[b] : values[a] < values[b]
            }
            var out = Array(repeating: 0, count: values.count)
            for (pos, idx) in indices.enumerated() {
                out[idx] = pos + 1
            }
            return out
        }

        // ---- Per-hole averages / % ----

        let avgMoneyPerHole: [Double] = (0..<holeCount).map { i in
            safeDiv(totalWinMoney[i], Double(max(1, winRoundsPerHole[i])))
        }

        let avgScorePerHole: [Double] = (0..<holeCount).map { i in
            safeDiv(Double(scoreSum[i]), Double(scoreCount[i]))
        }

        let avgVsParPerHole: [Double] = (0..<holeCount).map { i in
            avgScorePerHole[i] - Double(pars[i])
        }

        // Prox % (per player-sample, never > 100)
        let proxPctPerHole: [Double] = (0..<holeCount).map { i in
            safeDiv(Double(proxWins[i]) * 100.0,
                    Double(max(1, playerRoundsPerHole[i])))
        }

        // Wolf / Non-Wolf / Tie %
        let wolfWinPctPerHole: [Double] = (0..<holeCount).map { i in
            safeDiv(Double(wolfWinSamples[i]) * 100.0,
                    Double(max(1, wolfCallSamples[i])))
        }

        let tieWinPctPerHole: [Double] = (0..<holeCount).map { i in
            safeDiv(Double(tieSamples[i]) * 100.0,
                    Double(max(1, wolfCallSamples[i])))
        }

        let nonWolfWinPctPerHole: [Double] = (0..<holeCount).map { i in
            let total = Double(wolfCallSamples[i])
            let wolf  = Double(wolfWinSamples[i])
            let tie   = Double(tieSamples[i])
            guard total > 0 else { return 0 }
            let nonWolf = max(0.0, total - wolf - tie)
            return safeDiv(nonWolf * 100.0, total)
        }

        // ---- Ranks across holes ----

        let moneyRanks    = ranks(for: avgMoneyPerHole,    descending: true)
        let proxRanks     = ranks(for: proxPctPerHole,     descending: true)
        let scoreRanks    = ranks(for: avgVsParPerHole,    descending: false)
        let wolfRanks     = ranks(for: wolfWinPctPerHole,  descending: true)
        let nonWolfRanks  = ranks(for: nonWolfWinPctPerHole, descending: true)
        let tieRanks      = ranks(for: tieWinPctPerHole,   descending: true)
        let maxWinRanks   = ranks(for: maxWinPerHole,      descending: true)

        // ---- Build rows ----

        var built: [HoleRow] = []

        for h in 0..<holeCount {
            built.append(
                HoleRow(
                    holeNumber: h,
                    par: pars[h],
                    avgMoney: avgMoneyPerHole[h],
                    proxPct: proxPctPerHole[h],
                    avgScore: avgScorePerHole[h],
                    avgVsPar: avgVsParPerHole[h],
                    wolfWinPct: wolfWinPctPerHole[h],
                    nonWolfWinPct: nonWolfWinPctPerHole[h],
                    tieWinPct: tieWinPctPerHole[h],
                    maxWin: maxWinPerHole[h],
                    moneyRank: moneyRanks[h],
                    proxRank: proxRanks[h],
                    scoreRank: scoreRanks[h],
                    wolfRank: wolfRanks[h],
                    nonWolfRank: nonWolfRanks[h],
                    tieRank: tieRanks[h],
                    maxWinRank: maxWinRanks[h]
                )
            )
        }

        rows = built
        tableView.reloadData()
    }

    // MARK: - Empty background

    private func updateEmptyBackgroundIfNeeded() {
        if rows.isEmpty {
            let label = UILabel()
            label.textAlignment = .center
            label.numberOfLines = 0
            label.textColor = .secondaryLabel
            label.text =
            """
            No course stats yet.

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
        return 1
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
        return rows.isEmpty ? nil : "By Hole"
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "CourseSummaryCell",
            for: indexPath
        )

        cell.backgroundColor = .clear
        cell.detailTextLabel?.numberOfLines = 0

        let r = rows[indexPath.row]
        let holeNo = r.holeNumber + 1
        let delta  = r.avgVsPar
        let sign   = delta >= 0 ? "+" : "−"

        cell.textLabel?.text = "Hole \(holeNo) (Par \(r.par))"
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
            """,
            r.avgMoney,       r.moneyRank,
            r.maxWin,         r.maxWinRank,
            r.proxPct,        r.proxRank,
            r.avgScore,       sign, abs(delta), r.scoreRank,
            r.wolfWinPct,     r.wolfRank,
            r.nonWolfWinPct,  r.nonWolfRank,
            r.tieWinPct,      r.tieRank
        )

        return cell
    }

    // MARK: - Actions

    @IBAction private func closeTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
}
