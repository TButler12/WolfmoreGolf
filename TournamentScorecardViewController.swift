import UIKit

// MARK: - TournamentScorecardViewController

final class TournamentScorecardViewController: UIViewController {

    private let game: GameData

    // Layout constants
    private let cellH:    CGFloat = 28
    private let strkCellH: CGFloat = 14   // strokes/pops row
    private let nameW:    CGFloat = 92
    private let holeW:    CGFloat = 26
    private let summW:    CGFloat = 34

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
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action, target: self, action: #selector(shareTapped)
        )
        buildUI()
    }

    @objc private func doneTapped() { dismiss(animated: true) }

    @objc private func shareTapped() {
        let image = TournamentScorecardRenderer(game: game, filledHoles: computeFilledHoles()).render()
        let av = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let pop = av.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        present(av, animated: true)
    }

    private func computeFilledHoles() -> Range<Int> {
        let cap = min(game.playerNames.count, game.playerActivated.count)
        var maxFilled = -1
        for seat in 0..<cap {
            guard game.playerActivated[seat], seat < game.scores.count else { continue }
            for h in 0..<STANDARD_HOLES where h < game.scores[seat].count {
                if game.scores[seat][h] != nil { maxFilled = max(maxFilled, h) }
            }
        }
        return maxFilled >= 0 ? 0..<(maxFilled + 1) : 0..<0
    }

    // MARK: - Row kinds

    private enum RowKind { case header, par, player, playerGross, playerStrokes, team }

    private func rowBackground(_ kind: RowKind, altRow: Bool) -> UIColor {
        switch kind {
        case .header:         return .systemGray5
        case .par:            return .systemGray6
        case .player:         return altRow ? UIColor.systemGray6.withAlphaComponent(0.45) : .systemBackground
        case .playerGross:    return altRow ? UIColor.systemGray6.withAlphaComponent(0.45) : .systemBackground
        case .playerStrokes:  return altRow ? UIColor.systemGray6.withAlphaComponent(0.45) : .systemBackground
        case .team:           return UIColor.systemBlue.withAlphaComponent(0.07)
        }
    }

    // MARK: - Cell factory

    private func makeLabel(
        text: String,
        width: CGFloat,
        kind: RowKind,
        altRow: Bool = false,
        pts: Int? = nil,
        isSummary: Bool = false,
        height: CGFloat? = nil
    ) -> UILabel {
        let h = height ?? cellH
        let lbl = UILabel()
        lbl.text = text
        lbl.textAlignment = .center
        lbl.adjustsFontSizeToFitWidth = true
        lbl.minimumScaleFactor = 0.75
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.widthAnchor.constraint(equalToConstant: width).isActive = true
        lbl.heightAnchor.constraint(equalToConstant: h).isActive = true

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

        case .playerGross:
            lbl.font = .systemFont(ofSize: 10, weight: .regular)
            lbl.textColor = (text == "·" || text == "—") ? .tertiaryLabel : .secondaryLabel

        case .playerStrokes:
            lbl.font = .systemFont(ofSize: 10, weight: .regular)
            lbl.textColor = UIColor(red: 0.20, green: 0.45, blue: 0.80, alpha: 0.85)

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
        let players: [(seat: Int, name: String, hc: Int)] = (0..<capacity).compactMap { seat in
            guard game.playerActivated[seat] else { return nil }
            let n = game.playerNames[seat].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !n.isEmpty else { return nil }
            let hc = game.hcPlayers[safe: seat] ?? 0
            return (seat, n, hc)
        }

        // Per-hole Stableford pts [playerIdx][holeIdx], nil = unplayed
        let gm = GameManager.shared
        let playerPts: [[Int?]] = players.map { (seat, _, hc) in
            (0..<STANDARD_HOLES).map { h in
                let par   = game.courseParToPass[safe: h] ?? 4
                let si    = game.courseHCToPass[safe: h] ?? (h + 1)
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

        // Gross scores per player per hole [playerIdx][holeIdx]
        let playerGross: [[Int?]] = players.map { (seat, _, _) in
            (0..<STANDARD_HOLES).map { h in
                (seat < game.scores.count) ? game.scores[seat][h] : nil
            }
        }

        // Strokes received per player per hole [playerIdx][holeIdx]
        func strokesOnHole(hc: Int, si: Int) -> Int {
            guard hc > 0 else { return 0 }
            return hc / 18 + (si <= hc % 18 ? 1 : 0)
        }
        let playerStrokes: [[Int]] = players.map { (_, _, hc) in
            (0..<STANDARD_HOLES).map { h in
                strokesOnHole(hc: hc, si: game.courseHCToPass[safe: h] ?? (h + 1))
            }
        }

        // Column spec
        struct Col {
            let header: String; let width: CGFloat; let isSummary: Bool
            let parText: String
            let playerVals: [Int?]      // Stableford points
            let playerGrossVals: [Int?] // Gross scores (nil for summary cols)
            let playerStrokesVals: [Int]// Strokes on hole (0 for summary cols)
            let teamVal: Int?
        }

        var cols: [Col] = []
        for h in 0..<9 {
            cols.append(Col(header: "\(h+1)", width: holeW, isSummary: false,
                parText: "\(pars[h])",
                playerVals: playerPts.map { $0[h] },
                playerGrossVals: playerGross.map { $0[h] },
                playerStrokesVals: playerStrokes.map { $0[h] },
                teamVal: teamPts[h]))
        }
        cols.append(Col(header: "OUT", width: summW, isSummary: true,
            parText: "\(front.reduce(0){$0+pars[$1]})",
            playerVals: playerPts.map { rangeSum($0, front) },
            playerGrossVals: Array(repeating: nil, count: players.count),
            playerStrokesVals: Array(repeating: 0, count: players.count),
            teamVal: rangeSum(teamPts, front)))
        for h in 9..<18 {
            cols.append(Col(header: "\(h+1)", width: holeW, isSummary: false,
                parText: "\(pars[h])",
                playerVals: playerPts.map { $0[h] },
                playerGrossVals: playerGross.map { $0[h] },
                playerStrokesVals: playerStrokes.map { $0[h] },
                teamVal: teamPts[h]))
        }
        cols.append(Col(header: "IN", width: summW, isSummary: true,
            parText: "\(back.reduce(0){$0+pars[$1]})",
            playerVals: playerPts.map { rangeSum($0, back) },
            playerGrossVals: Array(repeating: nil, count: players.count),
            playerStrokesVals: Array(repeating: 0, count: players.count),
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
            playerVals: totPlayerVals,
            playerGrossVals: Array(repeating: nil, count: players.count),
            playerStrokesVals: Array(repeating: 0, count: players.count),
            teamVal: totTeam))

        // ── Names column (fixed, non-scrolling) ──────────────────────
        // Layout: header, par, [pts row, gross row, strokes row] × N, team

        let nameCol = UIStackView()
        nameCol.axis = .vertical
        nameCol.spacing = 1
        nameCol.translatesAutoresizingMaskIntoConstraints = false

        func addNameLabel(_ text: String, kind: RowKind, altRow: Bool = false, height: CGFloat? = nil) {
            let h = height ?? cellH
            let lbl = UILabel()
            lbl.text = text
            lbl.adjustsFontSizeToFitWidth = true
            lbl.minimumScaleFactor = 0.7
            lbl.lineBreakMode = .byTruncatingTail
            lbl.numberOfLines = 1
            lbl.backgroundColor = rowBackground(kind, altRow: altRow)
            lbl.translatesAutoresizingMaskIntoConstraints = false
            lbl.widthAnchor.constraint(equalToConstant: nameW).isActive = true
            lbl.heightAnchor.constraint(equalToConstant: h).isActive = true
            switch kind {
            case .header:
                lbl.font = .systemFont(ofSize: 10, weight: .semibold); lbl.textColor = .label
            case .par:
                lbl.font = .systemFont(ofSize: 11, weight: .semibold); lbl.textColor = .secondaryLabel
            case .player:
                lbl.font = .systemFont(ofSize: 11, weight: .regular); lbl.textColor = .label
            case .playerGross:
                lbl.font = .systemFont(ofSize: 10, weight: .regular); lbl.textColor = .tertiaryLabel
            case .playerStrokes:
                lbl.font = .systemFont(ofSize: 9, weight: .regular); lbl.textColor = .tertiaryLabel
            case .team:
                lbl.font = .systemFont(ofSize: 11, weight: .bold); lbl.textColor = .systemBlue
            }
            nameCol.addArrangedSubview(lbl)
        }

        addNameLabel("", kind: .header)
        addNameLabel("Par", kind: .par)
        for (pi, p) in players.enumerated() {
            let alt = pi % 2 == 0
            addNameLabel(p.name,       kind: .player,        altRow: alt)
            addNameLabel("HC=\(p.hc)", kind: .playerGross,   altRow: alt)
            addNameLabel("",           kind: .playerStrokes, altRow: alt, height: strkCellH)
        }
        addNameLabel("Team", kind: .team)

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
            // Players: points row + gross row + strokes row
            for (pi, pv) in col.playerVals.enumerated() {
                let alt = pi % 2 == 0
                // Stableford points row
                colStack.addArrangedSubview(makeLabel(
                    text: pv.map(String.init) ?? "·",
                    width: col.width, kind: .player,
                    altRow: alt, pts: pv, isSummary: col.isSummary))
                // Gross score row
                let gv = pi < col.playerGrossVals.count ? col.playerGrossVals[pi] : nil
                let grossText = col.isSummary ? "—" : (gv.map(String.init) ?? "·")
                colStack.addArrangedSubview(makeLabel(
                    text: grossText,
                    width: col.width, kind: .playerGross,
                    altRow: alt, isSummary: col.isSummary))
                // Strokes/pops row
                let sv = pi < col.playerStrokesVals.count ? col.playerStrokesVals[pi] : 0
                let dotsText = col.isSummary ? "" : (sv > 0 ? String(repeating: "•", count: sv) : "")
                colStack.addArrangedSubview(makeLabel(
                    text: dotsText,
                    width: col.width, kind: .playerStrokes,
                    altRow: alt, isSummary: col.isSummary, height: strkCellH))
            }
            // Team
            colStack.addArrangedSubview(makeLabel(
                text: col.teamVal.map(String.init) ?? "·",
                width: col.width, kind: .team, pts: col.teamVal, isSummary: col.isSummary))

            scoreGrid.addArrangedSubview(colStack)
        }

        // header + par + (pts + gross + strokes) × N + team
        let perPlayerH = cellH + cellH + strkCellH
        let fixedH     = cellH + cellH + cellH  // header + par + team
        let gridH      = fixedH + CGFloat(players.count) * perPlayerH
                       + CGFloat(2 + players.count * 3) * 1  // spacing

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
