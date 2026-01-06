//
import UIKit

final class CourseSummaryViewController: UITableViewController {

    // MARK: - Sorting

    private enum CourseSortKey { case hole, money, prox, wolf, nonWolf, umbie }
    private var sortKey: CourseSortKey = .money

    private let sortControl = UISegmentedControl(
        items: ["Hole", "Money", "Prox", "Wolf%", "Non-Wolf%", "Umbie%"]
    )

    // MARK: - Models

    private struct HoleRow {
        let holeIndex: Int   // 0-based
        let par: Int

        // Stored as 0–100
        let avgWinner: Double
        let biggestWin: Int
        let proxPct: Double
        let avgScore: Double?

        let wolfWinPct: Double
        let nonWolfWinPct: Double
        let tiePct: Double

        // Umbie
        let umbieCount: Int
        let umbiePct: Double

        // ranks (1 = best)
        var rankAvgWinner: Int = 0
        var rankBiggestWin: Int = 0
        var rankProx: Int = 0
        var rankAvgScore: Int = 0
        var rankWolf: Int = 0
        var rankNonWolf: Int = 0
        var rankTie: Int = 0
        var rankUmbie: Int = 0
    }

    private var rows: [HoleRow] = []

    // MARK: - Formatters

    private let currency1: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.minimumFractionDigits = 1
        nf.maximumFractionDigits = 1
        return nf
    }()

    private func money1(_ v: Double) -> String {
        currency1.string(from: NSNumber(value: v)) ?? String(format: "$%.1f", v)
    }

    private func pct0(_ v0to100: Double) -> String {
        "\(Int(v0to100.rounded()))%"
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "By Hole"

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "holeCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150
        tableView.separatorInset = .zero

        configureSortHeader()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(rebuild),
                                               name: .reloadUI,
                                               object: nil)

        rebuild()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // keep the header height correct
        if let header = tableView.tableHeaderView {
            let target = CGSize(width: tableView.bounds.width,
                                height: UIView.layoutFittingCompressedSize.height)
            let height = header.systemLayoutSizeFitting(target).height
            if header.frame.height != height {
                header.frame.size.height = height
                tableView.tableHeaderView = header
            }
        }
    }

    // MARK: - Header

    private func configureSortHeader() {
        sortControl.selectedSegmentIndex = 1 // Money default
        sortControl.addTarget(self, action: #selector(sortChanged(_:)), for: .valueChanged)

        let header = UIView()
        header.backgroundColor = .systemBackground

        sortControl.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(sortControl)

        NSLayoutConstraint.activate([
            sortControl.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 12),
            sortControl.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -12),
            sortControl.topAnchor.constraint(equalTo: header.topAnchor, constant: 10),
            sortControl.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -10),
        ])

        header.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 54)
        tableView.tableHeaderView = header
    }

    // MARK: - Actions

    @objc private func sortChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: sortKey = .hole
        case 1: sortKey = .money
        case 2: sortKey = .prox
        case 3: sortKey = .wolf
        case 4: sortKey = .nonWolf
        default: sortKey = .umbie
        }

        applySort()
        tableView.reloadData()
    }

    // MARK: - Rebuild

    @objc private func rebuild() {
        rows = buildRows()
        applyRanks(&rows)
        applySort()
        tableView.reloadData()

        if rows.isEmpty {
            let lbl = UILabel()
            lbl.text = "No Home Course rounds saved yet."
            lbl.textAlignment = .center
            lbl.numberOfLines = 0
            lbl.textColor = .secondaryLabel
            tableView.backgroundView = lbl
        } else {
            tableView.backgroundView = nil
        }
    }

    // MARK: - Build

    private func buildRows() -> [HoleRow] {
        let homeID = ProfileStore.homeCourseID.trimmingCharacters(in: .whitespacesAndNewlines)

        // Use ALL rounds on this course
        let roundsOnCourse = RoundStore.shared.rounds.filter {
            homeID.isEmpty ? true : $0.courseID == homeID
        }

        guard !roundsOnCourse.isEmpty else { return [] }

        // ✅ Primary grouping: gameID
        var games = Dictionary(grouping: roundsOnCourse, by: \.gameID)
            .values
            .map { Array($0) }

        // ✅ Back-compat fallback:
        // If every group is size 1, you're almost certainly saving a unique gameID per player row.
        // We coalesce by courseID + minute-bucket timestamp so 1 real game doesn't look like 5.
        let allSingletons = games.allSatisfy { $0.count == 1 }
        if allSingletons && roundsOnCourse.count >= 2 {
            let fallback = Dictionary(grouping: roundsOnCourse) { r in
                // minute-bucket; adjust to /30 if you want 30-second buckets
                let minuteBucket = Int(r.date.timeIntervalSince1970 / 60.0)
                return "\(r.courseID)|\(minuteBucket)"
            }
            let candidateGames = fallback.values.map { Array($0) }

            // Only accept fallback if it actually merges rows (otherwise it was pointless)
            if candidateGames.contains(where: { $0.count > 1 }) {
                games = candidateGames
            }
        }

        guard !games.isEmpty else { return [] }

        let pars = resolveParsFallback()

        return (0..<18).map { h in
            buildHoleRow(holeIndex: h, par: pars.safe(h) ?? 4, games: games)
        }
    }

    private func resolveParsFallback() -> [Int] {
        // 1) Prefer Home Course pars
        if let uuid = UUID(uuidString: ProfileStore.homeCourseID),
           let course = CourseLibrary.shared.get(id: uuid) {
            return Array(course.pars.prefix(18))
        }

        // 2) Fallback to current game pars
        if let g = GameManager.shared.currentGame {
            return Array(g.course.pars.prefix(18))
        }

        // 3) Final fallback
        return Array(repeating: 4, count: 18)
    }

    private func buildHoleRow(holeIndex h: Int, par: Int, games: [[RoundSummary]]) -> HoleRow {

        // Only games where hole was played by at least one player
        let playedGames = games.filter { group in
            group.contains { r in
                if scoreValue(r, h) != nil { return true }
                return h < max(r.holesPlayed, 0)
            }
        }

        let gameCount = playedGames.count
        guard gameCount > 0 else {
            return HoleRow(
                holeIndex: h, par: par,
                avgWinner: 0, biggestWin: 0,
                proxPct: 0, avgScore: nil,
                wolfWinPct: 0, nonWolfWinPct: 0, tiePct: 0,
                umbieCount: 0, umbiePct: 0
            )
        }

        // -------- Money: winner per game = max money in that game --------
        let winnersPerGame: [Int] = playedGames.map { group in
            group.map { moneyValue($0, h) }.max() ?? 0
        }

        let winningGames = winnersPerGame.filter { $0 > 0 }
        let avgWinner: Double = winningGames.isEmpty
            ? 0
            : Double(winningGames.reduce(0, +)) / Double(winningGames.count)

        let biggestWin: Int = winningGames.max() ?? 0

        // -------- Prox: awarded if ANY player in game has prox true --------
        let proxGames = playedGames.filter { group in
            group.contains { $0.proxPerHole.safe(h) == true }
        }.count
        let proxPct = (Double(proxGames) / Double(gameCount)) * 100.0

        // -------- Avg score: average of all recorded scores (all players) --------
        let allScores: [Int] = playedGames.flatMap { group in
            group.compactMap { scoreValue($0, h) }
        }
        let avgScore: Double? = allScores.isEmpty
            ? nil
            : Double(allScores.reduce(0, +)) / Double(allScores.count)

        // -------- Wolf / Non-wolf / Tie: decide from the GAME winner --------
        var wolfWins = 0
        var nonWolfWins = 0
        var ties = 0

        for group in playedGames {
            guard let winner = group.max(by: { moneyValue($0, h) < moneyValue($1, h) }) else { continue }
            let winAmt = moneyValue(winner, h)

            if winAmt <= 0 {
                ties += 1
            } else if winner.wolfTeamWonPerHole.safe(h) == true {
                wolfWins += 1
            } else {
                nonWolfWins += 1
            }
        }

        let wolfPct = (Double(wolfWins) / Double(gameCount)) * 100.0
        let nonWolfPct = (Double(nonWolfWins) / Double(gameCount)) * 100.0
        let tiePct = (Double(ties) / Double(gameCount)) * 100.0

        // -------- Umbie: hit if ANY player in game has umbie true --------
        let umbieGames = playedGames.filter { group in
            group.contains { $0.umbieWonPerHole.safe(h) == true }
        }.count
        let umbiePct = (Double(umbieGames) / Double(gameCount)) * 100.0

        return HoleRow(
            holeIndex: h,
            par: par,
            avgWinner: avgWinner,
            biggestWin: biggestWin,
            proxPct: proxPct,
            avgScore: avgScore,
            wolfWinPct: wolfPct,
            nonWolfWinPct: nonWolfPct,
            tiePct: tiePct,
            umbieCount: umbieGames,
            umbiePct: umbiePct
        )
    }

    // MARK: - Helpers

    private func moneyValue(_ r: RoundSummary, _ h: Int) -> Int {
        r.moneyPerHole.safe(h) ?? 0
    }

    private func scoreValue(_ r: RoundSummary, _ h: Int) -> Int? {
        guard let vOpt = r.scorePerHole.safe(h) else { return nil } // Int?
        return vOpt
    }

    // MARK: - Ranking

    private func applyRanks(_ rows: inout [HoleRow]) {

        func rankBy<T: Comparable>(_ value: (HoleRow) -> T, higherIsBetter: Bool) -> [Int] {
            let ordered = rows.enumerated().sorted { a, b in
                let va = value(a.element)
                let vb = value(b.element)
                return higherIsBetter ? (va > vb) : (va < vb)
            }

            var ranks = Array(repeating: 0, count: rows.count)
            for (i, item) in ordered.enumerated() {
                ranks[item.offset] = i + 1
            }
            return ranks
        }

        let rAvgWinner = rankBy({ $0.avgWinner }, higherIsBetter: true)
        let rBigWin    = rankBy({ $0.biggestWin }, higherIsBetter: true)
        let rProx      = rankBy({ $0.proxPct }, higherIsBetter: true)
        let rWolf      = rankBy({ $0.wolfWinPct }, higherIsBetter: true)
        let rNonWolf   = rankBy({ $0.nonWolfWinPct }, higherIsBetter: true)
        let rTie       = rankBy({ $0.tiePct }, higherIsBetter: true)
        let rUmbie     = rankBy({ $0.umbiePct }, higherIsBetter: true)

        // lower avg score is better
        let rScore = rankBy({ $0.avgScore ?? 9999.0 }, higherIsBetter: false)

        for i in 0..<rows.count {
            rows[i].rankAvgWinner  = rAvgWinner[i]
            rows[i].rankBiggestWin = rBigWin[i]
            rows[i].rankProx       = rProx[i]
            rows[i].rankWolf       = rWolf[i]
            rows[i].rankNonWolf    = rNonWolf[i]
            rows[i].rankTie        = rTie[i]
            rows[i].rankAvgScore   = rScore[i]
            rows[i].rankUmbie      = rUmbie[i]
        }
    }

    // MARK: - Sorting

    private func applySort() {
        switch sortKey {
        case .hole:
            rows.sort { $0.holeIndex < $1.holeIndex }

        case .money:
            rows.sort {
                if $0.avgWinner != $1.avgWinner { return $0.avgWinner > $1.avgWinner }
                if $0.biggestWin != $1.biggestWin { return $0.biggestWin > $1.biggestWin }
                return $0.holeIndex < $1.holeIndex
            }

        case .prox:
            rows.sort {
                if $0.proxPct != $1.proxPct { return $0.proxPct > $1.proxPct }
                return $0.holeIndex < $1.holeIndex
            }

        case .wolf:
            rows.sort {
                if $0.wolfWinPct != $1.wolfWinPct { return $0.wolfWinPct > $1.wolfWinPct }
                return $0.holeIndex < $1.holeIndex
            }

        case .nonWolf:
            rows.sort {
                if $0.nonWolfWinPct != $1.nonWolfWinPct { return $0.nonWolfWinPct > $1.nonWolfWinPct }
                return $0.holeIndex < $1.holeIndex
            }

        case .umbie:
            rows.sort {
                if $0.umbiePct != $1.umbiePct { return $0.umbiePct > $1.umbiePct }
                return $0.holeIndex < $1.holeIndex
            }
        }
    }

    // MARK: - Table Data Source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let r = rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "holeCell", for: indexPath)

        cell.selectionStyle = .none
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = .systemFont(ofSize: 16)

        let holeNum = r.holeIndex + 1

        let avgScoreLine: String = {
            guard let avg = r.avgScore else { return "Avg score —" }
            let delta = avg - Double(r.par)
            let sign = (delta >= 0) ? "+" : "–"
            return String(format: "Avg score %.1f (%@%.1f vs par, rank %d)", avg, sign, abs(delta), r.rankAvgScore)
        }()

        cell.textLabel?.text =
        """
        Hole \(holeNum) (Par \(r.par))
        Avg winner \(money1(r.avgWinner)) (rank \(r.rankAvgWinner))
        Biggest win $\(r.biggestWin) (rank \(r.rankBiggestWin))
        Prox \(pct0(r.proxPct)) (rank \(r.rankProx))
        \(avgScoreLine)
        Wolf win \(pct0(r.wolfWinPct)) (rank \(r.rankWolf))
        Non-Wolf win \(pct0(r.nonWolfWinPct)) (rank \(r.rankNonWolf))
        Tie \(pct0(r.tiePct)) (rank \(r.rankTie))
        Umbie \(pct0(r.umbiePct)) (\(r.umbieCount) hits, rank \(r.rankUmbie))
        """

        return cell
    }
}

// MARK: - Safe indexing

private extension Array {
    func safe(_ i: Int) -> Element? {
        guard i >= 0, i < count else { return nil }
        return self[i]
    }
}
