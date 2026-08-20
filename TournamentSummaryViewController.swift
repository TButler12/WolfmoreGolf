//
//  TournamentSummaryViewController.swift
//  WolfmoreGolf
//

import UIKit

// MARK: - Data model

private struct PlayerResult {
    let seat: Int
    let name: String
    let pointsPerHole: [Int?]   // nil = unplayed; index 0..17
    let totalPoints: Int
}

// MARK: - Cell

private final class TournamentResultCell: UITableViewCell {

    private let rankLabel   = UILabel()
    private let nameLabel   = UILabel()
    private let holeLabel   = UILabel()   // compact attributed hole-by-hole string
    private let totalLabel  = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        rankLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        rankLabel.textAlignment = .center
        rankLabel.setContentHuggingPriority(.required, for: .horizontal)

        nameLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        holeLabel.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        holeLabel.textAlignment = .center
        holeLabel.setContentHuggingPriority(.required, for: .horizontal)

        totalLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        totalLabel.textAlignment = .right
        totalLabel.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [rankLabel, nameLabel, holeLabel, totalLabel])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
    }

    func configure(result: PlayerResult, rank: String, isWinner: Bool) {
        rankLabel.text = rank
        nameLabel.text = result.name
        totalLabel.text = "\(result.totalPoints) pts"

        holeLabel.attributedText = makeHoleString(result.pointsPerHole)

        contentView.backgroundColor = isWinner
            ? UIColor.systemYellow.withAlphaComponent(0.22)
            : .systemBackground
    }

    private func makeHoleString(_ pts: [Int?]) -> NSAttributedString {
        let str = NSMutableAttributedString()
        for i in 0..<min(18, pts.count) {
            if i == 9 {
                let divider = NSAttributedString(
                    string: "·",
                    attributes: [.foregroundColor: UIColor.secondaryLabel]
                )
                str.append(divider)
            }
            let val = pts[i] ?? -1
            let ch = val >= 0 ? String(val) : "·"
            let color: UIColor
            switch val {
            case 3...: color = UIColor.systemGreen
            case 2:    color = UIColor.systemGreen.withAlphaComponent(0.65)
            case 1:    color = UIColor.label
            case 0:    color = UIColor.systemRed.withAlphaComponent(0.75)
            default:   color = UIColor.secondaryLabel
            }
            str.append(NSAttributedString(string: ch, attributes: [.foregroundColor: color]))
        }
        return str
    }
}

// MARK: - TournamentSummaryViewController

final class TournamentSummaryViewController: UIViewController {

    private let game: GameData
    private var results: [PlayerResult] = []
    private var didSave = false

    private let tableView = UITableView(frame: .zero, style: .plain)
    private static let cellID = "TournamentResultCell"

    init(game: GameData) {
        self.game = game
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Tournament Results"
        navigationItem.hidesBackButton = true
        view.backgroundColor = .systemBackground

        buildResults()
        buildUI()
    }

    // MARK: - Build results

