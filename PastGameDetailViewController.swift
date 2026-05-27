import UIKit

// MARK: - File-private helpers

private func relativeDate(_ date: Date) -> String {
    let cal = Calendar.current
    let now = Date()
    if cal.isDateInToday(date)     { return "Today" }
    if cal.isDateInYesterday(date) { return "Yesterday" }
    let days = cal.dateComponents([.day],
        from: cal.startOfDay(for: date),
        to:   cal.startOfDay(for: now)).day ?? 0
    if days < 7 { return fmtDate("EEEE", date) }
    if cal.component(.year, from: date) != cal.component(.year, from: now) {
        return fmtDate("MMM d, yyyy", date)
    }
    return fmtDate("EEE MMM d", date)
}

private func fmtDate(_ format: String, _ date: Date) -> String {
    let f = DateFormatter(); f.dateFormat = format; return f.string(from: date)
}

// MARK: - PlayerRow

private struct PlayerRow {
    let rank:       Int
    let name:       String
    let totalScore: Int?
    let totalMoney: Int
    let totalProx:  Int
    let scores:     [Int?]   // 18 gross scores
    let points:     [Int?]   // 18 Stableford pts (nil for non-tournament holes)
    let isMe:       Bool
    let fairways:   [Bool?]  // 18 elements
    let girs:       [Bool?]  // 18 elements
    let putts:      [Int?]   // 18 elements

    var firPct: String? {
        let v = fairways.compactMap { $0 }
        guard !v.isEmpty else { return nil }
        return "\(Int(round(Double(v.filter { $0 }.count) / Double(v.count) * 100)))%"
    }
    var girPct: String? {
        let v = girs.compactMap { $0 }
        guard !v.isEmpty else { return nil }
        return "\(Int(round(Double(v.filter { $0 }.count) / Double(v.count) * 100)))%"
    }
    var puttTotal: Int? {
        let v = putts.compactMap { $0 }
        return v.isEmpty ? nil : v.reduce(0, +)
    }
    var hasStats: Bool { firPct != nil || girPct != nil || puttTotal != nil }
}

// MARK: - DetailHeaderCell

private final class DetailHeaderCell: UITableViewCell {
    private let courseLabel = UILabel()
    private let dateLabel   = UILabel()
    private let metaLabel   = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        courseLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        courseLabel.adjustsFontForContentSizeCategory = true
        courseLabel.numberOfLines = 0

        for lbl in [dateLabel, metaLabel] {
            lbl.font = UIFont.preferredFont(forTextStyle: .subheadline)
            lbl.adjustsFontForContentSizeCategory = true
            lbl.textColor = .secondaryLabel
        }

        let stack = UIStackView(arrangedSubviews: [courseLabel, dateLabel, metaLabel])
        stack.axis    = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(courseName: String, date: Date, playerCount: Int, holesPlayed: Int) {
        courseLabel.text = courseName
        dateLabel.text   = relativeDate(date)
        let p = playerCount == 1 ? "1 player" : "\(playerCount) players"
        metaLabel.text   = "\(p) · \(holesPlayed) holes played"
    }
}

// MARK: - LeaderboardCell

private final class LeaderboardCell: UITableViewCell {
    private let rankLabel  = UILabel()
    private let nameLabel  = UILabel()
    private let scoreLabel = UILabel()
    private let moneyLabel = UILabel()
    private let proxLabel  = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        for lbl in [rankLabel, nameLabel, scoreLabel, moneyLabel, proxLabel] {
            lbl.font = UIFont.preferredFont(forTextStyle: .body)
            lbl.adjustsFontForContentSizeCategory = true
        }
        rankLabel.textAlignment  = .center
        scoreLabel.textAlignment = .center
        moneyLabel.textAlignment = .right
        proxLabel.textAlignment  = .center

        // Name truncates first so numeric columns always display in full
        nameLabel.lineBreakMode = .byTruncatingTail

