import UIKit

/// Two-stage flow: (1) pick a past event, (2) preview + edit handicaps, then bulk-add.
/// Duplicates (by lowercase name match) are excluded from the preview.
final class ClubEventCopyRosterViewController: UITableViewController {

    static let teal = UIColor(red: 0.10, green: 0.42, blue: 0.42, alpha: 1.0)

    private let targetEvent:   ClubEventRecord
    private let existingNames: Set<String>           // lowercased
    private let pastEvents:    [ClubEventOrganizerEntry]

    private enum Stage {
        case pickEvent
        case reviewPlayers(sourceName: String, players: [EditablePlayer], skippedCount: Int)
    }

    private struct EditablePlayer {
        let name:     String
        var handicap: Double
    }

    private var stage:    Stage = .pickEvent
    private var isSaving: Bool  = false

    init(event: ClubEventRecord, currentRoster: [ClubEventPlayer]) {
        self.targetEvent   = event
        self.existingNames = Set(currentRoster.map { $0.playerName.trimmingCharacters(in: .whitespaces).lowercased() })
        self.pastEvents    = ClubEventOrganizerStore.shared.all.filter { $0.id != event.id }
        super.init(style: .insetGrouped)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Copy Roster"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.largeTitleDisplayMode = .never
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.keyboardDismissMode = .interactive
        tableView.estimatedRowHeight = 50
        updateNav()
    }

    private func updateNav() {
        switch stage {
        case .pickEvent:
            navigationItem.rightBarButtonItem = nil
        case .reviewPlayers(_, let players, _):
            let btn = UIBarButtonItem(
                title: players.isEmpty ? "Done" : "Add \(players.count)",
                style: .done, target: self, action: #selector(addTapped))
            btn.isEnabled = !players.isEmpty
            navigationItem.rightBarButtonItem = btn
        }
    }

    // MARK: - Table data source

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch stage {
        case .pickEvent:
            return pastEvents.isEmpty ? 1 : pastEvents.count
        case .reviewPlayers(_, let players, _):
            return max(players.count, 1)
        }
    }

    override func tableView(_ tv: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch stage {
        case .pickEvent:
            return "SELECT PAST EVENT"
        case .reviewPlayers(let name, _, _):
            return "FROM \"\(name.uppercased())\""
        }
    }

    override func tableView(_ tv: UITableView, titleForFooterInSection section: Int) -> String? {
        guard case .reviewPlayers(_, _, let skipped) = stage, skipped > 0 else { return nil }
        return "\(skipped) player\(skipped == 1 ? "" : "s") already on this roster \(skipped == 1 ? "was" : "were") skipped."
    }

