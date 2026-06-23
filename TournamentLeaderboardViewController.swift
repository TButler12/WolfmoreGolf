import UIKit

// MARK: - TournamentLeaderboardViewController

final class TournamentLeaderboardViewController: UIViewController {

    // MARK: - Private models
    private struct MoneyRow  { let rank: Int; let name: String; let dayTotal: Double; let total: Double; let holesPlayed: Int; let offset: Double? }
    private struct ScoreRow  { let rank: Int; let name: String; let total: Int;    let holesPlayed: Int }
    private struct GroupRow  { let matchId: String; let playerNames: [String];     let holesPlayed: Int }
    private struct SkinsRow  { let rank: Int; let name: String; let skinsWon: Int; let holesPlayed: Int }

    // MARK: - State
    let tournamentCode: String
    private var record: TournamentRecord?
    private(set) var allRows: [TournamentHoleScoreRow] = []
    private var moneyData:      [MoneyRow]  = []
    private var tournamentData: [MoneyRow]  = []
    private var scoreData:      [ScoreRow]  = []
    private var groupData:      [GroupRow]  = []
    private var skinsData:      [SkinsRow]  = []
    private var refreshTimer: Timer?
    private var isRefreshing = false
    private var availableDays: [Int] = []
    private var selectedDay: Int? = nil
    private var playerOffsets: [String: Double] = [:]
    private var selectedGameType: String = "wolf"

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
    private let segment       = UISegmentedControl(items: ["Money", "Score", "Groups", "Tournament"])
    private let dayPicker     = UISegmentedControl()
    private let gameTypePicker = UISegmentedControl(items: ["Wolf", "Skins"])
    private let tableView     = UITableView(frame: .zero, style: .plain)
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

