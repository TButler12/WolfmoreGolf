import UIKit

// MARK: - PairedHole

struct PairedHole {
    let hcRank: Int
    let hostPhysicalHole: Int      // 1-based for display
    let hostScore: Int?            // gross
    let hostNetScore: Int?         // gross minus strokes
    let hostStrokes: Int           // HC strokes received on this hole
    let hostPar: Int?              // from CourseLibrary; nil when course not in library
    let opponentPhysicalHole: Int
    let opponentScore: Int?        // gross
    let opponentNetScore: Int?     // gross minus strokes
    let opponentStrokes: Int
    let opponentPar: Int?          // from CourseLibrary; nil when course not in library
    let netResult: Int             // +1 = owner wins, -1 = opponent wins, 0 = tie or uncommitted
}

// MARK: - ScorecardConfig

struct ScorecardConfig {
    let ownerName: String
    let opponentName: String
    let ownerCourse: String        // "" when same course
    let opponentCourse: String
    let pairs: [PairedHole]        // up to 18
    let stake: Double
    let trigger: Int
    let pressMode: NassauPressMode
    let isV2: Bool
    let isSameCourse: Bool
    let posLabel: String           // "H" same-course, "#" cross-course
    let title: String              // nav-bar title
}

// MARK: - ScorecardBuilder (pure logic — no UIKit; testable)

enum ScorecardBuilder {

    struct HoleData {
        let matchPos: Int          // 1-18
        let yourHole: Int          // 1-based course hole
        let yourPar: Int?
        let yourGross: Int?
        let yourStrokes: Int
        let yourNet: Int?
        let oppHole: Int
        let oppPar: Int?
        let oppGross: Int?
        let oppStrokes: Int
        let oppNet: Int?
        let bothScored: Bool
        let waitingForName: String? // non-nil when exactly one player hasn't scored
        let holeResult: Int        // +1 you win, -1 opp wins, 0 otherwise
        let runningNet: Int?       // cumulative after this hole if bothScored, else nil
    }

    enum Item {
        case header
        case pressStart(pressNumber: Int)
        case hole(HoleData)
        case subtotal(nine: Int, yourGross: Int, oppGross: Int, result: String)
    }

