import UIKit

struct PairedHole {
    let hcRank: Int
    let hostPhysicalHole: Int    // 1-based for display
    let hostScore: Int?          // gross
    let hostNetScore: Int?       // gross minus strokes
    let hostStrokes: Int         // HC strokes received on this hole
    let opponentPhysicalHole: Int
    let opponentScore: Int?      // gross
    let opponentNetScore: Int?   // gross minus strokes
    let opponentStrokes: Int
    let netResult: Int           // positive = host winning (net)
}

final class NassauScorecardViewController: UIViewController {

    var pairedHoles:    [PairedHole] = []
    var segmentTitle:   String = ""
    var ownerName:      String = ""
    var opponentName:   String = ""
    var ownerCourse:    String = ""
    var opponentCourse: String = ""
    /// Set by the presenting VC to provide fresh holes on refresh.
    var refreshProvider: (() async -> [PairedHole])?

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var refreshTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = segmentTitle
        view.backgroundColor = .systemBackground

        if refreshProvider != nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "arrow.clockwise"),
                style: .plain,
                target: self,
                action: #selector(refreshTapped)
            )
        }

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(PairedHoleCell.self, forCellReuseIdentifier: PairedHoleCell.reuseID)
        tableView.rowHeight           = UITableView.automaticDimension
        tableView.estimatedRowHeight  = 44
        tableView.tableHeaderView     = makeLegendView()
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard refreshProvider != nil else { return }
        refreshTapped()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.refreshTapped()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    @objc private func refreshTapped() {
        guard let provider = refreshProvider else { return }
        Task {
            let holes = await provider()
            await MainActor.run {
                self.pairedHoles = holes
                self.tableView.reloadData()
            }
        }
    }

    private func makeLegendView() -> UIView {
        let label = UILabel()
        label.text          = "Scores shown as Gross(Net)"
        label.font          = .systemFont(ofSize: 12, weight: .regular)
        label.textColor     = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 32))
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        return container
    }
}

// MARK: - UITableViewDataSource

extension NassauScorecardViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        pairedHoles.count + 1   // row 0 = column header
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PairedHoleCell.reuseID, for: indexPath) as! PairedHoleCell
        if indexPath.row == 0 {
            cell.configureAsHeader(ownerName: ownerName, opponentName: opponentName,
                                   ownerCourse: ownerCourse, opponentCourse: opponentCourse)
        } else {
            cell.configure(with: pairedHoles[indexPath.row - 1], ownerName: ownerName, opponentName: opponentName)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension NassauScorecardViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool { false }
}

// MARK: - PairedHoleCell

// Column widths shared by header row and data rows (guarantees alignment)
private enum HoleCellCol {
    static let hc:   CGFloat = 24
    static let hole: CGFloat = 38
    static let scr:  CGFloat = 32
    static let gap:  CGFloat = 6
}

final class PairedHoleCell: UITableViewCell {
    static let reuseID = "PairedHoleCell"

    // Name row — shown only in header mode
    private let nameRow        = UIStackView()
    private let hcSpacer       = UIView()
    private let ownerNameLbl   = UILabel()
    private let oppNameLbl     = UILabel()
    private let nameEndSpacer  = UIView()

    // Course row — shown in header mode when courses are provided
    private let courseRow         = UIStackView()
    private let hcCourseSpacer    = UIView()
    private let ownerCourseLbl    = UILabel()
    private let oppCourseLbl      = UILabel()
    private let courseEndSpacer   = UIView()

    // Column row — always visible
    private let colRow      = UIStackView()
    private let hcLbl       = UILabel()
    private let ownerHoleLbl = UILabel()
    private let ownerScrLbl  = UILabel()
    private let oppHoleLbl   = UILabel()
    private let oppScrLbl    = UILabel()
    private let resultLbl    = UILabel()

    private let outerStack = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        // -- Name row --
        hcSpacer.widthAnchor.constraint(equalToConstant: HoleCellCol.hc).isActive = true
        // Each player name spans their two paired columns + the gap between them
        let nameColWidth = HoleCellCol.hole + HoleCellCol.gap + HoleCellCol.scr
        configLabel(ownerNameLbl, size: 11, weight: .semibold, align: .center)
        configLabel(oppNameLbl,   size: 11, weight: .semibold, align: .center)
        ownerNameLbl.widthAnchor.constraint(equalToConstant: nameColWidth).isActive = true
        oppNameLbl.widthAnchor.constraint(equalToConstant: nameColWidth).isActive = true
        nameEndSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        nameRow.axis    = .horizontal
        nameRow.spacing = HoleCellCol.gap
        nameRow.isHidden = true
        for v in [hcSpacer, ownerNameLbl, oppNameLbl, nameEndSpacer] { nameRow.addArrangedSubview(v) }

        // -- Course row --
        hcCourseSpacer.widthAnchor.constraint(equalToConstant: HoleCellCol.hc).isActive = true
        configLabel(ownerCourseLbl, size: 10, weight: .regular, align: .center)
        configLabel(oppCourseLbl,   size: 10, weight: .regular, align: .center)
        ownerCourseLbl.textColor = .secondaryLabel
        oppCourseLbl.textColor   = .secondaryLabel
        ownerCourseLbl.widthAnchor.constraint(equalToConstant: HoleCellCol.hole + HoleCellCol.gap + HoleCellCol.scr).isActive = true
        oppCourseLbl.widthAnchor.constraint(equalToConstant: HoleCellCol.hole + HoleCellCol.gap + HoleCellCol.scr).isActive = true
        courseEndSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        courseRow.axis    = .horizontal
        courseRow.spacing = HoleCellCol.gap
        courseRow.isHidden = true
        for v in [hcCourseSpacer, ownerCourseLbl, oppCourseLbl, courseEndSpacer] { courseRow.addArrangedSubview(v) }

