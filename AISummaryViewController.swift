import UIKit
import MessageUI

// MARK: - Summary Style

enum SummaryStyle: Int, CaseIterable {
    case trashTalk, statistical, punchline, highlights

    var emoji: String {
        switch self {
        case .trashTalk:    return "😂"
        case .statistical:  return "📊"
        case .punchline:    return "💀"
        case .highlights:   return "⭐️"
        }
    }

    var title: String {
        switch self {
        case .trashTalk:    return "Trash Talk"
        case .statistical:  return "Statistical"
        case .punchline:    return "Punch Line"
        case .highlights:   return "Highlights"
        }
    }

    var subtitle: String {
        switch self {
        case .trashTalk:    return "Roast the loser, brutal but funny"
        case .statistical:  return "Data-focused performance breakdown"
        case .punchline:    return "Short, savage, funny — 5 lines max, no mercy"
        case .highlights:   return "Key moments — birdies, blow-ups, and clutch shots"
        }
    }

    func systemPrompt(isStableford: Bool = false, isTournament: Bool = false, isMatchPlay: Bool = false, isScramble: Bool = false) -> String {
        let stablefordNote = isStableford ? """
            IMPORTANT: This is a Stableford round — individual points-based scoring. \
            Focus on points earned per hole, standout individual performances, and the final leaderboard. \
            Do NOT mention Wolf, Lone Wolf, Nassau, Skins, Hammers, or money — none of those apply here.\n
            """ : ""
        let tournamentNote = (isTournament && !isScramble) ? """
            IMPORTANT: This is a multi-group tournament. Data includes all groups and an overall money leaderboard. \
            Structure your recap in two parts: (1) a brief summary of each group's round, calling out standout moments; \
            (2) the overall tournament leaderboard with commentary on who's up, who's down, and who had the biggest swing.\n
            """ : ""
        let scrambleNote = isScramble ? """
            IMPORTANT: This is a Scramble tournament — team stroke play. All players hit, the best shot is selected, \
            and everyone plays from that spot. Scores are shown relative to par: negative = under par (good), \
            positive = over par (bad), E = even. The leaderboard ranks teams from lowest to highest cumulative score vs par. \
            Structure your recap in two parts: (1) highlight each team's round — their best holes, birdies made, \
            pars saved, any blow-up holes; (2) the overall leaderboard with commentary on who's leading, \
            who's struggling, and any close battles. \
            Do NOT mention Wolf, Lone Wolf, Nassau, Skins, Hammers, or dollar amounts — this is pure team stroke play.\n
            """ : ""
        let matchPlayNote = isMatchPlay ? """
            IMPORTANT: This is a Match Play game — score is measured in holes won/lost, not strokes or net score. \
            Focus on how the match(es) played out: who was up or down, key turning-point holes, clutch wins, and the final result. \
            Do NOT mention money, dollar amounts, prize totals, or Nassau — match play is purely holes up or down.\n
            """ : ""
        // Applied to every style: birdies, eagles, and holes-in-one must always be gross scores, never net.
        let birdieNote = "IMPORTANT: When highlighting birdies, eagles, or holes-in-one, only reference gross scores — the actual strokes taken before any handicap adjustment. Never call a net birdie a birdie, never call a net eagle an eagle, and never call a net hole-in-one a hole-in-one. If a player made a score only by virtue of handicap strokes, do not describe it as a birdie or eagle.\n"
        let prefix = birdieNote + stablefordNote + tournamentNote + scrambleNote + matchPlayNote
        switch self {
        case .trashTalk:
            return prefix + """
            You are a savage but funny roaster. Roast the biggest loser, celebrate the winner. \
            Be specific — their worst holes, collapses, bad decisions, final standings. \
            Think Comedy Central Roast energy. Funny, not mean-spirited. \
            Format: each roast target gets their own paragraph separated by a blank line. \
            End with a standalone closing line that gives the winner genuine, slightly smug credit.
            """
        case .statistical:
            return prefix + """
            You are a golf data analyst. Write a clean, data-forward performance breakdown. \
            Use specific numbers — front/back split, best and worst holes, scoring vs par, key differentials. \
            Find the most interesting patterns and outliers. Professional tone, tight sentences. \
            Format: use short paragraphs separated by blank lines — one paragraph per player or theme. \
            Think ESPN Stats & Info meets Golf Digest analytics.
            """
        case .punchline:
            return prefix + """
            You are a savage deadpan comedian. Write 6 punches — one sentence each. \
            Name every player. Bury the bad ones with a specific, funny line about their worst moment. \
            The bigger the disaster, the harder you go. Anyone who played well gets one backhanded line. \
            Last line belongs to the winner: short, cold, devastating to everyone else. \
            Be funny first, brutal second. Think: mean tweet that gets screenshotted. \
            Format: each punch on its own line with a blank line between them — no paragraphs, no emojis.
            """
        case .highlights:
            return prefix + """
            No intro. No "ladies and gentlemen." Jump straight into the highlights. \
            Write one punchy line per highlight — almost like bullets but in plain sentences, no dashes or symbols. \
            Cover the best moments: natural gross birdies, eagles, prox wins, clutch saves. \
            Also call out the most brutal moments — a blow-up hole, a collapse, a shocking double. \
            Name names on every line. Be direct and specific — hole number, what happened, who did it. \
            6 to 8 lines total. Blank line between each. No warmup, no summary, no sign-off.
            """
        }
    }
}

