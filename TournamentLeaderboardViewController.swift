import UIKit

// MARK: - TournamentLeaderboardViewController

final class TournamentLeaderboardViewController: UIViewController {

    // MARK: - Private models
    private struct MoneyRow  { let rank: Int; let name: String; let dayTotal: Double; let total: Double; let holesPlayed: Int; let offset: Double? }
    private struct ScoreRow  { let rank: Int; let name: String; let total: Int;    let holesPlayed: Int }
    private struct GroupRow  { let matchId: String; let playerNames: [String];     let holesPlayed: Int }
    private struct SkinsRow  { let rank: Int; let name: String; let skinsWon: Int; let holesPlayed: Int; let potPayout: Double? }
    private struct PtsRow    { let rank: Int; let name: String; let dayPts: Int;   let holesPlayed: Int }

    // MARK: - State
    let tournamentCode: String
    private var record: TournamentRecord?
    private(set) var allRows: [TournamentHoleScoreRow] = []
    private var moneyData:      [MoneyRow]  = []
    private var tournamentData: [MoneyRow]  = []
    private var scoreData:      [ScoreRow]  = []
    private var groupData:      [GroupRow]  = []
    private var skinsData:      [SkinsRow]  = []
    private var stablefordIndividualData: [PtsRow] = []
    private var stablefordTeamData:       [PtsRow] = []

    // Local overrides — set at init from GameData so server record mismatches don't break display.
    private let localGameType: String?
    private let localStablefordEnabled: Bool
    // Detected from actual hole_scores rows (fallback for tournaments created before Stableford support).
    private var rowsDetectedStableford = false

    // Whether this tournament has a money format (Wolf/Skins) active.
    private var hasMoneyFormat: Bool {
        let gt = record?.gameType ?? localGameType ?? "wolf"
        return gt != "stableford"
    }
    // Whether this tournament has Stableford points tracking active.
    private var hasStablefordFormat: Bool {
        localStablefordEnabled
            || localGameType == "stableford"
            || record?.gameType == "stableford"
            || record?.stablefordEnabled == true
            || rowsDetectedStableford
    }

    // Current view mode: true = $ Money tabs, false = Pts tabs.
    private var showingMoneyView: Bool = true

    private var refreshTimer: Timer?
    private var isRefreshing = false
    private var availableDays: [Int] = []
    private var selectedDay: Int? = nil
    private var playerOffsets: [String: Double] = [:]
    private var allDayOffsets: [String: Double] = [:]
    private var selectedGameType: String = "wolf"

    private var currentUserName: String? {
        let n = ProfileStore.name?.trimmingCharacters(in: .whitespaces) ?? ""
        return n.isEmpty ? nil : n
    }

    // MARK: - UI
    private let isOrganizerView: Bool

    private let headerView     = UIView()
    private let titleLabel     = UILabel()
    private let subtitleLabel  = UILabel()
    private let liveDot        = UIView()
    private let liveLabel      = UILabel()
    private let statsLabel     = UILabel()
    private let potBannerLabel  = UILabel()
    private let moneyPtsToggle  = UISegmentedControl(items: ["$ Money", "Pts"])
    private let segment         = UISegmentedControl(items: ["Money", "Net Score", "Groups", "Tournament"])
    private let dayPicker       = UISegmentedControl()
    private let gameTypePicker  = UISegmentedControl(items: ["Wolf", "Net Skins", "Gross Skins"])
    private let tableView       = UITableView(frame: .zero, style: .plain)
    private let spinner         = UIActivityIndicatorView(style: .medium)