    static func build(config: ScorecardConfig) -> [Item] {
        let pairs = config.pairs
        guard !pairs.isEmpty else { return [.header] }

        // Per-hole data
        var cumNet = 0
        var holeData = [HoleData]()
        holeData.reserveCapacity(pairs.count)
        for (i, ph) in pairs.enumerated() {
            let bothScored      = ph.hostScore != nil && ph.opponentScore != nil
            let waitingForOpp   = ph.hostScore != nil && ph.opponentScore == nil
            let waitingForOwner = ph.hostScore == nil && ph.opponentScore != nil
            if bothScored { cumNet += ph.netResult }
            holeData.append(HoleData(
                matchPos:      i + 1,
                yourHole:      ph.hostPhysicalHole,
                yourPar:       ph.hostPar,
                yourGross:     ph.hostScore,
                yourStrokes:   ph.hostStrokes,
                yourNet:       ph.hostNetScore,
                oppHole:       ph.opponentPhysicalHole,
                oppPar:        ph.opponentPar,
                oppGross:      ph.opponentScore,
                oppStrokes:    ph.opponentStrokes,
                oppNet:        ph.opponentNetScore,
                bothScored:    bothScored,
                waitingForName: waitingForOpp   ? config.opponentName
                              : waitingForOwner ? config.ownerName
                              : nil,
                holeResult:    bothScored ? ph.netResult : 0,
                runningNet:    bothScored ? cumNet : nil
            ))
        }

        // Press detection — same algorithm and parameters as LiveNassauViewController
        let frontCount = min(9, pairs.count)
        let frontPairs = Array(pairs.prefix(frontCount))
        let backPairs  = pairs.count > 9 ? Array(pairs.suffix(from: 9)) : []

        var allPresses = [NassauPressDetector.Press]()
        if config.pressMode == .auto {
            let detect: (([PairedHole], Int, Int) -> [NassauPressDetector.Press]) = config.isV2
                ? { NassauPressDetector.detectV2(pairs: $0, holeOffset: $1, segmentEndPos: $2, trigger: config.trigger, stake: config.stake) }
                : { NassauPressDetector.detectLegacy(pairs: $0, holeOffset: $1, segmentEndPos: $2, trigger: config.trigger, stake: config.stake) }
            allPresses += detect(frontPairs, 0, frontCount)
            if !backPairs.isEmpty { allPresses += detect(backPairs, 9, pairs.count) }
        }
        // Group presses by startPos, preserving insertion order (deterministic across devices)
        var byPos = [Int: [Int]]()
        for (idx, p) in allPresses.enumerated() { byPos[p.startPos, default: []].append(idx + 1) }

        // Gross accumulators per nine
        var fg = 0; var fo = 0   // front yours / opp
        var bg = 0; var bo = 0   // back yours / opp

        var items: [Item] = [.header]
        for (i, hd) in holeData.enumerated() {
            // Subtotal after front 9 (only for 18-hole view)
            if i == 9 {
                let r = nineResult(holeData: Array(holeData.prefix(9)),
                                   ownerName: config.ownerName, oppName: config.opponentName)
                items.append(.subtotal(nine: 1, yourGross: fg, oppGross: fo, result: r))
            }
            // Press markers starting at this match position
            if let nums = byPos[hd.matchPos] {
                for n in nums { items.append(.pressStart(pressNumber: n)) }
            }
            items.append(.hole(hd))
            if hd.bothScored {
                if i < 9 { fg += hd.yourGross ?? 0; fo += hd.oppGross ?? 0 }
                else      { bg += hd.yourGross ?? 0; bo += hd.oppGross ?? 0 }
            }
        }
        // Final subtotal
        if pairs.count <= 9 {
            let r = nineResult(holeData: holeData, ownerName: config.ownerName, oppName: config.opponentName)
            items.append(.subtotal(nine: 1, yourGross: fg, oppGross: fo, result: r))
        } else {
            let r = nineResult(holeData: Array(holeData.suffix(from: 9)),
                               ownerName: config.ownerName, oppName: config.opponentName)
            items.append(.subtotal(nine: 2, yourGross: bg, oppGross: bo, result: r))
            let rAll = nineResult(holeData: holeData, ownerName: config.ownerName, oppName: config.opponentName)
            items.append(.subtotal(nine: 3, yourGross: fg + bg, oppGross: fo + bo, result: rAll))
        }
        return items
    }

    static func nineResult(holeData: [HoleData], ownerName: String, oppName: String) -> String {
        let scored = holeData.filter { $0.bothScored }
        guard !scored.isEmpty else { return "—" }
        let net = scored.reduce(0) { $0 + $1.holeResult }
        if net > 0 { return "\(ownerName) \(net) up" }
        if net < 0 { return "\(oppName) \(abs(net)) up" }
        return "All Square"
    }

    // Returns the press list in the same order as allPresses above — for marker alignment tests.
    static func presses(config: ScorecardConfig) -> [NassauPressDetector.Press] {
        guard config.pressMode == .auto else { return [] }
        let frontCount = min(9, config.pairs.count)
        let frontPairs = Array(config.pairs.prefix(frontCount))
        let backPairs  = config.pairs.count > 9 ? Array(config.pairs.suffix(from: 9)) : []
        let detect: (([PairedHole], Int, Int) -> [NassauPressDetector.Press]) = config.isV2
            ? { NassauPressDetector.detectV2(pairs: $0, holeOffset: $1, segmentEndPos: $2, trigger: config.trigger, stake: config.stake) }
            : { NassauPressDetector.detectLegacy(pairs: $0, holeOffset: $1, segmentEndPos: $2, trigger: config.trigger, stake: config.stake) }
        var result = detect(frontPairs, 0, frontCount)
        if !backPairs.isEmpty { result += detect(backPairs, 9, config.pairs.count) }
        return result
    }
}

