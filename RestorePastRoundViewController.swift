import UIKit

// MARK: - List VC

final class PastRoundsListViewController: UITableViewController {

    private let onRestored: () -> Void
    private var entries: [ResetSnapshotStore.Entry] = []

    init(onRestored: @escaping () -> Void) {
        self.onRestored = onRestored
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Restore Past Round"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(closeTapped)
        )
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        reload()
    }

    private func reload() {
        entries = ResetSnapshotStore.shared.allEntries()
        tableView.reloadData()
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    // MARK: UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        entries.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let entry = entries[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = entryTitle(entry)
        content.secondaryText = entrySubtitle(entry)
        content.secondaryTextProperties.color = .secondaryLabel
        content.secondaryTextProperties.font = .systemFont(ofSize: 13)
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        entries.isEmpty ? nil : "Saved snapshots (newest first)"
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let entry = entries[indexPath.row]
        // Capture nav + callback strongly BEFORE pushing. After dismiss the list VC is
        // deallocated, so [weak self] in the completion block would always be nil.
        let nav = navigationController
        let callback = onRestored
        let preview = PastRoundPreviewViewController(entry: entry, onRestored: {
            nav?.dismiss(animated: true, completion: callback)
        })
        navigationController?.pushViewController(preview, animated: true)
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { true }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let entry = entries[indexPath.row]
        ResetSnapshotStore.shared.remove(entry)
        entries.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        if entries.isEmpty { dismiss(animated: true) }
    }

    // MARK: - Helpers

    private func entryTitle(_ entry: ResetSnapshotStore.Entry) -> String {
        let g = entry.gameData
        let course = g.course.name
        let date = relativeDateString(entry.savedAt)
        return "\(course) · \(date)"
    }

    private func entrySubtitle(_ entry: ResetSnapshotStore.Entry) -> String {
        let g = entry.gameData
        let players = activePlayers(g)
        let formats = formatTags(g)
        var parts: [String] = []
        if !players.isEmpty { parts.append(players) }
        if !formats.isEmpty { parts.append(formats) }
        return parts.joined(separator: "  ·  ")
    }
}

// MARK: - Preview VC

final class PastRoundPreviewViewController: UIViewController {

    private let entry: ResetSnapshotStore.Entry
    private let onRestored: () -> Void

    init(entry: ResetSnapshotStore.Entry, onRestored: @escaping () -> Void) {
        self.entry = entry
        self.onRestored = onRestored
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Round Details"
        view.backgroundColor = .systemGroupedBackground
        buildUI()
    }

