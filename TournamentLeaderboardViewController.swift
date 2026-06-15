import UIKit

// MARK: - TournamentLeaderboardViewController

final class TournamentLeaderboardViewController: UIViewController {

    // MARK: - Private models
    private struct MoneyRow { let rank: Int; let name: String; let total: Double; let holesPlayed: Int }
    private struct ScoreRow { let rank: Int; let name: String; let total: Int;    let holesPlayed: Int }
    private struct GroupRow { let matchId: String; let playerNames: [String];     let holesPlayed: Int }

    // MARK: - State
    let tournamentCode: String
    private var record: TournamentRecord?
    private(set) var allRows: [TournamentHoleScoreRow] = []
    private var moneyData: [MoneyRow] = []
    private var scoreData: [ScoreRow] = []
    private var groupData: [GroupRow] = []
    private var refreshTimer: Timer?
    private var isRefreshing = false

    private var currentUserName: String? {
        let n = ProfileStore.name?.trimmingCharacters(in: .whitespaces) ?? ""
        return n.isEmpty ? nil : n
    }

    // MARK: - UI
    private let headerView    = UIView()
    private let titleLabel    = UILabel()
    private let subtitleLabel = UILabel()
    private let liveDot       = UIView()
    private let liveLabel     = UILabel()
    private let statsLabel    = UILabel()
    private let segment       = UISegmentedControl(items: ["Money", "Score", "Groups", "Proxes"])
    private let tableView     = UITableView(frame: .zero, style: .plain)
    private let proxesLabel   = UILabel()
    private let spinner       = UIActivityIndicatorView(style: .medium)

    // MARK: - Init
    init(code: String) {
        self.tournamentCode = code.uppercased()
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Leaderboard"
        view.backgroundColor = .systemBackground

        let refreshBtn = UIBarButtonItem(barButtonSystemItem: .refresh,
                                        target: self, action: #selector(refreshTapped))
        navigationItem.rightBarButtonItems = [refreshBtn, UIBarButtonItem(customView: spinner)]

        setupHeader()
        setupTable()

        Task { await loadData() }
        scheduleTimer()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    // MARK: - Timer
    private func scheduleTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { await self?.loadData() }
        }
    }

    // MARK: - Data
    @objc private func refreshTapped() { Task { await loadData() } }

