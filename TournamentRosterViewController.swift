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
        tableView.tableHeaderView = makeImportHeader()
    }

    // MARK: - Import header

    private func makeImportHeader() -> UIView {
        let container = UIView()
        let green = UIColor(red: 0.10, green: 0.33, blue: 0.18, alpha: 1.0)

        func makeButton(title: String, icon: String, action: Selector) -> UIButton {
            var cfg = UIButton.Configuration.tinted()
            cfg.title = title
            cfg.image = UIImage(systemName: icon)
            cfg.imagePadding = 6
            cfg.baseForegroundColor = green
            cfg.baseBackgroundColor = green
            let btn = UIButton(configuration: cfg)
            btn.addTarget(self, action: action, for: .touchUpInside)
            return btn
        }

        let pastBtn  = makeButton(title: "Copy from Previous Tournament",
                                   icon: "doc.on.doc",
                                   action: #selector(copyFromPastTapped))
        let savedBtn = makeButton(title: "Choose Saved Players",
                                   icon: "person.2",
                                   action: #selector(chooseFromSavedTapped))

        let stack = UIStackView(arrangedSubviews: [pastBtn, savedBtn])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
        ])

        container.frame = CGRect(x: 0, y: 0, width: 0, height: 150)
        return container
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let header = tableView.tableHeaderView else { return }
        let newSize = header.systemLayoutSizeFitting(
            CGSize(width: tableView.bounds.width, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel)
        if abs(header.frame.height - newSize.height) > 1 {
            header.frame.size.height = newSize.height
            tableView.tableHeaderView = header
        }
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

    // MARK: - Copy from previous tournament

    @objc private func copyFromPastTapped() {
        let history = TournamentHistoryStore.shared.all()
            .filter { $0.isOrganizer && $0.code != tournamentCode }

        guard !history.isEmpty else {
            let ac = UIAlertController(
                title: "No Previous Tournaments",
                message: "You haven't organized any other tournaments yet.",
                preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            return
        }

        let sheet = UIAlertController(
            title: "Copy from Previous Tournament", message: nil, preferredStyle: .actionSheet)
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        for entry in history {
            let label = "\(entry.name)  ·  \(fmt.string(from: entry.lastJoined))"
            sheet.addAction(UIAlertAction(title: label, style: .default) { [weak self] _ in
                self?.importFromPastTournament(code: entry.code, name: entry.name)
            })
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presentActionSheet(sheet)
    }

    private func importFromPastTournament(code: String, name: String) {
        let spinner = UIAlertController(title: nil, message: "Importing from \(name)…", preferredStyle: .alert)
        present(spinner, animated: true)
        Task {
            do {
                let fetched = try await SupabaseService.shared.fetchRoster(code: code)
                let existingLower = Set(self.entries.map { $0.canonicalName.lowercased() })
                var added = 0
                for src in fetched {
                    guard !existingLower.contains(src.canonicalName.lowercased()) else { continue }
                    let entry = TournamentRosterEntry(
                        id: UUID(),
                        tournamentCode: self.tournamentCode,
                        canonicalName: src.canonicalName,
                        handicap: src.handicap,
                        addedBy: "organizer",
                        groupCode: nil)
                    try await SupabaseService.shared.upsertRosterEntry(entry)
                    added += 1
                }
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        let msg = added == 0
                            ? "All players from \(name) are already on this roster."
                            : "\(added) player\(added == 1 ? "" : "s") added."
                        let ac = UIAlertController(title: "Done", message: msg, preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ac, animated: true)
                        self.loadRoster()
                    }
                }
            } catch {
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.showError("Import failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    // MARK: - Choose saved players

    @objc private func chooseFromSavedTapped() {
        let existingLower = Set(entries.map { $0.canonicalName.lowercased() })
        let picker = SavedPlayersPickerViewController(existingNames: existingLower)
        picker.onAdd = { [weak self] players in
            self?.bulkAdd(players)
        }
        navigationController?.pushViewController(picker, animated: true)
    }

    private func bulkAdd(_ players: [(name: String, handicap: Int)]) {
        guard !players.isEmpty else { return }
        let spinner = UIAlertController(
            title: nil,
            message: "Adding \(players.count) player\(players.count == 1 ? "" : "s")…",
            preferredStyle: .alert)
        present(spinner, animated: true)
        let existingLower = Set(entries.map { $0.canonicalName.lowercased() })
        Task {
            do {
                for p in players {
                    guard !existingLower.contains(p.name.lowercased()) else { continue }
                    let entry = TournamentRosterEntry(
                        id: UUID(),
                        tournamentCode: self.tournamentCode,
                        canonicalName: p.name,
                        handicap: p.handicap,
                        addedBy: "organizer",
                        groupCode: nil)
                    try await SupabaseService.shared.upsertRosterEntry(entry)
                }
                await MainActor.run {
                    spinner.dismiss(animated: false) { self.loadRoster() }
                }
            } catch {
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.showError("Add failed: \(error.localizedDescription)")
                    }
                }
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