        let stack = UIStackView(arrangedSubviews: [rankLabel, nameLabel, scoreLabel, moneyLabel, proxLabel])
        stack.axis    = .horizontal
        stack.spacing = 8   // separates rank from name
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            rankLabel.widthAnchor.constraint(equalToConstant: 28),
            scoreLabel.widthAnchor.constraint(equalToConstant: 36),
            moneyLabel.widthAnchor.constraint(equalToConstant: 68),
            proxLabel.widthAnchor.constraint(equalToConstant: 28),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with row: PlayerRow, isTournament: Bool = false) {
        rankLabel.text  = "#\(row.rank)"
        nameLabel.text  = row.isMe ? "\(row.name) (You)" : row.name

        if isTournament {
            scoreLabel.text      = row.totalScore.map { "\($0)" } ?? "—"
            scoreLabel.textColor = .secondaryLabel
            let pts = row.totalMoney
            moneyLabel.text      = "\(pts) pts"
            moneyLabel.textColor = pts > 0 ? .systemGreen : .secondaryLabel
            proxLabel.text       = ""
        } else {
            scoreLabel.text = row.totalScore.map { "\($0)" } ?? "—"
            scoreLabel.textColor = .label
            let m = row.totalMoney
            if m > 0 {
                moneyLabel.text      = "$\(m)"
                moneyLabel.textColor = .systemGreen
            } else if m < 0 {
                moneyLabel.text      = "$\(abs(m))"
                moneyLabel.textColor = .systemRed
            } else {
                moneyLabel.text      = "$0"
                moneyLabel.textColor = .secondaryLabel
            }
            proxLabel.text = "\(row.totalProx)"
        }

        contentView.backgroundColor = row.isMe
            ? UIColor.systemYellow.withAlphaComponent(0.15)
            : nil
    }
}

// MARK: - ScorecardCell

private final class ScorecardCell: UITableViewCell {
    private let outerStack = UIStackView()

    // Fixed column widths — chosen to fit two 9-column grids on any iPhone width
    private let nameColW:  CGFloat = 56
    private let holeColW:  CGFloat = 26
    private let totalColW: CGFloat = 34

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        outerStack.axis    = .vertical
        outerStack.spacing = 16
        outerStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(outerStack)
        NSLayoutConstraint.activate([
            outerStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            outerStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            // trailingAnchor is not pinned — grid width is determined by fixed column widths
            outerStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        outerStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }

    func configure(players: [PlayerRow], pars: [Int]?,
                   isTournament: Bool = false, teamPts: [Int?] = []) {
        outerStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        outerStack.addArrangedSubview(makeHalf("Front 9", 0..<9,  "Out", players, pars,
                                               isTournament: isTournament, teamPts: teamPts))
        let div = UIView()
        div.backgroundColor = .separator
        div.heightAnchor.constraint(equalToConstant: 1).isActive = true
        outerStack.addArrangedSubview(div)
        outerStack.addArrangedSubview(makeHalf("Back 9",  9..<18, "In",  players, pars,
                                               isTournament: isTournament, teamPts: teamPts))
    }

    // MARK: Grid builders

    private func makeHalf(_ title: String,
                          _ range: Range<Int>,
                          _ totalLabel: String,
                          _ players: [PlayerRow],
                          _ pars: [Int]?,
                          isTournament: Bool = false,
                          teamPts: [Int?] = []) -> UIView {
        let vStack = UIStackView()
        vStack.axis    = .vertical
        vStack.spacing = 1

        // "Front 9" / "Back 9" label
        let titleLbl = UILabel()
        titleLbl.text      = title
        titleLbl.font      = UIFont.preferredFont(forTextStyle: .caption1)
        titleLbl.textColor = .secondaryLabel
        titleLbl.adjustsFontForContentSizeCategory = true
        vStack.addArrangedSubview(titleLbl)
        vStack.setCustomSpacing(4, after: titleLbl)

        // Hole number header row — "Pts" label for tournament
        let holeNums = Array(range).map { "\($0 + 1)" } + [totalLabel]
        let headerName = isTournament ? "Pts" : ""
        vStack.addArrangedSubview(makeRow(headerName, holeNums, color: .secondaryLabel, bold: false))

        // Par row
        let parVals: [String]
        if let p = pars, p.count == 18 {
            let slice = Array(p[range])
            parVals = slice.map { "\($0)" } + ["\(slice.reduce(0, +))"]
        } else {
            parVals = Array(repeating: "—", count: range.count + 1)
        }
        vStack.addArrangedSubview(makeRow("Par", parVals, color: .secondaryLabel, bold: false))

        // Thin separator below par row
        let sep = UIView()
        sep.backgroundColor = .separator
        sep.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        vStack.addArrangedSubview(sep)
        vStack.setCustomSpacing(2, after: sep)

        // One row per player
        for player in players {
            if isTournament {
                guard player.points.count == STANDARD_HOLES else { continue }
                let slice    = Array(player.points[range])
                let vals     = slice.map { p -> String in p.map { "\($0)" } ?? "·" }
                let subtotal = slice.compactMap { $0 }.reduce(0, +)
                let totStr   = slice.contains(where: { $0 != nil }) ? "\(subtotal)" : "·"
                vStack.addArrangedSubview(
                    makeRow(player.name, vals + [totStr], color: .label, bold: player.isMe)
                )
            } else {
                guard player.scores.count == STANDARD_HOLES else { continue }
                let slice    = Array(player.scores[range])
                let vals     = slice.map { s -> String in s.map { "\($0)" } ?? "—" }
                let subtotal = slice.compactMap { $0 }.reduce(0, +)
                let totStr   = slice.contains(where: { $0 != nil }) ? "\(subtotal)" : "—"
                vStack.addArrangedSubview(
                    makeRow(player.name, vals + [totStr], color: .label, bold: player.isMe)
                )
            }
        }

        // Team row (tournament only)
        if isTournament && teamPts.count == STANDARD_HOLES {
            let slice    = Array(teamPts[range])
            let vals     = slice.map { p -> String in p.map { "\($0)" } ?? "·" }
            let subtotal = slice.compactMap { $0 }.reduce(0, +)
            let totStr   = slice.contains(where: { $0 != nil }) ? "\(subtotal)" : "·"
            vStack.addArrangedSubview(
                makeRow("Team", vals + [totStr], color: .systemBlue, bold: true)
            )
        }

        return vStack
    }

    private func makeRow(_ label: String,
                         _ values: [String],
                         color: UIColor,
                         bold: Bool) -> UIView {
        let hStack = UIStackView()
        hStack.axis      = .horizontal
        hStack.spacing   = 0
        hStack.alignment = .center

        let font: UIFont = bold
            ? UIFont.monospacedSystemFont(ofSize: 12, weight: .semibold)
            : UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)

        let nameLbl = UILabel()
        nameLbl.text              = label
        nameLbl.font              = font
        nameLbl.textColor         = color
        nameLbl.lineBreakMode     = .byTruncatingTail
        nameLbl.widthAnchor.constraint(equalToConstant: nameColW).isActive = true
        hStack.addArrangedSubview(nameLbl)

        for (i, val) in values.enumerated() {
            let lbl = UILabel()
            lbl.text          = val
            lbl.font          = font
            lbl.textColor     = color
            lbl.textAlignment = .center
            let w = (i == values.count - 1) ? totalColW : holeColW
            lbl.widthAnchor.constraint(equalToConstant: w).isActive = true
            hStack.addArrangedSubview(lbl)
        }
        return hStack
    }
}

