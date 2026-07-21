import UIKit

// Scorer-facing roster picker: select multiple players before dismissing.
// Primary path: tap names in sequence, Done to close. Auto-closes when all slots fill.
// Secondary: "Player not listed? Add manually."
// Presented modally from ManagePlayersViewController when in a tournament context.
final class TournamentRosterPickerViewController: UIViewController {

    // Called each time a player is tapped; sheet stays open for more picks.
    var onSelect: ((String, Int) -> Void)?
    // Set by presenter to (maxActivePlayers - currentSelectedCount) before presenting.
    var maxSelections: Int = 4

    private let tournamentCode: String
    private var allEntries: [TournamentRosterEntry] = []
    private var filtered: [TournamentRosterEntry] = []
    private var isLoading = true
    private var selectedNames: Set<String> = []
    private var remainingSelections: Int = 4

    private let searchBar = UISearchBar()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let addManuallyButton = UIButton(type: .system)
    private let spinner = UIActivityIndicatorView(style: .medium)

    init(tournamentCode: String) {
        self.tournamentCode = tournamentCode
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        remainingSelections = maxSelections
        view.backgroundColor = .systemGroupedBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(doneTapped))

        updateTitle()
        buildLayout()
        loadRoster()
    }

    // MARK: - Layout

    private func buildLayout() {
        searchBar.placeholder = "Search roster"
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.keyboardDismissMode = .onDrag
        tableView.translatesAutoresizingMaskIntoConstraints = false

        // "Player not listed?" footer button — deliberate secondary action
        var cfg = UIButton.Configuration.plain()
        cfg.title = "Player not listed?  Add manually"
        cfg.baseForegroundColor = .secondaryLabel
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0)
        addManuallyButton.configuration = cfg
        addManuallyButton.addTarget(self, action: #selector(addManuallyTapped), for: .touchUpInside)
        addManuallyButton.translatesAutoresizingMaskIntoConstraints = false

        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(addManuallyButton)
        view.addSubview(spinner)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: addManuallyButton.topAnchor),

            addManuallyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            addManuallyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            addManuallyButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    // MARK: - Title

    private func updateTitle() {
        if remainingSelections <= 0 {
            title = "All Slots Filled"
        } else if remainingSelections == 1 {
            title = "Select Player (1 slot left)"
        } else {
            title = "Select Players (\(remainingSelections) slots left)"
        }
    }

    // MARK: - Load

    private func loadRoster() {
        spinner.startAnimating()
        Task {
            do {
                let entries = try await SupabaseService.shared.fetchRoster(code: tournamentCode)
                await MainActor.run {
                    self.allEntries = entries.sorted { $0.canonicalName < $1.canonicalName }
                    self.filtered = self.allEntries
                    self.isLoading = false
                    self.spinner.stopAnimating()
                    self.tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.spinner.stopAnimating()
                    self.tableView.reloadData()
                }
            }
        }
    }

    // MARK: - Actions

    @objc private func cancelTapped() { dismiss(animated: true) }
    @objc private func doneTapped()   { dismiss(animated: true) }

    @objc private func addManuallyTapped() {
        let ac = UIAlertController(
            title: "Add Player Manually",
            message: "This player will be added to the tournament roster as a walk-on.",
            preferredStyle: .alert)
        ac.addTextField { tf in
            tf.placeholder = "Name"
            tf.autocapitalizationType = .words
            tf.autocorrectionType = .no
        }
        ac.addTextField { tf in
            tf.placeholder = "Handicap (0 = scratch)"
            tf.keyboardType = .numberPad
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Add & Select", style: .default) { [weak self, weak ac] _ in
            guard let self else { return }
            let name = (ac?.textFields?[0].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let hc = Int(ac?.textFields?[1].text ?? "") ?? 0
            guard !name.isEmpty else { return }
            let entry = TournamentRosterEntry(
                id: UUID(),
                tournamentCode: self.tournamentCode,
                canonicalName: name,
                handicap: hc,
                addedBy: "scorer")
            Task {
                try? await SupabaseService.shared.upsertRosterEntry(entry)
            }
            // Add to local list so the checkmark shows
            if !self.allEntries.contains(where: { $0.canonicalName == name }) {
                self.allEntries.append(entry)
                self.allEntries.sort { $0.canonicalName < $1.canonicalName }
                if let q = self.searchBar.text, !q.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    self.filtered = self.allEntries.filter {
                        $0.canonicalName.localizedCaseInsensitiveContains(q)
                    }
                } else {
                    self.filtered = self.allEntries
                }
            }
            self.select(name: name, hc: hc)
        })
        present(ac, animated: true)
    }

    private func select(name: String, hc: Int) {
        guard !selectedNames.contains(name), remainingSelections > 0 else { return }
        selectedNames.insert(name)
        remainingSelections -= 1
        onSelect?(name, hc)
        updateTitle()
        tableView.reloadData()
        if remainingSelections == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.dismiss(animated: true)
            }
        }
    }
}

// MARK: - UITableViewDataSource / Delegate

extension TournamentRosterPickerViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        isLoading ? 0 : max(filtered.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if filtered.isEmpty {
            var c = cell.defaultContentConfiguration()
            c.text = allEntries.isEmpty
                ? "No roster loaded — use Add manually below"
                : "No matches"
            c.textProperties.color = .secondaryLabel
            cell.contentConfiguration = c
            cell.selectionStyle = .none
            cell.accessoryType = .none
            return cell
        }
        let entry = filtered[indexPath.row]
        let alreadyPicked = selectedNames.contains(entry.canonicalName)
        var c = cell.defaultContentConfiguration()
        c.text = entry.canonicalName
        c.secondaryText = entry.handicap == 0 ? "Scratch" : "HC \(entry.handicap)"
        if entry.addedBy == "scorer" { c.secondaryText = (c.secondaryText ?? "") + "  •  walk-on" }
        c.textProperties.color = alreadyPicked ? .secondaryLabel : .label
        cell.contentConfiguration = c
        cell.accessoryType = alreadyPicked ? .checkmark : .none
        cell.selectionStyle = alreadyPicked ? .none : .default
        cell.tintColor = .systemGreen
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !filtered.isEmpty else { return }
        let entry = filtered[indexPath.row]
        guard !selectedNames.contains(entry.canonicalName) else { return }
        select(name: entry.canonicalName, hc: entry.handicap)
    }
}

// MARK: - UISearchBarDelegate

extension TournamentRosterPickerViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        filtered = q.isEmpty ? allEntries : allEntries.filter {
            $0.canonicalName.localizedCaseInsensitiveContains(q)
        }
        tableView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