// MARK: - Column layout constants

private enum Col {
    static let matchNum:   CGFloat = 22
    static let holeAndPar: CGFloat = 48   // "H10 P5"
    static let gross:      CGFloat = 26   // "10••"
    static let net:        CGFloat = 20   // "9"
    static let result:     CGFloat = 20   // "W"/"L"/"H"
    static let spacing:    CGFloat =  4
    // Total fixed per player section = holeAndPar + spacing + gross + spacing + net = 98
    static let playerSectionWidth = holeAndPar + spacing + gross + spacing + net
    static let headerHeight: CGFloat = 66
}

// MARK: - NassauScorecardViewController

final class NassauScorecardViewController: UIViewController {

    private let config: ScorecardConfig
    private let items:  [ScorecardBuilder.Item]
    private let tableView = UITableView(frame: .zero, style: .plain)

    static let headerCellID   = "ScorecardHeaderCell"
    static let holeCellID     = "ScorecardHoleCell"
    static let pressCellID    = "ScorecardPressCell"
    static let subtotalCellID = "ScorecardSubtotalCell"

    init(config: ScorecardConfig) {
        self.config = config
        self.items  = ScorecardBuilder.build(config: config)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = config.title
        view.backgroundColor = .systemBackground
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.separatorInset = .zero
        tableView.register(ScorecardHeaderCell.self,   forCellReuseIdentifier: Self.headerCellID)
        tableView.register(ScorecardHoleCell.self,     forCellReuseIdentifier: Self.holeCellID)
        tableView.register(ScorecardPressCell.self,    forCellReuseIdentifier: Self.pressCellID)
        tableView.register(ScorecardSubtotalCell.self, forCellReuseIdentifier: Self.subtotalCellID)
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(shareTapped))
    }

    @objc private func shareTapped() {
        let image = ScorecardRenderer.render(config: config)
        let ac = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let pop = ac.popoverPresentationController {
            pop.barButtonItem = navigationItem.rightBarButtonItem
        }
        present(ac, animated: true)
    }
}

// MARK: - UITableViewDataSource / Delegate

extension NassauScorecardViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch items[indexPath.row] {
        case .header:      return Col.headerHeight
        case .pressStart:  return 20
        case .hole:        return 34
        case .subtotal:    return 38
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch items[indexPath.row] {
        case .header:
            let c = tableView.dequeueReusableCell(withIdentifier: Self.headerCellID, for: indexPath) as! ScorecardHeaderCell
            c.configure(ownerName: config.ownerName, oppName: config.opponentName,
                        ownerCourse: config.ownerCourse, oppCourse: config.opponentCourse)
            return c
        case .pressStart(let num):
            let c = tableView.dequeueReusableCell(withIdentifier: Self.pressCellID, for: indexPath) as! ScorecardPressCell
            c.configure(pressNumber: num)
            return c
        case .hole(let hd):
            let c = tableView.dequeueReusableCell(withIdentifier: Self.holeCellID, for: indexPath) as! ScorecardHoleCell
            c.configure(hd: hd, ownerName: config.ownerName, oppName: config.opponentName)
            return c
        case .subtotal(let nine, let yg, let og, let result):
            let c = tableView.dequeueReusableCell(withIdentifier: Self.subtotalCellID, for: indexPath) as! ScorecardSubtotalCell
            c.configure(nine: nine, yourGross: yg, oppGross: og, result: result)
            return c
        }
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool { false }
}

// MARK: - ScorecardHeaderCell

final class ScorecardHeaderCell: UITableViewCell {

    private let nameRow   = UIStackView()
    private let courseRow = UIStackView()
    private let colRow    = UIStackView()
    private let outer     = UIStackView()

    // Name row
    private let nameSpacer    = UIView()
    private let ownerNameL    = makeL(size: 12, weight: .semibold, align: .center)
    private let oppNameL      = makeL(size: 12, weight: .semibold, align: .center)