    // MARK: - Init
    init(code: String, isOrganizerView: Bool = false, gameType: String? = nil, stablefordEnabled: Bool = false) {
        self.tournamentCode = code.uppercased()
        self.isOrganizerView = isOrganizerView
        self.localGameType = gameType
        self.localStablefordEnabled = stablefordEnabled
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = isOrganizerView ? "Tournament Results" : "Leaderboard"
        view.backgroundColor = .systemBackground

        let refreshBtn = UIBarButtonItem(barButtonSystemItem: .refresh,
                                        target: self, action: #selector(refreshTapped))
        navigationItem.rightBarButtonItems = [refreshBtn, UIBarButtonItem(customView: spinner)]

        if !isOrganizerView {
            let leaveBtn = UIBarButtonItem(title: "Leave", style: .plain,
                                           target: self, action: #selector(leaveTapped))
            leaveBtn.tintColor = .systemRed
            navigationItem.leftBarButtonItem = leaveBtn
        }

        setupHeader()
        setupTable()
        buildTabBar()

        Task { await loadData(refetchRecord: true) }
        scheduleTimer()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Task { await loadData(refetchRecord: false) }
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
            Task { await self?.loadData(refetchRecord: false) }
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
        tableView.verticalScrollIndicatorInsets.bottom = 44
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

    // refetchRecord: true  → re-fetch tournaments row (first load, explicit refresh button)
    // refetchRecord: false → skip tournaments row; use cached record (auto-refresh, viewDidAppear)
    @objc private func refreshTapped() { Task { await loadData(refetchRecord: true) } }

    @MainActor
    private func loadData(refetchRecord: Bool) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        spinner.startAnimating()
        defer { isRefreshing = false; spinner.stopAnimating() }

        // Use selectedDay if known; fall back to 1 so fetchPlayerOffsets can start in parallel.
        // If the true latest day differs (first load of a multi-day tournament), updateDayPicker
        // sets selectedDay and the next refresh corrects the offsets automatically.
        let day = selectedDay ?? 1

        do {
            if refetchRecord || record == nil {
                async let recFetch        = SupabaseService.shared.fetchTournament(code: tournamentCode)
                async let rowsFetch       = SupabaseService.shared.fetchTournamentHoleScores(code: tournamentCode)
                async let offsetsFetch    = SupabaseService.shared.fetchPlayerOffsets(code: tournamentCode, day: day)
                async let allOffsetsFetch = SupabaseService.shared.fetchAllPlayerOffsets(code: tournamentCode)
                let (rec, rows, offsets, allOffsets) = try await (recFetch, rowsFetch, offsetsFetch, allOffsetsFetch)
                record        = rec
                allRows       = rows
                playerOffsets = offsets
                allDayOffsets = allOffsets
            } else {
                async let rowsFetch       = SupabaseService.shared.fetchTournamentHoleScores(code: tournamentCode)
                async let offsetsFetch    = SupabaseService.shared.fetchPlayerOffsets(code: tournamentCode, day: day)
                async let allOffsetsFetch = SupabaseService.shared.fetchAllPlayerOffsets(code: tournamentCode)
                let (rows, offsets, allOffsets) = try await (rowsFetch, offsetsFetch, allOffsetsFetch)
                allRows       = rows
                playerOffsets = offsets
                allDayOffsets = allOffsets
            }

            #if DEBUG
            print("🗓 distinct days in allRows: \(Set(allRows.compactMap { $0.day }).sorted())")
            #endif
            recompute()
            updateDayPicker()
            applyHeader()
            applySegmentTitles()
            tableView.reloadData()
        } catch {
            print("❌ leaderboard loadData error: \(error)")
        }
    }

    // MARK: - Aggregation
    private func recompute() {
        // Auto-detect Stableford from actual row data (handles tournaments created before Stableford support).
        rowsDetectedStableford = allRows.contains { $0.gameType == "stableford" }

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

        // Full tournament field — every player with any data under this code, any day.
        // Used to ensure all players appear on every day tab, even if that day's data
        // is missing (e.g. scores not yet submitted, or submitted without tournament linkage).
        let fieldPlayers = Set(allRows.map { $0.playerName }).subtracting(["Team"])

        // ── Money ──
        var dayTotals: [String: Double] = [:]
        var pHoles:    [String: Int]    = [:]

        // Seed all field players so they appear even when the selected day has no data.
        for player in fieldPlayers { dayTotals[player] = 0; pHoles[player] = 0 }

        for (player, playerRows) in grouped {
            if let latest = playerRows.max(by: { $0.hole < $1.hole }) {
                dayTotals[player] = latest.totalMoney ?? 0
            }
            pHoles[player] = playerRows.count
        }

        // Players with data for this day sort by money descending; no-data players go last.
        moneyData = dayTotals.sorted {
            let aHoles = pHoles[$0.key] ?? 0
            let bHoles = pHoles[$1.key] ?? 0
            if aHoles > 0 && bHoles == 0 { return true }
            if aHoles == 0 && bHoles > 0 { return false }
            return $0.value > $1.value
        }.enumerated().map { i, kv in
            MoneyRow(rank: i+1, name: kv.key, dayTotal: kv.value, total: kv.value,
                     holesPlayed: pHoles[kv.key] ?? 0, offset: playerOffsets[kv.key])
        }

        // ── Skins ──
        // Computed field-wide from raw scores so all groups compete against each other.
        // Filtered to currentDay and selectedGameType so each day/type tab is independent.
        let skinGameType    = (selectedGameType == "gross_skins") ? "gross_skins" : "skins"
        let fullPot         = record?.potAmount
        let scoringStr      = record?.scoring ?? "net"
        let isCombinedPool  = scoringStr == "both_combined"

        // Recompute skins field-wide from raw scores so all groups compete against each other.
        // Per-group skinsWon values written by individual scorers are intentionally ignored here.
        let carryTies = record?.carryTies ?? false
        func countSkins(gameType: String, forDay: Int? = nil) -> [String: Int] {
            var totals: [String: Int] = [:]
            for player in fieldPlayers { totals[player] = 0 }
            let useGross = (gameType == "gross_skins")
            let rows = allRows
                .filter { $0.gameType == gameType && ($0.day ?? 1) == (forDay ?? currentDay) }
            let byHole = Dictionary(grouping: rows, by: { $0.hole })
            var carried = 0
            for hole in 1...18 {
                let holeRows = byHole[hole] ?? []
                guard !holeRows.isEmpty else { carried += carryTies ? 1 : 0; continue }
                let scores: [(name: String, score: Int)] = holeRows.compactMap { r in
                    let s = useGross ? r.grossScore : (r.netScore ?? r.grossScore)
                    return (r.playerName, s)
                }
                guard let low = scores.map(\.score).min() else { continue }
                let winners = scores.filter { $0.score == low }
                if winners.count == 1 {
                    totals[winners[0].name, default: 0] += 1 + carried
                    carried = 0
                } else {
                    if carryTies { carried += 1 }
                }
            }
            return totals
        }

        let skinTotals = countSkins(gameType: skinGameType)

        // Effective pot for this tab:
        // - combined_pool: full pot ÷ combined net+gross skins, so each skin has equal value.
        // - both:NN custom split: the per-type pot is baked into totalMoney rows by GameVC; use it.
        // - both (50/50) or single type: full pot for single type, half for each 50/50 type.
        let effectiveSkinsPot: Double?
        let totalSkinsForPot: Int
        if isCombinedPool, let pot = fullPot, pot > 0 {
            let netSkins   = countSkins(gameType: "skins")
            let grossSkins = countSkins(gameType: "gross_skins")
            let combined   = netSkins.values.reduce(0, +) + grossSkins.values.reduce(0, +)
            totalSkinsForPot  = skinTotals.values.reduce(0, +)
            effectiveSkinsPot = combined > 0 ? pot / Double(combined) * 1.0 : nil
            // perSkin already baked; potPayout = playerSkins × (pot / combinedTotal)
        } else {
            let isBothHalf = scoringStr == "both"
            let isCustom   = scoringStr.hasPrefix("both:") && !scoringStr.hasPrefix("both_")
            let effectivePot: Double?
            if let p = fullPot, p > 0 {
                if isBothHalf    { effectivePot = p / 2.0 }
                else if isCustom {
                    // Custom split is already encoded in the written totalMoney.
                    // For leaderboard banner, compute the effective pot for this tab.
                    if let grossPct = Double(scoringStr.dropFirst("both:".count)) {
                        let frac = min(0.99, max(0.01, grossPct / 100.0))
                        effectivePot = skinGameType == "gross_skins" ? p * frac : p * (1.0 - frac)
                    } else {
                        effectivePot = p / 2.0
                    }
                }
                else             { effectivePot = p }
            } else { effectivePot = nil }
            effectiveSkinsPot = effectivePot
            totalSkinsForPot  = skinTotals.values.reduce(0, +)
        }

        skinsData = skinTotals.sorted { $0.value > $1.value }.enumerated().map { i, kv in
            let potPayout: Double?
            if isCombinedPool, let perSkin = effectiveSkinsPot, kv.value > 0 {
                potPayout = Double(kv.value) * perSkin
            } else if let pot = effectiveSkinsPot, totalSkinsForPot > 0, kv.value > 0 {
                potPayout = (Double(kv.value) / Double(totalSkinsForPot)) * pot
            } else {
                potPayout = nil
            }
            return SkinsRow(rank: i+1, name: kv.key, skinsWon: kv.value,
                            holesPlayed: pHoles[kv.key] ?? 0, potPayout: potPayout)
        }

        // Tournament: cross-day sum. Skins uses field-wide countSkins per day (same logic
        // as the Money tab) to avoid per-group totalMoney values being summed incorrectly.
        // Wolf sums the latest totalMoney row per (player, day) from submitted data.
        let allGameRows = deduped.filter { ($0.gameType ?? "wolf") == selectedGameType }
        var tourneyTotals: [String: Double] = [:]
        var tourneyHoles:  [String: Int]    = [:]
        for player in fieldPlayers { tourneyTotals[player] = 0; tourneyHoles[player] = 0 }

        let isSkinType = (selectedGameType == "skins" || selectedGameType == "gross_skins")
        var currentDayMoneyByPlayer: [String: Double]

        if isSkinType {
            let useGrossT  = (selectedGameType == "gross_skins")
            let fullPotT   = record?.potAmount
            let scoringT   = record?.scoring ?? "net"
            let isCombT    = scoringT == "both_combined"
            let isBothT    = scoringT == "both"
            let isCustomT  = scoringT.hasPrefix("both:") && !scoringT.hasPrefix("both_")
            var currentDaySkinsPayoutByPlayer: [String: Double] = [:]

            for day in availableDays {
                let daySkins      = countSkins(gameType: selectedGameType, forDay: day)
                let totalDaySkins = daySkins.values.reduce(0, +)

                let perSkinT: Double?
                if let pot = fullPotT, pot > 0, totalDaySkins > 0 {
                    if isCombT {
                        let otherGT    = useGrossT ? "skins" : "gross_skins"
                        let otherSkins = countSkins(gameType: otherGT, forDay: day)
                        let combined   = totalDaySkins + otherSkins.values.reduce(0, +)
                        perSkinT = combined > 0 ? pot / Double(combined) : nil
                    } else {
                        let effectivePotT: Double
                        if isBothT {
                            effectivePotT = pot / 2.0
                        } else if isCustomT, let grossPct = Double(scoringT.dropFirst("both:".count)) {
                            let frac = min(0.99, max(0.01, grossPct / 100.0))
                            effectivePotT = useGrossT ? pot * frac : pot * (1.0 - frac)
                        } else {
                            effectivePotT = pot
                        }
                        perSkinT = effectivePotT / Double(totalDaySkins)
                    }
                } else {
                    perSkinT = nil
                }

                for (player, skins) in daySkins where skins > 0 {
                    if let ps = perSkinT {
                        let payout = Double(skins) * ps
                        tourneyTotals[player, default: 0] += payout
                        if day == currentDay { currentDaySkinsPayoutByPlayer[player] = payout }
                    }
                }
                let dayTypeRows = allRows.filter { $0.gameType == selectedGameType && ($0.day ?? 1) == day }
                for (player, pRows) in Dictionary(grouping: dayTypeRows, by: { $0.playerName }) {
                    tourneyHoles[player, default: 0] += pRows.count
                }
            }
            currentDayMoneyByPlayer = currentDaySkinsPayoutByPlayer
        } else {
            let byDay = Dictionary(grouping: allGameRows, by: { $0.day ?? 1 })
            for (_, dayRows) in byDay {
                let byPlayer = Dictionary(grouping: dayRows, by: { $0.playerName })
                for (player, pRows) in byPlayer {
                    if let latest = pRows.max(by: { $0.hole < $1.hole }) {
                        tourneyTotals[player, default: 0] += latest.totalMoney ?? 0
                    }
                    tourneyHoles[player, default: 0] += pRows.count
                }
            }
            currentDayMoneyByPlayer = Dictionary(moneyData.map { ($0.name, $0.dayTotal) },
                                                 uniquingKeysWith: { _, last in last })
        }

        tournamentData = tourneyTotals.sorted {
            let aHoles = tourneyHoles[$0.key] ?? 0
            let bHoles = tourneyHoles[$1.key] ?? 0
            if aHoles > 0 && bHoles == 0 { return true }
            if aHoles == 0 && bHoles > 0 { return false }
            let aTotal = $0.value + (allDayOffsets[$0.key] ?? 0)
            let bTotal = $1.value + (allDayOffsets[$1.key] ?? 0)
            return aTotal > bTotal
        }.enumerated().map { i, kv in
            let allDayTotal  = kv.value + (allDayOffsets[kv.key] ?? 0)
            let currentDayMoney = currentDayMoneyByPlayer[kv.key] ?? 0
            return MoneyRow(rank: i+1, name: kv.key, dayTotal: currentDayMoney,
                            total: allDayTotal, holesPlayed: tourneyHoles[kv.key] ?? 0,
                            offset: allDayOffsets[kv.key])
        }

        // ── Score ──
        let useNet = record?.scoring == "net"
        var sums:   [String: Int] = [:]
        var sHoles: [String: Int] = [:]
        for player in fieldPlayers { sums[player] = 0; sHoles[player] = 0 }
        for (player, playerRows) in grouped {
            sums[player]   = playerRows.reduce(0) { $0 + (useNet ? ($1.netScore ?? $1.grossScore) : $1.grossScore) }
            sHoles[player] = playerRows.count
        }
        // Players with data sort ascending (lower score wins); no-data players go last.
        scoreData = sums.sorted {
            let aHoles = sHoles[$0.key] ?? 0
            let bHoles = sHoles[$1.key] ?? 0
            if aHoles > 0 && bHoles == 0 { return true }
            if aHoles == 0 && bHoles > 0 { return false }
            return $0.value < $1.value
        }.enumerated().map { i, kv in
            ScoreRow(rank: i+1, name: kv.key, total: kv.value, holesPlayed: sHoles[kv.key] ?? 0)
        }

        // ── Groups: from full deduped set (not day-filtered); exclude synthetic team rows ──
        var gNames: [String: [String]]  = [:]
        var gHoles: [String: Set<Int>]  = [:]
        for r in deduped where r.gameType != "stableford_team" && r.playerName != "Team" {
            if !(gNames[r.matchId, default: []].contains(r.playerName)) {
                gNames[r.matchId, default: []].append(r.playerName)
            }
            gHoles[r.matchId, default: []].insert(r.hole)
        }
        groupData = gNames.map { id, names in
            GroupRow(matchId: id, playerNames: names, holesPlayed: gHoles[id]?.count ?? 0)
        }.sorted { ($0.playerNames.first ?? "") < ($1.playerNames.first ?? "") }

        // ── Stableford individual ──
        // One row per player: their running total pts at their furthest committed hole.
        // Exclude "Team" name defensively — team totals are never individual competitors.
        let sfIndividualRows = deduped.filter {
            ($0.gameType ?? "") == "stableford"
                && ($0.day ?? 1) == currentDay
                && $0.playerName != "Team"
        }
        var sfPts:   [String: Int] = [:]
        var sfHoles: [String: Int] = [:]
        for r in sfIndividualRows {
            let pts = Int((r.totalMoney ?? 0).rounded())
            if (sfPts[r.playerName] ?? -1) < pts { sfPts[r.playerName] = pts }
            sfHoles[r.playerName] = (sfHoles[r.playerName] ?? 0) + 1
        }
        stablefordIndividualData = sfPts.sorted {
            let aH = sfHoles[$0.key] ?? 0; let bH = sfHoles[$1.key] ?? 0
            if aH > 0 && bH == 0 { return true }
            if aH == 0 && bH > 0 { return false }
            return $0.value > $1.value
        }.enumerated().map { i, kv in
            PtsRow(rank: i+1, name: kv.key, dayPts: kv.value, holesPlayed: sfHoles[kv.key] ?? 0)
        }

        // ── Stableford team ──
        // One row per matchId (playing group): their team running total at their furthest hole.
        let sfTeamRows = deduped.filter {
            ($0.gameType ?? "") == "stableford_team" && ($0.day ?? 1) == currentDay
        }
        var teamPts:   [String: Int] = [:]   // matchId → best totalMoney seen
        var teamHoles: [String: Int] = [:]   // matchId → holes submitted
        var teamLabel: [String: String] = [:] // matchId → display label (player names)
        for r in sfTeamRows {
            let pts = Int((r.totalMoney ?? 0).rounded())
            if (teamPts[r.matchId] ?? -1) < pts { teamPts[r.matchId] = pts }
            teamHoles[r.matchId] = (teamHoles[r.matchId] ?? 0) + 1
        }
        // Build display label from wolf/stableford player names in the same matchId
        let playerRowsByMatch = Dictionary(grouping: deduped.filter {
            $0.gameType == "stableford" && ($0.day ?? 1) == currentDay
        }, by: { $0.matchId })
        for (mid, prows) in playerRowsByMatch {
            let names = Array(Set(prows.map { $0.playerName })).sorted().prefix(3)
            teamLabel[mid] = names.joined(separator: ", ")
        }
        stablefordTeamData = teamPts.sorted {
            let aH = teamHoles[$0.key] ?? 0; let bH = teamHoles[$1.key] ?? 0
            if aH > 0 && bH == 0 { return true }
            if aH == 0 && bH > 0 { return false }
            return $0.value > $1.value
        }.enumerated().map { i, kv in
            let label = teamLabel[kv.key] ?? kv.key
            return PtsRow(rank: i+1, name: label, dayPts: kv.value, holesPlayed: teamHoles[kv.key] ?? 0)
        }
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
        Task { await loadData(refetchRecord: false) }
    }

    @objc private func gameTypePickerChanged() {
        switch gameTypePicker.selectedSegmentIndex {
        case 1:  selectedGameType = "skins"
        case 2:  selectedGameType = "gross_skins"
        default: selectedGameType = "wolf"
        }
        recompute()
        applyHeader()
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

        potBannerLabel.font          = UIFont.systemFont(ofSize: 12, weight: .medium)
        potBannerLabel.textColor     = UIColor(red: 0.780, green: 0.635, blue: 0.188, alpha: 1.0)
        potBannerLabel.numberOfLines = 1
        potBannerLabel.isHidden      = true

        moneyPtsToggle.isHidden = true   // shown only when both modes are active
        moneyPtsToggle.addTarget(self, action: #selector(moneyPtsToggleChanged), for: .valueChanged)

        let vStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, liveRow, potBannerLabel, moneyPtsToggle, gameTypePicker, dayPicker, segment])
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

        let currentDay = selectedDay ?? availableDays.last ?? 1
        var parts: [String] = ["Day \(currentDay)"]
        if let cn = rec.courseName, !cn.isEmpty { parts.append(cn) }
        if let raw = rec.createdAt {
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            var d = iso.date(from: raw)
            if d == nil { iso.formatOptions = [.withInternetDateTime]; d = iso.date(from: raw) }
            if let date = d {
                let df = DateFormatter(); df.dateStyle = .medium; df.timeStyle = .none
                parts.append(df.string(from: date))
            }
        }
        subtitleLabel.text = parts.joined(separator: " · ")

        let playerCount    = Set(allRows.map { $0.playerName }).count
        let groupCount     = groupData.count
        let holesCompleted = Set(allRows.filter { ($0.day ?? 1) == currentDay }.map { $0.hole }).count
        let dayPlayerCount = Set(allRows.filter { ($0.day ?? 1) == currentDay }.map { $0.playerName }).count
        let missingNote    = dayPlayerCount < playerCount ? " (\(dayPlayerCount) scored)" : ""
        statsLabel.text = "· \(playerCount) player\(playerCount == 1 ? "" : "s")\(missingNote) · \(groupCount) group\(groupCount == 1 ? "" : "s") · \(holesCompleted)h"

        if let pot = rec.potAmount, pot > 0 {
            let scoring    = rec.scoring
            let totalSkins = skinsData.reduce(0) { $0 + $1.skinsWon }

            // Determine display pot and label for this tab.
            let displayPot: Double
            let potLabel: String
            if scoring == "both_combined" {
                displayPot = pot
                potLabel   = "Combined Skins Pot"
            } else if scoring == "both" {
                displayPot = pot / 2.0
                potLabel   = selectedGameType == "gross_skins" ? "Gross Skins Pot" : "Net Skins Pot"
            } else if scoring.hasPrefix("both:"), let grossPct = Double(scoring.dropFirst("both:".count)) {
                let frac   = min(0.99, max(0.01, grossPct / 100.0))
                displayPot = selectedGameType == "gross_skins" ? pot * frac : pot * (1.0 - frac)
                potLabel   = selectedGameType == "gross_skins" ? "Gross Skins Pot" : "Net Skins Pot"
            } else {
                displayPot = pot
                potLabel   = selectedGameType == "gross_skins" ? "Gross Skins Pot" : "Skins Pot"
            }

            let perSkin    = totalSkins > 0 ? displayPot / Double(totalSkins) : 0
            let perSkinStr = perSkin == floor(perSkin) ? "$\(Int(perSkin))" : String(format: "$%.2f", perSkin)
            let potStr     = displayPot == floor(displayPot) ? "$\(Int(displayPot))" : String(format: "$%.2f", displayPot)
            potBannerLabel.text    = "\(potLabel): \(potStr) · \(totalSkins) skins won · \(perSkinStr) per skin"
            potBannerLabel.isHidden = false
        } else {
            potBannerLabel.isHidden = true
        }
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

    private func applySegmentTitles() {
        // Determine which modes are available and update toggle visibility.
        let bothActive = hasMoneyFormat && hasStablefordFormat
        moneyPtsToggle.isHidden = !bothActive
        if !hasMoneyFormat    { showingMoneyView = false }
        if !hasStablefordFormat { showingMoneyView = true }
        moneyPtsToggle.selectedSegmentIndex = showingMoneyView ? 0 : 1

        // Rebuild the tab bar to match the active mode (avoids stale segment indices).
        while segment.numberOfSegments > 0 { segment.removeSegment(at: 0, animated: false) }
        if showingMoneyView {
            segment.insertSegment(withTitle: "Money",      at: 0, animated: false)
            segment.insertSegment(withTitle: "Net Score",  at: 1, animated: false)
            segment.insertSegment(withTitle: "Groups",     at: 2, animated: false)
            segment.insertSegment(withTitle: "Tournament", at: 3, animated: false)
            gameTypePicker.isHidden = false
        } else {
            segment.insertSegment(withTitle: "Individual", at: 0, animated: false)
            segment.insertSegment(withTitle: "Team",       at: 1, animated: false)
            segment.insertSegment(withTitle: "Groups",     at: 2, animated: false)
            gameTypePicker.isHidden = true
        }
        segment.selectedSegmentIndex = 0
    }

    @objc private func moneyPtsToggleChanged() {
        showingMoneyView = (moneyPtsToggle.selectedSegmentIndex == 0)
        applySegmentTitles()
        applyHeader()
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource / Delegate

extension TournamentLeaderboardViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showingMoneyView {
            switch segment.selectedSegmentIndex {
            case 0: return (selectedGameType == "skins" || selectedGameType == "gross_skins") ? skinsData.count : moneyData.count
            case 1: return scoreData.count
            case 2: return groupData.count
            case 3: return tournamentData.count
            default: return 0
            }
        } else {
            switch segment.selectedSegmentIndex {
            case 0: return stablefordIndividualData.count
            case 1: return stablefordTeamData.count
            case 2: return groupData.count
            default: return 0
            }
        }
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let me = currentUserName
        let i  = indexPath.row

        if showingMoneyView {
            switch segment.selectedSegmentIndex {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "money", for: indexPath) as! LeaderboardMoneyCell
                if selectedGameType == "skins" || selectedGameType == "gross_skins" {
                    let r = skinsData[i]
                    cell.configureSkins(rank: r.rank, name: r.name, skinsWon: r.skinsWon,
                                        potPayout: r.potPayout, holesPlayed: r.holesPlayed, isCurrentUser: r.name == me)
                } else {
                    let r = moneyData[i]
                    cell.configure(rank: r.rank, name: r.name, total: r.dayTotal,
                                   holesPlayed: r.holesPlayed, isCurrentUser: r.name == me)
                }
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "score", for: indexPath) as! LeaderboardScoreCell
                let r = scoreData[i]
                cell.configure(rank: r.rank, name: r.name, total: r.total,
                               holesPlayed: r.holesPlayed, isCurrentUser: r.name == me)
                return cell
            case 2:
                return makeGroupCell(tableView, indexPath: indexPath, row: groupData[i])
            case 3:
                let cell = tableView.dequeueReusableCell(withIdentifier: "money", for: indexPath) as! LeaderboardMoneyCell
                let r = tournamentData[i]
                cell.configure(rank: r.rank, name: r.name, total: r.total,
                               holesPlayed: r.holesPlayed, isCurrentUser: r.name == me, dayTotal: r.dayTotal)
                return cell
            default:
                return UITableViewCell()
            }
        } else {
            switch segment.selectedSegmentIndex {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "money", for: indexPath) as! LeaderboardMoneyCell
                let r = stablefordIndividualData[i]
                cell.configurePoints(rank: r.rank, name: r.name, pts: r.dayPts,
                                     holesPlayed: r.holesPlayed, isCurrentUser: r.name == me)
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "money", for: indexPath) as! LeaderboardMoneyCell
                let r = stablefordTeamData[i]
                cell.configurePoints(rank: r.rank, name: r.name, pts: r.dayPts,
                                     holesPlayed: r.holesPlayed, isCurrentUser: false)
                return cell
            case 2:
                return makeGroupCell(tableView, indexPath: indexPath, row: groupData[i])
            default:
                return UITableViewCell()
            }
        }
    }

    private func makeGroupCell(_ tableView: UITableView, indexPath: IndexPath, row: GroupRow) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "group", for: indexPath)
        var cfg = cell.defaultContentConfiguration()
        cfg.text = row.playerNames.joined(separator: ", ")
        cfg.secondaryText = "\(row.holesPlayed) hole\(row.holesPlayed == 1 ? "" : "s") played"
        cell.contentConfiguration = cfg
        cell.accessoryType   = .disclosureIndicator
        cell.backgroundColor = .systemBackground
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // Groups tap — both Money and Pts modes have Groups at segment index 2.
        if segment.selectedSegmentIndex == 2 {
            let g = groupData[indexPath.row]
            // Filter rows to the currently displayed game type so GroupDetail shows matching data.
            let filterType: String = showingMoneyView ? selectedGameType : "stableford"
            let rows = allRows.filter { $0.matchId == g.matchId && ($0.gameType ?? "wolf") == filterType }
            let vc = GroupDetailViewController(matchId: g.matchId, playerNames: g.playerNames, rows: rows)
            navigationController?.pushViewController(vc, animated: true)
            return
        }

        // Money mode — segment 0 interactions.
        if showingMoneyView && segment.selectedSegmentIndex == 0 {
            if selectedGameType == "skins" || selectedGameType == "gross_skins" {
                let row = skinsData[indexPath.row]
                let useGross2 = (selectedGameType == "gross_skins")
                let detailDay = selectedDay ?? availableDays.last ?? 1
                let allDayRows = allRows.filter { $0.gameType == selectedGameType && ($0.day ?? 1) == detailDay }
                let byHole2 = Dictionary(grouping: allDayRows, by: { $0.hole })
                let carryoversAllowed = record?.carryTies == true
                var wonHoles: [(hole: Int, count: Int)] = []
                var carried2 = 0
                for hole in 1...18 {
                    let holeRows = byHole2[hole] ?? []
                    guard !holeRows.isEmpty else { carried2 += carryoversAllowed ? 1 : 0; continue }
                    let scores = holeRows.map { r -> (name: String, score: Int) in
                        (r.playerName, useGross2 ? r.grossScore : (r.netScore ?? r.grossScore))
                    }
                    guard let low = scores.map(\.score).min() else { continue }
                    let winners = scores.filter { $0.score == low }
                    if winners.count == 1 {
                        let winner = winners[0].name
                        let earned = 1 + carried2
                        if winner == row.name { wonHoles.append((hole, earned)) }
                        carried2 = 0
                    } else if carryoversAllowed {
                        carried2 += 1
                    }
                }
                let message: String
                if wonHoles.isEmpty {
                    message = "No skins won yet"
                } else {
                    let totalSkins = wonHoles.reduce(0) { $0 + $1.count }
                    let lines = wonHoles.map { hole, count -> String in
                        let skinWord = count == 1 ? "skin" : "skins"
                        let carryovers = count - 1
                        if carryoversAllowed && carryovers > 0 {
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

            // Wolf money carry-over (organizer only).
            guard isOrganizerView || GameManager.shared.currentGame?.tournamentIsOrganizer == true else { return }
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
                        #if DEBUG
                        print("✅ upsertPlayerOffset succeeded")
                        #endif
                        await self.loadData(refetchRecord: false)
                    } catch {
                        print("❌ upsertPlayerOffset failed: \(error)")
                    }
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
        }
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

    func configureSkins(rank: Int, name: String, skinsWon: Int, potPayout: Double?,
                        holesPlayed: Int, isCurrentUser: Bool) {
        let gold = UIColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1.0)
        rankLabel.text      = "#\(rank)"
        rankLabel.textColor = rank == 1 ? gold : .secondaryLabel
        nameLabel.text      = name
        if let payout = potPayout, payout > 0 {
            moneyLabel.text = "\(skinsWon) skin\(skinsWon == 1 ? "" : "s") · $\(String(format: "%.2f", payout))"
        } else {
            moneyLabel.text = "\(skinsWon) skin\(skinsWon == 1 ? "" : "s")"
        }
        moneyLabel.textColor   = skinsWon > 0 ? .systemGreen : .secondaryLabel
        holesLabel.text        = "\(holesPlayed)h"
        dayTotalLabel.isHidden = true
        backgroundColor        = isCurrentUser ? UIColor.systemYellow.withAlphaComponent(0.25) : .systemBackground
    }

    func configurePoints(rank: Int, name: String, pts: Int, holesPlayed: Int, isCurrentUser: Bool) {
        let gold = UIColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1.0)
        rankLabel.text       = "#\(rank)"
        rankLabel.textColor  = rank == 1 ? gold : .secondaryLabel
        nameLabel.text       = name
        moneyLabel.text      = "\(pts) pt\(pts == 1 ? "" : "s")"
        moneyLabel.textColor = pts > 0 ? .systemGreen : .secondaryLabel
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
