import UIKit

struct PairedHole {
    let hcRank: Int
    let hostPhysicalHole: Int    // 1-based for display
    let hostScore: Int?
    let opponentPhysicalHole: Int
    let opponentScore: Int?
    let netResult: Int           // positive = host winning
}

final class NassauScorecardViewController: UIViewController {

    var pairedHoles:  [PairedHole] = []
    var segmentTitle: String = ""
    var ownerName:    String = ""
    var opponentName: String = ""

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = segmentTitle
        view.backgroundColor = .systemBackground
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(PairedHoleCell.self, forCellReuseIdentifier: PairedHoleCell.reuseID)
        tableView.rowHeight           = UITableView.automaticDimension
        tableView.estimatedRowHeight  = 44
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

// MARK: - UITableViewDataSource

extension NassauScorecardViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        pairedHoles.count + 1   // row 0 = column header
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "\(ownerName) vs \(opponentName)"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PairedHoleCell.reuseID, for: indexPath) as! PairedHoleCell
        if indexPath.row == 0 {
            cell.configureAsHeader(ownerName: ownerName, opponentName: opponentName)
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
    private let nameRow       = UIStackView()
    private let hcSpacer      = UIView()
    private let ownerNameLbl  = UILabel()
    private let oppNameLbl    = UILabel()
    private let nameEndSpacer = UIView()

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

    func configureAsHeader(ownerName: String, opponentName: String) {
        nameRow.isHidden = false
        ownerNameLbl.text  = ownerName
        oppNameLbl.text    = opponentName
        ownerNameLbl.textColor = .label
        oppNameLbl.textColor   = .label

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
        nameRow.isHidden = true

        hcLbl.text        = "\(hole.hcRank)"
        hcLbl.textColor   = .tertiaryLabel
        ownerHoleLbl.text  = hole.hostScore != nil ? "H\(hole.hostPhysicalHole)" : "—"
        ownerHoleLbl.textColor = .secondaryLabel
        ownerScrLbl.text   = hole.hostScore.map(String.init) ?? "—"
        oppHoleLbl.text    = hole.opponentScore != nil ? "H\(hole.opponentPhysicalHole)" : "—"
        oppHoleLbl.textColor = .secondaryLabel
        oppScrLbl.text     = hole.opponentScore.map(String.init) ?? "—"

        if let hs = hole.hostScore, let os = hole.opponentScore {
            if hs < os {
                resultLbl.text      = ownerName
                resultLbl.textColor = .systemGreen
                ownerScrLbl.textColor = .systemGreen
                oppScrLbl.textColor   = .label
            } else if hs > os {
                resultLbl.text      = opponentName
                resultLbl.textColor = .systemRed
                ownerScrLbl.textColor = .label
                oppScrLbl.textColor   = .systemRed
            } else {
                resultLbl.text      = "Halved"
                resultLbl.textColor = .secondaryLabel
                ownerScrLbl.textColor = .label
                oppScrLbl.textColor   = .label
            }
        } else {
            resultLbl.text      = "Waiting"
            resultLbl.textColor = .tertiaryLabel
            ownerScrLbl.textColor = hole.hostScore != nil ? .label : .tertiaryLabel
            oppScrLbl.textColor   = hole.opponentScore != nil ? .label : .tertiaryLabel
        }
    }
}