    @MainActor
    private func loadData() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        spinner.startAnimating()
        defer { isRefreshing = false; spinner.stopAnimating() }
        do {
            async let a = SupabaseService.shared.fetchTournament(code: tournamentCode)
            async let b = SupabaseService.shared.fetchTournamentHoleScores(code: tournamentCode)
            let (rec, rows) = try await (a, b)
            record  = rec
            allRows = rows
            recompute()
            applyHeader()
            tableView.reloadData()
        } catch {
            print("❌ leaderboard loadData error: \(error)")
        }
    }

    // MARK: - Aggregation
    private func recompute() {
        // Deduplicate: one row per (playerName, hole). If the same player submitted
        // from multiple match_ids (e.g. after a rejoin), keep the first occurrence so
        // each hole only counts once in both money and score calculations.
        let deduped: [TournamentHoleScoreRow] = {
            var seen = Set<String>()
            return allRows.filter { seen.insert("\($0.playerName)|\($0.hole)").inserted }
        }()

        let grouped = Dictionary(grouping: deduped, by: { $0.playerName })

        // ── Money: total_money from the highest-hole row per player ──
        var totals: [String: Double] = [:]
        var pHoles: [String: Int]    = [:]
        for (player, rows) in grouped {
            if let latest = rows.max(by: { $0.hole < $1.hole }) {
                totals[player] = latest.totalMoney ?? 0
            }
            pHoles[player] = rows.count
        }
        moneyData = totals.sorted { $0.value > $1.value }.enumerated().map { i, kv in
            MoneyRow(rank: i+1, name: kv.key, total: kv.value, holesPlayed: pHoles[kv.key] ?? 0)
        }

        // ── Score: SUM(net or gross) across deduplicated rows per player ──
        let useNet = record?.scoring == "net"
        var sums:   [String: Int] = [:]
        var sHoles: [String: Int] = [:]
        for (player, rows) in grouped {
            sums[player]   = rows.reduce(0) { $0 + (useNet ? ($1.netScore ?? $1.grossScore) : $1.grossScore) }
            sHoles[player] = rows.count
        }
        scoreData = sums.sorted { $0.value < $1.value }.enumerated().map { i, kv in
            ScoreRow(rank: i+1, name: kv.key, total: kv.value, holesPlayed: sHoles[kv.key] ?? 0)
        }

        // ── Groups: DISTINCT match_id from deduplicated rows only ──
        // Using deduped means a match_id that was entirely superseded by a rejoin
        // (all its holes already claimed by another match_id) contributes zero rows
        // and therefore doesn't appear as a phantom extra group.
        var gNames: [String: [String]]  = [:]
        var gHoles: [String: Set<Int>]  = [:]
        for r in deduped {
            if !(gNames[r.matchId, default: []].contains(r.playerName)) {
                gNames[r.matchId, default: []].append(r.playerName)
            }
            gHoles[r.matchId, default: []].insert(r.hole)
        }
        groupData = gNames.map { id, names in
            GroupRow(matchId: id, playerNames: names, holesPlayed: gHoles[id]?.count ?? 0)
        }.sorted { ($0.playerNames.first ?? "") < ($1.playerNames.first ?? "") }
    }

    // MARK: - Header setup
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.adjustsFontSizeToFitWidth = true; titleLabel.minimumScaleFactor = 0.7
        titleLabel.text = "Loading…"

        subtitleLabel.font = UIFont.systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel

        liveDot.backgroundColor    = .systemGreen
        liveDot.layer.cornerRadius = 5
        liveDot.translatesAutoresizingMaskIntoConstraints = false

        liveLabel.text      = "LIVE"
        liveLabel.font      = UIFont.systemFont(ofSize: 12, weight: .bold)
        liveLabel.textColor = .systemGreen

        statsLabel.font      = UIFont.systemFont(ofSize: 12)
        statsLabel.textColor = .secondaryLabel

        let liveRow = UIStackView(arrangedSubviews: [liveDot, liveLabel, statsLabel])
        liveRow.axis = .horizontal; liveRow.spacing = 5; liveRow.alignment = .center
        NSLayoutConstraint.activate([
            liveDot.widthAnchor.constraint(equalToConstant: 10),
            liveDot.heightAnchor.constraint(equalToConstant: 10),
        ])

        segment.selectedSegmentIndex = 0
        segment.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)

        let vStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, liveRow, segment])
        vStack.axis = .vertical; vStack.spacing = 6
        vStack.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(vStack)

        let sep = UIView()
        sep.backgroundColor = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(sep)

        tableView.translatesAutoresizingMaskIntoConstraints   = false
        proxesLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        view.addSubview(proxesLabel)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            vStack.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 14),
            vStack.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            vStack.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            vStack.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -12),

            sep.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            sep.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            sep.heightAnchor.constraint(equalToConstant: 0.5),

            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            proxesLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            proxesLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
        ])

        startLivePulse()
    }

    private func startLivePulse() {
        let scaleA = CABasicAnimation(keyPath: "transform.scale")
        scaleA.fromValue = 1.0; scaleA.toValue = 1.6
        let opacA = CABasicAnimation(keyPath: "opacity")
        opacA.fromValue = 1.0; opacA.toValue = 0.2
        let grp = CAAnimationGroup()
        grp.animations = [scaleA, opacA]; grp.duration = 0.9
        grp.autoreverses = true; grp.repeatCount = .infinity
        grp.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        liveDot.layer.add(grp, forKey: "pulse")
    }

    private func applyHeader() {
        guard let rec = record else { return }
        titleLabel.text = rec.name

        var parts: [String] = []
        if let cn = rec.courseName, !cn.isEmpty { parts.append(cn) }
        if let raw = rec.createdAt {
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            var d = iso.date(from: raw)
            if d == nil {
                iso.formatOptions = [.withInternetDateTime]
                d = iso.date(from: raw)
            }
            if let date = d {
                let df = DateFormatter(); df.dateStyle = .medium; df.timeStyle = .none
                parts.append(df.string(from: date))
            }
        }
        subtitleLabel.text = parts.joined(separator: " · ")

        let playerCount = Set(allRows.map { $0.playerName }).count
        let groupCount  = groupData.count
        statsLabel.text = "· \(playerCount) player\(playerCount == 1 ? "" : "s") · \(groupCount) group\(groupCount == 1 ? "" : "s")"
    }

    // MARK: - Table setup
    private func setupTable() {
        tableView.register(LeaderboardMoneyCell.self, forCellReuseIdentifier: "money")
        tableView.register(LeaderboardScoreCell.self, forCellReuseIdentifier: "score")
        tableView.register(UITableViewCell.self,       forCellReuseIdentifier: "group")
        tableView.dataSource       = self
        tableView.delegate         = self
        tableView.rowHeight        = UITableView.automaticDimension
        tableView.estimatedRowHeight = 52

        proxesLabel.text          = "Coming Soon"
        proxesLabel.font          = UIFont.systemFont(ofSize: 20, weight: .medium)
        proxesLabel.textColor     = .secondaryLabel
        proxesLabel.textAlignment = .center
        proxesLabel.isHidden      = true
    }

    @objc private func segmentChanged() {
        let isProxes         = segment.selectedSegmentIndex == 3
        tableView.isHidden   = isProxes
        proxesLabel.isHidden = !isProxes
        if !isProxes { tableView.reloadData() }
    }
}

// MARK: - UITableViewDataSource / Delegate

