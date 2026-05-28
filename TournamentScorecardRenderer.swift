import UIKit

// MARK: - TournamentScorecardRenderer
//
// Renders a tournament Stableford scorecard as a retina PNG suitable for
// sharing via AirDrop, iMessage, AirPrint, or Photos.
//
// Usage:
//   let image = TournamentScorecardRenderer(game: game, filledHoles: 0..<9).render()
//   // filledHoles = 0..<9  → front-9 submit (back 9 shown as dots)
//   // filledHoles = 9..<18 → back-nine-first submit
//   // filledHoles = 0..<18 → full 18

final class TournamentScorecardRenderer {

    // ── Layout ───────────────────────────────────────────────
    private let pageW: CGFloat = 1080
    private let hPad:  CGFloat = 24
    private let nameW: CGFloat = 78
    private let holeW: CGFloat = 44
    private let summW: CGFloat = 54
    // Row heights
    private let hdrH:  CGFloat = 22
    private let parH:  CGFloat = 22
    private let ptsH:  CGFloat = 28
    private let grsH:  CGFloat = 18
    private let strkH: CGFloat = 13   // strokes/pops dots row
    private let teamH: CGFloat = 28

    // ── Input ────────────────────────────────────────────────
    private let game:        GameData
    private let filledHoles: Range<Int>
    private let date:        Date

    init(game: GameData, filledHoles: Range<Int> = 0..<18, date: Date = Date()) {
        self.game        = game
        self.filledHoles = filledHoles
        self.date        = date
    }

    // MARK: - Public entry point

