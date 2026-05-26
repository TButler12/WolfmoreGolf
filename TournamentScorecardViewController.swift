import UIKit

// MARK: - TournamentScorecardViewController

final class TournamentScorecardViewController: UIViewController {

    private let game: GameData

    // Layout constants
    private let cellH: CGFloat = 28
    private let nameW: CGFloat = 92
    private let holeW: CGFloat = 26
    private let summW: CGFloat = 34

    init(game: GameData) {
        self.game = game
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Scorecard"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(doneTapped)
        )
        buildUI()
    }

    @objc private func doneTapped() { dismiss(animated: true) }

    // MARK: - Row kinds

    private enum RowKind { case header, par, player, team }

    private func rowBackground(_ kind: RowKind, altRow: Bool) -> UIColor {
        switch kind {
        case .header: return .systemGray5
        case .par:    return .systemGray6
        case .player: return altRow ? UIColor.systemGray6.withAlphaComponent(0.45) : .systemBackground
        case .team:   return UIColor.systemBlue.withAlphaComponent(0.07)
        }
    }

    // MARK: - Cell factory

    private func makeLabel(
        text: String,
        width: CGFloat,
        kind: RowKind,
        altRow: Bool = false,
        pts: Int? = nil,
        isSummary: Bool = false
    ) -> UILabel {
        let lbl = UILabel()
        lbl.text = text
        lbl.textAlignment = .center
        lbl.adjustsFontSizeToFitWidth = true
        lbl.minimumScaleFactor = 0.75
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.widthAnchor.constraint(equalToConstant: width).isActive = true
        lbl.heightAnchor.constraint(equalToConstant: cellH).isActive = true

        lbl.backgroundColor = isSummary
            ? (kind == .team ? UIColor.systemBlue.withAlphaComponent(0.07) : .systemGray5)
            : rowBackground(kind, altRow: altRow)

        switch kind {
        case .header:
            lbl.font = .systemFont(ofSize: 10, weight: .semibold)
            lbl.textColor = .label

        case .par:
            lbl.font = .systemFont(ofSize: 11, weight: isSummary ? .semibold : .regular)
            lbl.textColor = .secondaryLabel

        case .player:
            lbl.font = .systemFont(ofSize: 11, weight: isSummary ? .semibold : .regular)
            if let p = pts, !isSummary {
                switch p {
                case 3...: lbl.textColor = .systemGreen
                case 2:    lbl.textColor = UIColor.systemGreen.withAlphaComponent(0.65)
                case 1:    lbl.textColor = .label
                default:   lbl.textColor = UIColor.systemRed.withAlphaComponent(0.75)
                }
            } else {
                lbl.textColor = (text == "·") ? .secondaryLabel : .label
            }

        case .team:
            lbl.font = .systemFont(ofSize: 11, weight: .semibold)
            lbl.textColor = (text == "·") ? .secondaryLabel : .systemBlue
        }

        return lbl
    }

    // MARK: - Build UI

    private func buildUI() {

        // Active players in seat order
        let capacity = min(game.playerNames.count, game.playerActivated.count)
        let players: [(seat: Int, name: String)] = (0..<capacity).compactMap { seat in
            guard game.playerActivated[seat] else { return nil }
            let n = game.playerNames[seat].trimmingCharacters(in: .whitespacesAndNewlines)
            return n.isEmpty ? nil : (seat, n)
        }

        // Per-hole Stableford pts [playerIdx][holeIdx], nil = unplayed
        let gm = GameManager.shared
        let playerPts: [[Int?]] = players.map { (seat, _) in
            (0..<STANDARD_HOLES).map { h in
                let par  = game.courseParToPass[safe: h] ?? 4
                let si   = game.courseHCToPass[safe: h] ?? (h + 1)
                let hc   = game.hcPlayers[safe: seat] ?? 0
                let gross = (seat < game.scores.count) ? game.scores[seat][h] : nil
                return gm.stablefordPoints(grossScore: gross, par: par, playerHC: hc, strokeIndex: si)
            }
        }

        // Team pts per hole: top-3 sum, nil if no scores yet
        let teamPts: [Int?] = (0..<STANDARD_HOLES).map { h in
            let pts = playerPts.compactMap { $0[h] }
            return pts.isEmpty ? nil : pts.sorted(by: >).prefix(3).reduce(0, +)
        }

        let pars = (0..<STANDARD_HOLES).map { game.courseParToPass[safe: $0] ?? 4 }
        let front = Array(0..<9)
        let back  = Array(9..<18)

        func rangeSum(_ vals: [Int?], _ range: [Int]) -> Int? {
            let v = range.compactMap { vals[$0] }
            return v.isEmpty ? nil : v.reduce(0, +)
        }

        // Column spec: header, width, isSummary, parText, playerVals, teamVal
        struct Col {
            let header: String; let width: CGFloat; let isSummary: Bool
            let parText: String; let playerVals: [Int?]; let teamVal: Int?
        }

        var cols: [Col] = []
        for h in 0..<9 {
            cols.append(Col(header: "\(h+1)", width: holeW, isSummary: false,
                parText: "\(pars[h])",
                playerVals: playerPts.map { $0[h] }, teamVal: teamPts[h]))
        }
        cols.append(Col(header: "OUT", width: summW, isSummary: true,
            parText: "\(front.reduce(0){$0+pars[$1]})",
            playerVals: playerPts.map { rangeSum($0, front) },
            teamVal: rangeSum(teamPts, front)))
        for h in 9..<18 {
            cols.append(Col(header: "\(h+1)", width: holeW, isSummary: false,
                parText: "\(pars[h])",
                playerVals: playerPts.map { $0[h] }, teamVal: teamPts[h]))
        }
        cols.append(Col(header: "IN", width: summW, isSummary: true,
            parText: "\(back.reduce(0){$0+pars[$1]})",
            playerVals: playerPts.map { rangeSum($0, back) },
            teamVal: rangeSum(teamPts, back)))

        let totPlayerVals: [Int?] = playerPts.map { row in
            let f = rangeSum(row, front), b = rangeSum(row, back)
            return (f == nil && b == nil) ? nil : (f ?? 0) + (b ?? 0)
        }
        let totTeam: Int? = {
            let f = rangeSum(teamPts, front), b = rangeSum(teamPts, back)
            return (f == nil && b == nil) ? nil : (f ?? 0) + (b ?? 0)
        }()
        cols.append(Col(header: "TOT", width: summW + 4, isSummary: true,
            parText: "\(pars.reduce(0,+))",
            playerVals: totPlayerVals, teamVal: totTeam))

        // ── Names column (fixed, non-scrolling) ──────────────────────

        let nameRows: [(text: String, kind: RowKind)] =
            [("", .header), ("Par", .par)]
            + players.map { ($0.name, .player) }
            + [("Team", .team)]

        let nameCol = UIStackView()
        nameCol.axis = .vertical
        nameCol.spacing = 1
        nameCol.translatesAutoresizingMaskIntoConstraints = false

        for (i, row) in nameRows.enumerated() {
            let lbl = UILabel()
            lbl.text = (row.kind == .header) ? "" : row.text
            lbl.adjustsFontSizeToFitWidth = true
            lbl.minimumScaleFactor = 0.7
            lbl.lineBreakMode = .byTruncatingTail
            lbl.numberOfLines = 1

            let isPlayer = row.kind == .player
            let playerIdx = i - 2
            let altRow = isPlayer && playerIdx % 2 == 0

            lbl.backgroundColor = rowBackground(row.kind, altRow: altRow)

            switch row.kind {
            case .header:
                lbl.font = .systemFont(ofSize: 10, weight: .semibold)
                lbl.textColor = .label
            case .par:
                lbl.font = .systemFont(ofSize: 11, weight: .semibold)
                lbl.textColor = .secondaryLabel
            case .player:
                lbl.font = .systemFont(ofSize: 11, weight: .regular)
                lbl.textColor = .label
            case .team:
                lbl.font = .systemFont(ofSize: 11, weight: .bold)
                lbl.textColor = .systemBlue
            }

            lbl.translatesAutoresizingMaskIntoConstraints = false
            lbl.widthAnchor.constraint(equalToConstant: nameW).isActive = true
            lbl.heightAnchor.constraint(equalToConstant: cellH).isActive = true
            nameCol.addArrangedSubview(lbl)
        }

        // ── Score columns (inside UIScrollView) ──────────────────────

        let scoreGrid = UIStackView()
        scoreGrid.axis = .horizontal
        scoreGrid.spacing = 1
        scoreGrid.translatesAutoresizingMaskIntoConstraints = false

        for col in cols {
            let colStack = UIStackView()
            colStack.axis = .vertical
            colStack.spacing = 1

            // Header
            colStack.addArrangedSubview(makeLabel(
                text: col.header, width: col.width, kind: .header, isSummary: col.isSummary))
            // Par
            colStack.addArrangedSubview(makeLabel(
                text: col.parText, width: col.width, kind: .par, isSummary: col.isSummary))
            // Players
            for (pi, pv) in col.playerVals.enumerated() {
                colStack.addArrangedSubview(makeLabel(
                    text: pv.map(String.init) ?? "·",
                    width: col.width, kind: .player,
                    altRow: pi % 2 == 0, pts: pv, isSummary: col.isSummary))
            }
            // Team
            colStack.addArrangedSubview(makeLabel(
                text: col.teamVal.map(String.init) ?? "·",
                width: col.width, kind: .team, pts: col.teamVal, isSummary: col.isSummary))

            scoreGrid.addArrangedSubview(colStack)
        }

        let totalRows = 2 + players.count + 1
        let gridH = CGFloat(totalRows) * cellH + CGFloat(totalRows - 1) * 1

        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(scoreGrid)
        scrollView.heightAnchor.constraint(equalToConstant: gridH).isActive = true

        NSLayoutConstraint.activate([
            scoreGrid.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            scoreGrid.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            scoreGrid.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            scoreGrid.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            scoreGrid.heightAnchor.constraint(equalToConstant: gridH),
        ])

        // ── Subtitle ──────────────────────────────────────────────────

        let fmt = DateFormatter(); fmt.dateStyle = .medium; fmt.timeStyle = .none
        let subtitle = UILabel()
        subtitle.text = "\(game.course.name)  ·  \(fmt.string(from: Date()))"
        subtitle.font = .preferredFont(forTextStyle: .caption1)
        subtitle.textColor = .secondaryLabel
        subtitle.textAlignment = .center
        subtitle.adjustsFontSizeToFitWidth = true
        subtitle.minimumScaleFactor = 0.8
        subtitle.translatesAutoresizingMaskIntoConstraints = false

        // ── Layout ────────────────────────────────────────────────────

        let gridRow = UIStackView(arrangedSubviews: [nameCol, scrollView])
        gridRow.axis = .horizontal
        gridRow.spacing = 1
        gridRow.alignment = .top
        gridRow.translatesAutoresizingMaskIntoConstraints = false

        let outer = UIStackView(arrangedSubviews: [subtitle, gridRow])
        outer.axis = .vertical
        outer.spacing = 10
        outer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(outer)

        NSLayoutConstraint.activate([
            outer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            outer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            outer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
        ])
    }
}
