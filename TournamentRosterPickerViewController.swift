import UIKit

// Scorer-facing roster picker: select multiple players before dismissing.
// Primary path: tap names in sequence, Done to close. Auto-closes when all slots fill.
// Secondary: "Player not listed? Add manually."
// Presented modally from ManagePlayersViewController when in a tournament context.
final class TournamentRosterPickerViewController: UIViewController {

    // Called each time a NEW player is tapped; pre-checked players do not fire this.
    var onSelect: ((String, Int) -> Void)?
    // Called when a checked player is tapped to deselect them.
    var onDeselect: ((String) -> Void)?
    // Absolute player ceiling — set by presenter.
    var maxPlayers: Int = 5
    // Names already in FriendStore with preselectForRound = true (device owner excluded).
    // Picker pre-checks the intersection with the loaded roster; non-roster names are silently omitted.
    var preSelectedNames: Set<String> = []
    // The current scorer's group code — entries claimed by a different group are shown as taken.
    // Falls back to DeviceID so claiming always fires even before a groupCode is assigned.
    var myGroupCode: String? = nil
    private var myClaimID: String { myGroupCode ?? DeviceID.id }

    private let tournamentCode: String
    private var allEntries: [TournamentRosterEntry] = []
    private var filtered: [TournamentRosterEntry] = []
    private var isLoading = true
    private var selectedNames: Set<String> = []
    private var remainingSelections: Int = 0

    private let searchBar = UISearchBar()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let spinner = UIActivityIndicatorView(style: .medium)
    private var pollTimer: Timer?

    init(tournamentCode: String) {
        self.tournamentCode = tournamentCode
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        remainingSelections = maxPlayers   // recalculated in loadRoster() once pre-checks are known
        view.backgroundColor = .systemGroupedBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(doneTapped))

        updateTitle()
        buildLayout()
        loadRoster()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshClaims()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { [weak self] _ in
            self?.refreshClaims()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pollTimer?.invalidate()
        pollTimer = nil
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

        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(spinner)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

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

    // Re-fetch only group_code values so new claims from other scorers become visible
    // without resetting the current scorer's selections.
    private func refreshClaims() {
        guard !isLoading else { return }
        Task {
            guard let fresh = try? await SupabaseService.shared.fetchRoster(code: tournamentCode) else { return }
            await MainActor.run {
                let byName = Dictionary(fresh.map { ($0.canonicalName, $0) }, uniquingKeysWith: { _, last in last })
                self.allEntries = self.allEntries.map { entry in
                    guard let updated = byName[entry.canonicalName] else { return entry }
                    return updated
                }
                let q = (self.searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                self.filtered = q.isEmpty ? self.allEntries : self.allEntries.filter {
                    $0.canonicalName.localizedCaseInsensitiveContains(q)
                }
                self.tableView.reloadData()
            }
        }
    }

    private func loadRoster() {
        spinner.startAnimating()
        Task {
            do {
                let entries = try await SupabaseService.shared.fetchRoster(code: tournamentCode)
                await MainActor.run {
                    self.allEntries = entries.sorted { $0.canonicalName < $1.canonicalName }
                    self.filtered = self.allEntries
                    // Pre-check the intersection of caller-supplied names and the loaded roster.
                    // Non-roster names in preSelectedNames are silently omitted — not shown, not checked.
                    let rosterNames = Set(self.allEntries.map { $0.canonicalName })
                    self.selectedNames = self.preSelectedNames.intersection(rosterNames)
                    self.remainingSelections = self.maxPlayers - self.selectedNames.count
                    self.isLoading = false
                    self.spinner.stopAnimating()
                    self.updateTitle()
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

    private func select(name: String, hc: Int, entryID: UUID? = nil) {
        guard !selectedNames.contains(name), remainingSelections > 0 else { return }
        selectedNames.insert(name)
        remainingSelections -= 1
        onSelect?(name, hc)
        updateTitle()
        tableView.reloadData()
        if let id = entryID {
            // Snapshot value types so the claim fires even if self is released before
            // the Task executes (e.g. the view auto-dismisses when all slots fill).
            let claimID = myClaimID
            let tCode   = tournamentCode
            Task { [weak self] in
                // claimRosterEntry uses only value-type captures — no self needed.
                try? await SupabaseService.shared.claimRosterEntry(id: id, groupCode: claimID)
                // Verify claim succeeded — another device may have won the race.
                guard let fresh = try? await SupabaseService.shared.fetchRoster(code: tCode),
                      let entry = fresh.first(where: { $0.id == id }) else { return }
                await MainActor.run {
                    guard let self else { return }
                    // Update local entries with latest group_code values
                    let byID = Dictionary(fresh.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
                    self.allEntries = self.allEntries.map { byID[$0.id] ?? $0 }
                    self.filtered   = self.filtered.map   { byID[$0.id] ?? $0 }
                    // If our claim didn't stick, roll it back locally
                    if let winner = entry.groupCode, !winner.isEmpty, winner != claimID {
                        self.selectedNames.remove(name)
                        self.remainingSelections += 1
                        self.onDeselect?(name)
                        self.updateTitle()
                        let ac = UIAlertController(
                            title: "Player Taken",
                            message: "\(name) was just claimed by another group.",
                            preferredStyle: .alert
                        )
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ac, animated: true)
                    }
                    self.tableView.reloadData()
                }
            }
        }
        if remainingSelections == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.dismiss(animated: true)
            }
        }
    }

    private func deselect(name: String, entryID: UUID? = nil) {
        guard selectedNames.contains(name) else { return }
        selectedNames.remove(name)
        remainingSelections += 1
        onDeselect?(name)
        updateTitle()
        tableView.reloadData()
        if let id = entryID {
            Task { try? await SupabaseService.shared.unclaimRosterEntry(id: id) }
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
        let takenByOther: Bool = {
            if alreadyPicked { return false }   // own selection — never block or label as taken
            guard let gc = entry.groupCode, !gc.isEmpty else { return false }
            return gc != myClaimID
        }()
        var c = cell.defaultContentConfiguration()
        c.text = entry.canonicalName
        if takenByOther {
            c.secondaryText = "Taken"
            c.textProperties.color = .tertiaryLabel
            c.secondaryTextProperties.color = .tertiaryLabel
        } else {
            c.secondaryText = entry.handicap == 0 ? "Scratch" : "HC \(entry.handicap)"
            if entry.addedBy == "scorer" { c.secondaryText = (c.secondaryText ?? "") + "  •  walk-on" }
            c.textProperties.color = alreadyPicked ? .secondaryLabel : .label
        }
        cell.contentConfiguration = c
        cell.accessoryType = alreadyPicked ? .checkmark : .none
        cell.selectionStyle = takenByOther ? .none : .default
        cell.tintColor = .systemGreen
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !filtered.isEmpty else { return }
        let entry = filtered[indexPath.row]
        // Block taps on players claimed by another group — but always allow deselecting own picks
        if !selectedNames.contains(entry.canonicalName),
           let gc = entry.groupCode, !gc.isEmpty, gc != myClaimID { return }
        if selectedNames.contains(entry.canonicalName) {
            deselect(name: entry.canonicalName, entryID: entry.id)
        } else {
            select(name: entry.canonicalName, hc: entry.handicap, entryID: entry.id)
        }
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
