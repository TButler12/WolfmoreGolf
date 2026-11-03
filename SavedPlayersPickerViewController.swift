import UIKit

// Grouped checklist of saved players for bulk-adding to a tournament roster.
// Section 0: "My Regulars" (PermanentRosterStore), Section 1: "Other Players" (FriendStore).
// A player in both stores appears only under My Regulars. HC comes from FriendStore when
// available, otherwise from PermanentRosterStore.
final class SavedPlayersPickerViewController: UITableViewController {

    struct PlayerRow {
        let name: String
        let handicap: Int
    }

    private let existingNames: Set<String> // lowercased names already on tournament roster
    var onAdd: ([(name: String, handicap: Int)]) -> Void = { _ in }

    private var regulars: [PlayerRow] = []
    private var others:   [PlayerRow] = []
    private var checked:  Set<String> = [] // lowercased player names

    private var addButton: UIBarButtonItem!

    init(existingNames: Set<String>) {
        self.existingNames = existingNames
        super.init(style: .insetGrouped)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Choose Saved Players"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

        addButton = UIBarButtonItem(title: "Add", style: .done,
                                    target: self, action: #selector(addTapped))
        addButton.isEnabled = false
        navigationItem.rightBarButtonItem = addButton

        buildData()
    }

    // MARK: - Data

    private func buildData() {
        let permanents = PermanentRosterStore.shared.players
        let permanentLower = Set(permanents.map { $0.name.lowercased() })

        let friendsByLower = Dictionary(
            FriendStore.shared.friends.map { ($0.name.lowercased(), $0) },
            uniquingKeysWith: { first, _ in first })

        // My Regulars: PermanentRosterStore players not already on roster.
        // HC: prefer FriendStore defaultHC if a matching friend exists.
        regulars = permanents
            .filter { !existingNames.contains($0.name.lowercased()) }
            .map { p in
                let hc = friendsByLower[p.name.lowercased()]?.defaultHC ?? p.handicap
                return PlayerRow(name: p.name, handicap: hc)
            }

        // Other Players: FriendStore players not in PermanentRosterStore and not on roster.
        others = FriendStore.shared.friends
            .filter { !permanentLower.contains($0.name.lowercased()) &&
                      !existingNames.contains($0.name.lowercased()) }
            .map { PlayerRow(name: $0.name, handicap: $0.defaultHC) }
    }

    // MARK: - Section helpers

    private enum SectionKind { case regulars, others }

    private var visibleSections: [SectionKind] {
        var s: [SectionKind] = []
        if !regulars.isEmpty { s.append(.regulars) }
        if !others.isEmpty   { s.append(.others) }
        return s
    }

    private func rows(for section: Int) -> [PlayerRow] {
        switch visibleSections[section] {
        case .regulars: return regulars
        case .others:   return others
        }
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        visibleSections.isEmpty ? 1 : visibleSections.count
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        visibleSections.isEmpty ? 1 : rows(for: section).count
    }

    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
        guard !visibleSections.isEmpty else { return nil }
        switch visibleSections[section] {
        case .regulars: return "My Regulars"
        case .others:   return "Other Players"
        }
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if visibleSections.isEmpty {
            var c = cell.defaultContentConfiguration()
            c.text = "No saved players yet"
            c.textProperties.color = .secondaryLabel
            cell.contentConfiguration = c
            cell.selectionStyle = .none
            cell.accessoryType = .none
            return cell
        }
        let player = rows(for: indexPath.section)[indexPath.row]
        var c = cell.defaultContentConfiguration()
        c.text = player.name
        c.secondaryText = player.handicap == 0 ? "Scratch" : "HC \(player.handicap)"
        cell.contentConfiguration = c
        cell.accessoryType = checked.contains(player.name.lowercased()) ? .checkmark : .none
        cell.selectionStyle = .default
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !visibleSections.isEmpty else { return }
        let key = rows(for: indexPath.section)[indexPath.row].name.lowercased()
        if checked.contains(key) { checked.remove(key) } else { checked.insert(key) }
        tableView.reloadRows(at: [indexPath], with: .none)
        updateAddButton()
    }

    private func updateAddButton() {
        addButton.isEnabled = !checked.isEmpty
        addButton.title = checked.isEmpty ? "Add" : "Add \(checked.count)"
    }

    // MARK: - Actions

    @objc private func addTapped() {
        var result: [(name: String, handicap: Int)] = []
        for r in regulars where checked.contains(r.name.lowercased()) {
            result.append((name: r.name, handicap: r.handicap))
        }
        for o in others where checked.contains(o.name.lowercased()) {
            result.append((name: o.name, handicap: o.handicap))
        }
        navigationController?.popViewController(animated: true)
        onAdd(result)
    }
}