    // Course row (shown only when at least one course is non-empty)
    private let courseSpacer  = UIView()
    private let ownerCourseL  = makeL(size: 10, weight: .regular,  align: .center)
    private let oppCourseL    = makeL(size: 10, weight: .regular,  align: .center)

    // Column row labels
    private let matchNumL   = makeL(size: 10, weight: .regular, align: .center)
    private let yHoleL      = makeL(size: 10, weight: .regular, align: .center)
    private let yGrossL     = makeL(size: 10, weight: .regular, align: .center)
    private let yNetL       = makeL(size: 10, weight: .regular, align: .center)
    private let oHoleL      = makeL(size: 10, weight: .regular, align: .center)
    private let oGrossL     = makeL(size: 10, weight: .regular, align: .center)
    private let oNetL       = makeL(size: 10, weight: .regular, align: .center)
    private let resultL     = makeL(size: 10, weight: .regular, align: .center)
    private let statusL     = makeL(size: 10, weight: .regular, align: .left)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .secondarySystemBackground

        // Name row
        nameSpacer.widthAnchor.constraint(equalToConstant: Col.matchNum).isActive = true
        [ownerNameL, oppNameL].forEach {
            $0.widthAnchor.constraint(equalToConstant: Col.playerSectionWidth).isActive = true
            $0.textColor = .label
        }
        nameRow.axis    = .horizontal
        nameRow.spacing = Col.spacing
        for v in [nameSpacer, ownerNameL, oppNameL] { nameRow.addArrangedSubview(v) }

        // Course row
        courseSpacer.widthAnchor.constraint(equalToConstant: Col.matchNum).isActive = true
        [ownerCourseL, oppCourseL].forEach {
            $0.widthAnchor.constraint(equalToConstant: Col.playerSectionWidth).isActive = true
            $0.textColor = .secondaryLabel
        }
        courseRow.axis    = .horizontal
        courseRow.spacing = Col.spacing
        for v in [courseSpacer, ownerCourseL, oppCourseL] { courseRow.addArrangedSubview(v) }

        // Column row
        for (l, w) in [(matchNumL, Col.matchNum), (yHoleL, Col.holeAndPar),
                       (yGrossL, Col.gross), (yNetL, Col.net),
                       (oHoleL, Col.holeAndPar), (oGrossL, Col.gross), (oNetL, Col.net),
                       (resultL, Col.result)] {
            l.widthAnchor.constraint(equalToConstant: w).isActive = true
            l.textColor = .secondaryLabel
        }
        statusL.textColor = .secondaryLabel
        statusL.setContentHuggingPriority(.defaultLow, for: .horizontal)

        colRow.axis    = .horizontal
        colRow.spacing = Col.spacing
        for v in [matchNumL, yHoleL, yGrossL, yNetL, oHoleL, oGrossL, oNetL, resultL, statusL] {
            colRow.addArrangedSubview(v)
        }