// MARK: - StatsRowCell

private final class StatsRowCell: UITableViewCell {
    private let nameLabel  = UILabel()
    private let firLabel   = UILabel()
    private let girLabel   = UILabel()
    private let puttsLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        nameLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        nameLabel.adjustsFontForContentSizeCategory = true

        for lbl in [firLabel, girLabel, puttsLabel] {
            lbl.font      = UIFont.preferredFont(forTextStyle: .subheadline)
            lbl.textColor = .secondaryLabel
            lbl.textAlignment = .center
            lbl.adjustsFontForContentSizeCategory = true
        }

        let stack = UIStackView(arrangedSubviews: [nameLabel, firLabel, girLabel, puttsLabel])
        stack.axis    = .horizontal
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            firLabel.widthAnchor.constraint(equalToConstant: 68),
            girLabel.widthAnchor.constraint(equalToConstant: 68),
            puttsLabel.widthAnchor.constraint(equalToConstant: 72),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with row: PlayerRow) {
        nameLabel.text  = row.isMe ? "\(row.name) (You)" : row.name
        firLabel.text   = row.firPct.map   { "FIR \($0)" }    ?? "FIR —"
        girLabel.text   = row.girPct.map   { "GIR \($0)" }    ?? "GIR —"
        puttsLabel.text = row.puttTotal.map { "\($0) putts" }  ?? "— putts"
    }
}

// MARK: - PastGameDetailViewController

final class PastGameDetailViewController: UIViewController {

    private let allRows:  [RoundSummary]
    private let courseID: String

    private var playerRows:   [PlayerRow] = []
    private var pars:         [Int]?
    private var courseName:   String  = "Unknown Course"
    private var roundDate:    Date    = Date()
    private var holesPlayed:  Int     = 0
    private var hasStats:     Bool    = false
    private var isTournament: Bool    = false
    private var teamPts:      [Int?]  = []

    private let tableView = UITableView(frame: .zero, style: .grouped)

    private enum CellID {
        static let header      = "DetailHeader"
        static let leaderboard = "Leaderboard"
        static let scorecard   = "Scorecard"
        static let stats       = "Stats"
    }

    // MARK: - Init

    init(rows: [RoundSummary], courseID: String) {
        self.allRows  = rows
        self.courseID = courseID
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Round Detail"
        view.backgroundColor = .systemGroupedBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(deleteTapped)
        )
        navigationItem.rightBarButtonItem?.tintColor = .systemRed

