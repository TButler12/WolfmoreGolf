import UIKit

// MARK: - GameSummary

private struct GameSummary {
    let gameID: UUID
    let date: Date
    let courseID: String
    let playerCount: Int
    let userMoney: Int
}

// MARK: - Cell

private final class PastGameCell: UITableViewCell {
    private let courseLabel = UILabel()
    private let dateLabel   = UILabel()
    private let detailLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        courseLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        courseLabel.adjustsFontForContentSizeCategory = true

        dateLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        dateLabel.adjustsFontForContentSizeCategory = true
        dateLabel.textColor = .secondaryLabel

        detailLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        detailLabel.adjustsFontForContentSizeCategory = true
        detailLabel.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [courseLabel, dateLabel, detailLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        ])
    }

    func configure(with summary: GameSummary) {
        if let uid = UUID(uuidString: summary.courseID),
           let profile = CourseLibrary.shared.get(id: uid) {
            courseLabel.text = profile.name
        } else {
            courseLabel.text = "Unknown Course"
        }

        dateLabel.text = Self.relativeDate(summary.date)

        let players = "\(summary.playerCount) player\(summary.playerCount == 1 ? "" : "s")"
        if summary.userMoney > 0 {
            detailLabel.text      = "\(players) · You: $\(summary.userMoney)"
            detailLabel.textColor = .systemGreen
        } else if summary.userMoney < 0 {
            detailLabel.text      = "\(players) · You: $\(abs(summary.userMoney))"
            detailLabel.textColor = .systemRed
        } else {
            detailLabel.text      = players
            detailLabel.textColor = .secondaryLabel
        }
    }

    private static func relativeDate(_ date: Date) -> String {
        let cal = Calendar.current
        let now = Date()

        if cal.isDateInToday(date)     { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }

        let startOfDate = cal.startOfDay(for: date)
        let startOfNow  = cal.startOfDay(for: now)
        let daysAgo = cal.dateComponents([.day], from: startOfDate, to: startOfNow).day ?? 0

        if daysAgo < 7 {
            return fmt("EEEE").string(from: date)           // "Saturday"
        }
        if cal.component(.year, from: date) != cal.component(.year, from: now) {
            return fmt("MMM d, yyyy").string(from: date)    // "May 3, 2024"
        }
        return fmt("EEE MMM d").string(from: date)          // "Sat May 3"
    }

    private static func fmt(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.dateFormat = format
        return f
    }
}

// MARK: - PastGamesViewController

final class PastGamesViewController: UIViewController {

    private let tableView  = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private var games: [GameSummary] = []

    private static let cellID = "PastGameCell"

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Past Games"
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(close)
        )

        setupTableView()
        setupEmptyLabel()
        loadData()
    }

    @objc private func close() {
        dismiss(animated: true)
    }

    // MARK: - Setup

    private func setupTableView() {
        tableView.register(PastGameCell.self, forCellReuseIdentifier: Self.cellID)
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.rowHeight  = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupEmptyLabel() {
        emptyLabel.text = "No past games yet.\n\nWhen you tap End Round and save, your rounds will appear here."
        emptyLabel.font = UIFont.preferredFont(forTextStyle: .body)
        emptyLabel.textColor   = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
        ])
    }

    // MARK: - Data

    private func loadData() {
        let rows    = RoundStore.shared.visibleRows(isPro: false)
        let grouped = Dictionary(grouping: rows, by: \.gameID)
        let userName = ProfileStore.name?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        games = grouped.compactMap { _, playerRows in
            guard let first = playerRows.first else { return nil }
            let userRow = userName.isEmpty ? nil : playerRows.first {
                $0.playerName.trimmingCharacters(in: .whitespacesAndNewlines)
                    .caseInsensitiveCompare(userName) == .orderedSame
            }
            return GameSummary(
                gameID:      first.gameID,
                date:        first.date,
                courseID:    first.courseID,
                playerCount: playerRows.count,
                userMoney:   userRow?.totalMoney ?? 0
            )
        }
        .sorted { $0.date > $1.date }

        emptyLabel.isHidden = !games.isEmpty
        tableView.isHidden  = games.isEmpty
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource / Delegate

extension PastGamesViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        games.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: Self.cellID, for: indexPath) as! PastGameCell
        cell.configure(with: games[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let summary = games[indexPath.row]
        let rows = RoundStore.shared.visibleRows(isPro: false)
            .filter { $0.gameID == summary.gameID }
        let vc = PastGameDetailViewController(rows: rows, courseID: summary.courseID)
        navigationController?.pushViewController(vc, animated: true)
    }
}