        let leaveBtn = UIBarButtonItem(title: "Leave", style: .plain,
                                       target: self, action: #selector(leaveTapped))
        leaveBtn.tintColor = .systemRed
        navigationItem.leftBarButtonItem = leaveBtn

        setupHeader()
        setupTable()
        buildTabBar()

        Task { await loadData() }
        scheduleTimer()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Task { await loadData() }
        if refreshTimer == nil { scheduleTimer() }
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

    // MARK: - Tab bar

    private func buildTabBar() {
        let wolfGreen = UIColor(red: 0.10, green: 0.33, blue: 0.18, alpha: 1.0)
        let isLive = GameManager.shared.currentGame?.liveSessionId != nil

        let bar = UIView()
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.97)
        bar.layer.borderWidth = 0.5
        bar.layer.borderColor = UIColor.separator.cgColor
        view.addSubview(bar)
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bar.heightAnchor.constraint(equalToConstant: 44),
        ])

        func makeTabBtn(icon: String, title: String) -> UIButton {
            var cfg = UIButton.Configuration.plain()
            cfg.image = UIImage(systemName: icon, withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .medium))
            cfg.title = title
            cfg.imagePlacement = .leading
            cfg.imagePadding = 4
            cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { a in
                var a = a; a.font = UIFont.systemFont(ofSize: 12, weight: .semibold); return a
            }
            let btn = UIButton(configuration: cfg)
            btn.tintColor = .secondaryLabel
            return btn
        }

        let scoreBtn = makeTabBtn(icon: "target", title: "Score")
        scoreBtn.addTarget(self, action: #selector(tabScoreTapped), for: .touchUpInside)

        let liveBtn = makeTabBtn(icon: "tv", title: "Live Wolf")
        liveBtn.addTarget(self, action: #selector(tabLiveTapped), for: .touchUpInside)
        liveBtn.isHidden = !isLive

        let leaderboardBtn = makeTabBtn(icon: "trophy", title: "Leaderboard")
        leaderboardBtn.addTarget(self, action: #selector(tabLeaderboardTapped), for: .touchUpInside)
        leaderboardBtn.tintColor = wolfGreen

        let stack = UIStackView(arrangedSubviews: [scoreBtn, liveBtn, leaderboardBtn])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        bar.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: bar.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: bar.trailingAnchor),
            stack.topAnchor.constraint(equalTo: bar.topAnchor),
            stack.bottomAnchor.constraint(equalTo: bar.bottomAnchor),
        ])

        if isLive {
            let dot = UIView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.backgroundColor = UIColor(red: 0.2, green: 1.0, blue: 0.4, alpha: 1)
            dot.layer.cornerRadius = 4
            dot.isUserInteractionEnabled = false
            bar.addSubview(dot)
            let pulse = CABasicAnimation(keyPath: "opacity")
            pulse.fromValue = 1.0; pulse.toValue = 0.2
            pulse.duration = 0.85; pulse.autoreverses = true; pulse.repeatCount = .infinity
            dot.layer.add(pulse, forKey: "livePulse")
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: 8),
                dot.heightAnchor.constraint(equalToConstant: 8),
                dot.centerYAnchor.constraint(equalTo: liveBtn.centerYAnchor),
                dot.trailingAnchor.constraint(equalTo: liveBtn.trailingAnchor, constant: -8),
            ])
        }

        tableView.contentInset.bottom = 44
        tableView.scrollIndicatorInsets.bottom = 44
    }

    @objc private func tabScoreTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func tabLiveTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func tabLeaderboardTapped() { /* already here */ }

    // MARK: - Actions

    @objc private func leaveTapped() {
        let ac = UIAlertController(
            title: "Leave this tournament?",
            message: "Your progress is saved.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Leave", style: .destructive) { [weak self] _ in
            guard let self else { return }
            if let nav = self.navigationController, nav.presentingViewController != nil {
                nav.dismiss(animated: true)
            } else {
                self.navigationController?.popToRootViewController(animated: true)
            }
        })
        present(ac, animated: true)
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

            let currentDay = selectedDay ?? Set(rows.compactMap { $0.day }).max() ?? 1
            playerOffsets = try await SupabaseService.shared.fetchPlayerOffsets(code: tournamentCode, day: currentDay)

            print("🗓 distinct days in allRows: \(Set(allRows.compactMap { $0.day }).sorted())")
            recompute()
            updateDayPicker()
            applyHeader()
            tableView.reloadData()
        } catch {
            print("❌ leaderboard loadData error: \(error)")
        }
    }

    // MARK: - Aggregation
    private func recompute() {
        // ── Deduplicate: one row per (playerName, day, hole, game_type) ──
        let deduped: [TournamentHoleScoreRow] = {
            var seen = Set<String>()
            return allRows.filter {
                seen.insert("\($0.playerName)|\($0.day ?? 1)|\($0.hole)|\($0.gameType ?? "wolf")").inserted
            }
        }()

        // ── Available days (for day picker) ──
        availableDays = Array(Set(deduped.compactMap { $0.day })).sorted()

        // ── Filter to selected day and game type ──
        let currentDay = selectedDay ?? availableDays.last ?? 1
        let rows = deduped.filter {
            ($0.day ?? 1) == currentDay && ($0.gameType ?? "wolf") == selectedGameType
        }

        let grouped = Dictionary(grouping: rows, by: { $0.playerName })

        // ── Money ──
        var dayTotals: [String: Double] = [:]
        var pHoles:    [String: Int]    = [:]
        for (player, playerRows) in grouped {
            if let latest = playerRows.max(by: { $0.hole < $1.hole }) {
                dayTotals[player] = latest.totalMoney ?? 0
            }
            pHoles[player] = playerRows.count
        }

        moneyData = dayTotals.sorted { $0.value > $1.value }.enumerated().map { i, kv in
            MoneyRow(rank: i+1, name: kv.key, dayTotal: kv.value, total: kv.value,
                     holesPlayed: pHoles[kv.key] ?? 0, offset: playerOffsets[kv.key])
        }

        // ── Skins ──
        var skinTotals: [String: Int] = [:]
        for (player, playerRows) in grouped {
            if let latest = playerRows.max(by: { $0.hole < $1.hole }) {
                skinTotals[player] = latest.skinsWon ?? 0
            }
        }
        skinsData = skinTotals.sorted { $0.value > $1.value }.enumerated().map { i, kv in
            SkinsRow(rank: i+1, name: kv.key, skinsWon: kv.value, holesPlayed: pHoles[kv.key] ?? 0)
        }

        tournamentData = moneyData.map { row in
            let agg = row.dayTotal + (playerOffsets[row.name] ?? 0)
            return MoneyRow(rank: 0, name: row.name, dayTotal: row.dayTotal, total: agg,
                            holesPlayed: row.holesPlayed, offset: playerOffsets[row.name])
        }.sorted { $0.total > $1.total }
         .enumerated().map { i, r in
            MoneyRow(rank: i+1, name: r.name, dayTotal: r.dayTotal, total: r.total,
                     holesPlayed: r.holesPlayed, offset: r.offset)
        }

        // ── Score ──
        let useNet = record?.scoring == "net"
        var sums:   [String: Int] = [:]
        var sHoles: [String: Int] = [:]
        for (player, playerRows) in grouped {
            sums[player]   = playerRows.reduce(0) { $0 + (useNet ? ($1.netScore ?? $1.grossScore) : $1.grossScore) }
            sHoles[player] = playerRows.count
        }
        scoreData = sums.sorted { $0.value < $1.value }.enumerated().map { i, kv in
            ScoreRow(rank: i+1, name: kv.key, total: kv.value, holesPlayed: sHoles[kv.key] ?? 0)
        }

        // ── Groups: from full deduped set (not day-filtered) ──
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

    private func updateDayPicker() {
        let previous = selectedDay
        dayPicker.removeAllSegments()
        for (i, day) in availableDays.enumerated() {
            dayPicker.insertSegment(withTitle: "Day \(day)", at: i, animated: false)
        }
        if let previous, let idx = availableDays.firstIndex(of: previous) {
            dayPicker.selectedSegmentIndex = idx
        } else {
            dayPicker.selectedSegmentIndex = max(0, availableDays.count - 1)
            selectedDay = availableDays.last
        }
        dayPicker.isHidden = availableDays.count <= 1
    }

    @objc private func dayPickerChanged() {
        selectedDay = availableDays[safe: dayPicker.selectedSegmentIndex]
        Task { await loadData() }
    }

    @objc private func gameTypePickerChanged() {
        selectedGameType = gameTypePicker.selectedSegmentIndex == 1 ? "skins" : "wolf"
        recompute()
        tableView.reloadData()
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

        dayPicker.addTarget(self, action: #selector(dayPickerChanged), for: .valueChanged)
        dayPicker.isHidden = true

        gameTypePicker.selectedSegmentIndex = 0
        gameTypePicker.addTarget(self, action: #selector(gameTypePickerChanged), for: .valueChanged)

        let vStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, liveRow, gameTypePicker, dayPicker, segment])
        vStack.axis = .vertical; vStack.spacing = 6
        vStack.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(vStack)

        let sep = UIView()
        sep.backgroundColor = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(sep)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

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

    }

    @objc private func segmentChanged() {
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource / Delegate

extension TournamentLeaderboardViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch segment.selectedSegmentIndex {
        case 0: return selectedGameType == "skins" ? skinsData.count : moneyData.count
        case 1: return scoreData.count
        case 2: return groupData.count
        case 3: return tournamentData.count
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
            if selectedGameType == "skins" {
                let r = skinsData[i]
                cell.configureSkins(rank: r.rank, name: r.name, skinsWon: r.skinsWon,
                                    holesPlayed: r.holesPlayed, isCurrentUser: r.name == me)
            } else {
                let r = moneyData[i]
                cell.configure(rank: r.rank, name: r.name, total: r.dayTotal,
                               holesPlayed: r.holesPlayed, isCurrentUser: r.name == me)
            }
            return cell

        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "money",
                                                     for: indexPath) as! LeaderboardMoneyCell
            let r = tournamentData[i]
            cell.configure(rank: r.rank, name: r.name, total: r.total,
                           holesPlayed: r.holesPlayed, isCurrentUser: r.name == me,
                           dayTotal: r.dayTotal)
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
        if segment.selectedSegmentIndex == 0 {
            tableView.deselectRow(at: indexPath, animated: true)

            if selectedGameType == "skins" {
                let row = skinsData[indexPath.row]
                let playerRows = allRows
                    .filter { $0.playerName == row.name && ($0.gameType ?? "wolf") == "skins" }
                    .sorted { $0.hole < $1.hole }
                var prev = 0
                var wonHoles: [(hole: Int, count: Int)] = []
                for r in playerRows {
                    let current = r.skinsWon ?? 0
                    if current > prev { wonHoles.append((r.hole, current - prev)) }
                    prev = current
                }
                let message: String
                if wonHoles.isEmpty {
                    message = "No skins won yet"
                } else {
                    let totalSkins = wonHoles.reduce(0) { $0 + $1.count }
                    let lines = wonHoles.map { hole, count -> String in
                        let carryovers = count - 1
                        let skinWord = count == 1 ? "skin" : "skins"
                        if carryovers > 0 {
                            let cWord = carryovers == 1 ? "carryover" : "carryovers"
                            return "Hole \(hole): \(count) \(skinWord) (included \(carryovers) \(cWord))"
                        }
                        return "Hole \(hole): \(count) \(skinWord)"
                    }
                    let totalWord = totalSkins == 1 ? "skin" : "skins"
                    message = "Won skins on:\n\(lines.joined(separator: "\n"))\n\n\(totalSkins) \(totalWord) total"
                }
                let alert = UIAlertController(title: row.name, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                return
            }

            guard UserDefaults.standard.bool(forKey: "isOrganizer_\(tournamentCode)") else { return }
            let row = moneyData[indexPath.row]
            let alert = UIAlertController(
                title: "Carry-over for \(row.name)",
                message: "Enter carry-over from previous days",
                preferredStyle: .alert
            )
            alert.addTextField { tf in
                tf.keyboardType = .numbersAndPunctuation
                tf.placeholder = "e.g. 42.00 or -18.00"
                tf.text = self.playerOffsets[row.name].map { String($0) } ?? ""
            }
            alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
                guard let self,
                      let text = alert.textFields?.first?.text,
                      let amount = Double(text) else { return }
                Task {
                    do {
                        try await SupabaseService.shared.upsertPlayerOffset(
                            code: self.tournamentCode,
                            day: self.selectedDay ?? 1,
                            playerName: row.name,
                            amount: amount
                        )
                        print("✅ upsertPlayerOffset succeeded")
                        await self.loadData()
                    } catch {
                        print("❌ upsertPlayerOffset failed: \(error)")
                    }
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
            return
        }

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

    private let rankLabel     = UILabel()
    private let nameLabel     = UILabel()
    private let moneyLabel    = UILabel()
    private let dayTotalLabel = UILabel()
    private let holesLabel    = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .default

        rankLabel.font          = UIFont.systemFont(ofSize: 15, weight: .semibold)
        rankLabel.textAlignment = .center
        rankLabel.setContentHuggingPriority(.required, for: .horizontal)
        rankLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        rankLabel.widthAnchor.constraint(equalToConstant: 38).isActive = true

        nameLabel.font = UIFont.systemFont(ofSize: 16)
        nameLabel.adjustsFontSizeToFitWidth = true; nameLabel.minimumScaleFactor = 0.75
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        moneyLabel.font          = UIFont.systemFont(ofSize: 15, weight: .semibold)
        moneyLabel.textAlignment = .right
        moneyLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        moneyLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        dayTotalLabel.font          = UIFont.systemFont(ofSize: 11)
        dayTotalLabel.textColor     = .tertiaryLabel
        dayTotalLabel.textAlignment = .right
        dayTotalLabel.isHidden      = true

        let valueStack = UIStackView(arrangedSubviews: [moneyLabel, dayTotalLabel])
        valueStack.axis    = .vertical
        valueStack.spacing = 1
        valueStack.alignment = .trailing
        valueStack.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        valueStack.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        holesLabel.font          = UIFont.systemFont(ofSize: 12)
        holesLabel.textColor     = .tertiaryLabel
        holesLabel.textAlignment = .right
        holesLabel.widthAnchor.constraint(equalToConstant: 30).isActive = true
        holesLabel.setContentHuggingPriority(.required, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [rankLabel, nameLabel, valueStack, holesLabel])
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

    func configureSkins(rank: Int, name: String, skinsWon: Int, holesPlayed: Int, isCurrentUser: Bool) {
        let gold = UIColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1.0)
        rankLabel.text       = "#\(rank)"
        rankLabel.textColor  = rank == 1 ? gold : .secondaryLabel
        nameLabel.text       = name
        moneyLabel.text      = "\(skinsWon) skin\(skinsWon == 1 ? "" : "s")"
        moneyLabel.textColor = skinsWon > 0 ? .systemGreen : .secondaryLabel
        holesLabel.text      = "\(holesPlayed)h"
        dayTotalLabel.isHidden = true
        backgroundColor      = isCurrentUser ? UIColor.systemYellow.withAlphaComponent(0.25) : .systemBackground
    }

    func configure(rank: Int, name: String, total: Double, holesPlayed: Int, isCurrentUser: Bool, dayTotal: Double? = nil) {
        let gold = UIColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1.0)
        rankLabel.text       = "#\(rank)"
        rankLabel.textColor  = rank == 1 ? gold : .secondaryLabel
        nameLabel.text       = name
        let sign             = total >= 0 ? "+" : "-"
        moneyLabel.text      = "\(sign)$\(String(format: "%.2f", abs(total)))"
        moneyLabel.textColor = total > 0 ? .systemGreen : (total < 0 ? .systemRed : .secondaryLabel)
        holesLabel.text      = "\(holesPlayed)h"
        backgroundColor      = isCurrentUser ? UIColor.systemYellow.withAlphaComponent(0.25) : .systemBackground

        if let dayTotal, abs(dayTotal - total) > 0.001 {
            let dsign            = dayTotal >= 0 ? "+" : "-"
            dayTotalLabel.text   = "Today: \(dsign)$\(String(format: "%.2f", abs(dayTotal)))"
            dayTotalLabel.isHidden = false
        } else {
            dayTotalLabel.isHidden = true
        }
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