        buildData()
        setupTable()
    }

    // MARK: - Delete

    @objc private func deleteTapped() {
        let ac = UIAlertController(
            title: "Delete this round?",
            message: "This permanently removes the round from your history. This cannot be undone.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.performDelete()
        })
        present(ac, animated: true)
    }

    private func performDelete() {
        guard let gameID = allRows.first?.gameID else { return }
        RoundStore.shared.deleteGame(gameID: gameID)
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Data

    private func buildData() {
        guard let first = allRows.first else { return }
        roundDate    = first.date
        holesPlayed  = allRows.map { $0.holesPlayed }.max() ?? 0
        isTournament = first.gameTypePerHole?.first == .tournament

        if let uid = UUID(uuidString: courseID),
           let profile = CourseLibrary.shared.get(id: uid) {
            courseName = profile.name
            pars = profile.pars.count == 18 ? profile.pars : nil
        }

        let me = (ProfileStore.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let sorted = allRows.sorted { $0.totalMoney > $1.totalMoney }

        playerRows = sorted.enumerated().map { idx, r in
            let isMe = !me.isEmpty &&
                r.playerName.trimmingCharacters(in: .whitespacesAndNewlines)
                    .caseInsensitiveCompare(me) == .orderedSame

            let pts: [Int?] = isTournament
                ? (0..<STANDARD_HOLES).map { h in
                    guard h < r.scorePerHole.count, r.scorePerHole[h] != nil,
                          h < r.moneyPerHole.count else { return nil }
                    return r.moneyPerHole[h]
                }
                : Array(repeating: nil, count: STANDARD_HOLES)

            func pad<T>(_ arr: [T], with fill: T) -> [T] {
                arr.count >= STANDARD_HOLES ? Array(arr.prefix(STANDARD_HOLES))
                    : arr + Array(repeating: fill, count: STANDARD_HOLES - arr.count)
            }

            return PlayerRow(
                rank:       idx + 1,
                name:       r.playerName,
                totalScore: r.totalScore,
                totalMoney: r.totalMoney,
                totalProx:  r.totalProx,
                scores:     pad(r.scorePerHole,       with: nil),
                points:     pts,
                isMe:       isMe,
                fairways:   pad(r.fairwayHitPerHole,  with: nil),
                girs:       pad(r.girPerHole,          with: nil),
                putts:      pad(r.puttsPerHole,        with: nil)
            )
        }

        if isTournament {
            teamPts = (0..<STANDARD_HOLES).map { h in
                let holePts: [Int] = playerRows.compactMap { row in
                    guard h < row.points.count else { return nil }
                    return row.points[h]
                }
                return holePts.isEmpty ? nil : holePts.sorted(by: >).prefix(3).reduce(0, +)
            }
        }

        hasStats = !isTournament && playerRows.contains { $0.hasStats }
    }

    // MARK: - Table setup

    private func setupTable() {
        tableView.register(DetailHeaderCell.self,  forCellReuseIdentifier: CellID.header)
        tableView.register(LeaderboardCell.self,   forCellReuseIdentifier: CellID.leaderboard)
        tableView.register(ScorecardCell.self,     forCellReuseIdentifier: CellID.scorecard)
        tableView.register(StatsRowCell.self,      forCellReuseIdentifier: CellID.stats)
        tableView.dataSource         = self
        tableView.delegate           = self
        tableView.rowHeight          = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private var sectionCount: Int { hasStats ? 4 : 3 }
}

// MARK: - UITableViewDataSource / Delegate

extension PastGameDetailViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { sectionCount }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return playerRows.count
        case 2: return 1
        case 3: return playerRows.filter { $0.hasStats }.count
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1: return "Leaderboard"
        case 2: return isTournament ? "Stableford" : "Scorecard"
        case 3: return "Stats"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let c = tableView.dequeueReusableCell(
                withIdentifier: CellID.header, for: indexPath) as! DetailHeaderCell
            c.configure(courseName: courseName, date: roundDate,
                        playerCount: playerRows.count, holesPlayed: holesPlayed)
            return c
        case 1:
            let c = tableView.dequeueReusableCell(
                withIdentifier: CellID.leaderboard, for: indexPath) as! LeaderboardCell
            c.configure(with: playerRows[indexPath.row], isTournament: isTournament)
            return c
        case 2:
            let c = tableView.dequeueReusableCell(
                withIdentifier: CellID.scorecard, for: indexPath) as! ScorecardCell
            c.configure(players: playerRows, pars: pars, isTournament: isTournament, teamPts: teamPts)
            return c
        case 3:
            let statsRows = playerRows.filter { $0.hasStats }
            let c = tableView.dequeueReusableCell(
                withIdentifier: CellID.stats, for: indexPath) as! StatsRowCell
            c.configure(with: statsRows[indexPath.row])
            return c
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
