import UIKit

// Organizer-facing roster editor: add/edit/delete players for a tournament.
// Presented from Live & Connected → Manage Tournament → Edit Roster.
final class TournamentRosterViewController: UITableViewController {

    private let tournamentCode: String
    private let tournamentName: String
    private var entries: [TournamentRosterEntry] = []
    private var isLoading = false

    init(code: String, name: String) {
        self.tournamentCode = code
        self.tournamentName = name
        super.init(style: .insetGrouped)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Roster"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add, target: self, action: #selector(addTapped))
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadRoster()
    }

    // MARK: - Load

    private func loadRoster() {
        isLoading = true
        tableView.reloadData()
        Task {
            do {
                let fetched = try await SupabaseService.shared.fetchRoster(code: tournamentCode)
                await MainActor.run {
                    self.entries = fetched.sorted { $0.canonicalName < $1.canonicalName }
                    self.isLoading = false
                    self.tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.tableView.reloadData()
                    self.showError("Could not load roster: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        isLoading ? 1 : max(entries.count, 1)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        isLoading ? nil : "\(entries.count) player\(entries.count == 1 ? "" : "s")"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if isLoading {
            var c = cell.defaultContentConfiguration()
            c.text = "Loading…"
            c.textProperties.color = .secondaryLabel
            cell.contentConfiguration = c
            cell.selectionStyle = .none
            return cell
        }
        if entries.isEmpty {
            var c = cell.defaultContentConfiguration()
            c.text = "No players yet — tap ＋ to add"
            c.textProperties.color = .secondaryLabel
            cell.contentConfiguration = c
            cell.selectionStyle = .none
            return cell
        }
        let entry = entries[indexPath.row]
        var c = cell.defaultContentConfiguration()
        c.text = entry.canonicalName
        c.secondaryText = entry.handicap == 0 ? "HC: scratch" : "HC: \(entry.handicap)"
        if entry.addedBy == "scorer" {
            c.secondaryText = (c.secondaryText ?? "") + "  •  walk-on"
        }
        cell.contentConfiguration = c
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        !isLoading && !entries.isEmpty
    }

    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let entry = entries[indexPath.row]
        Task {
            do {
                try await SupabaseService.shared.deleteRosterEntry(id: entry.id)
                await MainActor.run {
                    self.entries.remove(at: indexPath.row)
                    self.tableView.reloadData()
                }
            } catch {
                await MainActor.run { self.showError("Delete failed: \(error.localizedDescription)") }
            }
        }
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !isLoading, !entries.isEmpty else { return }
        presentEditor(entry: entries[indexPath.row])
    }

    // MARK: - Add / Edit

    @objc private func addTapped() { presentEditor(entry: nil) }

    private func presentEditor(entry: TournamentRosterEntry?) {
        let isNew = entry == nil
        let ac = UIAlertController(
            title: isNew ? "Add Player" : "Edit Player",
            message: nil,
            preferredStyle: .alert)

        ac.addTextField { tf in
            tf.placeholder = "Name (e.g. McTommy)"
            tf.text = entry?.canonicalName
            tf.autocapitalizationType = .words
            tf.autocorrectionType = .no
            tf.returnKeyType = .next
        }
        ac.addTextField { tf in
            tf.placeholder = "Handicap (0 = scratch)"
            tf.text = entry.map { "\($0.handicap)" }
            tf.keyboardType = .numberPad
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: isNew ? "Add" : "Save", style: .default) { [weak self, weak ac] _ in
            guard let self else { return }
            let name = (ac?.textFields?[0].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let hcStr = (ac?.textFields?[1].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return }
            let hc = Int(hcStr) ?? 0
            let updated = TournamentRosterEntry(
                id: entry?.id ?? UUID(),
                tournamentCode: self.tournamentCode,
                canonicalName: name,
                handicap: hc,
                addedBy: entry?.addedBy ?? "organizer",
                groupCode: entry?.groupCode)
            self.saveEntry(updated)
        })

        present(ac, animated: true) {
            ac.textFields?.first?.selectAll(nil)
        }
    }

    private func saveEntry(_ entry: TournamentRosterEntry) {
        Task {
            do {
                try await SupabaseService.shared.upsertRosterEntry(entry)
                await MainActor.run { self.loadRoster() }
            } catch {
                await MainActor.run { self.showError("Save failed: \(error.localizedDescription)") }
            }
        }
    }

    // MARK: - Error

    private func showError(_ msg: String) {
        let ac = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}