    private func buildUI() {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -32),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40),
        ])

        stack.addArrangedSubview(makeDetailCard())
        stack.addArrangedSubview(makeRestoreButton())
    }

    private func makeDetailCard() -> UIView {
        let g = entry.gameData
        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 12
        card.clipsToBounds = true

        let vstack = UIStackView()
        vstack.axis = .vertical
        vstack.spacing = 0
        vstack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(vstack)

        NSLayoutConstraint.activate([
            vstack.topAnchor.constraint(equalTo: card.topAnchor),
            vstack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            vstack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            vstack.bottomAnchor.constraint(equalTo: card.bottomAnchor),
        ])

        let rows: [(String, String)] = [
            ("Course",  g.course.name),
            ("Saved",   fullDateString(entry.savedAt)),
            ("Players", activePlayers(g).isEmpty ? "—" : activePlayers(g)),
            ("Formats", formatTags(g).isEmpty ? "—" : formatTags(g)),
        ]

        for (idx, (label, value)) in rows.enumerated() {
            let row = makeRow(label: label, value: value)
            vstack.addArrangedSubview(row)
            if idx < rows.count - 1 {
                let sep = UIView()
                sep.backgroundColor = .separator
                sep.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
                vstack.addArrangedSubview(sep)
            }
        }

        return card
    }

    private func makeRow(label: String, value: String) -> UIView {
        let row = UIView()
        row.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true

        let labelView = UILabel()
        labelView.text = label
        labelView.font = .systemFont(ofSize: 15, weight: .medium)
        labelView.textColor = .secondaryLabel
        labelView.translatesAutoresizingMaskIntoConstraints = false

        let valueView = UILabel()
        valueView.text = value
        valueView.font = .systemFont(ofSize: 15)
        valueView.textColor = .label
        valueView.textAlignment = .right
        valueView.numberOfLines = 0
        valueView.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(labelView)
        row.addSubview(valueView)

        NSLayoutConstraint.activate([
            labelView.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            labelView.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            labelView.widthAnchor.constraint(equalToConstant: 72),
            valueView.leadingAnchor.constraint(equalTo: labelView.trailingAnchor, constant: 8),
            valueView.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            valueView.topAnchor.constraint(equalTo: row.topAnchor, constant: 12),
            valueView.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -12),
        ])

        return row
    }

    private func makeRestoreButton() -> UIView {
        let btn = UIButton(type: .system)
        btn.setTitle("Restore This Round", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        btn.backgroundColor = UIColor(red: 0.18, green: 0.55, blue: 0.24, alpha: 1)
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 12
        btn.heightAnchor.constraint(equalToConstant: 52).isActive = true
        btn.addTarget(self, action: #selector(restoreTapped), for: .touchUpInside)
        return btn
    }

    @objc private func restoreTapped() {
        let hasCommittedHoles = currentRoundHasCommittedHoles()
        if hasCommittedHoles {
            let ac = UIAlertController(
                title: "Replace Current Round?",
                message: "Your current round has committed holes. Restoring will replace it.",
                preferredStyle: .alert
            )
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            ac.addAction(UIAlertAction(title: "Restore", style: .destructive) { [weak self] _ in
                self?.doRestore()
            })
            present(ac, animated: true)
        } else {
            doRestore()
        }
    }

    private func doRestore() {
        ResetSnapshotStore.shared.restore(entry: entry)
        onRestored()
    }

    private func currentRoundHasCommittedHoles() -> Bool {
        // 1. Try decoding directly from disk — most authoritative source
        if let data = UserDefaults.standard.data(forKey: "currentGame_v1"),
           let g = try? JSONDecoder().decode(GameData.self, from: data) {
            return g.holeCommitted.contains(true)
        }
        // 2. Fall back to whatever is already in memory
        if let g = GameManager.shared.currentGame {
            return g.holeCommitted.contains(true)
        }
        // 3. Try loading from disk into memory as a last resort
        if GameManager.shared.loadLastOpened(notify: false) {
            return GameManager.shared.currentGame?.holeCommitted.contains(true) == true
        }
        return false
    }
}

// MARK: - Shared helpers

private func activePlayers(_ g: GameData) -> String {
    let names = (0..<min(MAX_PLAYERS, g.playerActivated.count)).compactMap { i -> String? in
        guard g.playerActivated[i] else { return nil }
        let name = (g.playerNames[safe: i] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? nil : name
    }
    return names.joined(separator: ", ")
}

private func formatTags(_ g: GameData) -> String {
    var tags: [String] = []
    switch g.resolvedGameType {
    case .wolf:           tags.append("Wolf 2-Pt")
    case .wolfLowBall:    tags.append("Wolf LowBall")
    case .sixPointScotch: tags.append("6-Pt Scotch")
    case .hammer:         tags.append("Hammer")
    case .tournament:
        if let tgt = g.tournamentGameType {
            switch tgt {
            case "wolf":       tags.append("Tournament Wolf")
            case "skins":      tags.append("Tournament Skins")
            case "stableford": tags.append("Stableford")
            default:           tags.append("Tournament")
            }
        } else {
            tags.append("Tournament")
        }
    }
    if g.nassauState != nil { tags.append("Nassau") }
    if g.skinsState  != nil { tags.append("Skins") }
    return tags.joined(separator: " · ")
}

private func relativeDateString(_ date: Date) -> String {
    let cal = Calendar.current
    if cal.isDateInToday(date) { return "Today" }
    if cal.isDateInYesterday(date) { return "Yesterday" }
    let fmt = DateFormatter()
    fmt.dateFormat = "MMM d"
    return fmt.string(from: date)
}

private func fullDateString(_ date: Date) -> String {
    let fmt = DateFormatter()
    fmt.dateStyle = .medium
    fmt.timeStyle = .short
    return fmt.string(from: date)
}