extension TournamentLeaderboardViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch segment.selectedSegmentIndex {
        case 0: return moneyData.count
        case 1: return scoreData.count
        case 2: return groupData.count
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let me = currentUserName
        let i  = indexPath.row
        switch segment.selectedSegmentIndex {

        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "money",
                                                     for: indexPath) as! LeaderboardMoneyCell
            let r = moneyData[i]
            cell.configure(rank: r.rank, name: r.name, total: r.total,
                           holesPlayed: r.holesPlayed, isCurrentUser: r.name == me)
            return cell

        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "score",
                                                     for: indexPath) as! LeaderboardScoreCell
            let r = scoreData[i]
            cell.configure(rank: r.rank, name: r.name, total: r.total,
                           holesPlayed: r.holesPlayed, isCurrentUser: r.name == me)
            return cell

        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "group", for: indexPath)
            let r = groupData[i]
            var cfg = cell.defaultContentConfiguration()
            cfg.text = r.playerNames.joined(separator: ", ")
            cfg.secondaryText = "\(r.holesPlayed) hole\(r.holesPlayed == 1 ? "" : "s") played"
            cell.contentConfiguration = cfg
            cell.accessoryType  = .disclosureIndicator
            cell.backgroundColor = .systemBackground
            return cell

        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard segment.selectedSegmentIndex == 2 else { return }
        let g    = groupData[indexPath.row]
        let rows = allRows.filter { $0.matchId == g.matchId }
        let vc   = GroupDetailViewController(matchId: g.matchId,
                                              playerNames: g.playerNames,
                                              rows: rows)
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Money Cell

private final class LeaderboardMoneyCell: UITableViewCell {

    private let rankLabel  = UILabel()
    private let nameLabel  = UILabel()
    private let moneyLabel = UILabel()
    private let holesLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        rankLabel.font          = UIFont.systemFont(ofSize: 15, weight: .semibold)
        rankLabel.textAlignment = .center
        rankLabel.setContentHuggingPriority(.required, for: .horizontal)
        rankLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        rankLabel.widthAnchor.constraint(equalToConstant: 38).isActive = true

        nameLabel.font = UIFont.systemFont(ofSize: 16)
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        nameLabel.adjustsFontSizeToFitWidth = true; nameLabel.minimumScaleFactor = 0.75

        moneyLabel.font          = UIFont.systemFont(ofSize: 15, weight: .semibold)
        moneyLabel.textAlignment = .right
        moneyLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        moneyLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        holesLabel.font          = UIFont.systemFont(ofSize: 12)
        holesLabel.textColor     = .tertiaryLabel
        holesLabel.textAlignment = .right
        holesLabel.widthAnchor.constraint(equalToConstant: 30).isActive = true
        holesLabel.setContentHuggingPriority(.required, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [rankLabel, nameLabel, moneyLabel, holesLabel])
        stack.axis = .horizontal; stack.spacing = 8; stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(rank: Int, name: String, total: Double, holesPlayed: Int, isCurrentUser: Bool) {
        let gold = UIColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1.0)
        rankLabel.text      = "#\(rank)"
        rankLabel.textColor = rank == 1 ? gold : .secondaryLabel
        nameLabel.text      = name
        let sign = total >= 0 ? "+" : "-"
        moneyLabel.text      = "\(sign)$\(String(format: "%.2f", abs(total)))"
        moneyLabel.textColor = total > 0 ? .systemGreen : (total < 0 ? .systemRed : .secondaryLabel)
        holesLabel.text      = "\(holesPlayed)h"
        backgroundColor      = isCurrentUser ? UIColor.systemYellow.withAlphaComponent(0.25) : .systemBackground
    }
}

// MARK: - Score Cell

private final class LeaderboardScoreCell: UITableViewCell {

    private let rankLabel  = UILabel()
    private let nameLabel  = UILabel()
    private let scoreLabel = UILabel()
    private let holesLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        rankLabel.font          = UIFont.systemFont(ofSize: 15, weight: .semibold)
        rankLabel.textAlignment = .center
        rankLabel.setContentHuggingPriority(.required, for: .horizontal)
        rankLabel.widthAnchor.constraint(equalToConstant: 38).isActive = true

        nameLabel.font = UIFont.systemFont(ofSize: 16)
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        nameLabel.adjustsFontSizeToFitWidth = true; nameLabel.minimumScaleFactor = 0.75

        scoreLabel.font          = UIFont.systemFont(ofSize: 15, weight: .semibold)
        scoreLabel.textAlignment = .right
        scoreLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        scoreLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        holesLabel.font          = UIFont.systemFont(ofSize: 12)
        holesLabel.textColor     = .tertiaryLabel
        holesLabel.textAlignment = .right
        holesLabel.widthAnchor.constraint(equalToConstant: 30).isActive = true
        holesLabel.setContentHuggingPriority(.required, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [rankLabel, nameLabel, scoreLabel, holesLabel])
        stack.axis = .horizontal; stack.spacing = 8; stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(rank: Int, name: String, total: Int, holesPlayed: Int, isCurrentUser: Bool) {
        let gold = UIColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1.0)
        rankLabel.text      = "#\(rank)"
        rankLabel.textColor = rank == 1 ? gold : .secondaryLabel
        nameLabel.text      = name
        scoreLabel.text     = "\(total)"
        scoreLabel.textColor = .label
        holesLabel.text     = "\(holesPlayed)h"
        backgroundColor     = isCurrentUser ? UIColor.systemYellow.withAlphaComponent(0.25) : .systemBackground
    }
}
