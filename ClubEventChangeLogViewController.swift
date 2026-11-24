import UIKit

/// Read-only view of organizer change-log entries for a club event.
final class ClubEventChangeLogViewController: UITableViewController {

    private let tournamentId: UUID
    private var entries: [ClubEventChangeLogEntry] = []

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    init(tournamentId: UUID) {
        self.tournamentId = tournamentId
        super.init(style: .insetGrouped)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Change Log"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemGroupedBackground
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        load()
    }

    private func load() {
        Task {
            let fetched = (try? await SupabaseService.shared.fetchClubEventChangeLog(
                tournamentId: tournamentId)) ?? []
            await MainActor.run {
                self.entries = fetched
                self.tableView.reloadData()
            }
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        entries.isEmpty ? 1 : entries.count
    }

    override func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        guard !entries.isEmpty else {
            var cfg = cell.defaultContentConfiguration()
            cfg.text = "No changes recorded"
            cfg.textProperties.color = .secondaryLabel
            cell.contentConfiguration = cfg
            cell.selectionStyle = .none
            return cell
        }
        let e = entries[indexPath.row]
        var cfg = cell.defaultContentConfiguration()
        cfg.text = e.summary
        cfg.secondaryText = dateFormatter.string(from: e.changedAt)
        cfg.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = cfg
        cell.selectionStyle = .none
        return cell
    }
}