        // -- Column row --
        configLabel(hcLbl,        size: 12, weight: .regular,  align: .center)
        configLabel(ownerHoleLbl, size: 13, weight: .regular,  align: .center)
        configLabel(ownerScrLbl,  size: 13, weight: .semibold, align: .center)
        configLabel(oppHoleLbl,   size: 13, weight: .regular,  align: .center)
        configLabel(oppScrLbl,    size: 13, weight: .semibold, align: .center)
        configLabel(resultLbl,    size: 13, weight: .regular,  align: .left)
        hcLbl.widthAnchor.constraint(equalToConstant: HoleCellCol.hc).isActive = true
        ownerHoleLbl.widthAnchor.constraint(equalToConstant: HoleCellCol.hole).isActive = true
        ownerScrLbl.widthAnchor.constraint(equalToConstant: HoleCellCol.scr).isActive = true
        oppHoleLbl.widthAnchor.constraint(equalToConstant: HoleCellCol.hole).isActive = true
        oppScrLbl.widthAnchor.constraint(equalToConstant: HoleCellCol.scr).isActive = true
        resultLbl.setContentHuggingPriority(.defaultLow, for: .horizontal)

        colRow.axis    = .horizontal
        colRow.spacing = HoleCellCol.gap
        for v in [hcLbl, ownerHoleLbl, ownerScrLbl, oppHoleLbl, oppScrLbl, resultLbl] { colRow.addArrangedSubview(v) }

        // -- Outer vertical stack --
        outerStack.axis    = .vertical
        outerStack.spacing = 2
        outerStack.translatesAutoresizingMaskIntoConstraints = false
        outerStack.addArrangedSubview(nameRow)
        outerStack.addArrangedSubview(courseRow)
        outerStack.addArrangedSubview(colRow)
        contentView.addSubview(outerStack)
        NSLayoutConstraint.activate([
            outerStack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            outerStack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            outerStack.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            outerStack.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    private func configLabel(_ l: UILabel, size: CGFloat, weight: UIFont.Weight, align: NSTextAlignment) {
        l.font = .systemFont(ofSize: size, weight: weight)
        l.textAlignment = align
        l.lineBreakMode = .byTruncatingTail
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.75
    }

    func configureAsHeader(ownerName: String, opponentName: String,
                           ownerCourse: String = "", opponentCourse: String = "") {
        nameRow.isHidden = false
        ownerNameLbl.text  = ownerName
        oppNameLbl.text    = opponentName
        ownerNameLbl.textColor = .label
        oppNameLbl.textColor   = .label

        let hasCourses = !ownerCourse.isEmpty || !opponentCourse.isEmpty
        courseRow.isHidden   = !hasCourses
        ownerCourseLbl.text  = ownerCourse.isEmpty    ? "" : ownerCourse
        oppCourseLbl.text    = opponentCourse.isEmpty ? "" : opponentCourse

        hcLbl.text        = "#"
        ownerHoleLbl.text = "Hole"
        ownerScrLbl.text  = "Scr"
        oppHoleLbl.text   = "Hole"
        oppScrLbl.text    = "Scr"
        resultLbl.text    = "Result"

        for l in [hcLbl, ownerHoleLbl, ownerScrLbl, oppHoleLbl, oppScrLbl, resultLbl] {
            l.textColor = .secondaryLabel
        }
    }

    func configure(with hole: PairedHole, ownerName: String, opponentName: String) {
        nameRow.isHidden   = true
        courseRow.isHidden = true

        hcLbl.text             = "\(hole.hcRank)"
        hcLbl.textColor        = .tertiaryLabel
        ownerHoleLbl.text      = hole.hostScore != nil ? "H\(hole.hostPhysicalHole)" : "—"
        ownerHoleLbl.textColor = .secondaryLabel
        oppHoleLbl.text        = hole.opponentScore != nil ? "H\(hole.opponentPhysicalHole)" : "—"
        oppHoleLbl.textColor   = .secondaryLabel

        ownerScrLbl.text = scoreText(gross: hole.hostScore,     net: hole.hostNetScore,     strokes: hole.hostStrokes)
        oppScrLbl.text   = scoreText(gross: hole.opponentScore, net: hole.opponentNetScore, strokes: hole.opponentStrokes)

        // Winner comparison on net scores; fall back to gross if net unavailable
        let ownerCompare = hole.hostNetScore     ?? hole.hostScore
        let oppCompare   = hole.opponentNetScore ?? hole.opponentScore

        if let h = ownerCompare, let o = oppCompare {
            if h < o {
                resultLbl.text        = ownerName
                resultLbl.textColor   = .systemGreen
                ownerScrLbl.textColor = .systemGreen
                oppScrLbl.textColor   = .label
            } else if h > o {
                resultLbl.text        = opponentName
                resultLbl.textColor   = .systemRed
                ownerScrLbl.textColor = .label
                oppScrLbl.textColor   = .systemRed
            } else {
                resultLbl.text        = "Halved"
                resultLbl.textColor   = .secondaryLabel
                ownerScrLbl.textColor = .label
                oppScrLbl.textColor   = .label
            }
        } else {
            resultLbl.text        = "—"
            resultLbl.textColor   = .tertiaryLabel
            ownerScrLbl.textColor = hole.hostScore     != nil ? .label : .tertiaryLabel
            oppScrLbl.textColor   = hole.opponentScore != nil ? .label : .tertiaryLabel
        }
    }

    private func scoreText(gross: Int?, net: Int?, strokes: Int) -> String {
        guard let g = gross else { return "—" }
        if strokes > 0, let n = net { return "\(g)(\(n))" }
        return "\(g)"
    }
}