    override func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch stage {
        case .pickEvent:
            return eventCell(row: indexPath.row)
        case .reviewPlayers(_, let players, _):
            return players.isEmpty ? emptyCell() : playerCell(row: indexPath.row, players: players)
        }
    }

    override func tableView(_ tv: UITableView, didSelectRowAt indexPath: IndexPath) {
        tv.deselectRow(at: indexPath, animated: true)
        guard case .pickEvent = stage, !pastEvents.isEmpty else { return }
        loadRoster(for: pastEvents[indexPath.row])
    }

    // MARK: - Event cell (stage 1)

    private func eventCell(row: Int) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.contentConfiguration = nil
        var cfg = cell.defaultContentConfiguration()
        if pastEvents.isEmpty {
            cfg.text = "No past events on this device"
            cfg.textProperties.color = .secondaryLabel
            cell.contentConfiguration = cfg
            cell.selectionStyle = .none
            cell.accessoryType  = .none
        } else {
            let e = pastEvents[row]
            cfg.text          = e.name
            cfg.secondaryText = e.courseName
            cell.contentConfiguration = cfg
            cell.selectionStyle = .default
            cell.accessoryType  = .disclosureIndicator
        }
        return cell
    }

    // MARK: - Empty cell (stage 2, all duplicates)

    private func emptyCell() -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.contentConfiguration = nil
        var cfg = cell.defaultContentConfiguration()
        cfg.text = "All players already on this roster"
        cfg.textProperties.color = .secondaryLabel
        cell.contentConfiguration = cfg
        cell.selectionStyle = .none
        cell.accessoryType  = .none
        return cell
    }

    // MARK: - Player cell (stage 2)

    private func playerCell(row: Int, players: [EditablePlayer]) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.contentConfiguration = nil
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.selectionStyle = .none
        cell.accessoryType  = .none

        let nameLabel = UILabel()
        nameLabel.text = players[row].name
        nameLabel.font = .preferredFont(forTextStyle: .body)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let hcField = UITextField()
        hcField.text          = fmtHC(players[row].handicap)
        hcField.font          = .monospacedDigitSystemFont(ofSize: 17, weight: .regular)
        hcField.textColor     = .secondaryLabel
        hcField.textAlignment = .right
        hcField.keyboardType  = .numbersAndPunctuation
        hcField.returnKeyType = .done
        hcField.tag           = row
        hcField.delegate      = self
        hcField.translatesAutoresizingMaskIntoConstraints = false
        hcField.setContentHuggingPriority(.required, for: .horizontal)

        cell.contentView.addSubview(nameLabel)
        cell.contentView.addSubview(hcField)
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            nameLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: hcField.leadingAnchor, constant: -8),
            hcField.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            hcField.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            hcField.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),
            cell.contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 48),
        ])
        return cell
    }

    // MARK: - Load roster

    private func loadRoster(for entry: ClubEventOrganizerEntry) {
        let spinner = UIAlertController(title: nil, message: "Loading roster…", preferredStyle: .alert)
        present(spinner, animated: true)
        Task {
            do {
                let roster = try await SupabaseService.shared.fetchClubEventRoster(tournamentId: entry.id)
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        let candidates = roster
                            .filter { !self.existingNames.contains($0.playerName.trimmingCharacters(in: .whitespaces).lowercased()) }
                            .map { EditablePlayer(name: $0.playerName, handicap: $0.handicap) }
                        let skipped = roster.count - candidates.count
                        self.stage = .reviewPlayers(sourceName: entry.name,
                                                    players: candidates,
                                                    skippedCount: skipped)
                        self.tableView.reloadData()
                        self.updateNav()
                    }
                }
            } catch {
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        let ac = UIAlertController(title: "Error", message: error.localizedDescription,
                                                   preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ac, animated: true)
                    }
                }
            }
        }
    }

    // MARK: - Add players

    @objc private func addTapped() {
        guard case .reviewPlayers(_, let players, _) = stage, !players.isEmpty else { return }
        guard !isSaving else { return }
        view.endEditing(true)
        isSaving = true

        let spinner = UIAlertController(title: nil, message: "Adding players…", preferredStyle: .alert)
        present(spinner, animated: true)

        Task {
            var added = 0
            var lastError: Error?
            for player in players {
                do {
                    _ = try await SupabaseService.shared.addClubEventPlayer(
                        tournamentId: targetEvent.id,
                        name: player.name,
                        handicap: player.handicap)
                    added += 1
                } catch {
                    lastError = error
                }
            }
            await MainActor.run {
                self.isSaving = false
                spinner.dismiss(animated: false) {
                    if let err = lastError {
                        let msg = added > 0
                            ? "\(added) of \(players.count) added. Error: \(err.localizedDescription)"
                            : err.localizedDescription
                        let ac = UIAlertController(title: "Partial Error", message: msg, preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                            self?.navigationController?.popViewController(animated: true)
                        })
                        self.present(ac, animated: true)
                    } else {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func fmtHC(_ hc: Double) -> String {
        hc == Double(Int(hc)) ? "\(Int(hc))" : String(format: "%.1f", hc)
    }
}

// MARK: - UITextFieldDelegate

extension ClubEventCopyRosterViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ tf: UITextField) {
        guard case .reviewPlayers(let name, var players, let skipped) = stage else { return }
        let row = tf.tag
        guard row < players.count else { return }
        let raw = (tf.text ?? "").trimmingCharacters(in: .whitespaces)
        if let val = Double(raw), val >= -10, val <= 54 {
            players[row].handicap = val
        } else {
            tf.text = fmtHC(players[row].handicap)
        }
        stage = .reviewPlayers(sourceName: name, players: players, skippedCount: skipped)
    }

    func textFieldShouldReturn(_ tf: UITextField) -> Bool {
        tf.resignFirstResponder()
        return true
    }
}