    private func buildResults() {
        let gm = GameManager.shared
        let committed = game.holeCommitted
        let activeSeats = (0..<min(MAX_PLAYERS, game.playerActivated.count)).filter {
            game.playerActivated[$0] &&
            !(game.playerNames[safe: $0] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        results = activeSeats.map { seat in
            let name = (game.playerNames[safe: seat] ?? "Player \(seat+1)")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let hc = game.hcPlayers[safe: seat] ?? 0

            var pointsPerHole = [Int?](repeating: nil, count: STANDARD_HOLES)
            var total = 0
            for hole in 0..<STANDARD_HOLES {
                guard hole < committed.count && committed[hole] else { continue }
                let par   = game.courseParToPass[safe: hole] ?? 4
                let si    = game.courseHCToPass[safe: hole] ?? (hole + 1)
                let gross = (seat < game.scores.count) ? game.scores[seat][hole] : nil
                if let pts = gm.stablefordPoints(
                    grossScore: gross, par: par, playerHC: hc, strokeIndex: si,
                    baseline: game.stablefordBaseline
                ) {
                    pointsPerHole[hole] = pts
                    total += pts
                }
            }
            return PlayerResult(seat: seat, name: name, pointsPerHole: pointsPerHole, totalPoints: total)
        }
        .sorted { $0.totalPoints > $1.totalPoints }
    }

    // MARK: - Build UI

    private func buildUI() {
        // Header
        let headerStack = buildHeader()

        // Team Score card
        let teamCard = buildTeamScoreCard()

        // Table
        tableView.register(TournamentResultCell.self, forCellReuseIdentifier: Self.cellID)
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 56
        tableView.isScrollEnabled = false
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        // UITableView inside UIStackView doesn't report intrinsic height reliably;
        // pin height explicitly so Auto Layout doesn't collapse the table to zero.
        tableView.heightAnchor.constraint(
            equalToConstant: CGFloat(max(1, results.count)) * 64
        ).isActive = true

        // Button bar
        let saveBtn      = makeButton(title: "Save to History", tint: .systemGreen,  action: #selector(saveTapped))
        let shareBtn     = makeButton(title: "Submit Score",      tint: .systemBlue,   action: #selector(shareTapped))
        let scorecardBtn = makeButton(title: "Scorecard",        tint: .systemIndigo, action: #selector(scorecardTapped))
        let btnRow = UIStackView(arrangedSubviews: [saveBtn, shareBtn, scorecardBtn])
        btnRow.axis = .horizontal
        btnRow.spacing = 10
        btnRow.distribution = .fillEqually

        let doneBtn = makeButton(title: "Done", tint: .systemGray, action: #selector(doneTapped))

        let outer = UIStackView(arrangedSubviews: [headerStack, teamCard, tableView, btnRow, doneBtn])
        outer.axis = .vertical
        outer.spacing = 16
        outer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(outer)

        NSLayoutConstraint.activate([
            outer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            outer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            outer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            outer.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
    }

    private func buildTeamScoreCard() -> UIView {
        // Sum only committed holes; stale prior-round scores exist in game.scores
        // but game.holeCommitted is reset each round.
        let committed = game.holeCommitted
        var teamTotal = 0
        for h in 0..<min(committed.count, STANDARD_HOLES) {
            if committed[h] {
                teamTotal += GameManager.shared.teamHoleScore(hole: h, game: game)
            }
        }

        let titleLabel = UILabel()
        titleLabel.text = "Team Score"
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center

        let totalLabel = UILabel()
        totalLabel.text = "\(teamTotal)"
        totalLabel.font = UIFont.systemFont(ofSize: 44, weight: .bold)
        totalLabel.textAlignment = .center
        totalLabel.textColor = .label

        let subtitleLabel = UILabel()
        let n = game.stablefordCountingPlayers
        subtitleLabel.text = n == 4 ? "All scores count per hole"
                           : "Top \(n) scores per hole"
        subtitleLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [titleLabel, totalLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .center

        let card = UIView()
        card.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)
        card.layer.cornerRadius = 12
        card.translatesAutoresizingMaskIntoConstraints = false

        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
        ])
        return card
    }

    private func buildHeader() -> UIStackView {
        let titleLabel = UILabel()
        titleLabel.text = "Tournament Results"
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textAlignment = .center

        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        let subtitle = "\(game.course.name)  ·  \(fmt.string(from: Date()))"
        let subLabel = UILabel()
        subLabel.text = subtitle
        subLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        subLabel.textColor = .secondaryLabel
        subLabel.textAlignment = .center
        subLabel.numberOfLines = 2

        let stack = UIStackView(arrangedSubviews: [titleLabel, subLabel])
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }

    private func makeButton(title: String, tint: UIColor, action: Selector) -> UIButton {
        var cfg = UIButton.Configuration.tinted()
        cfg.title = title
        cfg.baseBackgroundColor = tint
        cfg.baseForegroundColor = tint
        cfg.cornerStyle = .large
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 8)
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs; a.font = UIFont.systemFont(ofSize: 15, weight: .semibold); return a
        }
        let btn = UIButton(configuration: cfg)
        btn.addTarget(self, action: action, for: .touchUpInside)
        return btn
    }

    // MARK: - Rank helpers

    private func rankString(for index: Int) -> String {
        guard index < results.count else { return "" }
        let pts = results[index].totalPoints
        // tie: same points as index-1 means same rank
        if index > 0 && results[index - 1].totalPoints == pts {
            return rankString(for: index - 1)
        }
        let rank = index + 1
        switch rank {
        case 1:  return "🥇"
        case 2:  return "🥈"
        case 3:  return "🥉"
        default: return "\(rank)"
        }
    }

    private var winnerPoints: Int { results.first?.totalPoints ?? 0 }

    // MARK: - Actions

    @objc private func saveTapped() {
        guard !didSave else {
            let ac = UIAlertController(title: "Already Saved", message: nil, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            return
        }
        print("DEBUG Save tapped — activePlayers: \(GameManager.shared.currentGame?.playerActivated.filter { $0 }.count ?? -1)")
        print("DEBUG Save tapped — playerNames: \(GameManager.shared.currentGame?.playerNames ?? [])")
        RoundStore.shared.recordTournamentGame(game: game)
        didSave = true
        let ac = UIAlertController(title: "Saved ✓", message: "Round saved to history.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    private func computePlayedHoles() -> Range<Int> {
        let committed = game.holeCommitted
        if !committed.isEmpty {
            var maxCommitted = -1
            for h in 0..<min(committed.count, STANDARD_HOLES) {
                if committed[h] { maxCommitted = h }
            }
            if maxCommitted >= 0 { return 0..<(maxCommitted + 1) }
        }
        // Fallback: scan score arrays
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

    @objc private func shareTapped() {
        let image = TournamentScorecardRenderer(game: game, filledHoles: computePlayedHoles()).render()
        let av = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let pop = av.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        present(av, animated: true)
    }

    @objc private func scorecardTapped() {
        let vc = TournamentScorecardViewController(game: game)
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func doneTapped() {
        // Dismiss back to GameViewController, which already sits on the nav stack.
        dismiss(animated: true)
    }


}

// MARK: - UITableViewDataSource

extension TournamentSummaryViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        results.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: Self.cellID, for: indexPath) as! TournamentResultCell
        let r = results[indexPath.row]
        cell.configure(
            result: r,
            rank: rankString(for: indexPath.row),
            isWinner: r.totalPoints == winnerPoints
        )
        return cell
    }
}

// MARK: - RoundStore: save tournament game

extension RoundStore {

    /// Saves each active player's Stableford points in moneyPerHole / totalMoney
    /// so Past Games can display "Tournament · N players · X pts".
    func recordTournamentGame(game g: GameData) {
        print("DEBUG recordTournamentGame called")
        print("DEBUG activePlayers: \(g.playerActivated.filter { $0 }.count)")
        print("DEBUG playerNames: \(g.playerNames)")
        print("DEBUG playerActivated: \(g.playerActivated)")
        print("DEBUG scores[0]: \(g.scores.count > 0 ? String(describing: g.scores[0]) : "MISSING")")
        print("DEBUG scores[1]: \(g.scores.count > 1 ? String(describing: g.scores[1]) : "MISSING")")
        print("DEBUG scores[2]: \(g.scores.count > 2 ? String(describing: g.scores[2]) : "MISSING")")
        print("DEBUG scores[3]: \(g.scores.count > 3 ? String(describing: g.scores[3]) : "MISSING")")

        let sharedGameID = UUID()
        let now = Date()
        let gm  = GameManager.shared

        let capacity = min(g.playerNames.count, g.playerActivated.count)
        let activeSeats = (0..<capacity).filter {
            g.playerActivated[$0] &&
            !g.playerNames[$0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        // Compute courseID the same way Wolf mode does
        let courseIDForRound: String = {
            guard let homeUUID = UUID(uuidString: ProfileStore.homeCourseID),
                  let homeCourse = CourseLibrary.shared.get(id: homeUUID)
            else { return "" }
            let currentPars = Array(g.course.pars.prefix(STANDARD_HOLES))
            let currentHCs  = Array(g.course.holeHandicaps.prefix(STANDARD_HOLES))
            let homePars    = Array(homeCourse.pars.prefix(STANDARD_HOLES))
            let homeHCs     = Array(homeCourse.hcs.prefix(STANDARD_HOLES))
            return (currentPars == homePars && currentHCs == homeHCs)
                ? homeCourse.id.uuidString : ""
        }()

        for seat in activeSeats {
            let name = g.playerNames[seat].trimmingCharacters(in: .whitespacesAndNewlines)
            let hc   = g.hcPlayers[safe: seat] ?? 0

            var ptsPerHole = [Int](repeating: 0, count: STANDARD_HOLES)
            var total = 0
            for hole in 0..<STANDARD_HOLES {
                let par   = g.courseParToPass[safe: hole] ?? 4
                let si    = g.courseHCToPass[safe: hole] ?? (hole + 1)
                let gross = (seat < g.scores.count) ? g.scores[seat][hole] : nil
                let pts   = gm.stablefordPoints(grossScore: gross, par: par, playerHC: hc, strokeIndex: si,
                                                baseline: g.stablefordBaseline) ?? 0
                ptsPerHole[hole] = pts
                total += pts
            }

            let scores: [Int?] = (seat < g.scores.count)
                ? Array(g.scores[seat].prefix(STANDARD_HOLES))
                : Array(repeating: nil, count: STANDARD_HOLES)

            let playedScores = scores.compactMap { $0 }
            let totalScore: Int? = playedScores.isEmpty ? nil : playedScores.reduce(0, +)

            let summary = RoundSummary(
                gameID: sharedGameID,
                date: now,
                courseID: courseIDForRound,
                playerName: name,
                totalMoney: total,
                totalProx: 0,
                totalScore: totalScore,
                holesPlayed: playedScores.count,
                moneyPerHole: ptsPerHole,
                proxPerHole: Array(repeating: false, count: STANDARD_HOLES),
                scorePerHole: scores,
                wolfCalledPerHole: Array(repeating: false, count: STANDARD_HOLES),
                wolfTeamWonPerHole: Array(repeating: false, count: STANDARD_HOLES),
                umbieWonPerHole: Array(repeating: false, count: STANDARD_HOLES),
                gameTypePerHole: Array(repeating: .tournament, count: STANDARD_HOLES)
            )
            add(summary)
        }
    }
}