    func render() -> UIImage {
        let players = buildPlayers()
        let pars    = (0..<STANDARD_HOLES).map { game.courseParToPass[safe: $0] ?? 4 }
        let teamPts = buildTeamPts(players: players)

        let docHdrH: CGFloat = 130
        let gridH   = hdrH + parH + CGFloat(players.count) * (ptsH + grsH + strkH) + 2 + teamH
        let footerH: CGFloat = 52
        let totalH  = docHdrH + gridH + footerH

        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 2
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: pageW, height: totalH), format: fmt)

        return renderer.image { _ in
            // Always literal white — suitable for printing
            UIColor.white.setFill()
            UIRectFill(CGRect(x: 0, y: 0, width: pageW, height: totalH))

            var y: CGFloat = 0
            y = drawDocHeader(y: y, players: players)
            y = drawGrid(y: y, players: players, pars: pars, teamPts: teamPts)
            drawFooter(y: y)
        }
    }

    // MARK: - Data builders

    private struct PlayerData {
        let name:    String
        let hc:      Int
        let pts:     [Int?]  // 18 elements; nil = unplayed or outside filledHoles
        let gross:   [Int?]  // 18 elements
        let strokes: [Int]   // 18 elements: strokes received on each hole
    }

    private func buildPlayers() -> [PlayerData] {
        let gm  = GameManager.shared
        let cap = min(game.playerNames.count, game.playerActivated.count)
        return (0..<cap).compactMap { seat -> PlayerData? in
            guard game.playerActivated[seat] else { return nil }
            let name = game.playerNames[seat].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            let hc = game.hcPlayers[safe: seat] ?? 0
            let pts: [Int?] = (0..<STANDARD_HOLES).map { h in
                guard filledHoles.contains(h) else { return nil }
                let par   = game.courseParToPass[safe: h] ?? 4
                let si    = game.courseHCToPass[safe: h] ?? (h + 1)
                let gross = (seat < game.scores.count) ? game.scores[seat][h] : nil
                return gm.stablefordPoints(grossScore: gross, par: par, playerHC: hc, strokeIndex: si)
            }
            let gross: [Int?] = (0..<STANDARD_HOLES).map { h in
                guard filledHoles.contains(h) else { return nil }
                return (seat < game.scores.count) ? game.scores[seat][h] : nil
            }
            let strokes: [Int] = (0..<STANDARD_HOLES).map { h in
                guard hc > 0 else { return 0 }
                let si = game.courseHCToPass[safe: h] ?? (h + 1)
                return hc / 18 + (si <= hc % 18 ? 1 : 0)
            }
            return PlayerData(name: name, hc: hc, pts: pts, gross: gross, strokes: strokes)
        }
    }

    private func buildTeamPts(players: [PlayerData]) -> [Int?] {
        (0..<STANDARD_HOLES).map { h in
            guard filledHoles.contains(h) else { return nil }
            let vals = players.compactMap { $0.pts[h] }
            return vals.isEmpty ? nil : vals.sorted(by: >).prefix(3).reduce(0, +)
        }
    }

    // MARK: - Document header

    @discardableResult
    private func drawDocHeader(y: CGFloat, players: [PlayerData]) -> CGFloat {
        var cy = y + 28

        drawCentered("WOLFMORE STABLEFORD", y: cy,
                     font: .systemFont(ofSize: 28, weight: .bold), color: .black)
        cy += 38

        let dateFmt = DateFormatter()
        dateFmt.dateStyle = .medium
        dateFmt.timeStyle = .none
        drawCentered("\(game.course.name)  ·  \(dateFmt.string(from: date))", y: cy,
                     font: .systemFont(ofSize: 17, weight: .regular),
                     color: UIColor(white: 0.30, alpha: 1))
        cy += 26

        let names = players.map { $0.name }.joined(separator: " · ")
        drawCentered("Group: \(names)", y: cy,
                     font: .systemFont(ofSize: 15, weight: .regular),
                     color: UIColor(white: 0.45, alpha: 1))
        cy += 22

        return cy + 16
    }

    // MARK: - Scorecard grid

    @discardableResult
    private func drawGrid(y: CGFloat, players: [PlayerData],
                          pars: [Int], teamPts: [Int?]) -> CGFloat {

        // Column layout: ci 0=name, 1-9=h1-9, 10=OUT, 11-19=h10-18, 20=IN, 21=TOT
        var colXs = [CGFloat](repeating: 0, count: 22)
        var cx = hPad
        colXs[0] = cx; cx += nameW
        for i in 1...9  { colXs[i] = cx; cx += holeW }
        colXs[10] = cx; cx += summW
        for i in 11...19 { colXs[i] = cx; cx += holeW }
        colXs[20] = cx; cx += summW
        colXs[21] = cx; cx += summW
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

        // Colors
        let hdrBg      = UIColor(white: 0.88, alpha: 1)
        let parBg      = UIColor(white: 0.93, alpha: 1)
        let summBg     = UIColor(white: 0.85, alpha: 1)
        let altBg      = UIColor(white: 0.975, alpha: 1)
        let teamBg     = UIColor(red: 0.84, green: 0.92, blue: 1.00, alpha: 1)
        let teamSummBg = UIColor(red: 0.76, green: 0.86, blue: 1.00, alpha: 1)
        let sepLine    = UIColor(white: 0.65, alpha: 1)
        let gridLine   = UIColor(white: 0.76, alpha: 1)
        let dotGray    = UIColor(white: 0.65, alpha: 1)
        let teamBlue   = UIColor(red: 0.08, green: 0.24, blue: 0.82, alpha: 1)
        let teamDot    = UIColor(red: 0.55, green: 0.65, blue: 0.90, alpha: 1)

        func ptsColor(_ pts: Int?) -> UIColor {
            guard let p = pts else { return dotGray }
            switch p {
            case 4...: return UIColor(red: 0.00, green: 0.40, blue: 0.08, alpha: 1)
            case 3:    return UIColor(red: 0.04, green: 0.52, blue: 0.12, alpha: 1)
            case 2:    return UIColor(red: 0.08, green: 0.62, blue: 0.18, alpha: 1)
            case 1:    return .black
            default:   return UIColor(red: 0.78, green: 0.06, blue: 0.06, alpha: 1)
            }
        }

        let front = Array(0..<9)
        let back  = Array(9..<18)

        // Returns (sum, hasAny) for the given array and hole range
        func rangeSum(_ arr: [Int?], _ r: [Int]) -> (Int, Bool) {
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
                cell(headers[ci],
                     x: colXs[ci], y: ry, w: colW(ci), h: hdrH,
                     font: .systemFont(ofSize: 11, weight: weight),
                     color: UIColor(white: 0.28, alpha: 1))
            }
        }
        ry += hdrH

        // ── Par row ───────────────────────────────────────────
        let frontPar = front.reduce(0) { $0 + pars[$1] }
        let backPar  = back.reduce(0)  { $0 + pars[$1] }
        let parTexts: [String] = ["Par"]
            + (0..<9).map  { "\(pars[$0])" }
            + ["\(frontPar)"]
            + (9..<18).map { "\(pars[$0])" }
            + ["\(backPar)", "\(frontPar + backPar)"]

        for ci in 0..<22 {
            fill(x: colXs[ci], y: ry, w: colW(ci), h: parH,
                 color: isSumm(ci) ? summBg : parBg)
            cell(parTexts[ci],
                 x: colXs[ci], y: ry, w: colW(ci), h: parH,
                 font: .systemFont(ofSize: 12, weight: isSumm(ci) ? .semibold : .regular),
                 color: UIColor(white: 0.38, alpha: 1),
                 leftAlign: ci == 0)
        }
        ry += parH

        // ── Player rows ───────────────────────────────────────
        for (pi, player) in players.enumerated() {
            let rowBg: UIColor = pi % 2 == 1 ? altBg : .white
            let (frontSum, hasFront) = rangeSum(player.pts, front)
            let (backSum,  hasBack)  = rangeSum(player.pts, back)

            // Points row
            for ci in 0..<22 {
                fill(x: colXs[ci], y: ry, w: colW(ci), h: ptsH,
                     color: isSumm(ci) ? summBg : rowBg)
                let boldFont   = UIFont.systemFont(ofSize: 14, weight: .bold)
                let semiBFont  = UIFont.systemFont(ofSize: 13, weight: .semibold)
                switch ci {
                case 0:
                    // Name on top portion, "Points" sub-label on bottom
                    let nameH = ptsH * 0.62
                    let subH  = ptsH - nameH
                    cell(player.name,
                         x: colXs[ci], y: ry, w: colW(ci), h: nameH,
                         font: semiBFont, color: .black, leftAlign: true)
                    cell("Points",
                         x: colXs[ci], y: ry + nameH, w: colW(ci), h: subH,
                         font: .systemFont(ofSize: 8, weight: .regular),
                         color: UIColor(white: 0.60, alpha: 1), leftAlign: true)
                case 10:
                    let text = hasFront ? "\(frontSum)" : "·"
                    cell(text, x: colXs[ci], y: ry, w: colW(ci), h: ptsH,
                         font: boldFont, color: hasFront ? .black : dotGray)
                case 20:
                    let text = hasBack ? "\(backSum)" : "·"
                    cell(text, x: colXs[ci], y: ry, w: colW(ci), h: ptsH,
                         font: boldFont, color: hasBack ? .black : dotGray)
                case 21:
                    let (totText, totColor): (String, UIColor)
                    switch (hasFront, hasBack) {
                    case (true, true):   (totText, totColor) = ("\(frontSum + backSum)", .black)
                    case (true, false):  (totText, totColor) = ("\(frontSum)", .black)
                    case (false, true):  (totText, totColor) = ("\(backSum)", .black)
                    default:             (totText, totColor) = ("·", dotGray)
                    }
                    cell(totText, x: colXs[ci], y: ry, w: colW(ci), h: ptsH,
                         font: boldFont, color: totColor)
                default:
                    if let h = hIdx(ci) {
                        let pts  = player.pts[h]
                        cell(pts.map { "\($0)" } ?? "·",
                             x: colXs[ci], y: ry, w: colW(ci), h: ptsH,
                             font: semiBFont, color: ptsColor(pts))
                    }
                }
            }
            ry += ptsH

            // Gross row — subtotals in OUT/IN/TOT
            let (frontGross, hasFrontGross) = rangeSum(player.gross, front)
            let (backGross,  hasBackGross)  = rangeSum(player.gross, back)
            let summaryGrayFont = UIFont.systemFont(ofSize: 11, weight: .semibold)
            let summaryGrayClr  = UIColor(white: 0.38, alpha: 1)

            for ci in 0..<22 {
                fill(x: colXs[ci], y: ry, w: colW(ci), h: grsH,
                     color: isSumm(ci) ? summBg : rowBg)
                if ci == 0 {
                    cell("HC=\(player.hc)",
                         x: colXs[ci], y: ry, w: colW(ci), h: grsH,
                         font: .systemFont(ofSize: 10, weight: .regular),
                         color: UIColor(white: 0.50, alpha: 1), leftAlign: true)
                } else if ci > 0 {
                    let (text, clr, fnt): (String, UIColor, UIFont)
                    switch ci {
                    case 10:
                        let t = hasFrontGross ? "\(frontGross)" : "—"
                        (text, clr, fnt) = (t, summaryGrayClr, summaryGrayFont)
                    case 20:
                        let t = hasBackGross ? "\(backGross)" : "—"
                        (text, clr, fnt) = (t, summaryGrayClr, summaryGrayFont)
                    case 21:
                        let tot: String
                        switch (hasFrontGross, hasBackGross) {
                        case (true, true):   tot = "\(frontGross + backGross)"
                        case (true, false):  tot = "\(frontGross)"
                        case (false, true):  tot = "\(backGross)"
                        default:             tot = "—"
                        }
                        (text, clr, fnt) = (tot, summaryGrayClr, summaryGrayFont)
                    default:
                        if let h = hIdx(ci), let g = player.gross[h] {
                            (text, clr, fnt) = ("\(g)", UIColor(white: 0.42, alpha: 1),
                                                .systemFont(ofSize: 11, weight: .regular))
                        } else {
                            (text, clr, fnt) = ("·", dotGray,
                                                .systemFont(ofSize: 11, weight: .regular))
                        }
                    }
                    cell(text, x: colXs[ci], y: ry, w: colW(ci), h: grsH,
                         font: fnt, color: clr)
                }
            }
            ry += grsH

            // Strokes/pops dots row
            let strkBlue = UIColor(red: 0.20, green: 0.45, blue: 0.80, alpha: 0.80)
            for ci in 0..<22 {
                fill(x: colXs[ci], y: ry, w: colW(ci), h: strkH,
                     color: isSumm(ci) ? summBg : rowBg)
                switch ci {
                case 0:
                    cell("Strokes",
                         x: colXs[ci], y: ry, w: colW(ci), h: strkH,
                         font: .systemFont(ofSize: 8, weight: .regular),
                         color: UIColor(white: 0.55, alpha: 1), leftAlign: true)
                default:
                    if let h = hIdx(ci) {
                        let s = player.strokes[h]
                        if s > 0 {
                            cell(String(repeating: "•", count: s),
                                 x: colXs[ci], y: ry, w: colW(ci), h: strkH,
                                 font: .systemFont(ofSize: 11, weight: .regular),
                                 color: strkBlue)
                        }
                    }
                }
            }
            ry += strkH
        }

        // ── Team separator ────────────────────────────────────
        sepLine.setFill()
        UIRectFill(CGRect(x: hPad, y: ry, width: gridW, height: 2))
        ry += 2

        // ── Team row ─────────────────────────────────────────
        let (frontTeam, hasFrontTeam) = rangeSum(teamPts, front)
        let (backTeam,  hasBackTeam)  = rangeSum(teamPts, back)
        let boldFont = UIFont.systemFont(ofSize: 14, weight: .bold)

        for ci in 0..<22 {
            fill(x: colXs[ci], y: ry, w: colW(ci), h: teamH,
                 color: isSumm(ci) ? teamSummBg : teamBg)
            switch ci {
            case 0:
                cell("TEAM", x: colXs[ci], y: ry, w: colW(ci), h: teamH,
                     font: .systemFont(ofSize: 13, weight: .bold),
                     color: teamBlue, leftAlign: true)
            case 10:
                let text = hasFrontTeam ? "\(frontTeam)" : "·"
                cell(text, x: colXs[ci], y: ry, w: colW(ci), h: teamH,
                     font: boldFont, color: hasFrontTeam ? teamBlue : teamDot)
            case 20:
                let text = hasBackTeam ? "\(backTeam)" : "·"
                cell(text, x: colXs[ci], y: ry, w: colW(ci), h: teamH,
                     font: boldFont, color: hasBackTeam ? teamBlue : teamDot)
            case 21:
                let (totText, totColor): (String, UIColor)
                switch (hasFrontTeam, hasBackTeam) {
                case (true, true):   (totText, totColor) = ("\(frontTeam + backTeam)", teamBlue)
                case (true, false):  (totText, totColor) = ("\(frontTeam)", teamBlue)
                case (false, true):  (totText, totColor) = ("\(backTeam)", teamBlue)
                default:             (totText, totColor) = ("·", teamDot)
                }
                cell(totText, x: colXs[ci], y: ry, w: colW(ci), h: teamH,
                     font: boldFont, color: totColor)
            default:
                if let h = hIdx(ci) {
                    let pts = teamPts[h]
                    cell(pts.map { "\($0)" } ?? "·",
                         x: colXs[ci], y: ry, w: colW(ci), h: teamH,
                         font: boldFont, color: pts != nil ? teamBlue : teamDot)
                }
            }
        }
        ry += teamH

        // ── Grid lines (drawn on top of cells) ────────────────
        gridLine.setFill()
        // Horizontal lines
        var lineY = y
        UIRectFill(CGRect(x: hPad, y: lineY, width: gridW, height: 0.5))
        lineY += hdrH
        UIRectFill(CGRect(x: hPad, y: lineY, width: gridW, height: 0.5))
        lineY += parH
        UIRectFill(CGRect(x: hPad, y: lineY, width: gridW, height: 0.5))
        for _ in players {
            lineY += ptsH + grsH + strkH
            UIRectFill(CGRect(x: hPad, y: lineY, width: gridW, height: 0.5))
        }
        // Vertical lines
        for ci in 0..<22 {
            UIRectFill(CGRect(x: colXs[ci], y: y, width: 0.5, height: ry - y))
        }
        UIRectFill(CGRect(x: hPad + gridW, y: y, width: 0.5, height: ry - y))

        return ry
    }

    // MARK: - Footer

    private func drawFooter(y: CGFloat) {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        drawCentered("Submitted via Wolfmore  ·  \(fmt.string(from: date))",
                     y: y + 18,
                     font: .systemFont(ofSize: 13, weight: .regular),
                     color: UIColor(white: 0.58, alpha: 1))
    }

    // MARK: - Drawing primitives

    private func fill(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, color: UIColor) {
        color.setFill()
        UIRectFill(CGRect(x: x, y: y, width: w, height: h))
    }

    private func cell(_ text: String,
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
