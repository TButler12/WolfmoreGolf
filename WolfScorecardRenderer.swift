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
        let players   = buildPlayers()
        let pars      = (0..<STANDARD_HOLES).map { game.courseParToPass[safe: $0] ?? 4 }
        let bbTeams   = buildBestBallTeams(players: players, pars: pars)
        let mpStatus  = buildMatchPlayStatus(players: players, pars: pars)

        let teamsLine: String? = mpStatus.map { "Teams: \($0.teamALabel) vs. \($0.teamBLabel)" }
        let docHdrH: CGFloat   = teamsLine != nil ? 114 : 96
        let totalPlayerRows = players.reduce(0) { $0 + ($1.gross2 != nil ? 2 : 1) }
        let extraRows = bbTeams.count + (mpStatus != nil ? 1 : 0)
        let gridH   = hdrH + parH + CGFloat(totalPlayerRows + extraRows) * playerH
        let footerH: CGFloat = mpStatus != nil ? 60 : 40
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
            y = drawGrid(y: y, players: players, pars: pars, bbTeams: bbTeams, mpStatus: mpStatus)
            drawFooter(y: y, matchResult: mpStatus?.finalResult)
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
        let cap  = min(game.playerNames.count, game.playerActivated.count)
        return (0..<cap).compactMap { seat -> PlayerData? in
            guard game.playerActivated[seat] else { return nil }
            let name = game.playerNames[seat].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            let hc    = game.hcPlayers[safe: seat] ?? 0
            let gross = (0..<STANDARD_HOLES).map { h -> Int? in
                seat < game.scores.count ? game.scores[seat][h] : nil
            }
            let gross2: [Int?]? = is36 ? (STANDARD_HOLES..<(2 * STANDARD_HOLES)).map { h -> Int? in
                guard seat < game.scores.count, h < game.scores[seat].count else { return nil }
                return game.scores[seat][h]
            } : nil
            return PlayerData(seat: seat, name: name, hc: hc, gross: gross, gross2: gross2)
        }
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
                    guard let g = (s < game.scores.count ? game.scores[s][h] : nil) else { continue }
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
        let teamALabel:    String
        let teamBLabel:    String
        let statusPerHole: [String?]  // 18 elements, nil = hole not yet scored
        let outStatus:     String?    // running lead after hole 9
        let inStatus:      String?    // running lead after hole 18
        let shortResult:   String     // e.g. "3&2", "2 UP", "AS"
        let finalResult:   String     // full footer text
    }

    private func buildMatchPlayStatus(players: [PlayerData], pars: [Int]) -> MatchPlayStatusData? {
        guard game.resolvedGameType == .matchPlay else { return nil }

        let activeSeats = players.map { $0.seat }
        let teamA = (game.matchPlayTeamA ?? []).filter { activeSeats.contains($0) }
        let teamB = (game.matchPlayTeamB ?? []).filter { activeSeats.contains($0) }
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

        var runningLead = 0
        var statusPerHole = [String?](repeating: nil, count: STANDARD_HOLES)
        var decisiveHole: Int? = nil
        var decisiveLead = 0
        var holesPlayed  = 0

        for h in 0..<STANDARD_HOLES {
            let aN = teamA.compactMap { s -> Int? in
                guard let g = (s < game.scores.count ? game.scores[s][h] : nil) else { return nil }
                return g - strokes(seat: s, h: h)
            }.min()
            let bN = teamB.compactMap { s -> Int? in
                guard let g = (s < game.scores.count ? game.scores[s][h] : nil) else { return nil }
                return g - strokes(seat: s, h: h)
            }.min()
            guard let aN, let bN else { break }

            if aN < bN      { runningLead += 1 }
            else if bN < aN { runningLead -= 1 }

            holesPlayed = h + 1
            let remaining = STANDARD_HOLES - holesPlayed
            if decisiveHole == nil && abs(runningLead) > remaining {
                decisiveHole = h; decisiveLead = runningLead
            }
            statusPerHole[h] = leadStr(runningLead)
        }

        let outStatus = holesPlayed >= 9  ? statusPerHole[8]  : nil
        let inStatus  = holesPlayed >= 18 ? statusPerHole[17] : nil

        let shortResult: String
        let finalResult: String
        if holesPlayed == 0 {
            shortResult = "—"; finalResult = "—"
        } else if let dh = decisiveHole {
            let margin    = abs(decisiveLead)
            let remaining = STANDARD_HOLES - (dh + 1)
            let winner    = decisiveLead > 0 ? teamALabel : teamBLabel
            shortResult = remaining == 0 ? "\(margin) UP" : "\(margin)&\(remaining)"
            finalResult = remaining == 0 ? "\(winner) won \(margin) UP"
                                         : "\(winner) won \(margin)&\(remaining)"
        } else if holesPlayed == STANDARD_HOLES {
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
                          mpStatus: MatchPlayStatusData? = nil) -> CGFloat {

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
        let wolfMask = game.wolfMaskByHole

        // Colors
        let hdrBg      = UIColor(white: 0.88, alpha: 1)
        let parBg      = UIColor(white: 0.93, alpha: 1)
        let summBg     = UIColor(white: 0.85, alpha: 1)
        let wolfTeamBg = UIColor(red: 1.00, green: 0.86, blue: 0.86, alpha: 1)  // soft red
        let packBg     = UIColor(red: 0.88, green: 0.92, blue: 1.00, alpha: 1)  // soft blue
        let altBg      = UIColor(white: 0.972, alpha: 1)
        let gridLine   = UIColor(white: 0.76, alpha: 1)
        let dotGray    = UIColor(white: 0.65, alpha: 1)
        let boldSumm   = UIFont.systemFont(ofSize: 13, weight: .bold)

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
            fill(x: colXs[ci], y: ry, w: colW(ci), h: hdrH,
                 color: isSumm(ci) ? summBg : hdrBg)
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
            fill(x: colXs[ci], y: ry, w: colW(ci), h: parH,
                 color: isSumm(ci) ? summBg : parBg)
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
                    let wolfCalled = mask.contains(true)
                    if wolfCalled {
                        let onWolfTeam = seat < mask.count && mask[seat]
                        bg = onWolfTeam ? wolfTeamBg : packBg
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
            let rowBg = pi % 2 == 1 ? altBg : UIColor.white
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

        // ── Match Play status row ─────────────────────────────
        if let mp = mpStatus {
            let mpBg       = UIColor(red: 0.88, green: 0.93, blue: 1.00, alpha: 1)  // soft blue
            let mpUpClr    = UIColor(red: 0.10, green: 0.50, blue: 0.18, alpha: 1)  // green = Team A up
            let mpDnClr    = UIColor(red: 0.72, green: 0.12, blue: 0.12, alpha: 1)  // red = Team B up
            let mpAsClr    = UIColor(white: 0.48, alpha: 1)
            let mpTitleClr = UIColor(red: 0.20, green: 0.44, blue: 0.70, alpha: 1)

            func mpStatusColor(_ s: String) -> UIColor {
                if s.hasPrefix("+") { return mpUpClr }
                if s.hasPrefix("-") { return mpDnClr }
                return mpAsClr
            }

            gridLine.setFill()
            UIRectFill(CGRect(x: hPad, y: ry, width: gridW, height: 1.0))

            for ci in 0..<22 {
                let w = colW(ci)
                fill(x: colXs[ci], y: ry, w: w, h: playerH,
                     color: isSumm(ci) ? summBg : mpBg)

                switch ci {
                case 0:
                    let nameH: CGFloat = playerH * 0.60
                    let subH:  CGFloat = playerH - nameH
                    drawCell("Match",
                             x: colXs[ci], y: ry, w: w, h: nameH,
                             font: .systemFont(ofSize: 12, weight: .bold),
                             color: mpTitleClr, leftAlign: true)
                    drawCell("+ = \(mp.teamALabel)",
                             x: colXs[ci], y: ry + nameH, w: w, h: subH,
                             font: .systemFont(ofSize: 9, weight: .regular),
                             color: mpTitleClr, leftAlign: true)

                case 10:
                    let s = mp.outStatus ?? "·"
                    drawCell(s, x: colXs[ci], y: ry, w: w, h: playerH,
                             font: boldSumm, color: mp.outStatus != nil ? mpStatusColor(s) : dotGray)

                case 20:
                    let s = mp.inStatus ?? "·"
                    drawCell(s, x: colXs[ci], y: ry, w: w, h: playerH,
                             font: boldSumm, color: mp.inStatus != nil ? mpStatusColor(s) : dotGray)

                case 21:
                    // shortResult is decisive notation ("3&2", "2 UP", "AS") — always show in title blue
                    drawCell(mp.shortResult, x: colXs[ci], y: ry, w: w, h: playerH,
                             font: .systemFont(ofSize: 11, weight: .bold),
                             color: mp.shortResult == "AS" ? mpAsClr : mpTitleClr)

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

        // ── Grid lines ────────────────────────────────────────
        gridLine.setFill()
        var lineY = y
        let totalPlayerRows = players.reduce(0) { $0 + ($1.gross2 != nil ? 2 : 1) }
        let extraRows = bbTeams.count + (mpStatus != nil ? 1 : 0)
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