// MARK: - Game Context Builder

private enum GameContextBuilder {

    static func isStableford(_ g: GameData) -> Bool {
        g.resolvedGameType == .tournament &&
        (g.tournamentGameType == "stableford" || g.tournamentGameType == nil)
    }

    static func isMatchPlay(_ g: GameData) -> Bool {
        g.resolvedGameType.isMatchPlay
    }

    static func build(from g: GameData, includeSkins: Bool = false) -> String {
        if isMatchPlay(g) { return buildMatchPlay(from: g) }
        return isStableford(g) ? buildStableford(from: g) : buildWolf(from: g, includeSkins: includeSkins)
    }

    // MARK: - Stableford context

    private static func buildStableford(from g: GameData) -> String {
        var lines: [String] = []
        let courseName = g.course.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let df = DateFormatter(); df.dateStyle = .long; df.timeStyle = .none

        lines.append("GAME FORMAT: Stableford (individual points-based scoring)")
        lines.append("COURSE: \(courseName.isEmpty ? "Unknown Course" : courseName)")
        lines.append("DATE: \(df.string(from: Date()))")

        let activePlayers: [(seat: Int, name: String, hc: Int)] = (0..<MAX_PLAYERS).compactMap { i in
            guard i < g.playerNames.count, i < g.playerActivated.count, g.playerActivated[i] else { return nil }
            let name = g.playerNames[i].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            return (i, name, i < g.hcPlayers.count ? g.hcPlayers[i] : 0)
        }
        let playerList = activePlayers.map { "\($0.name) (HC \($0.hc))" }.joined(separator: ", ")
        lines.append("PLAYERS (\(activePlayers.count)): \(playerList)")
        lines.append("")
        lines.append("POINTS: Net eagle=4, Net birdie=3, Net par=2, Net bogey=1, Net double+=0")
        lines.append("")

        let hasFifthPlayer = activePlayers.count >= 5
        let committed = g.holeCommitted
        let gm = GameManager.shared

        lines.append("HOLE-BY-HOLE:")
        for hole in 0..<STANDARD_HOLES {
            guard hole < committed.count, committed[hole] else { continue }
            let par = g.courseParToPass[safe: hole] ?? 4
            let si  = g.courseHCToPass[safe: hole]  ?? (hole + 1)

            var holeParts: [String] = []
            var allPts: [Int] = []
            for (seat, name, hc) in activePlayers {
                let gross = (seat < g.scores.count) ? g.scores[seat][hole] : nil
                let strokes = gm.absoluteStrokesGiven(playerHC: hc, strokeIndex: si)
                let pts = gm.stablefordPoints(grossScore: gross, par: par, playerHC: hc, strokeIndex: si,
                                              baseline: g.stablefordBaseline) ?? 0
                allPts.append(pts)
                let grossStr = gross.map(String.init) ?? "–"
                let netStr   = gross.map { "\($0 - strokes)" } ?? "–"
                holeParts.append("\(name): \(grossStr) gross / \(netStr) net / \(pts)pt")
            }

            var holeLine = "  Hole \(hole + 1) (Par \(par), SI \(si)): " + holeParts.joined(separator: " | ")
            if !hasFifthPlayer {
                let n = g.stablefordCountingPlayers
                let teamPts = allPts.sorted(by: >).prefix(n).reduce(0, +)
                holeLine += " | TEAM BEST-\(n): \(teamPts)pt"
            }
            lines.append(holeLine)
        }
        lines.append("")

        lines.append("STABLEFORD TOTALS:")
        for (seat, name, _) in activePlayers {
            let total = gm.totalStablefordPoints(playerIndex: seat, game: g)
            lines.append("  \(name): \(total) pts")
        }
        if !hasFifthPlayer {
            let teamTotal = gm.runningTeamStablefordTotal(game: g)
            lines.append("  TEAM TOTAL: \(teamTotal) pts")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Match Play context

    private static func buildMatchPlay(from g: GameData) -> String {
        var lines: [String] = []

        let courseName = g.course.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let df = DateFormatter(); df.dateStyle = .long; df.timeStyle = .none

        let isDual = g.isDualMatch
        let hasTwoVsTwo = (g.nassauState?.twoVsTwoMatches.count ?? 0) > 0
        let formatStr: String
        if isDual      { formatStr = "Dual Match Play (1v1 + 1v1)" }
        else if hasTwoVsTwo { formatStr = "Team Match Play (2v2)" }
        else           { formatStr = "Match Play (1v1)" }

        lines.append("GAME FORMAT: \(formatStr)")
        lines.append("COURSE: \(courseName.isEmpty ? "Unknown Course" : courseName)")
        lines.append("DATE: \(df.string(from: Date()))")

        let activePlayers: [(seat: Int, name: String)] = (0..<MAX_PLAYERS).compactMap { i in
            guard i < g.playerNames.count, i < g.playerActivated.count,
                  g.playerActivated[i] else { return nil }
            let name = g.playerNames[i].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            return (i, name)
        }
        lines.append("PLAYERS (\(activePlayers.count)): \(activePlayers.map(\.name).joined(separator: ", "))")
        lines.append("")

        // Match results from NassauEngine (holes won/lost per segment, no money)
        if let nassau = g.nassauState {
            let summaries = NassauEngine.finalSummaries(
                state: nassau,
                playerNames: g.playerNames,
                gameData: g
            )
            for summary in summaries {
                lines.append("MATCH: \(summary.team1Display) vs \(summary.team2Display)")
                for seg in [summary.front9, summary.back9, summary.overall18].compactMap({ $0 }) {
                    let holesLine = "holes won: \(summary.team1Display) \(seg.holesWonTeam1), \(summary.team2Display) \(seg.holesWonTeam2), halved \(seg.ties)"
                    lines.append("  \(seg.title): \(seg.resultText) (\(holesLine))")
                }
                if !summary.presses.isEmpty {
                    lines.append("  Presses: " + summary.presses.map { "\($0.title): \($0.resultText)" }.joined(separator: "; "))
                }
                lines.append("")
            }
        }

        // Hole-by-hole gross scores (no money columns)
        let pars = g.course.pars
        let committed = g.holeCommitted
        lines.append("HOLE-BY-HOLE SCORES (gross):")
        for hole in 0..<g.totalHoles {
            guard hole < committed.count, committed[hole] else { continue }
            let par = hole < pars.count ? pars[hole] : 4
            let scoreParts: [String] = activePlayers.map { seat, name in
                var s = "–"
                if seat < g.scores.count, hole < g.scores[seat].count, let v = g.scores[seat][hole] { s = "\(v)" }
                return "\(name): \(s)"
            }
            lines.append("  Hole \(hole + 1) (Par \(par)): " + scoreParts.joined(separator: ", "))
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Wolf context (original)

    private static func buildWolf(from g: GameData, includeSkins: Bool = false) -> String {
        var lines: [String] = []

        let courseName = g.course.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let df = DateFormatter(); df.dateStyle = .long; df.timeStyle = .none
        lines.append("COURSE: \(courseName.isEmpty ? "Unknown Course" : courseName)")
        lines.append("DATE: \(df.string(from: Date()))")

        let activePlayers: [(seat: Int, name: String)] = (0..<MAX_PLAYERS).compactMap { i in
            guard i < g.playerNames.count, i < g.playerActivated.count,
                  g.playerActivated[i] else { return nil }
            let name = g.playerNames[i].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            return (i, name)
        }
        let playerList = activePlayers.map(\.name).joined(separator: ", ")
        lines.append("PLAYERS (\(activePlayers.count)): \(playerList)")
        lines.append("")

        // Wolf hole-by-hole
        lines.append("WOLF RESULTS:")
        let pars = g.course.pars
        let committed = g.holeCommitted
        let hammers = g.hammerCountPerHole ?? Array(repeating: 0, count: STANDARD_HOLES)
        let wolfPlayers = g.wolfPlayerPerHole ?? []
        let wolfAlone = g.wolfWentAlonePerHole ?? Array(repeating: false, count: STANDARD_HOLES)
        let wolfTeamWon = g.wolfTeamWonPerHole
        let holeDollars = g.gameHoleDollarsArray

        for hole in 0..<STANDARD_HOLES {
            guard hole < committed.count, committed[hole] else { continue }
            let par = hole < pars.count ? pars[hole] : 4
            let dollars = hole < holeDollars.count ? holeDollars[hole] : 2.0
            let hammerCount = hole < hammers.count ? hammers[hole] : 0

            var wolfName = "?"
            if hole < wolfPlayers.count, let ws = wolfPlayers[hole],
               let player = activePlayers.first(where: { $0.seat == ws }) {
                wolfName = player.name
            }
            let alone = hole < wolfAlone.count ? wolfAlone[hole] : false
            let teamWon = hole < wolfTeamWon.count ? wolfTeamWon[hole] : false

            var holeLine = "  Hole \(hole + 1) (Par \(par), $\(Int(dollars)))"
            if hammerCount > 0 { holeLine += " [×\(hammerCount) hammers]" }
            holeLine += ": Wolf=\(wolfName)\(alone ? " LONE" : "")"
            holeLine += " → \(teamWon ? "Wolf team WON" : "Pack WON")"

            // Scores & per-hole money
            var moneyParts: [String] = []
            for (seat, name) in activePlayers {
                var score = "–"
                if seat < g.scores.count {
                    let row = g.scores[seat]
                    if hole < row.count, let s = row[hole] { score = "\(s)" }
                }
                var money = ""
                if seat < g.playerMoney.count {
                    let m = g.playerMoney[seat]
                    if hole < m.count {
                        let v = m[hole]
                        if v != 0 { money = " (\(v > 0 ? "+" : "")\(Int(v)))" }
                    }
                }
                moneyParts.append("\(name):\(score)\(money)")
            }
            holeLine += " | " + moneyParts.joined(separator: ", ")
            lines.append(holeLine)
        }
        lines.append("")

        // Prox
        let proxWinners = g.proxWinnerPerHole
        var proxByPlayer: [Int: [Int]] = [:]
        for (hole, winner) in proxWinners.enumerated() {
            guard let w = winner else { continue }
            proxByPlayer[w, default: []].append(hole + 1)
        }
        if !proxByPlayer.isEmpty {
            lines.append("PROX WINNERS:")
            for (seat, holes) in proxByPlayer.sorted(by: { $0.key < $1.key }) {
                if let name = activePlayers.first(where: { $0.seat == seat })?.name {
                    lines.append("  \(name): holes \(holes.map(String.init).joined(separator: ", "))")
                }
            }
            lines.append("")
        }

        // Skins (only included when user opts in via the Include Skins toggle)
        if includeSkins, let skins = g.skinsState {
            let skinResults = skins.resultsByHole.filter { !$0.winningPlayerIndexes.isEmpty }
            if !skinResults.isEmpty {
                lines.append("SKINS:")
                for result in skinResults {
                    let winners = result.winningPlayerIndexes.compactMap { idx in
                        activePlayers.first(where: { $0.seat == idx })?.name
                    }
                    if !winners.isEmpty {
                        lines.append("  Hole \(result.holeIndex + 1): \(winners.joined(separator: "/")) won \(result.awardedSkinCount) skin(s) ($\(Int(skins.settings.skinValue * Double(result.awardedSkinCount))))")
                    }
                }
                lines.append("")
                lines.append("Skins totals:")
                for (seat, name) in activePlayers {
                    let skinsWon = seat < skins.skinsWonByPlayer.count ? skins.skinsWonByPlayer[seat] : 0
                    let moneyWon = seat < skins.moneyWonByPlayer.count ? skins.moneyWonByPlayer[seat] : 0
                    if skinsWon > 0 { lines.append("  \(name): \(skinsWon) skin(s), +$\(Int(moneyWon))") }
                }
                lines.append("")
            }
        }

        // Nassau
        if let nassau = g.nassauState, nassau.settings.isEnabled {
            let allMatches = nassau.oneVsOneMatches + nassau.twoVsTwoMatches
            if !allMatches.isEmpty {
                lines.append("NASSAU MATCHES:")
                for match in allMatches {
                    lines.append("  \(match.summaryLine(playerNames: g.playerNames))")
                }
                lines.append("")
            }
        }

        // Money totals
        lines.append("FINAL MONEY:")
        var totalsByPlayer: [(name: String, total: Double)] = []
        for (seat, name) in activePlayers {
            var total = 0.0
            if seat < g.playerMoney.count {
                total = g.playerMoney[seat].prefix(STANDARD_HOLES).reduce(0, +)
            }
            totalsByPlayer.append((name, total))
        }
        for (name, total) in totalsByPlayer.sorted(by: { $0.total > $1.total }) {
            let sign = total >= 0 ? "+" : ""
            lines.append("  \(name): \(sign)$\(Int(total.rounded()))")
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - Tournament Context Builder

private enum TournamentContextBuilder {

    static func build(code: String, day: Int, tournamentName: String,
                      courseName: String, gameType: String,
                      coursePars: [Int]) async throws -> String {
        let rows = try await SupabaseService.shared.fetchTournamentHoleScores(code: code)
        let dayRows = rows.filter { ($0.day ?? 1) == day }

        var lines: [String] = []
        let df = DateFormatter(); df.dateStyle = .long; df.timeStyle = .none
        lines.append("TOURNAMENT: \(tournamentName)")
        lines.append("COURSE: \(courseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Unknown Course" : courseName)")
        lines.append("DATE: \(df.string(from: Date()))")
        lines.append("DAY: \(day)")
        lines.append("GAME TYPE: \(gameType)")
        lines.append("")

        let isScramble = gameType.lowercased() == "scramble"

        // Aggregate per-team/player totals.
        // Scramble: holeMoney/totalMoney are always 0 — use cumulative netScore (gross - par) instead.
        // All other formats: use totalMoney from the latest submitted hole.
        var playerTotals: [String: Double] = [:]
        var playerHolesPlayed: [String: Int] = [:]
        if isScramble {
            var netSums: [String: Double] = [:]
            for row in dayRows {
                let name = row.playerName
                playerHolesPlayed[name] = max(playerHolesPlayed[name] ?? 0, row.hole)
                if let net = row.netScore { netSums[name, default: 0] += Double(net) }
            }
            playerTotals = netSums
        } else {
            for row in dayRows {
                let name = row.playerName
                playerHolesPlayed[name] = max(playerHolesPlayed[name] ?? 0, row.hole)
                if let total = row.totalMoney, row.hole >= (playerHolesPlayed[name] ?? 0) {
                    playerTotals[name] = total
                }
            }
        }

        func vsParLabel(_ val: Double) -> String {
            let n = Int(val.rounded())
            if n == 0 { return "E" }
            return n > 0 ? "+\(n)" : "\(n)"
        }

        // Overall leaderboard — Scramble sorts ascending (lower score = better), others descending.
        let leaderboard = playerTotals.sorted { isScramble ? $0.value < $1.value : $0.value > $1.value }
        lines.append("OVERALL LEADERBOARD (\(leaderboard.count) \(isScramble ? "teams" : "players")):")
        for (i, (name, total)) in leaderboard.enumerated() {
            let holes = playerHolesPlayed[name] ?? 0
            let standing = isScramble ? vsParLabel(total) : { let s = total >= 0 ? "+" : ""; return "\(s)$\(Int(total.rounded()))" }()
            lines.append("  #\(i + 1) \(name): \(standing) (thru \(holes))")
        }
        lines.append("")

        // Group by matchId (each matchId is one scorer group's round)
        var byMatch: [String: [TournamentHoleScoreRow]] = [:]
        for row in dayRows { byMatch[row.matchId, default: []].append(row) }

        lines.append("GROUPS (\(byMatch.count) scoring group\(byMatch.count == 1 ? "" : "s")):")
        for (_, groupRows) in byMatch.sorted(by: { $0.key < $1.key }) {
            let playerNames = Array(Set(groupRows.map { $0.playerName })).sorted()
            let maxHole = groupRows.map { $0.hole }.max() ?? 0
            lines.append("")
            lines.append("  \(isScramble ? "Team" : "Players"): \(playerNames.joined(separator: ", ")) | Thru hole \(maxHole)")

            // Hole-by-hole for this group
            let holesInGroup = Array(Set(groupRows.map { $0.hole })).sorted()
            for hole in holesInGroup {
                let holeRows = groupRows.filter { $0.hole == hole }
                    .sorted { $0.playerName < $1.playerName }
                let par = (hole - 1) < coursePars.count ? coursePars[hole - 1] : 4
                var parts: [String] = []
                for row in holeRows {
                    var part: String
                    if isScramble {
                        let netStr = row.netScore.map { vsParLabel(Double($0)) } ?? "–"
                        part = "\(row.playerName): \(row.grossScore) (\(netStr))"
                    } else {
                        part = "\(row.playerName): \(row.grossScore) gross"
                        if let net = row.netScore { part += "/\(net) net" }
                        if let money = row.holeMoney, money != 0 {
                            let sign = money >= 0 ? "+" : ""
                            part += " (\(sign)$\(Int(money.rounded())))"
                        }
                    }
                    parts.append(part)
                }
                lines.append("    Hole \(hole) (Par \(par)): " + parts.joined(separator: " | "))
            }

            // Group running totals
            lines.append("    Running total: " + playerNames.compactMap { name -> String? in
                guard let total = playerTotals[name] else { return nil }
                if isScramble { return "\(name) \(vsParLabel(total))" }
                let sign = total >= 0 ? "+" : ""
                return "\(name) \(sign)$\(Int(total.rounded()))"
            }.joined(separator: ", "))
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - NassauMatch summary helper

private extension NassauMatch {
    func summaryLine(playerNames: [String]) -> String {
        func name(_ idx: Int) -> String {
            guard idx >= 0, idx < playerNames.count else { return "Player \(idx + 1)" }
            let n = playerNames[idx].trimmingCharacters(in: .whitespacesAndNewlines)
            return n.isEmpty ? "Player \(idx + 1)" : n
        }
        let side1 = team1PlayerIndexes.map(name).joined(separator: "/")
        let side2 = team2PlayerIndexes.map(name).joined(separator: "/")
        return "\(side1) vs \(side2) ($\(Int(stake))/side)"
    }
}

// MARK: - AISummaryViewController

final class AISummaryViewController: UIViewController, MFMessageComposeViewControllerDelegate {

    private enum State { case picker, loading, result(String, SummaryStyle) }
    private var state: State = .picker { didSet { applyState() } }
    private var limitWarningSentThisSession = false
    private var includeSkins: Bool = false

    // Picker
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let noteField = UITextField()

    // Loading
    private let spinner   = UIActivityIndicatorView(style: .large)
    private let loadLabel = UILabel()

    // Result
    private let scrollView  = UIScrollView()
    private let summaryLabel = UILabel()
    private let shareGroupBtn  = UIButton(type: .system)
    private let shareOrgBtn    = UIButton(type: .system)
    private let bottomStack    = UIStackView()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "AI Summary"
        view.backgroundColor = .systemGroupedBackground

        setupPicker()
        setupLoading()
        setupResult()
        applyState()
    }

    // MARK: - Setup

    private func setupPicker() {
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(StyleCell.self, forCellReuseIdentifier: StyleCell.reuseID)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "NoteCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SkinsCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .systemGroupedBackground
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupLoading() {
        spinner.translatesAutoresizingMaskIntoConstraints = false
        loadLabel.translatesAutoresizingMaskIntoConstraints = false
        let isTournament = GameManager.shared.currentGame?.tournamentCode != nil
        loadLabel.text = isTournament ? "Fetching all groups & generating recap…" : "Generating your round recap…"
        loadLabel.font = .systemFont(ofSize: 16, weight: .medium)
        loadLabel.textColor = .secondaryLabel
        loadLabel.textAlignment = .center
        view.addSubview(spinner)
        view.addSubview(loadLabel)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            loadLabel.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 16),
            loadLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    private func setupResult() {
        summaryLabel.numberOfLines = 0
        summaryLabel.font = .systemFont(ofSize: 16)
        summaryLabel.textColor = .label
        summaryLabel.translatesAutoresizingMaskIntoConstraints = false

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.addSubview(summaryLabel)
        view.addSubview(scrollView)

        // Share buttons
        configureShareButton(shareGroupBtn, title: "Share with Group", isPrimary: true)
        configureShareButton(shareOrgBtn,   title: "Copy Organizer",   isPrimary: false)
        shareGroupBtn.addTarget(self, action: #selector(shareGroupTapped), for: .touchUpInside)
        shareOrgBtn.addTarget(self, action: #selector(shareOrgTapped),   for: .touchUpInside)

        bottomStack.axis = .vertical
        bottomStack.spacing = 10
        bottomStack.translatesAutoresizingMaskIntoConstraints = false
        bottomStack.addArrangedSubview(shareGroupBtn)
        bottomStack.addArrangedSubview(shareOrgBtn)
        view.addSubview(bottomStack)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            bottomStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            bottomStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bottomStack.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -14),
            shareGroupBtn.heightAnchor.constraint(equalToConstant: 50),
            shareOrgBtn.heightAnchor.constraint(equalToConstant: 50),

            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomStack.topAnchor, constant: -12),

            summaryLabel.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            summaryLabel.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            summaryLabel.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            summaryLabel.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            summaryLabel.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),
        ])
    }

    private func configureShareButton(_ btn: UIButton, title: String, isPrimary: Bool) {
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        if isPrimary {
            btn.backgroundColor = UIColor(red: 0.106, green: 0.227, blue: 0.165, alpha: 1)
            btn.setTitleColor(.white, for: .normal)
        } else {
            btn.backgroundColor = .secondarySystemBackground
            btn.setTitleColor(UIColor(red: 0.106, green: 0.227, blue: 0.165, alpha: 1), for: .normal)
            btn.layer.borderWidth = 1.5
            btn.layer.borderColor = UIColor(red: 0.106, green: 0.227, blue: 0.165, alpha: 1).cgColor
        }
    }

    // MARK: - State

    private func applyState() {
        switch state {
        case .picker:
            tableView.isHidden   = false
            tableView.reloadData()
            spinner.isHidden     = true
            spinner.stopAnimating()
            loadLabel.isHidden   = true
            scrollView.isHidden  = true
            bottomStack.isHidden = true
            navigationItem.rightBarButtonItem = nil

        case .loading:
            tableView.isHidden   = true
            spinner.isHidden     = false
            spinner.startAnimating()
            loadLabel.isHidden   = false
            scrollView.isHidden  = true
            bottomStack.isHidden = true
            navigationItem.rightBarButtonItem = nil

        case .result(let text, _):
            tableView.isHidden   = true
            spinner.isHidden     = true
            spinner.stopAnimating()
            loadLabel.isHidden   = true
            scrollView.isHidden  = false
            bottomStack.isHidden = false
            summaryLabel.text    = text
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "Try Again", style: .plain,
                target: self, action: #selector(tryAgainTapped)
            )
        }
    }

    // MARK: - Generation

    private func generate(style: SummaryStyle) {
        guard let game = GameManager.shared.currentGame else { return }
        let pm = PremiumManager.shared
        guard pm.canUse(.aiSummary) else {
            showMonthlyLimitReached()
            return
        }
        noteField.resignFirstResponder()
        state = .loading

        let note = noteField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let isTournament = game.tournamentCode != nil
        let isScramble   = isTournament && (game.tournamentGameType == "scramble")
        let isMatchPlay  = !isTournament && GameContextBuilder.isMatchPlay(game)
        let isStableford = !isTournament && !isMatchPlay && GameContextBuilder.isStableford(game)
        let systemPrompt = style.systemPrompt(isStableford: isStableford, isTournament: isTournament, isMatchPlay: isMatchPlay, isScramble: isScramble)

        Task {
            do {
                var context: String
                if let code = game.tournamentCode {
                    context = try await TournamentContextBuilder.build(
                        code: code,
                        day: game.tournamentDay ?? 1,
                        tournamentName: game.tournamentName ?? "Tournament",
                        courseName: game.course.name,
                        gameType: game.tournamentGameType ?? "wolf",
                        coursePars: game.course.pars
                    )
                } else {
                    context = GameContextBuilder.build(from: game, includeSkins: includeSkins)
                }
                if !note.isEmpty {
                    context += "\n\nAdditional context from the scorer: \(note)"
                }

                let text = try await ClaudeService.generate(
                    systemPrompt: systemPrompt,
                    userMessage: "Here is the golf round data. Write your recap:\n\n\(context)"
                )
                await MainActor.run {
                    pm.recordUse(.aiSummary)
                    pm.nudgeIfNeeded(for: .aiSummary, from: self)
                    self.state = .result(text, style)
                }
            } catch {
                await MainActor.run {
                    self.state = .picker
                    self.showError(error.localizedDescription)
                }
            }
        }
    }

    private func showMonthlyLimitReached() {
        let pm = PremiumManager.shared
        let monthFmt = DateFormatter()
        monthFmt.dateFormat = "yyyy-MM"
        let month = monthFmt.string(from: Date())

        let displayFmt = DateFormatter()
        displayFmt.dateFormat = "MMMM"
        let monthName = displayFmt.string(from: Date())

        let usageCount = pm.usageCount(for: .aiSummary)
        let freeLimit = PremiumManager.Feature.aiSummary.freeLimit
        let wasPremiumThisMonth = PremiumManager.wasPremiumThisMonth()

        AnalyticsService.track("ai_summary_limit_hit", properties: [
            "user_id": DeviceID.id,
            "usage_count": usageCount,
            "free_limit": freeLimit,
            "month": month,
            "was_premium_this_month": wasPremiumThisMonth,
        ])

        let ac = UIAlertController(
            title: "Monthly Limit Reached",
            message: "You've used your 5 free AI summaries for \(monthName). Upgrade to WolfMore Premium for unlimited summaries.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "Upgrade to Premium", style: .default) { [weak self] _ in
            guard let self else { return }
            AnalyticsService.track("ai_summary_upgrade_tapped", properties: [
                "user_id": DeviceID.id,
                "source": "ai_summary_limit_alert",
                "usage_count": usageCount,
                "month": month,
            ])
            self.present(PaywallViewController(feature: .aiSummary), animated: true)
        })
        ac.addAction(UIAlertAction(title: "Maybe Next Month", style: .cancel) { _ in
            AnalyticsService.track("ai_summary_upgrade_dismissed", properties: [
                "user_id": DeviceID.id,
                "usage_count": usageCount,
                "month": month,
            ])
        })
        present(ac, animated: true)
    }

    // MARK: - Actions

    @objc private func tryAgainTapped() {
        state = .picker
    }

    @objc private func shareGroupTapped() {
        guard case .result(let text, _) = state else { return }
        let vc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let pop = vc.popoverPresentationController {
            pop.sourceView = shareGroupBtn; pop.sourceRect = shareGroupBtn.bounds
        }
        present(vc, animated: true)
    }

    @objc private func shareOrgTapped() {
        guard case .result(let text, _) = state else { return }
        let stripped = stripMoney(from: text)

        let orgName  = ProfileStore.organizerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let orgPhone = ProfileStore.organizerPhone.trimmingCharacters(in: .whitespacesAndNewlines)

        if orgPhone.isEmpty {
            promptSetOrganizer { [weak self] in self?.shareOrgTapped() }
            return
        }

        if MFMessageComposeViewController.canSendText() {
            let mc = MFMessageComposeViewController()
            mc.messageComposeDelegate = self
            mc.recipients = [orgPhone]
            mc.body = stripped
            present(mc, animated: true)
        } else {
            let shareText = orgName.isEmpty ? stripped : "For \(orgName):\n\(stripped)"
            let vc = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
            if let pop = vc.popoverPresentationController {
                pop.sourceView = shareOrgBtn; pop.sourceRect = shareOrgBtn.bounds
            }
            present(vc, animated: true)
        }
    }

    private func promptSetOrganizer(completion: (() -> Void)? = nil) {
        let ac = UIAlertController(
            title: "Set Organizer Contact",
            message: "Save a name and phone number for your group organizer. Used for 'Copy Organizer' shares.",
            preferredStyle: .alert
        )
        ac.addTextField { tf in
            tf.placeholder = "Name (e.g. Pete)"
            tf.autocapitalizationType = .words
            tf.text = ProfileStore.organizerName
        }
        ac.addTextField { tf in
            tf.placeholder = "Phone number"
            tf.keyboardType = .phonePad
            tf.text = ProfileStore.organizerPhone
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Save", style: .default) { [weak ac] _ in
            let name  = ac?.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let phone = ac?.textFields?[1].text?.filter(\.isNumber) ?? ""
            ProfileStore.organizerName  = name
            ProfileStore.organizerPhone = phone
            completion?()
        })
        present(ac, animated: true)
    }

    // MFMessageComposeViewControllerDelegate
    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                      didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
    }

    // MARK: - Helpers

    private func stripMoney(from text: String) -> String {
        // Remove dollar amounts ($12, +$32, -$8, $1.50, etc.)
        var result = text
        let pattern = "[+-]?\\$\\d+(\\.\\d{1,2})?"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, range: range, withTemplate: "")
        }
        // Collapse double spaces
        while result.contains("  ") { result = result.replacingOccurrences(of: "  ", with: " ") }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func showError(_ message: String) {
        let ac = UIAlertController(title: "Couldn't Generate Summary",
                                   message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}

// MARK: - UITableViewDataSource / Delegate

extension AISummaryViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { 3 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:  return 1                        // personal note
        case 1:  return 1                        // skins toggle
        default: return SummaryStyle.allCases.count
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:  return "Add a personal note (optional)"
        case 1:  return "Options"
        default: return "Choose a voice for your round recap"
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section == 2 else { return nil }
        let pm = PremiumManager.shared
        if pm.isPremium { return nil }
        let remaining = pm.remainingFreeUses(for: .aiSummary)
        if remaining == 0 {
            let fmt = DateFormatter()
            fmt.dateFormat = "MMMM"
            return "You've used all 5 free AI summaries for \(fmt.string(from: Date())). Tap to upgrade."
        }
        if remaining <= 2 {
            if !limitWarningSentThisSession {
                limitWarningSentThisSession = true
                let keyFmt = DateFormatter()
                keyFmt.dateFormat = "yyyy-MM"
                AnalyticsService.track("ai_summary_limit_warning_shown", properties: [
                    "user_id": DeviceID.id,
                    "remaining_count": remaining,
                    "month": keyFmt.string(from: Date()),
                ])
            }
            return "\(remaining) AI \(remaining == 1 ? "summary" : "summaries") left this month."
        }
        return nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell", for: indexPath)
            if noteField.superview == nil {
                noteField.placeholder = "Any moments or inside jokes to include?"
                noteField.font = .systemFont(ofSize: 15)
                noteField.returnKeyType = .done
                noteField.delegate = self
                noteField.translatesAutoresizingMaskIntoConstraints = false
                cell.contentView.addSubview(noteField)
                NSLayoutConstraint.activate([
                    noteField.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                    noteField.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                    noteField.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                    noteField.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
                ])
            }
            cell.selectionStyle = .none
            return cell
        }

        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SkinsCell", for: indexPath)
            cell.textLabel?.text = "Include Skins"
            cell.textLabel?.font = .systemFont(ofSize: 15)
            cell.selectionStyle = .none
            let sw = UISwitch()
            sw.isOn = includeSkins
            sw.onTintColor = UIColor(red: 0.106, green: 0.227, blue: 0.165, alpha: 1)
            sw.addTarget(self, action: #selector(skinsToggled(_:)), for: .valueChanged)
            cell.accessoryView = sw
            return cell
        }

        let style = SummaryStyle.allCases[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: StyleCell.reuseID, for: indexPath) as! StyleCell
        cell.configure(style: style)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:  return 50
        case 1:  return 44
        default: return 72
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 2 else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        let style = SummaryStyle.allCases[indexPath.row]
        generate(style: style)
    }
}

// MARK: - UITextFieldDelegate

extension AISummaryViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Skins toggle

extension AISummaryViewController {
    @objc private func skinsToggled(_ sender: UISwitch) {
        includeSkins = sender.isOn
    }
}

// MARK: - StyleCell

private final class StyleCell: UITableViewCell {
    static let reuseID = "StyleCell"

    private let emojiLabel    = UILabel()
    private let titleLabel    = UILabel()
    private let subtitleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator

        emojiLabel.font = .systemFont(ofSize: 28)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiLabel.widthAnchor.constraint(equalToConstant: 44).isActive = true

        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 3

        let row = UIStackView(arrangedSubviews: [emojiLabel, textStack])
        row.axis = .horizontal
        row.spacing = 10
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(style: SummaryStyle) {
        emojiLabel.text    = style.emoji
        titleLabel.text    = style.title
        subtitleLabel.text = style.subtitle
    }
}