        outer.axis      = .vertical
        outer.spacing   = 2
        outer.translatesAutoresizingMaskIntoConstraints = false
        outer.addArrangedSubview(nameRow)
        outer.addArrangedSubview(courseRow)
        outer.addArrangedSubview(colRow)
        contentView.addSubview(outer)
        NSLayoutConstraint.activate([
            outer.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            outer.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            outer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            outer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(ownerName: String, oppName: String, ownerCourse: String, oppCourse: String) {
        ownerNameL.text   = ownerName.isEmpty ? "You" : ownerName
        oppNameL.text     = oppName.isEmpty   ? "Opp" : oppName
        ownerCourseL.text = ownerCourse
        oppCourseL.text   = oppCourse
        courseRow.isHidden = ownerCourse.isEmpty && oppCourse.isEmpty
        matchNumL.text = "#"
        yHoleL.text  = "Hole"; yGrossL.text = "Gr"; yNetL.text = "Net"
        oHoleL.text  = "Hole"; oGrossL.text = "Gr"; oNetL.text = "Net"
        resultL.text = "R"; statusL.text = "Status"
    }
}

// MARK: - ScorecardHoleCell

final class ScorecardHoleCell: UITableViewCell {

    private let stack    = UIStackView()
    private let matchL   = makeL(size: 12, weight: .regular,  align: .center)
    private let yHoleL   = makeL(size: 11, weight: .regular,  align: .center)
    private let yGrossL  = makeL(size: 12, weight: .semibold, align: .center)
    private let yNetL    = makeL(size: 11, weight: .regular,  align: .center)
    private let oHoleL   = makeL(size: 11, weight: .regular,  align: .center)
    private let oGrossL  = makeL(size: 12, weight: .semibold, align: .center)
    private let oNetL    = makeL(size: 11, weight: .regular,  align: .center)
    private let resultL  = makeL(size: 12, weight: .semibold, align: .center)
    private let statusL  = makeL(size: 11, weight: .regular,  align: .left)

    // Waiting overlay (replaces score labels when one player hasn't scored)
    private let waitingL = makeL(size: 11, weight: .regular, align: .center)
    private let waitingStack = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        // Widths
        matchL.widthAnchor.constraint(equalToConstant: Col.matchNum).isActive = true
        yHoleL.widthAnchor.constraint(equalToConstant: Col.holeAndPar).isActive = true
        yGrossL.widthAnchor.constraint(equalToConstant: Col.gross).isActive = true
        yNetL.widthAnchor.constraint(equalToConstant: Col.net).isActive = true
        oHoleL.widthAnchor.constraint(equalToConstant: Col.holeAndPar).isActive = true
        oGrossL.widthAnchor.constraint(equalToConstant: Col.gross).isActive = true
        oNetL.widthAnchor.constraint(equalToConstant: Col.net).isActive = true
        resultL.widthAnchor.constraint(equalToConstant: Col.result).isActive = true
        statusL.setContentHuggingPriority(.defaultLow, for: .horizontal)

        stack.axis    = .horizontal
        stack.spacing = Col.spacing
        stack.alignment = .center
        for v in [matchL, yHoleL, yGrossL, yNetL, oHoleL, oGrossL, oNetL, resultL, statusL] {
            stack.addArrangedSubview(v)
        }

        // Waiting overlay: matchL | waitingL | resultL
        let wMatchSpacer = UIView()
        wMatchSpacer.widthAnchor.constraint(equalToConstant: Col.matchNum).isActive = true
        let wResultSpacer = UIView()
        wResultSpacer.widthAnchor.constraint(equalToConstant: Col.result).isActive = true
        waitingL.textColor = .tertiaryLabel
        waitingL.setContentHuggingPriority(.defaultLow, for: .horizontal)
        waitingStack.axis    = .horizontal
        waitingStack.spacing = Col.spacing
        waitingStack.alignment = .center
        waitingStack.addArrangedSubview(wMatchSpacer)
        waitingStack.addArrangedSubview(waitingL)
        waitingStack.addArrangedSubview(wResultSpacer)

        for sv in [stack, waitingStack] {
            sv.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(sv)
            NSLayoutConstraint.activate([
                sv.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
                sv.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
                sv.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
                sv.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            ])
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(hd: ScorecardBuilder.HoleData, ownerName: String, oppName: String) {
        matchL.text = "\(hd.matchPos)"
        matchL.textColor = .tertiaryLabel

        if let waiting = hd.waitingForName {
            // One player hasn't scored — show waiting overlay
            stack.isHidden        = true
            waitingStack.isHidden = false
            // Copy matchL into the wMatchSpacer area via the real matchL... actually matchL is
            // in `stack`, so just show matchNum inline in waitingL prefix.
            waitingL.text = "Waiting for \(waiting)"
        } else {
            stack.isHidden        = false
            waitingStack.isHidden = true

            yHoleL.text  = holeParText(hole: hd.yourHole, par: hd.yourPar)
            oHoleL.text  = holeParText(hole: hd.oppHole,  par: hd.oppPar)
            yHoleL.textColor  = .secondaryLabel
            oHoleL.textColor  = .secondaryLabel

            if let g = hd.yourGross {
                let dots = String(repeating: "•", count: hd.yourStrokes)
                yGrossL.text = "\(g)\(dots)"
                yNetL.text   = "\(hd.yourNet ?? g)"
                yGrossL.textColor = hd.holeResult == 1 ? .systemGreen : .label
                yNetL.textColor   = .secondaryLabel
            } else {
                yGrossL.text = "—"; yNetL.text = ""
                yGrossL.textColor = .tertiaryLabel; yNetL.textColor = .tertiaryLabel
            }

            if let g = hd.oppGross {
                let dots = String(repeating: "•", count: hd.oppStrokes)
                oGrossL.text = "\(g)\(dots)"
                oNetL.text   = "\(hd.oppNet ?? g)"
                oGrossL.textColor = hd.holeResult == -1 ? .systemRed : .label
                oNetL.textColor   = .secondaryLabel
            } else {
                oGrossL.text = "—"; oNetL.text = ""
                oGrossL.textColor = .tertiaryLabel; oNetL.textColor = .tertiaryLabel
            }

            if hd.bothScored {
                switch hd.holeResult {
                case 1:
                    resultL.text = "W"; resultL.textColor = .systemGreen
                case -1:
                    resultL.text = "L"; resultL.textColor = .systemRed
                default:
                    resultL.text = "H"; resultL.textColor = .secondaryLabel
                }
            } else {
                resultL.text = ""; resultL.textColor = .tertiaryLabel
            }

            if let rn = hd.runningNet {
                if rn > 0      { statusL.text = "\(rn) up"; statusL.textColor = .systemGreen }
                else if rn < 0 { statusL.text = "\(abs(rn)) dn"; statusL.textColor = .systemRed }
                else           { statusL.text = "AS";  statusL.textColor = .secondaryLabel }
            } else {
                statusL.text = ""; statusL.textColor = .tertiaryLabel
            }
        }
    }

    private func holeParText(hole: Int, par: Int?) -> String {
        if let p = par { return "H\(hole) P\(p)" }
        return "H\(hole)"
    }
}

// MARK: - ScorecardPressCell

final class ScorecardPressCell: UITableViewCell {
    private let label = makeL(size: 10, weight: .semibold, align: .center)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle   = .none
        backgroundColor  = .systemBackground
        label.textColor  = .systemOrange
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            label.topAnchor.constraint(equalTo: contentView.topAnchor),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(pressNumber: Int) {
        label.text = "── P\(pressNumber) starts ──────────────────"
    }
}

// MARK: - ScorecardSubtotalCell

final class ScorecardSubtotalCell: UITableViewCell {
    private let stack    = UIStackView()
    private let nineL    = makeL(size: 11, weight: .semibold, align: .left)
    private let yGrossL  = makeL(size: 12, weight: .semibold, align: .center)
    private let oppGrossL = makeL(size: 12, weight: .semibold, align: .center)
    private let resultL  = makeL(size: 11, weight: .regular, align: .left)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle  = .none
        backgroundColor = .secondarySystemBackground

        // Widths: nine label spans matchNum + holeAndPar + spacings up to gross
        let nineWidth = Col.matchNum + Col.spacing + Col.holeAndPar + Col.spacing
        nineL.widthAnchor.constraint(equalToConstant: nineWidth).isActive = true
        yGrossL.widthAnchor.constraint(equalToConstant: Col.gross).isActive = true
        // spacer between gross columns
        let midSpacer = UIView()
        midSpacer.widthAnchor.constraint(equalToConstant: Col.net + Col.spacing + Col.holeAndPar + Col.spacing).isActive = true
        oppGrossL.widthAnchor.constraint(equalToConstant: Col.gross).isActive = true
        resultL.setContentHuggingPriority(.defaultLow, for: .horizontal)
        resultL.textColor = .secondaryLabel

        stack.axis      = .horizontal
        stack.spacing   = Col.spacing
        stack.alignment = .center
        for v in [nineL, yGrossL, midSpacer, oppGrossL, resultL] { stack.addArrangedSubview(v) }

        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(nine: Int, yourGross: Int, oppGross: Int, result: String) {
        nineL.text     = nine == 1 ? "Front 9" : nine == 2 ? "Back 9" : "18 Holes"
        yGrossL.text   = yourGross > 0 ? "\(yourGross)" : "—"
        oppGrossL.text = oppGross  > 0 ? "\(oppGross)"  : "—"
        resultL.text   = result
    }
}

// MARK: - Label factory

private func makeL(size: CGFloat, weight: UIFont.Weight, align: NSTextAlignment) -> UILabel {
    let l = UILabel()
    l.font = UIFont.monospacedDigitSystemFont(ofSize: size, weight: weight)
    l.textAlignment = align
    l.adjustsFontSizeToFitWidth = true
    l.minimumScaleFactor = 0.7
    l.lineBreakMode = .byTruncatingTail
    return l
}

// MARK: - ScorecardRenderer

enum ScorecardRenderer {

    static let renderWidth: CGFloat = 390

    static func render(config: ScorecardConfig) -> UIImage {
        let items = ScorecardBuilder.build(config: config)
        let df = DateFormatter()
        df.dateStyle = .medium; df.timeStyle = .none
        let dateStr = df.string(from: Date())

        let topH: CGFloat    = 54
        let botH: CGFloat    = 46
        let contentH         = items.reduce(0) { $0 + itemHeight($1) }
        let totalH           = topH + contentH + botH

        let container = UIView(frame: CGRect(x: 0, y: 0, width: renderWidth, height: totalH))
        container.backgroundColor = .systemBackground
        container.overrideUserInterfaceStyle = .light

        // Title header
        let topView = buildTopView(config: config, dateStr: dateStr)
        topView.frame = CGRect(x: 0, y: 0, width: renderWidth, height: topH)
        container.addSubview(topView)

        // Scorecard rows
        var y = topH
        for item in items {
            let h = itemHeight(item)
            let cell = buildCell(for: item, config: config)
            cell.frame = CGRect(x: 0, y: y, width: renderWidth, height: h)
            cell.layoutIfNeeded()
            container.addSubview(cell)
            y += h
        }

        // Money footer
        let botView = buildBotView(config: config)
        botView.frame = CGRect(x: 0, y: y, width: renderWidth, height: botH)
        container.addSubview(botView)

        container.layoutIfNeeded()

        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 2
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: renderWidth, height: totalH), format: fmt)
        return renderer.image { _ in
            UITraitCollection(userInterfaceStyle: .light).performAsCurrent {
                container.layer.render(in: UIGraphicsGetCurrentContext()!)
            }
        }
    }

    private static func itemHeight(_ item: ScorecardBuilder.Item) -> CGFloat {
        switch item {
        case .header:     return Col.headerHeight
        case .pressStart: return 20
        case .hole:       return 34
        case .subtotal:   return 38
        }
    }

    private static func buildCell(for item: ScorecardBuilder.Item, config: ScorecardConfig) -> UIView {
        switch item {
        case .header:
            let c = ScorecardHeaderCell(style: .default, reuseIdentifier: nil)
            c.configure(ownerName: config.ownerName, oppName: config.opponentName,
                        ownerCourse: config.ownerCourse, oppCourse: config.opponentCourse)
            return c
        case .pressStart(let n):
            let c = ScorecardPressCell(style: .default, reuseIdentifier: nil)
            c.configure(pressNumber: n)
            return c
        case .hole(let hd):
            let c = ScorecardHoleCell(style: .default, reuseIdentifier: nil)
            c.configure(hd: hd, ownerName: config.ownerName, oppName: config.opponentName)
            return c
        case .subtotal(let n, let yg, let og, let r):
            let c = ScorecardSubtotalCell(style: .default, reuseIdentifier: nil)
            c.configure(nine: n, yourGross: yg, oppGross: og, result: r)
            return c
        }
    }

    private static func buildTopView(config: ScorecardConfig, dateStr: String) -> UIView {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        let titleL = UILabel()
        titleL.font = .systemFont(ofSize: 14, weight: .semibold)
        titleL.textAlignment = .center
        titleL.textColor = .label
        titleL.text = config.title.isEmpty ? "Nassau Scorecard" : config.title
        let dateL = UILabel()
        dateL.font = .systemFont(ofSize: 11, weight: .regular)
        dateL.textAlignment = .center
        dateL.textColor = .secondaryLabel
        dateL.text = dateStr
        let stack = UIStackView(arrangedSubviews: [titleL, dateL])
        stack.axis = .vertical; stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: v.centerYAnchor),
        ])
        return v
    }

    private static func buildBotView(config: ScorecardConfig) -> UIView {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        let moneyL = UILabel()
        moneyL.font = .systemFont(ofSize: 13, weight: .semibold)
        moneyL.textAlignment = .center
        moneyL.textColor = .label
        moneyL.text = computeNetMoney(config: config)
        let brandL = UILabel()
        brandL.font = .systemFont(ofSize: 10, weight: .regular)
        brandL.textAlignment = .center
        brandL.textColor = .tertiaryLabel
        brandL.text = "WolfMore Golf"
        let stack = UIStackView(arrangedSubviews: [moneyL, brandL])
        stack.axis = .vertical; stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: v.centerYAnchor),
        ])
        return v
    }

    static func computeNetMoney(config: ScorecardConfig) -> String {
        let pairs      = config.pairs
        let frontCount = min(9, pairs.count)
        let frontPairs = Array(pairs.prefix(frontCount))
        let backPairs  = pairs.count > 9 ? Array(pairs.suffix(from: 9)) : []
        let frontStatus   = NassauPressDetector.runningStatus(from: frontPairs)
        let backStatus    = NassauPressDetector.runningStatus(from: backPairs)
        let overallStatus = NassauPressDetector.runningStatus(from: pairs)
        let isFrontComplete = frontPairs.filter { $0.hostScore != nil && $0.opponentScore != nil }.count == frontCount
        let isBackComplete  = backPairs.isEmpty || backPairs.filter { $0.hostScore != nil && $0.opponentScore != nil }.count == backPairs.count
        let isFullComplete  = isFrontComplete && isBackComplete
        let stake = config.stake
        var total = NassauPressDetector.segmentMoney(status: frontStatus,   complete: isFrontComplete, stake: stake)
                  + NassauPressDetector.segmentMoney(status: backStatus,    complete: isBackComplete,  stake: stake)
                  + NassauPressDetector.segmentMoney(status: overallStatus, complete: isFullComplete,  stake: stake)
        if config.pressMode == .auto {
            let detect: (([PairedHole], Int, Int) -> [NassauPressDetector.Press]) = config.isV2
                ? { NassauPressDetector.detectV2(pairs: $0,  holeOffset: $1, segmentEndPos: $2, trigger: config.trigger, stake: config.stake) }
                : { NassauPressDetector.detectLegacy(pairs: $0, holeOffset: $1, segmentEndPos: $2, trigger: config.trigger, stake: config.stake) }
            let allPresses = detect(frontPairs, 0, frontCount) + detect(backPairs, 9, pairs.count)
            for p in allPresses {
                let complete = p.endPos <= 9 ? isFrontComplete : isBackComplete
                total += NassauPressDetector.segmentMoney(status: p.runningStatus, complete: complete, stake: p.stake)
            }
        }
        let amt = total == floor(total) ? "$\(Int(abs(total)))" : String(format: "$%.2f", abs(total))
        if total > 0      { return "\(config.ownerName) +\(amt)" }
        else if total < 0 { return "\(config.opponentName) +\(amt)" }
        else              { return "Even" }
    }
}
