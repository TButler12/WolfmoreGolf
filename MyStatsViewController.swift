import UIKit

final class MyStatsViewController: UIViewController {
    
    // MARK: - Modes / Sorting
    
    enum Mode { case me, friends }
    enum SortKey { case name, money, prox }
    
    var mode: Mode = .me
    private var sortKey: SortKey = .money
    
    // MARK: - UI
    
    private let textView = UITextView()
    private let sortControl = UISegmentedControl(items: ["Name", "Money", "Prox"])
    
    // MARK: - Data
    
    private var allFriends: [Friend] { FriendStore.shared.friends }
    
    // MARK: - Formatting
    
    private let currency0: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 0
        return nf
    }()
    
    private func wonLostText(totalMoney: Int) -> String {
        let verb = (totalMoney >= 0) ? "Won" : "Lost"
        let amt = abs(totalMoney)
        let amtStr = currency0.string(from: NSNumber(value: amt)) ?? "\(amt)"
        return "\(verb) \(amtStr)"
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        title = (mode == .me) ? "My Stats" : "Friend Stats"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: #selector(doneTapped)
        )
        
        configureTextView()
        
        if mode == .friends {
            configureSortControl()
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reload),
            name: .reloadUI,
            object: nil
        )
        
        reload()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UI Setup
    
    private func configureTextView() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.font = .monospacedSystemFont(ofSize: 16, weight: .regular)
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 14, bottom: 16, right: 14)
        
        view.addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func configureSortControl() {
        sortControl.selectedSegmentIndex = 1
        sortControl.addTarget(self, action: #selector(sortChanged(_:)), for: .valueChanged)
        navigationItem.titleView = sortControl
    }
    
    // MARK: - Actions
    
    @objc private func doneTapped() {
        if let nav = navigationController, nav.viewControllers.first != self {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    @objc private func sortChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: sortKey = .name
        case 1: sortKey = .money
        default: sortKey = .prox
        }
        reload()
    }
    
    // MARK: - Reload
    
    @objc private func reload() {
        switch mode {
        case .me:
            navigationItem.titleView = nil
            title = "My Stats"
            textView.attributedText = buildMyStatsAttributedText()
            
        case .friends:
            title = "Friend Stats"
            textView.attributedText = buildFriendStatsAttributedTextPinnedMe()
        }
    }
    
    
    
    // MARK: - Build: My Stats
    private var bodyFont: UIFont {
        .monospacedSystemFont(ofSize: 16, weight: .regular)
    }
    
    private var boldFont: UIFont {
        .monospacedSystemFont(ofSize: 16, weight: .bold)
    }
    
    private var smallBoldFont: UIFont {
        .monospacedSystemFont(ofSize: 15, weight: .semibold)
    }
    
    private func attrs(
        font: UIFont,
        color: UIColor = .label
    ) -> [NSAttributedString.Key: Any] {
        [
            .font: font,
            .foregroundColor: color
        ]
    }
    private func statSymbol(for value: Bool?) -> (text: String, color: UIColor) {
        guard let value else { return ("–", .quaternaryLabel) }
        return value ? ("●", .systemGreen) : ("○", .tertiaryLabel)
    }
    private func buildMyStatsMessage() -> String {
        let myName = (ProfileStore.name ?? "Player 1")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let s = RoundStore.shared.stats(forPlayerNamed: myName) else {
            return "No rounds saved yet for \(myName)."
        }

        var text = formatBlock(name: myName, stats: s, showDetailStats: true)

        if let lastRound = RoundStore.shared.lastRound(forPlayer: myName) {
            text += "\n\n— LAST ROUND (BY HOLE) —\n"
            text += formatLastRoundByHole(lastRound)
        }

        let parText = formatAveragesByPar()

        if !parText.isEmpty {
            text += "\n\n— AVERAGES BY PAR —\n"
            text += parText
        }

        return text
    
    }
    
    private func attributedLastRoundByHole(_ r: RoundSummary) -> NSAttributedString {
        let result = NSMutableAttributedString()

        result.append(NSAttributedString(
            string: "Hole\tScore\tFW\tGIR\tPutts\n",
            attributes: rowAttrs(font: bodyFont, color: .secondaryLabel)
        ))
        for h in 0..<18 {
            let fwValue: Bool? = h < r.fairwayHitPerHole.count ? r.fairwayHitPerHole[h] : nil
            let girValue: Bool? = h < r.girPerHole.count ? r.girPerHole[h] : nil

            let fw = statSymbol(for: fwValue)
            let gir = statSymbol(for: girValue)

            let score: String = {
                guard h < r.scorePerHole.count else { return "–" }
                guard let value = r.scorePerHole[h] else { return "–" }
                return "\(value)"
            }()

            let putts: String = {
                guard h < r.puttsPerHole.count else { return "–" }
                guard let value = r.puttsPerHole[h] else { return "–" }
                return "\(value)"
            }()

            result.append(NSAttributedString(
                string: "\(h + 1)\t",
                attributes: rowAttrs(font: bodyFont, color: .secondaryLabel)
            ))

            result.append(NSAttributedString(
                string: "\(score)\t",
                attributes: rowAttrs(font: bodyFont, color: .label)
            ))

            result.append(NSAttributedString(
                string: "\(fw.text)\t",
                attributes: rowAttrs(font: bodyFont, color: fw.color)
            ))

            result.append(NSAttributedString(
                string: "\(gir.text)\t",
                attributes: rowAttrs(font: bodyFont, color: gir.color)
            ))

            let puttsColor: UIColor = putts == "–" ? .quaternaryLabel : .label
            result.append(NSAttributedString(
                string: "\(putts)\n",
                attributes: rowAttrs(font: bodyFont, color: puttsColor)
            ))
        }
        return result
    }
    private func attributedHoleAverages(_ avgs: [RoundStore.HoleAverage]) -> NSAttributedString {
        let result = NSMutableAttributedString()

        result.append(NSAttributedString(
            string: "Hole\tFW%\tGIR%\tPutts\n",
            attributes: rowAttrs(font: bodyFont, color: .secondaryLabel)
        ))

        for a in avgs {
            let fw = a.fairwayPct.map { String(format: "%.0f%%", $0) } ?? "–"
            let gir = a.girPct.map { String(format: "%.0f%%", $0) } ?? "–"
            let putts = a.avgPutts.map { String(format: "%.1f", $0) } ?? "–"

            result.append(NSAttributedString(
                string: "\(a.hole)\t\(fw)\t\(gir)\t\(putts)\n",
                attributes: rowAttrs(font: bodyFont, color: .secondaryLabel)
            ))
        }

        return result
    }
    private func buildMyStatsAttributedText() -> NSAttributedString {
        let result = NSMutableAttributedString()

        let myName = (ProfileStore.name ?? "Player 1")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let s = RoundStore.shared.stats(forPlayerNamed: myName) else {
            return NSAttributedString(
                string: "No rounds saved yet for \(myName).",
                attributes: attrs(font: bodyFont)
            )
        }

        result.append(NSAttributedString(
            string: formatBlock(name: myName, stats: s, showDetailStats: true),
            attributes: attrs(font: bodyFont)
        ))

        if let lastRound = RoundStore.shared.lastRound(forPlayer: myName) {
            result.append(NSAttributedString(
                string: "\n\n— LAST ROUND (BY HOLE) —\n",
                attributes: attrs(font: boldFont)
            ))
            result.append(attributedLastRoundByHole(lastRound))
            result.append(NSAttributedString(string: "\n", attributes: attrs(font: bodyFont)))
            result.append(attributedLastRoundTotals(lastRound))
        }

        let parText = formatAveragesByPar()

        if !parText.isEmpty {
            result.append(NSAttributedString(
                string: "\n\n— AVERAGES BY PAR —\n",
                attributes: attrs(font: boldFont)
            ))

            result.append(NSAttributedString(
                string: parText,
                attributes: attrs(font: bodyFont, color: .secondaryLabel)
            ))
        }

        return result
    }
    private func buildFriendStatsAttributedTextPinnedMe() -> NSAttributedString {
        let result = NSMutableAttributedString()

        let myName = (ProfileStore.name ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if !myName.isEmpty,
           let myStats = RoundStore.shared.stats(forPlayerNamed: myName) {

            result.append(NSAttributedString(
                string: "— ME —\n",
                attributes: attrs(font: boldFont)
            ))

            result.append(NSAttributedString(
                string: formatBlock(name: myName, stats: myStats),
                attributes: attrs(font: bodyFont)
            ))

            if let lastRound = RoundStore.shared.lastRound(forPlayer: myName) {
                result.append(NSAttributedString(
                    string: "\n\n— LAST ROUND (BY HOLE) —\n",
                    attributes: attrs(font: boldFont)
                ))
                result.append(attributedLastRoundByHole(lastRound))
                result.append(NSAttributedString(
                    string: "\n",
                    attributes: attrs(font: bodyFont)
                ))
                result.append(attributedLastRoundTotals(lastRound))
            }

            let holeAverages = RoundStore.shared.averagesByHole(forPlayer: myName)
            let parText = formatAveragesByPar()

            if !parText.isEmpty {
                result.append(NSAttributedString(
                    string: "\n\n— AVERAGES BY PAR —\n",
                    attributes: attrs(font: boldFont)
                ))

                result.append(NSAttributedString(
                    string: parText,
                    attributes: attrs(font: bodyFont, color: .secondaryLabel)
                ))
            }
        }

        var friendRows: [(name: String, stats: MyStats)] = allFriends.compactMap { f in
            let n = f.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !n.isEmpty else { return nil }

            if !myName.isEmpty, n.caseInsensitiveCompare(myName) == .orderedSame {
                return nil
            }

            guard let s = RoundStore.shared.stats(forPlayerNamed: n) else { return nil }
            return (n, s)
        }

        switch sortKey {
        case .name:
            friendRows.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .money:
            friendRows.sort { $0.stats.totalMoney > $1.stats.totalMoney }
        case .prox:
            friendRows.sort { $0.stats.totalProx > $1.stats.totalProx }
        }

        if !friendRows.isEmpty {
            result.append(NSAttributedString(
                string: "\n\n— FRIENDS —\n",
                attributes: attrs(font: boldFont)
            ))

            for (index, row) in friendRows.enumerated() {
                if index > 0 {
                    result.append(NSAttributedString(
                        string: "\n\n",
                        attributes: attrs(font: bodyFont)
                    ))
                }

                result.append(NSAttributedString(
                    string: formatBlock(name: row.name, stats: row.stats, showDetailStats: false),
                    attributes: attrs(font: bodyFont)
                ))
            }
        }

        if result.length == 0 {
            return NSAttributedString(
                string: "No rounds saved yet.",
                attributes: attrs(font: bodyFont)
            )
        }

        return result
    }
    private func formatAveragesByPar() -> String {
        guard let g = GameManager.shared.currentGame else { return "" }

        let myName = (ProfileStore.name ?? "Player 1")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let holeAverages = RoundStore.shared.averagesByHole(forPlayer: myName)
        guard !holeAverages.isEmpty else { return "" }

        let pars = Array(g.course.pars.prefix(18))

        func line(for par: Int) -> String {
            let holes = holeAverages.filter { avg in
                let index = avg.hole - 1
                return pars.indices.contains(index) && pars[index] == par
            }

            guard !holes.isEmpty else {
                return "Par \(par)s\n  No data"
            }

            let fwValues = holes.compactMap { $0.fairwayPct }
            let girValues = holes.compactMap { $0.girPct }
            let puttValues = holes.compactMap { $0.avgPutts }

            let fwText: String
            if par == 3 || fwValues.isEmpty {
                fwText = "FW —"
            } else {
                let avg = fwValues.reduce(0, +) / Double(fwValues.count)
                fwText = String(format: "FW %.0f%%", avg)
            }

            let girText: String = {
                guard !girValues.isEmpty else { return "GIR —" }
                let avg = girValues.reduce(0, +) / Double(girValues.count)
                return String(format: "GIR %.0f%%", avg)
            }()

            let puttsText: String = {
                guard !puttValues.isEmpty else { return "Putts —" }
                let avg = puttValues.reduce(0, +) / Double(puttValues.count)
                return String(format: "Putts %.1f", avg)
            }()

            return """
            Par \(par)s
              \(fwText)   \(girText)   \(puttsText)
            """
        }

        return [3, 4, 5]
            .map { line(for: $0) }
            .joined(separator: "\n\n")
    }
    private func rowParagraphStyle() -> NSParagraphStyle {
        let p = NSMutableParagraphStyle()
        p.defaultTabInterval = 60
        p.tabStops = [
            NSTextTab(textAlignment: .center, location: 100),    // Hole
            NSTextTab(textAlignment: .center, location: 142),    // Score
            NSTextTab(textAlignment: .center, location: 182),  // FW
            NSTextTab(textAlignment: .center, location: 122),  // GIR
            NSTextTab(textAlignment: .right, location: 282)    // Putts
        ]
        return p
    }

    private func rowAttrs(
        font: UIFont,
        color: UIColor = .label
    ) -> [NSAttributedString.Key: Any] {
        [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: rowParagraphStyle()
        ]
    }
    
    private func attributedLastRoundTotals(_ r: RoundSummary) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        let holes = min(18, max(r.holesPlayed, 0))
        
        var fwHit = 0
        var fwTotal = 0
        var girHit = 0
        var girTotal = 0
        var puttSum = 0
        var puttTotal = 0
        
        for h in 0..<holes {
            if h < r.fairwayHitPerHole.count, let fw = r.fairwayHitPerHole[h] {
                fwTotal += 1
                if fw { fwHit += 1 }
            }
            
            if h < r.girPerHole.count, let gir = r.girPerHole[h] {
                girTotal += 1
                if gir { girHit += 1 }
            }
            
            if h < r.puttsPerHole.count, let p = r.puttsPerHole[h] {
                puttSum += p
                puttTotal += 1
            }
        }
        
        let fwPct = fwTotal > 0 ? Int((Double(fwHit) / Double(fwTotal) * 100).rounded()) : 0
        let girPct = girTotal > 0 ? Int((Double(girHit) / Double(girTotal) * 100).rounded()) : 0
        let avgPutts = puttTotal > 0 ? String(format: "%.1f", Double(puttSum) / Double(puttTotal)) : "–"
        
        result.append(NSAttributedString(
            string: "Totals\n",
            attributes: attrs(font: smallBoldFont, color: .secondaryLabel)
        ))
        
        result.append(NSAttributedString(
            string: "FIR \(fwHit)/\(fwTotal) (\(fwPct)%)\n",
            attributes: attrs(font: bodyFont)
        ))
        result.append(NSAttributedString(
            string: "GIR \(girHit)/\(girTotal) (\(girPct)%)\n",
            attributes: attrs(font: bodyFont)
        ))
        result.append(NSAttributedString(
            string: "Avg Putts \(avgPutts)",
            attributes: attrs(font: bodyFont)
        ))
        
        return result
    }
    // MARK: - Build: Friends Stats
    
    private func buildFriendStatsMessagePinnedMe() -> String {
        let myName = (ProfileStore.name ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        var blocks: [String] = []
        
        if !myName.isEmpty,
           let myStats = RoundStore.shared.stats(forPlayerNamed: myName) {
            
            var meBlock = formatBlock(name: myName, stats: myStats)
            
            if let lastRound = RoundStore.shared.lastRound(forPlayer: myName) {
                meBlock += "\n\n— LAST ROUND (BY HOLE) —\n"
                meBlock += formatLastRoundByHole(lastRound)
                meBlock += "\n" + formatLastRoundTotals(lastRound)
            }
            
            let parText = formatAveragesByPar()

            if !parText.isEmpty {
                meBlock += "\n\n— AVERAGES BY PAR —\n"
                meBlock += parText
            }
            
            blocks.append("— ME —\n" + meBlock)
        }
        
        var friendRows: [(name: String, stats: MyStats)] = allFriends.compactMap { f in
            let n = f.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !n.isEmpty else { return nil }
            
            if !myName.isEmpty, n.caseInsensitiveCompare(myName) == .orderedSame {
                return nil
            }
            
            guard let s = RoundStore.shared.stats(forPlayerNamed: n) else { return nil }
            return (n, s)
        }
        
        guard !(blocks.isEmpty && friendRows.isEmpty) else {
            return "No rounds saved yet."
        }
        
        switch sortKey {
        case .name:
            friendRows.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .money:
            friendRows.sort { $0.stats.totalMoney > $1.stats.totalMoney }
        case .prox:
            friendRows.sort { $0.stats.totalProx > $1.stats.totalProx }
        }
        
        if !friendRows.isEmpty {
            let friendsText = friendRows
                .map { formatBlock(name: $0.name, stats: $0.stats) }
                .joined(separator: "\n\n")
            
            blocks.append("— FRIENDS —\n" + friendsText)
        }
        
        return blocks.joined(separator: "\n\n\n")
    }
    
    // MARK: - Formatting
    private func formatLastRoundTotals(_ r: RoundSummary) -> String {
        let holes = min(18, max(r.holesPlayed, 0))
        
        var fwHit = 0
        var fwTotal = 0
        var girHit = 0
        var girTotal = 0
        var puttSum = 0
        var puttTotal = 0
        
        for h in 0..<holes {
            if h < r.fairwayHitPerHole.count, let fw = r.fairwayHitPerHole[h] {
                fwTotal += 1
                if fw { fwHit += 1 }
            }
            
            if h < r.girPerHole.count, let gir = r.girPerHole[h] {
                girTotal += 1
                if gir { girHit += 1 }
            }
            
            if h < r.puttsPerHole.count, let p = r.puttsPerHole[h] {
                puttSum += p
                puttTotal += 1
            }
        }
        
        let fwPct = fwTotal > 0 ? Int((Double(fwHit) / Double(fwTotal) * 100.0).rounded()) : 0
        let girPct = girTotal > 0 ? Int((Double(girHit) / Double(girTotal) * 100.0).rounded()) : 0
        let avgPutts = puttTotal > 0 ? String(format: "%.1f", Double(puttSum) / Double(puttTotal)) : "-"
        
        return """
        Totals
        FIR \(fwHit)/\(fwTotal) (\(fwPct)%)
        GIR \(girHit)/\(girTotal) (\(girPct)%)
        Avg Putts \(avgPutts)
        """
    }
    private func formatBlock(name: String, stats s: MyStats, showDetailStats: Bool = true) -> String {
        let totalLine = wonLostText(totalMoney: s.totalMoney)
        let avgMoneyStr = String(format: "%.1f", s.avgMoneyPerRound)
        let avgProxStr  = String(format: "%.1f", s.avgProxPerRound)

        var text = """
        • \(name)
          \(s.rounds) rds
          \(totalLine)
          avg $\(avgMoneyStr) per 18
          prox \(s.totalProx) total (avg \(avgProxStr) per 18)
        """

        if showDetailStats {
            let fwPct = String(format: "%.0f", s.fairwayPct)
            let girPct = String(format: "%.0f", s.girPct)
            let puttsAvg = String(format: "%.1f", s.avgPutts)

            text += """

              FIR \(s.fairwaysHit)/\(s.fairwaysPossible) (\(fwPct)%)
              GIR \(s.girHit)/\(s.girPossible) (\(girPct)%)
              avg putts \(puttsAvg)
            """
        }

        return text
    }
    
    private func col(_ value: String, width: Int) -> String {
        if value.count >= width { return value }
        return String(repeating: " ", count: width - value.count) + value
    }
    
    private func formatLastRoundByHole(_ r: RoundSummary) -> String {
        var lines: [String] = []
        
        lines.append(
            col("Hole", width: 4) + " " +
            col("FW", width: 4) + " " +
            col("GIR", width: 4) + " " +
            col("Putts", width: 5)
        )
        
        for h in 0..<18 {
            let fw: String = {
                guard h < r.fairwayHitPerHole.count else { return "-" }
                guard let value = r.fairwayHitPerHole[h] else { return "-" }
                return value ? "✓" : "-"
            }()
            
            let gir: String = {
                guard h < r.girPerHole.count else { return "-" }
                guard let value = r.girPerHole[h] else { return "-" }
                return value ? "✓" : "-"
            }()
            
            let putts: String = {
                guard h < r.puttsPerHole.count else { return "-" }
                guard let value = r.puttsPerHole[h] else { return "-" }
                return "\(value)"
            }()
            
            lines.append(
                col("\(h + 1)", width: 4) + " " +
                col(fw, width: 4) + " " +
                col(gir, width: 4) + " " +
                col(putts, width: 5)
            )
        }
        
        return lines.joined(separator: "\n")
    }
    
    private func formatHoleAverages(_ avgs: [RoundStore.HoleAverage]) -> String {
        var lines: [String] = []
        
        lines.append(
            col("Hole", width: 4) + " " +
            col("FW%", width: 4) + " " +
            col("GIR%", width: 4) + " " +
            col("Putts", width: 5)
        )
        
        for a in avgs {
            let fw = a.fairwayPct.map { String(format: "%.0f%%", $0) } ?? "-"
            let gir = a.girPct.map { String(format: "%.0f%%", $0) } ?? "-"
            let putts = a.avgPutts.map { String(format: "%.1f", $0) } ?? "-"
            
            lines.append(
                col("\(a.hole)", width: 4) + " " +
                col(fw, width: 4) + " " +
                col(gir, width: 4) + " " +
                col(putts, width: 5)
            )
        }
        
        return lines.joined(separator: "\n")
    }
    
}
