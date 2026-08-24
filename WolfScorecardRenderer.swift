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

        let docHdrH: CGFloat = 96
        let totalPlayerRows = players.reduce(0) { $0 + ($1.gross2 != nil ? 2 : 1) }
        let gridH   = hdrH + parH + CGFloat(totalPlayerRows) * playerH
        let footerH: CGFloat = 40
        let totalH  = docHdrH + gridH + footerH

        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 2
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: pageW, height: totalH), format: fmt)

        return renderer.image { _ in
            UIColor.white.setFill()
            UIRectFill(CGRect(x: 0, y: 0, width: pageW, height: totalH))

            var y: CGFloat = 0
            y = drawDocHeader(y: y, players: players)
            y = drawGrid(y: y, players: players, pars: pars)
            drawFooter(y: y)
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

    // MARK: - Document header

    @discardableResult
    private func drawDocHeader(y: CGFloat, players: [PlayerData]) -> CGFloat {
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

        return cy + 8
    }

    // MARK: - Scorecard grid

    @discardableResult
    private func drawGrid(y: CGFloat, players: [PlayerData], pars: [Int]) -> CGFloat {

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

        // ── Grid lines ────────────────────────────────────────
        gridLine.setFill()
        var lineY = y
        let totalPlayerRows = players.reduce(0) { $0 + ($1.gross2 != nil ? 2 : 1) }
        for step in [hdrH, parH] + Array(repeating: playerH, count: totalPlayerRows) {
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

    private func drawFooter(y: CGFloat) {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        drawCentered("Wolfmore  ·  \(fmt.string(from: date))",
                     y: y + 12,
                     font: .systemFont(ofSize: 12, weight: .regular),
                     color: UIColor(white: 0.58, alpha: 1))
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
