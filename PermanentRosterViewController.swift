import UIKit

// Organizer-facing permanent roster manager.
// Shows a locally-stored list of players (name + HC) that persists across tournaments.
// When opened with a tournamentCode, a "Load into Tournament" footer button upserts
// all permanent roster players into that tournament's Supabase roster.
final class PermanentRosterViewController: UIViewController {

    // Set by the presenter when opened from a tournament context.
    var tournamentCode: String?

    private let store = PermanentRosterStore.shared
    private var players: [PermanentRosterPlayer] = []
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let loadButton = UIButton(type: .system)
    private let spinner = UIActivityIndicatorView(style: .medium)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Permanent Roster"
        view.backgroundColor = .systemGroupedBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add, target: self, action: #selector(addPlayerTapped))

        buildLayout()
        reload()
    }

    // MARK: - Layout

    private func buildLayout() {
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)

        if tournamentCode != nil {
            var cfg = UIButton.Configuration.filled()
            cfg.title = "Load into Tournament"
            cfg.baseBackgroundColor = UIColor(red: 0.10, green: 0.33, blue: 0.18, alpha: 1.0)
            cfg.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 0, bottom: 14, trailing: 0)
            loadButton.configuration = cfg
            loadButton.layer.cornerRadius = 12
            loadButton.clipsToBounds = true
            loadButton.addTarget(self, action: #selector(loadIntoTournamentTapped), for: .touchUpInside)
            loadButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(loadButton)

            NSLayoutConstraint.activate([
                loadButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                loadButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                loadButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
                loadButton.heightAnchor.constraint(equalToConstant: 50),

                tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                tableView.bottomAnchor.constraint(equalTo: loadButton.topAnchor, constant: -8),
            ])
        } else {
            NSLayoutConstraint.activate([
                tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        }

        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func reload() {
        players = store.players
        tableView.reloadData()
        if tournamentCode != nil {
            loadButton.isEnabled = !players.isEmpty
        }
    }

    // MARK: - Actions

    @objc private func addPlayerTapped() {
        showEditAlert(title: "Add Player", name: "", handicap: 0) { [weak self] name, hc in
            self?.store.upsert(name: name, handicap: hc)
            self?.reload()
        }
    }

    private func editPlayer(_ player: PermanentRosterPlayer) {
        showEditAlert(title: "Edit Player", name: player.name, handicap: player.handicap) { [weak self] name, hc in
            self?.store.remove(id: player.id)
            self?.store.upsert(name: name, handicap: hc)
            self?.reload()
        }
    }

    private func showEditAlert(title: String, name: String, handicap: Int,
                               completion: @escaping (String, Int) -> Void) {
        let ac = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        ac.addTextField { tf in
            tf.placeholder = "Player name"
            tf.text = name
            tf.autocapitalizationType = .words
            tf.autocorrectionType = .no
        }
        ac.addTextField { tf in
            tf.placeholder = "Handicap (0 = scratch)"
            tf.keyboardType = .numberPad
            tf.text = handicap == 0 && name.isEmpty ? "" : "\(handicap)"
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Save", style: .default) { [weak ac] _ in
            let n = (ac?.textFields?[0].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let hc = max(0, Int(ac?.textFields?[1].text ?? "") ?? 0)
            guard !n.isEmpty else { return }
            completion(n, hc)
        })
        present(ac, animated: true)
    }

    @objc private func loadIntoTournamentTapped() {
        guard let code = tournamentCode, !players.isEmpty else { return }
        let ac = UIAlertController(
            title: "Load into Tournament?",
            message: "\(players.count) player\(players.count == 1 ? "" : "s") will be added to this tournament's roster. Existing entries are not removed.",
            preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Load", style: .default) { [weak self] _ in
            self?.performLoad(code: code)
        })
        present(ac, animated: true)
    }

    private func performLoad(code: String) {
        spinner.startAnimating()
        loadButton.isEnabled = false
        Task {
            do {
                for player in players {
                    let entry = TournamentRosterEntry(
                        id: UUID(),
                        tournamentCode: code,
                        canonicalName: player.name,
                        handicap: player.handicap,
                        addedBy: "organizer",
                        groupCode: nil)
                    try await SupabaseService.shared.upsertRosterEntry(entry)
                }
                await MainActor.run {
                    self.spinner.stopAnimating()
                    self.loadButton.isEnabled = true
                    let done = UIAlertController(
                        title: "Loaded",
                        message: "\(self.players.count) player\(self.players.count == 1 ? "" : "s") added to the tournament roster.",
                        preferredStyle: .alert)
                    done.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                        self?.navigationController?.popViewController(animated: true)
                    })
                    self.present(done, animated: true)
                }
            } catch {
                await MainActor.run {
                    self.spinner.stopAnimating()
                    self.loadButton.isEnabled = true
                    let err = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    err.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(err, animated: true)
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource / Delegate

extension PermanentRosterViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        players.isEmpty ? 1 : players.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if players.isEmpty {
            var c = cell.defaultContentConfiguration()
            c.text = "No players yet — tap + to add"
            c.textProperties.color = .secondaryLabel
            cell.contentConfiguration = c
            cell.selectionStyle = .none
            return cell
        }
        let p = players[indexPath.row]
        var c = cell.defaultContentConfiguration()
        c.text = p.name
        c.secondaryText = p.handicap == 0 ? "Scratch" : "HC \(p.handicap)"
        cell.contentConfiguration = c
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !players.isEmpty else { return }
        editPlayer(players[indexPath.row])
    }

    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete, !players.isEmpty else { return }
        store.remove(id: players[indexPath.row].id)
        reload()
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        players.isEmpty ? nil : "\(players.count) player\(players.count == 1 ? "" : "s")"
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        tournamentCode != nil ? "Tap a player to edit their name or handicap. Swipe left to remove." : "Tap a player to edit. Swipe left to remove."
    }
}
