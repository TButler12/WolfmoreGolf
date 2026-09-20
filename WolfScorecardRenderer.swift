import UIKit

// MARK: - WolfScorecardRenderer
//
// Renders a traditional gross-score scorecard as a retina PNG suitable for
// sharing via iMessage, AirDrop, or Photos.
//
// Score annotations (per traditional scorecard convention):
//   Eagle or better → double circle
//   Birdie          → single circle
//   Par             → plain number
//   Bogey           → single square
//   Double bogey+   → double square
//
// Wolf team coloring (per hole, from wolfMaskByHole):
//   Wolf team member → warm red cell background
//   Pack member      → light blue cell background
//   No wolf called   → neutral row background

final class WolfScorecardRenderer {

    // ── Layout ────────────────────────────────────────────────
    private let pageW:   CGFloat = 1080
    private let hPad:    CGFloat = 24
    private let nameW:   CGFloat = 110
    private let holeW:   CGFloat = 42
    private let summW:   CGFloat = 54

    private let hdrH:    CGFloat = 22
    private let parH:    CGFloat = 22
    private let playerH: CGFloat = 36   // single row per player — tall enough for annotations

    // ── Input ─────────────────────────────────────────────────
    private let game: GameData
    private let date: Date

    init(game: GameData, date: Date = Date()) {
        self.game = game
        self.date = date
    }

    // MARK: - Public entry point

