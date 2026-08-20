import UIKit

final class GroupDetailViewController: UIViewController {

    // MARK: - State
    private let matchId: String
    private let playerNames: [String]
    private let rows: [TournamentHoleScoreRow]

    // Unique holes sorted ascending; hole → [playerName → row]
    private var holeNumbers: [Int] = []
    private var dataByHole:  [Int: [String: TournamentHoleScoreRow]] = [:]

    // MARK: - UI
    private let tableView = UITableView(frame: .zero, style: .grouped)

    // MARK: - Init
    init(matchId: String, playerNames: [String], rows: [TournamentHoleScoreRow]) {
        self.matchId     = matchId
        self.playerNames = playerNames
        self.rows        = rows
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        let nameSnippet = playerNames.prefix(2).joined(separator: ", ")
        title = playerNames.count > 2 ? "\(nameSnippet)…" : nameSnippet
        view.backgroundColor = .systemBackground
        prepareData()
        setupTable()
    }

    // MARK: - Data
    private func prepareData() {
        var byHole: [Int: [String: TournamentHoleScoreRow]] = [:]
        for r in rows {
            byHole[r.hole, default: [:]][r.playerName] = r
        }
        dataByHole  = byHole
        holeNumbers = byHole.keys.sorted()
    }

    // MARK: - Layout
    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(GroupHoleCell.self, forCellReuseIdentifier: "holeCell")
        tableView.dataSource       = self
        tableView.rowHeight        = UITableView.automaticDimension
        tableView.estimatedRowHeight = 64
        tableView.separatorInset   = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
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

extension GroupDetailViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        holeNumbers.count
    }

    func tableView(_ tableView: UITableView,
                   titleForHeaderInSection section: Int) -> String? {
        playerNames.joined(separator: " · ")
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "holeCell",
                                                 for: indexPath) as! GroupHoleCell
        let hole     = holeNumbers[indexPath.row]
        let holeData = dataByHole[hole] ?? [:]
        cell.configure(hole: hole, playerNames: playerNames, holeData: holeData)
        return cell
    }
}

// MARK: - GroupHoleCell

private final class GroupHoleCell: UITableViewCell {

    private let holeLabel   = UILabel()
    private let detailLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        holeLabel.font          = UIFont.systemFont(ofSize: 14, weight: .semibold)
        holeLabel.textAlignment = .center
        holeLabel.textColor     = .secondaryLabel
        holeLabel.setContentHuggingPriority(.required, for: .horizontal)
        holeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        holeLabel.widthAnchor.constraint(equalToConstant: 40).isActive = true

        detailLabel.font          = UIFont.systemFont(ofSize: 14)
        detailLabel.numberOfLines = 0
        detailLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        let stack = UIStackView(arrangedSubviews: [holeLabel, detailLabel])
        stack.axis      = .horizontal
        stack.spacing   = 10
        stack.alignment = .top
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(hole: Int, playerNames: [String], holeData: [String: TournamentHoleScoreRow]) {
        holeLabel.text = "H\(hole)"

        let parts: [String] = playerNames.compactMap { name in
            guard let r = holeData[name] else { return nil }
            let m = r.holeMoney ?? 0.0
            let valueStr: String
            if r.gameType == "stableford" {
                let pts = Int(m.rounded())
                valueStr = "\(pts) pt\(pts == 1 ? "" : "s")"
            } else {
                let sign = m >= 0 ? "+" : ""
                if m == Double(Int(m)) {
                    valueStr = "\(sign)$\(Int(abs(m)))"
                } else {
                    valueStr = "\(sign)$\(String(format: "%.2f", abs(m)))"
                }
            }
            return "\(name): \(r.grossScore)  \(valueStr)"
        }
        detailLabel.text = parts.joined(separator: "\n")
    }
}