    func render() -> UIImage {
        let players = buildPlayers()
        let pars    = (0..<STANDARD_HOLES).map { game.courseParToPass[safe: $0] ?? 4 }
        let bbTeams = buildBestBallTeams(players: players, pars: pars)

        // Build match statuses (1 for single match, 2 for dual 1v1).
        var mpStatuses: [MatchPlayStatusData] = []
        if game.resolvedGameType == .matchPlay {
            let isDual = game.isDualMatch
            if let s = buildMatchPlayStatus(
                rawTeamA: game.matchPlayTeamA ?? [], rawTeamB: game.matchPlayTeamB ?? [],
                players: players, pars: pars, matchLabel: isDual ? "Match 1" : "Match") {
                mpStatuses.append(s)
            }
            if isDual, let s = buildMatchPlayStatus(
                rawTeamA: game.matchPlayTeamA2 ?? [], rawTeamB: game.matchPlayTeamB2 ?? [],
                players: players, pars: pars, matchLabel: "Match 2") {
                mpStatuses.append(s)
            }
        }

        let teamsLine: String?
        if mpStatuses.count == 2 {
            teamsLine = "M1: \(mpStatuses[0].teamALabel) vs. \(mpStatuses[0].teamBLabel)   M2: \(mpStatuses[1].teamALabel) vs. \(mpStatuses[1].teamBLabel)"
        } else {
            teamsLine = mpStatuses.first.map { "Teams: \($0.teamALabel) vs. \($0.teamBLabel)" }
        }

        let teamTeeRow = buildTeamTeeRow()

        let docHdrH: CGFloat   = teamsLine != nil ? 114 : 96
        let totalPlayerRows = players.reduce(0) { $0 + ($1.gross2 != nil ? 2 : 1) }
        let extraRows = bbTeams.count + mpStatuses.count + (teamTeeRow != nil ? 1 : 0)
        let gridH   = hdrH + parH + CGFloat(totalPlayerRows + extraRows) * playerH
        let footerH: CGFloat = !mpStatuses.isEmpty ? 60 : 40
        let totalH  = docHdrH + gridH + footerH

        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 2
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: pageW, height: totalH), format: fmt)

        return renderer.image { _ in
            UIColor.white.setFill()
            UIRectFill(CGRect(x: 0, y: 0, width: pageW, height: totalH))

            var y: CGFloat = 0
            y = drawDocHeader(y: y, players: players, teamsLine: teamsLine)
            y = drawGrid(y: y, players: players, pars: pars, bbTeams: bbTeams,
                         mpStatuses: mpStatuses, teamTeeRow: teamTeeRow)
            let footerResult: String?
            if mpStatuses.count == 2 {
                footerResult = "M1: \(mpStatuses[0].finalResult)  ·  M2: \(mpStatuses[1].finalResult)"
            } else {
                footerResult = mpStatuses.first?.finalResult
            }
            drawFooter(y: y, matchResult: footerResult)
        }
    }

    // MARK: - Data builder

    private struct PlayerData {
        let seat:  Int
        let name:  String
        let hc:    Int
        let gross: [Int?]    // 18 elements (round 1), nil = unplayed
        let gross2: [Int?]?  // 18 elements (round 2), nil if not a 36-hole round
    }

    private func buildPlayers() -> [PlayerData] {
        let is36 = game.matchPlay36Holes

        // For 9-hole games, map 0-based course hole index → match position so scores
        // land in the correct physical-hole column of the 18-column card.
        let nineSeqMap: [Int: Int]? = game.isNineHoleMatch ? {
            var m = [Int: Int]()
            for (mp, ch) in game.nineHoleSequence.enumerated() { m[ch] = mp }
            return m
        }() : nil

        let cap = min(game.playerNames.count, game.playerActivated.count)
        return (0..<cap).compactMap { seat -> PlayerData? in
            guard game.playerActivated[seat] else { return nil }
            let name = game.playerNames[seat].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            let hc = game.hcPlayers[safe: seat] ?? 0
            let gross: [Int?]
            if let seqMap = nineSeqMap {
                gross = (0..<STANDARD_HOLES).map { courseH -> Int? in
                    guard let mp = seqMap[courseH] else { return nil }
                    guard game.holeCommitted[safe: mp] == true else { return nil }
                    return game.scores[safe: seat]?[safe: mp] ?? nil
                }
            } else {
                gross = (0..<STANDARD_HOLES).map { h -> Int? in
                    guard game.holeCommitted[safe: h] == true else { return nil }
                    return game.scores[safe: seat]?[safe: h] ?? nil
                }
            }
            let gross2: [Int?]? = is36 ? (STANDARD_HOLES..<(2 * STANDARD_HOLES)).map { h -> Int? in
                guard seat < game.scores.count, h < game.scores[seat].count else { return nil }
                return game.scores[seat][h]
            } : nil
            return PlayerData(seat: seat, name: name, hc: hc, gross: gross, gross2: gross2)
        }
    }

    // MARK: - Team Tee Game row builder

    private struct TeamTeeRowData {
        let modeLabel: String    // e.g. "Fixed 2" or "By Par 4/3/2"
        let netPerHole: [Int?]   // 18 elements — nil = hole not committed
    }

    private func buildTeamTeeRow() -> TeamTeeRowData? {
        guard let settings = game.teamTeeSettings, settings.isEnabled else { return nil }
        guard let result = TeamTeeEngine.recalculate(gameData: game), result.holesCompleted > 0 else { return nil }

        let modeLabel: String = {
            switch settings.countMode {
            case .fixed: return "Fixed \(settings.fixedCount)"
            case .byPar: return "By Par \(settings.par3Count)/\(settings.par4Count)/\(settings.par5Count)"
            }
        }()

        var netPerHole: [Int?] = Array(repeating: nil, count: STANDARD_HOLES)
        for mp in 0..<game.totalHoles {
            let ch = game.courseHoleIndex(for: mp)
            if ch < STANDARD_HOLES, let hr = result.holeResults[safe: mp] {
                netPerHole[ch] = hr?.netScore
            }
        }
        return TeamTeeRowData(modeLabel: modeLabel, netPerHole: netPerHole)
    }

    // MARK: - Best Ball team data builder

    private struct BestBallTeamData {
        let label:        String    // e.g. "Team A: Alice & Bob"
        let countingGross: [Int?]   // 18 elements — gross of the better-net player each hole
    }

    private func buildBestBallTeams(players: [PlayerData], pars: [Int]) -> [BestBallTeamData] {
        guard game.resolvedGameType == .bestBall else { return [] }

        let activeSeats = players.map { $0.seat }
        guard !activeSeats.isEmpty else { return [] }

        let baseHC = activeSeats.compactMap { game.hcPlayers[safe: $0] }.min() ?? 0

        func strokesGiven(seat: Int, holeIdx: Int) -> Int {
            let si = { () -> Int in
                let raw = game.courseHCToPass[safe: holeIdx] ?? STANDARD_HOLES
                return max(1, min(STANDARD_HOLES, raw == 0 ? STANDARD_HOLES : raw))
            }()
            let delta = max(0, (game.hcPlayers[safe: seat] ?? 0) - baseHC)
            if delta <= STANDARD_HOLES { return si <= delta ? 1 : 0 }
            return 1 + (si <= (delta - STANDARD_HOLES) ? 1 : 0)
        }

        func teamRow(seats: [Int], label: String) -> BestBallTeamData? {
            guard !seats.isEmpty else { return nil }
            let counting: [Int?] = (0..<STANDARD_HOLES).map { h in
                var bestNet = Int.max
                var bestGross: Int? = nil
                for s in seats {
                    guard let g = game.scores[safe: s]?[safe: h] ?? nil else { continue }
                    let net = g - strokesGiven(seat: s, holeIdx: h)
                    if net < bestNet { bestNet = net; bestGross = g }
                }
                return bestGross
            }
            return BestBallTeamData(label: label, countingGross: counting)
        }

        func playerName(_ seat: Int) -> String {
            (game.playerNames[safe: seat] ?? "P\(seat + 1)")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let teamA = (game.matchPlayTeamA ?? []).filter { activeSeats.contains($0) }
        let teamB = (game.matchPlayTeamB ?? []).filter { activeSeats.contains($0) }

        guard !teamA.isEmpty, !teamB.isEmpty else { return [] }

        let labelA = "Team A: " + teamA.map { playerName($0) }.joined(separator: " & ")
        let labelB = "Team B: " + teamB.map { playerName($0) }.joined(separator: " & ")

        return [teamRow(seats: teamA, label: labelA), teamRow(seats: teamB, label: labelB)]
            .compactMap { $0 }
    }

    // MARK: - Match Play status builder

    private struct MatchPlayStatusData {
        let matchLabel:    String     // "Match", "Match 1", "Match 2"
        let teamALabel:    String
        let teamBLabel:    String
        let statusPerHole: [String?]  // 18 elements, nil = hole not yet scored
        let outStatus:     String?    // running lead after hole 9
        let inStatus:      String?    // running lead after hole 18
        let shortResult:   String     // e.g. "3&2", "2 UP", "AS"
        let finalResult:   String     // full footer text
    }

    private func buildMatchPlayStatus(rawTeamA: [Int], rawTeamB: [Int],
                                       players: [PlayerData], pars: [Int],
                                       matchLabel: String) -> MatchPlayStatusData? {
        let activeSeats = players.map { $0.seat }
        let teamA = rawTeamA.filter { activeSeats.contains($0) }
        let teamB = rawTeamB.filter { activeSeats.contains($0) }
        guard !teamA.isEmpty, !teamB.isEmpty else { return nil }

        let baseHC = activeSeats.compactMap { game.hcPlayers[safe: $0] }.min() ?? 0

        func strokes(seat: Int, h: Int) -> Int {
            let raw = game.courseHCToPass[safe: h] ?? STANDARD_HOLES
            let si  = max(1, min(STANDARD_HOLES, raw == 0 ? STANDARD_HOLES : raw))
            let d   = max(0, (game.hcPlayers[safe: seat] ?? 0) - baseHC)
            if d <= STANDARD_HOLES { return si <= d ? 1 : 0 }
            return 1 + (si <= (d - STANDARD_HOLES) ? 1 : 0)
        }

        func playerName(_ seat: Int) -> String {
            (game.playerNames[safe: seat] ?? "P\(seat+1)")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        func leadStr(_ lead: Int) -> String {
            if lead == 0 { return "AS" }
            return lead > 0 ? "+\(lead)" : "\(lead)"
        }

        let teamALabel = teamA.map { playerName($0) }.joined(separator: " & ")
        let teamBLabel = teamB.map { playerName($0) }.joined(separator: " & ")

        // For 9-hole, iterate match positions (playing order) so scores land at
        // physical course-hole positions in statusPerHole.
        let nineSeq: [Int]? = game.isNineHoleMatch ? game.nineHoleSequence : nil
        let totalMatchHoles = nineSeq != nil ? 9 : STANDARD_HOLES

        var runningLead = 0
        var statusPerHole = [String?](repeating: nil, count: STANDARD_HOLES)
        var decisiveData: (lead: Int, remaining: Int)? = nil
        var holesPlayed  = 0

        for i in 0..<totalMatchHoles {
            let h        = nineSeq?[i] ?? i   // 0-based course hole index
            let scoreIdx = i                   // match position == score array index

            let aN = teamA.compactMap { s -> Int? in
                guard game.holeCommitted[safe: scoreIdx] == true else { return nil }
                guard let g = game.scores[safe: s]?[safe: scoreIdx] ?? nil else { return nil }
                return g - strokes(seat: s, h: h)
            }.min()
            let bN = teamB.compactMap { s -> Int? in
                guard game.holeCommitted[safe: scoreIdx] == true else { return nil }
                guard let g = game.scores[safe: s]?[safe: scoreIdx] ?? nil else { return nil }
                return g - strokes(seat: s, h: h)
            }.min()
            guard let aN, let bN else { break }

            if aN < bN      { runningLead += 1 }
            else if bN < aN { runningLead -= 1 }

            holesPlayed = i + 1
            let remaining = totalMatchHoles - holesPlayed
            if decisiveData == nil && abs(runningLead) > remaining {
                decisiveData = (runningLead, remaining)
            }
            statusPerHole[h] = leadStr(runningLead)
        }

        // OUT/IN subtotals only make sense for standard 18-hole games.
        let outStatus = (nineSeq == nil && holesPlayed >= 9)  ? statusPerHole[8]  : nil
        let inStatus  = (nineSeq == nil && holesPlayed >= 18) ? statusPerHole[17] : nil

        let shortResult: String
        let finalResult: String
        if holesPlayed == 0 {
            shortResult = "—"; finalResult = "—"
        } else if let dd = decisiveData {
            let margin = abs(dd.lead)
            let winner = dd.lead > 0 ? teamALabel : teamBLabel
            shortResult = dd.remaining == 0 ? "\(margin) UP" : "\(margin)&\(dd.remaining)"
            finalResult = dd.remaining == 0 ? "\(winner) won \(margin) UP"
                                            : "\(winner) won \(margin)&\(dd.remaining)"
        } else if holesPlayed == totalMatchHoles {
            if runningLead == 0 {
                shortResult = "AS"; finalResult = "All Square"
            } else {
                let winner = runningLead > 0 ? teamALabel : teamBLabel
                shortResult = "\(abs(runningLead)) UP"
                finalResult = "\(winner) won \(abs(runningLead)) UP"
            }
        } else {
            shortResult = "\(leadStr(runningLead)) / \(holesPlayed) holes"
            finalResult = shortResult
        }

        return MatchPlayStatusData(
            matchLabel:    matchLabel,
            teamALabel:    teamALabel,
            teamBLabel:    teamBLabel,
            statusPerHole: statusPerHole,
            outStatus:     outStatus,
            inStatus:      inStatus,
            shortResult:   shortResult,
            finalResult:   finalResult
        )
    }

    // MARK: - Document header

    @discardableResult
    private func drawDocHeader(y: CGFloat, players: [PlayerData], teamsLine: String? = nil) -> CGFloat {
        var cy = y + 20

        drawCentered("WOLFMORE SCORECARD", y: cy,
                     font: .systemFont(ofSize: 26, weight: .bold), color: .black)
        cy += 34

        let dateFmt = DateFormatter()
        dateFmt.dateStyle = .medium
        dateFmt.timeStyle = .none
        drawCentered("\(game.course.name)  ·  \(dateFmt.string(from: date))", y: cy,
                     font: .systemFont(ofSize: 15, weight: .regular),
                     color: UIColor(white: 0.35, alpha: 1))
        cy += 22

        let names = players.map { $0.name }.joined(separator: " · ")
        drawCentered("Group: \(names)", y: cy,
                     font: .systemFont(ofSize: 13, weight: .regular),
                     color: UIColor(white: 0.50, alpha: 1))
        cy += 18

        if let tl = teamsLine {
            drawCentered(tl, y: cy,
                         font: .systemFont(ofSize: 12, weight: .semibold),
                         color: UIColor(red: 0.20, green: 0.44, blue: 0.70, alpha: 1))
            cy += 18
        }

        return cy + 8
    }

    // MARK: - Scorecard grid

    @discardableResult
    private func drawGrid(y: CGFloat, players: [PlayerData], pars: [Int],
                          bbTeams: [BestBallTeamData] = [],
                          mpStatuses: [MatchPlayStatusData] = [],
                          teamTeeRow: TeamTeeRowData? = nil) -> CGFloat {

        // Column x-positions: ci 0=name, 1-9=h1-9, 10=OUT, 11-19=h10-18, 20=IN, 21=TOT
        var colXs = [CGFloat](repeating: 0, count: 22)
        var cx = hPad
        colXs[0] = cx; cx += nameW
        for i in 1...9   { colXs[i] = cx; cx += holeW }
        colXs[10] = cx;  cx += summW
        for i in 11...19 { colXs[i] = cx; cx += holeW }
        colXs[20] = cx;  cx += summW
        colXs[21] = cx;  cx += summW
        let gridW = cx - hPad

        func colW(_ ci: Int) -> CGFloat {
            (ci == 10 || ci == 20 || ci == 21) ? summW : (ci == 0 ? nameW : holeW)
        }
        func hIdx(_ ci: Int) -> Int? {
            if ci >= 1  && ci <= 9  { return ci - 1 }
            if ci >= 11 && ci <= 19 { return ci - 2 }
            return nil
        }
        func isSumm(_ ci: Int) -> Bool { ci == 10 || ci == 20 || ci == 21 }

        // Wolf team membership per hole: [hole][seat] → Bool
        // Only applies to wolf-style game types; Match Play and Best Ball use pairing colors instead.
        let applyWolfColoring = game.resolvedGameType != .matchPlay && game.resolvedGameType != .bestBall
        let wolfMask = game.wolfMaskByHole

        // Dual-match pairing seat sets — used for player row color coding.
        let match1Seats = Set((game.matchPlayTeamA ?? []) + (game.matchPlayTeamB ?? []))
        let match2Seats = Set((game.matchPlayTeamA2 ?? []) + (game.matchPlayTeamB2 ?? []))
        let isDualMatchCard = !match2Seats.isEmpty

        // Colors
        let hdrBg        = UIColor(white: 0.88, alpha: 1)
        let parBg        = UIColor(white: 0.93, alpha: 1)
        let summBg       = UIColor(white: 0.85, alpha: 1)
        let wolfTeamBg   = UIColor(red: 1.00, green: 0.86, blue: 0.86, alpha: 1)  // soft red
        let packBg       = UIColor(red: 0.88, green: 0.92, blue: 1.00, alpha: 1)  // soft blue
        let altBg        = UIColor(white: 0.972, alpha: 1)
        let gridLine     = UIColor(white: 0.76, alpha: 1)
        let dotGray      = UIColor(white: 0.65, alpha: 1)
        let boldSumm     = UIFont.systemFont(ofSize: 13, weight: .bold)
        // Match pairing row tints — applied to player rows when dual-match is active.
        let match1TitleClr = UIColor(red: 0.20, green: 0.44, blue: 0.70, alpha: 1)
        let match2TitleClr = UIColor(red: 0.56, green: 0.28, blue: 0.00, alpha: 1)
        let match1RowBg  = UIColor(red: 0.88, green: 0.93, blue: 1.00, alpha: 1)  // soft blue
        let match2RowBg  = UIColor(red: 1.00, green: 0.92, blue: 0.82, alpha: 1)  // soft amber

        // Starting hole column highlight — only for 9-hole games.
        let startHoleBg  = UIColor(red: 1.00, green: 0.82, blue: 0.86, alpha: 1)  // soft rose
        let startCourseH: Int? = game.isNineHoleMatch ? (game.nineHoleStartingHole - 1) : nil
        // ci 1-9 → courseH 0-8, ci 11-19 → courseH 9-17
        let startColCI: Int? = startCourseH.map { ch in ch < 9 ? ch + 1 : ch + 2 }

        let front = Array(0..<9)
        let back  = Array(9..<18)

        func rangeSum(_ arr: [Int?], _ r: [Int]) -> (sum: Int, hasAny: Bool) {
            let vals = r.compactMap { arr[$0] }
            return (vals.reduce(0, +), !vals.isEmpty)
        }

        let headers = ["","1","2","3","4","5","6","7","8","9","OUT",
                       "10","11","12","13","14","15","16","17","18","IN","TOT"]

        var ry = y

        // ── Header row ────────────────────────────────────────
        for ci in 0..<22 {
            let isStartCol = startColCI.map { $0 == ci } ?? false
            fill(x: colXs[ci], y: ry, w: colW(ci), h: hdrH,
                 color: isStartCol ? startHoleBg : (isSumm(ci) ? summBg : hdrBg))
            if ci > 0 {
                let weight: UIFont.Weight = isSumm(ci) ? .bold : .semibold
                drawCell(headers[ci],
                         x: colXs[ci], y: ry, w: colW(ci), h: hdrH,
                         font: .systemFont(ofSize: 11, weight: weight),
                         color: UIColor(white: 0.28, alpha: 1))
            }
        }
        ry += hdrH

        // ── Par row ───────────────────────────────────────────
        let frontPar = front.reduce(0) { $0 + pars[$1] }
        let backPar  = back.reduce(0)  { $0 + pars[$1] }
        let parTexts = ["Par"]
            + (0..<9).map  { "\(pars[$0])" }
            + ["\(frontPar)"]
            + (9..<18).map { "\(pars[$0])" }
            + ["\(backPar)", "\(frontPar + backPar)"]

        for ci in 0..<22 {
            let isStartCol = startColCI.map { $0 == ci } ?? false
            fill(x: colXs[ci], y: ry, w: colW(ci), h: parH,
                 color: isStartCol ? startHoleBg : (isSumm(ci) ? summBg : parBg))
            drawCell(parTexts[ci],
                     x: colXs[ci], y: ry, w: colW(ci), h: parH,
                     font: .systemFont(ofSize: 12, weight: isSumm(ci) ? .semibold : .regular),
                     color: UIColor(white: 0.38, alpha: 1),
                     leftAlign: ci == 0)
        }
        ry += parH

        // ── Player rows (draws R1 then optional R2 per player) ─
        let dimGray = UIColor(white: 0.55, alpha: 1)

        func drawPlayerRow(gross: [Int?], holeOffset: Int, seat: Int, rowBg: UIColor,
                           nameLabel: String, subLabel: String, subLabelColor: UIColor) {
            let (frontGross, hasFront) = rangeSum(gross, front)
            let (backGross,  hasBack)  = rangeSum(gross, back)

            for ci in 0..<22 {
                let w = colW(ci)

                let bg: UIColor
                if let localH = hIdx(ci) {
                    let gameH = localH + holeOffset
                    let mask  = gameH < wolfMask.count ? wolfMask[gameH] : []
                    let wolfCalled = applyWolfColoring && mask.contains(true)
                    if wolfCalled {
                        let onWolfTeam = seat < mask.count && mask[seat]
                        bg = onWolfTeam ? wolfTeamBg : packBg
                    } else if startColCI.map({ $0 == ci }) ?? false {
                        bg = startHoleBg
                    } else {
                        bg = rowBg
                    }
                } else {
                    bg = isSumm(ci) ? summBg : rowBg
                }
                fill(x: colXs[ci], y: ry, w: w, h: playerH, color: bg)

                switch ci {
                case 0:
                    let nameH: CGFloat = playerH * 0.60
                    let subH:  CGFloat = playerH - nameH
                    drawCell(nameLabel,
                             x: colXs[ci], y: ry, w: w, h: nameH,
                             font: .systemFont(ofSize: 12, weight: .semibold),
                             color: .black, leftAlign: true)
                    drawCell(subLabel,
                             x: colXs[ci], y: ry + nameH, w: w, h: subH,
                             font: .systemFont(ofSize: 9, weight: .regular),
                             color: subLabelColor, leftAlign: true)

                case 10:
                    drawCell(hasFront ? "\(frontGross)" : "·",
                             x: colXs[ci], y: ry, w: w, h: playerH,
                             font: boldSumm, color: hasFront ? .black : dotGray)

                case 20:
                    drawCell(hasBack ? "\(backGross)" : "·",
                             x: colXs[ci], y: ry, w: w, h: playerH,
                             font: boldSumm, color: hasBack ? .black : dotGray)

                case 21:
                    let (totTxt, totClr): (String, UIColor)
                    switch (hasFront, hasBack) {
                    case (true, true):  (totTxt, totClr) = ("\(frontGross + backGross)", .black)
                    case (true, false): (totTxt, totClr) = ("\(frontGross)", .black)
                    case (false, true): (totTxt, totClr) = ("\(backGross)", .black)
                    default:            (totTxt, totClr) = ("·", dotGray)
                    }
                    drawCell(totTxt, x: colXs[ci], y: ry, w: w, h: playerH,
                             font: boldSumm, color: totClr)

                default:
                    if let localH = hIdx(ci) {
                        if let score = gross[localH] {
                            let diff  = score - pars[localH]
                            let color = scoreColor(diff: diff)
                            drawCell("\(score)",
                                     x: colXs[ci], y: ry, w: w, h: playerH,
                                     font: .systemFont(ofSize: 14, weight: .semibold),
                                     color: color)
                            drawAnnotation(diff: diff,
                                           x: colXs[ci], y: ry, w: w, h: playerH,
                                           color: color)
                        } else {
                            drawCell("·",
                                     x: colXs[ci], y: ry, w: w, h: playerH,
                                     font: .systemFont(ofSize: 11, weight: .regular),
                                     color: dotGray)
                        }
                    }
                }
            }
            ry += playerH
        }

        for (pi, player) in players.enumerated() {
            // Dual-match: tint each player's row by their match pairing.
            let rowBg: UIColor
            if isDualMatchCard && match1Seats.contains(player.seat) {
                rowBg = match1RowBg
            } else if isDualMatchCard && match2Seats.contains(player.seat) {
                rowBg = match2RowBg
            } else {
                rowBg = pi % 2 == 1 ? altBg : UIColor.white
            }
            // Round 1
            drawPlayerRow(gross: player.gross, holeOffset: 0, seat: player.seat, rowBg: rowBg,
                          nameLabel: player.name,
                          subLabel: "HC \(player.hc)",
                          subLabelColor: UIColor(white: 0.50, alpha: 1))
            // Round 2 (36-hole only)
            if let g2 = player.gross2 {
                drawPlayerRow(gross: g2, holeOffset: STANDARD_HOLES, seat: player.seat,
                              rowBg: rowBg,
                              nameLabel: player.name,
                              subLabel: "R2",
                              subLabelColor: dimGray)
            }
        }

        // ── Best Ball team rows ───────────────────────────────
        let bbTeamBg = UIColor(red: 0.88, green: 0.96, blue: 0.88, alpha: 1)  // soft green
        let bbLabelColor = UIColor(red: 0.12, green: 0.42, blue: 0.18, alpha: 1)

        if !bbTeams.isEmpty {
            // Divider line above team section
            gridLine.setFill()
            UIRectFill(CGRect(x: hPad, y: ry, width: gridW, height: 1.0))
        }

        for team in bbTeams {
            let (frontSum, hasFront) = rangeSum(team.countingGross, front)
            let (backSum,  hasBack)  = rangeSum(team.countingGross, back)

            for ci in 0..<22 {
                let w = colW(ci)
                let bg: UIColor = isSumm(ci) ? summBg : bbTeamBg
                fill(x: colXs[ci], y: ry, w: w, h: playerH, color: bg)

                switch ci {
                case 0:
                    let nameH: CGFloat = playerH * 0.60
                    let subH:  CGFloat = playerH - nameH
                    let shortLabel = team.label
                    drawCell(shortLabel,
                             x: colXs[ci], y: ry, w: w, h: nameH,
                             font: .systemFont(ofSize: 11, weight: .bold),
                             color: bbLabelColor, leftAlign: true)
                    drawCell("Best Ball",
                             x: colXs[ci], y: ry + nameH, w: w, h: subH,
                             font: .systemFont(ofSize: 9, weight: .regular),
                             color: bbLabelColor, leftAlign: true)

                case 10:
                    drawCell(hasFront ? "\(frontSum)" : "·",
                             x: colXs[ci], y: ry, w: w, h: playerH,
                             font: boldSumm, color: hasFront ? bbLabelColor : dotGray)

                case 20:
                    drawCell(hasBack ? "\(backSum)" : "·",
                             x: colXs[ci], y: ry, w: w, h: playerH,
                             font: boldSumm, color: hasBack ? bbLabelColor : dotGray)

                case 21:
                    let (totTxt, totClr): (String, UIColor)
                    switch (hasFront, hasBack) {
                    case (true, true):  (totTxt, totClr) = ("\(frontSum + backSum)", bbLabelColor)
                    case (true, false): (totTxt, totClr) = ("\(frontSum)", bbLabelColor)
                    case (false, true): (totTxt, totClr) = ("\(backSum)", bbLabelColor)
                    default:            (totTxt, totClr) = ("·", dotGray)
                    }
                    drawCell(totTxt, x: colXs[ci], y: ry, w: w, h: playerH,
                             font: boldSumm, color: totClr)

                default:
                    if let localH = hIdx(ci), let score = team.countingGross[localH] {
                        let diff = score - pars[localH]
                        drawCell("\(score)",
                                 x: colXs[ci], y: ry, w: w, h: playerH,
                                 font: .systemFont(ofSize: 14, weight: .bold),
                                 color: bbLabelColor)
                        drawAnnotation(diff: diff,
                                       x: colXs[ci], y: ry, w: w, h: playerH,
                                       color: bbLabelColor)
                    } else if hIdx(ci) != nil {
                        drawCell("·", x: colXs[ci], y: ry, w: w, h: playerH,
                                 font: .systemFont(ofSize: 11, weight: .regular),
                                 color: dotGray)
                    }
                }
            }
            ry += playerH
        }

        // ── Match Play status rows (one per match, two for dual 1v1) ─────
        let mpUpClr = UIColor(red: 0.10, green: 0.50, blue: 0.18, alpha: 1)
        let mpDnClr = UIColor(red: 0.72, green: 0.12, blue: 0.12, alpha: 1)
        let mpAsClr = UIColor(white: 0.48, alpha: 1)

        func mpStatusColor(_ s: String) -> UIColor {
            if s.hasPrefix("+") { return mpUpClr }
            if s.hasPrefix("-") { return mpDnClr }
            return mpAsClr
        }

        for (idx, mp) in mpStatuses.enumerated() {
            let mpBg      = idx == 0 ? match1RowBg : match2RowBg
            let titleClr  = idx == 0 ? match1TitleClr : match2TitleClr

            gridLine.setFill()
            UIRectFill(CGRect(x: hPad, y: ry, width: gridW, height: 1.0))

            for ci in 0..<22 {
                let w = colW(ci)
                let isStartCol = startColCI.map { $0 == ci } ?? false
                fill(x: colXs[ci], y: ry, w: w, h: playerH,
                     color: isSumm(ci) ? summBg : (isStartCol ? startHoleBg : mpBg))

                switch ci {
                case 0:
                    let nameH: CGFloat = playerH * 0.60
                    let subH:  CGFloat = playerH - nameH
                    drawCell(mp.matchLabel,
                             x: colXs[ci], y: ry, w: w, h: nameH,
                             font: .systemFont(ofSize: 12, weight: .bold),
                             color: titleClr, leftAlign: true)
                    drawCell("+ = \(mp.teamALabel)",
                             x: colXs[ci], y: ry + nameH, w: w, h: subH,
                             font: .systemFont(ofSize: 9, weight: .regular),
                             color: titleClr, leftAlign: true)

                case 10:
                    let s = mp.outStatus ?? "·"
                    drawCell(s, x: colXs[ci], y: ry, w: w, h: playerH,
                             font: boldSumm, color: mp.outStatus != nil ? mpStatusColor(s) : dotGray)

                case 20:
                    let s = mp.inStatus ?? "·"
                    drawCell(s, x: colXs[ci], y: ry, w: w, h: playerH,
                             font: boldSumm, color: mp.inStatus != nil ? mpStatusColor(s) : dotGray)

                case 21:
                    drawCell(mp.shortResult, x: colXs[ci], y: ry, w: w, h: playerH,
                             font: .systemFont(ofSize: 11, weight: .bold),
                             color: mp.shortResult == "AS" ? mpAsClr : titleClr)

                default:
                    if let localH = hIdx(ci) {
                        let s = mp.statusPerHole[localH] ?? "·"
                        let clr = mp.statusPerHole[localH] != nil ? mpStatusColor(s) : dotGray
                        drawCell(s, x: colXs[ci], y: ry, w: w, h: playerH,
                                 font: .systemFont(ofSize: 11, weight: .semibold), color: clr)
                    }
                }
            }
            ry += playerH
        }

        // ── Team Tee Game row ─────────────────────────────────
        if let ttr = teamTeeRow {
            let ttBg       = UIColor(red: 0.88, green: 0.94, blue: 1.00, alpha: 1)  // soft sky blue
            let ttLabelClr = UIColor(red: 0.10, green: 0.30, blue: 0.60, alpha: 1)
            let (frontNets, hasFront) = rangeSum(ttr.netPerHole, front)
            let (backNets,  hasBack)  = rangeSum(ttr.netPerHole, back)

            gridLine.setFill()
            UIRectFill(CGRect(x: hPad, y: ry, width: gridW, height: 1.0))

            for ci in 0..<22 {
                let w = colW(ci)
                let bg: UIColor = isSumm(ci) ? summBg : ttBg
                fill(x: colXs[ci], y: ry, w: w, h: playerH, color: bg)

                switch ci {
                case 0:
                    let nameH: CGFloat = playerH * 0.60
                    let subH:  CGFloat = playerH - nameH
                    drawCell("Team Tee",
                             x: colXs[ci], y: ry, w: w, h: nameH,
                             font: .systemFont(ofSize: 11, weight: .bold),
                             color: ttLabelClr, leftAlign: true)
                    drawCell(ttr.modeLabel,
                             x: colXs[ci], y: ry + nameH, w: w, h: subH,
                             font: .systemFont(ofSize: 9, weight: .regular),
                             color: ttLabelClr, leftAlign: true)

                case 10:
                    drawCell(hasFront ? "\(frontNets)" : "·",
                             x: colXs[ci], y: ry, w: w, h: playerH,
                             font: boldSumm, color: hasFront ? ttLabelClr : dotGray)

                case 20:
                    drawCell(hasBack ? "\(backNets)" : "·",
                             x: colXs[ci], y: ry, w: w, h: playerH,
                             font: boldSumm, color: hasBack ? ttLabelClr : dotGray)

                case 21:
                    let (totTxt, totClr): (String, UIColor)
                    switch (hasFront, hasBack) {
                    case (true, true):  (totTxt, totClr) = ("\(frontNets + backNets)", ttLabelClr)
                    case (true, false): (totTxt, totClr) = ("\(frontNets)", ttLabelClr)
                    case (false, true): (totTxt, totClr) = ("\(backNets)", ttLabelClr)
                    default:            (totTxt, totClr) = ("·", dotGray)
                    }
                    drawCell(totTxt, x: colXs[ci], y: ry, w: w, h: playerH,
                             font: boldSumm, color: totClr)

                default:
                    if let localH = hIdx(ci) {
                        if let net = ttr.netPerHole[localH] {
                            drawCell("\(net)",
                                     x: colXs[ci], y: ry, w: w, h: playerH,
                                     font: .systemFont(ofSize: 14, weight: .bold),
                                     color: ttLabelClr)
                        } else {
                            drawCell("·", x: colXs[ci], y: ry, w: w, h: playerH,
                                     font: .systemFont(ofSize: 11, weight: .regular),
                                     color: dotGray)
                        }
                    }
                }
            }
            ry += playerH
        }

        // ── Grid lines ────────────────────────────────────────
        gridLine.setFill()
        var lineY = y
        let totalPlayerRows = players.reduce(0) { $0 + ($1.gross2 != nil ? 2 : 1) }
        let extraRows = bbTeams.count + mpStatuses.count + (teamTeeRow != nil ? 1 : 0)
        for step in [hdrH, parH] + Array(repeating: playerH, count: totalPlayerRows + extraRows) {
            UIRectFill(CGRect(x: hPad, y: lineY, width: gridW, height: 0.5))
            lineY += step
        }
        UIRectFill(CGRect(x: hPad, y: lineY, width: gridW, height: 0.5))
        for ci in 0..<22 {
            UIRectFill(CGRect(x: colXs[ci], y: y, width: 0.5, height: ry - y))
        }
        UIRectFill(CGRect(x: hPad + gridW, y: y, width: 0.5, height: ry - y))

        return ry
    }

    // MARK: - Score color

    private func scoreColor(diff: Int) -> UIColor {
        switch diff {
        case ...(-2): return UIColor(red: 0.00, green: 0.44, blue: 0.05, alpha: 1)  // eagle green
        case -1:      return UIColor(red: 0.08, green: 0.58, blue: 0.15, alpha: 1)  // birdie green
        case 0:       return UIColor(white: 0.20, alpha: 1)                          // par — near-black
        case 1:       return UIColor(red: 0.62, green: 0.33, blue: 0.00, alpha: 1)  // bogey brown
        default:      return UIColor(red: 0.78, green: 0.10, blue: 0.10, alpha: 1)  // double+ red
        }
    }

    // MARK: - Score annotation (circle / square)

    private func drawAnnotation(diff: Int, x: CGFloat, y: CGFloat,
                                 w: CGFloat, h: CGFloat, color: UIColor) {
        guard diff != 0 else { return }

        let inset: CGFloat = 4
        let side   = min(w, h) - inset * 2
        let center = CGPoint(x: x + w / 2, y: y + h / 2)
        color.setStroke()

        switch diff {
        case ...(-2):   // Eagle or better: double circle
            let r1 = side / 2
            let r2 = r1 - 3.5
            stroke(oval: center, radius: r1)
            stroke(oval: center, radius: r2)

        case -1:        // Birdie: single circle
            stroke(oval: center, radius: side / 2)

        case 1:         // Bogey: single square
            stroke(square: center, side: side)

        default:        // Double bogey+: double square
            stroke(square: center, side: side)
            stroke(square: center, side: side + 7)
        }
    }

    private func stroke(oval center: CGPoint, radius: CGFloat) {
        let p = UIBezierPath(arcCenter: center, radius: max(radius, 1),
                             startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        p.lineWidth = 1.5
        p.stroke()
    }

    private func stroke(square center: CGPoint, side: CGFloat) {
        let s = max(side, 2)
        let r = CGRect(x: center.x - s / 2, y: center.y - s / 2, width: s, height: s)
        let p = UIBezierPath(rect: r)
        p.lineWidth = 1.5
        p.stroke()
    }

    // MARK: - Footer

    private func drawFooter(y: CGFloat, matchResult: String? = nil) {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        drawCentered("Wolfmore  ·  \(fmt.string(from: date))",
                     y: y + 12,
                     font: .systemFont(ofSize: 12, weight: .regular),
                     color: UIColor(white: 0.58, alpha: 1))
        if let result = matchResult {
            drawCentered("Result: \(result)",
                         y: y + 30,
                         font: .systemFont(ofSize: 13, weight: .semibold),
                         color: UIColor(red: 0.20, green: 0.44, blue: 0.70, alpha: 1))
        }
    }

    // MARK: - Drawing primitives

    private func fill(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, color: UIColor) {
        color.setFill()
        UIRectFill(CGRect(x: x, y: y, width: w, height: h))
    }

    private func drawCell(_ text: String,
                          x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat,
                          font: UIFont, color: UIColor,
                          leftAlign: Bool = false) {
        guard !text.isEmpty else { return }
        let para           = NSMutableParagraphStyle()
        para.alignment     = leftAlign ? .left : .center
        para.lineBreakMode = .byTruncatingTail
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font, .foregroundColor: color, .paragraphStyle: para
        ]
        let inset: CGFloat = leftAlign ? 5 : 1
        let tw = w - inset * 2
        let th = min(h, (text as NSString).boundingRect(
            with: CGSize(width: tw, height: h),
            options: .usesLineFragmentOrigin, attributes: attrs, context: nil).height)
        (text as NSString).draw(
            in: CGRect(x: x + inset, y: y + (h - th) / 2, width: tw, height: th),
            withAttributes: attrs)
    }

    private func drawCentered(_ text: String, y: CGFloat, font: UIFont, color: UIColor) {
        let para       = NSMutableParagraphStyle()
        para.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font, .foregroundColor: color, .paragraphStyle: para
        ]
        (text as NSString).draw(
            in: CGRect(x: hPad, y: y, width: pageW - 2 * hPad, height: 60),
            withAttributes: attrs)
    }
}
