import UIKit

final class LiveConnectedViewController: UITableViewController {

    private let watchedSessionsKey = "watchedWolfSessions"

    private struct Row {
        let title: String
        let subtitle: String
        let action: () -> Void
    }

    private struct Section {
        let header: String
        let rows: [Row]
    }

    private var sections: [Section] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Live & Connected"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(closeTapped)
        )
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        buildSections()
        tableView.reloadData()
    }

    // MARK: - Build

    private func buildSections() {
        var result: [Section] = []

        result.append(Section(header: "JOIN", rows: [
            Row(title: "Join Tournament",
                subtitle: "Enter a code to join an existing tournament") { [weak self] in
                self?.joinTournamentTapped()
            },
            Row(title: "Join Nassau Match",
                subtitle: "Import an invite to join a live Nassau match") { [weak self] in
                guard let self else { return }
                WolfActions.joinLiveMatch(from: self)
            },
            Row(title: "Watch Live",
                subtitle: "Watch a friend's round in real time") { [weak self] in
                self?.watchLiveTapped()
            },
        ]))

        result.append(Section(header: "CREATE", rows: [
            Row(title: "Create Tournament",
                subtitle: "Set up a new tournament and share a join code") { [weak self] in
                self?.createTournamentTapped()
            },
            Row(title: "Create Nassau Match",
                subtitle: "Start a live match and send an invite") { [weak self] in
                guard let self else { return }
                guard GameManager.shared.currentGame != nil else {
                    self.showError("Start a game first before creating a Nassau match.")
                    return
                }
                WolfActions.startLiveMatch(from: self)
            },
            Row(title: "Start Live Wolf",
                subtitle: "Broadcast your scores to spectators") { [weak self] in
                guard let self else { return }
                guard GameManager.shared.currentGame != nil else {
                    self.showError("Start a game first before going Live Wolf.")
                    return
                }
                WolfActions.presentGoLive(from: self)
            },
        ]))

        let isOrganizer = GameManager.shared.currentGame?.tournamentIsOrganizer == true
            && GameManager.shared.currentGame?.tournamentCode != nil
        if isOrganizer {
            let day = GameManager.shared.currentGame?.tournamentDay ?? 1
            result.append(Section(header: "MANAGE", rows: [
                Row(title: "Manage Tournament",
                    subtitle: "Currently Day \(day)") { [weak self] in
                    self?.manageTournamentTapped()
                },
            ]))
        }

        sections = result
    }

    // MARK: - UITableViewDataSource / Delegate

    override func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].header
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let row = sections[indexPath.section].rows[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = row.title
        content.secondaryText = row.subtitle
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        sections[indexPath.section].rows[indexPath.row].action()
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    // MARK: - Join Tournament

    private func joinTournamentTapped() {
        let ac = UIAlertController(
            title: "Join Tournament",
            message: "Enter the 6-letter code from the tournament organizer.",
            preferredStyle: .alert
        )
        ac.addTextField { tf in
            tf.placeholder = "XXXXXX"
            tf.autocapitalizationType = .allCharacters
            tf.autocorrectionType = .no
            tf.returnKeyType = .join
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Join", style: .default) { [weak self, weak ac] _ in
            let raw = (ac?.textFields?.first?.text ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
            guard raw.count == 6 else {
                self?.showError("Please enter a 6-letter code.")
                return
            }
            self?.joinTournament(code: raw)
        })
        present(ac, animated: true)
    }

    private func joinTournament(code: String) {
        let spinner = UIAlertController(title: nil, message: "Looking up tournament…", preferredStyle: .alert)
        present(spinner, animated: true)
        Task {
            do {
                let record = try await SupabaseService.shared.fetchTournament(code: code)
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.showJoinConfirmation(record: record)
                    }
                }
            } catch {
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.showError("Tournament not found. Check the code and try again.\n\n\(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func showJoinConfirmation(record: TournamentRecord) {
        let scoringLabel = record.scoring == "net" ? "Net" : "Gross"
        let gameDesc: String
        switch record.gameType {
        case "wolf":
            gameDesc = "Wolf · \(scoringLabel)"
        case "skins":
            let carry = record.carryTies == true ? "carry ties" : "no carry"
            let stakeStr = record.stake.map { "$\(Int($0))/hole" } ?? ""
            gameDesc = "Skins · \(scoringLabel) · \(carry)\(stakeStr.isEmpty ? "" : " · \(stakeStr)")"
        default:
            gameDesc = "Stableford · \(scoringLabel)"
        }
        let msg = "\"\(record.name)\"\n\(gameDesc)\nCreated by: \(record.createdBy)"
        let ac = UIAlertController(title: "Join This Tournament?", message: msg, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Join", style: .default) { [weak self] _ in
            self?.applyJoinedTournament(record: record)
        })
        present(ac, animated: true)
    }

    private func applyJoinedTournament(record: TournamentRecord) {
        if GameManager.shared.currentGame == nil {
            _ = GameManager.shared.loadLastOpened(notify: false)
        }
        if GameManager.shared.currentGame == nil {
            GameManager.shared.startNewGame()
        }
        let groupCode = UUID().uuidString
        let tournamentMatchId = UUID().uuidString
        GameManager.shared.update { g in
            g.tournamentCode         = record.code
            g.groupCode              = groupCode
            g.tournamentMatchId      = tournamentMatchId
            g.tournamentName         = record.name
            g.tournamentGameType     = record.gameType
            g.tournamentScoringType  = record.scoring
            g.tournamentDay          = record.currentDay ?? 1
            g.tournamentIsOrganizer  = (record.createdBy == DeviceID.id)
            g.tournamentPotAmount    = record.potAmount
        }
        UserDefaults.standard.set(record.currentDay ?? 1, forKey: "lastTournamentDay_\(record.code)")
        GameManager.shared.saveCurrent()
        NotificationCenter.default.post(name: .reloadUI, object: nil)
        dismiss(animated: true)
    }

    // MARK: - Create Tournament

    private func createTournamentTapped() {
        let vc = TeeGameSetupViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Manage Tournament

    private func manageTournamentTapped() {
        let sheet = UIAlertController(title: "Manage Tournament", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "View Results", style: .default) { [weak self] _ in
            self?.viewOrganizerResults()
        })
        sheet.addAction(UIAlertAction(title: "Advance to Next Day", style: .default) { [weak self] _ in
            self?.advanceDay()
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presentActionSheet(sheet)
    }

    private func viewOrganizerResults() {
        guard let code = GameManager.shared.currentGame?.tournamentCode else {
            showError("No active tournament found.")
            return
        }
        let vc = TournamentLeaderboardViewController(code: code, isOrganizerView: true)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func advanceDay() {
        guard let code = GameManager.shared.currentGame?.tournamentCode else { return }
        let spinner = UIAlertController(title: nil, message: "Advancing day…", preferredStyle: .alert)
        present(spinner, animated: true)
        Task {
            do {
                try await SupabaseService.shared.advanceTournamentDay(code: code)
                let record = try await SupabaseService.shared.fetchTournament(code: code)
                let newDay = record.currentDay ?? 1
                GameManager.shared.update { g in g.tournamentDay = newDay }
                UserDefaults.standard.set(newDay, forKey: "lastTournamentDay_\(code)")
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.buildSections()
                        self.tableView.reloadData()
                        let ac = UIAlertController(title: "Advanced to Day \(newDay)",
                                                   message: nil, preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ac, animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.showError("Failed to advance day: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    // MARK: - Watch Live

    private func watchLiveTapped() {
        let saved = UserDefaults.standard.stringArray(forKey: watchedSessionsKey) ?? []
        guard !saved.isEmpty else {
            showWatchLiveAlert()
            return
        }
        Task {
            var activeCodes: [String] = []
            await withTaskGroup(of: (String, Bool).self) { group in
                for code in saved {
                    group.addTask {
                        let session = try? await SupabaseService.shared.fetchWolfSessionByCode(code: code)
                        return (code, session?.status == "active")
                    }
                }
                for await (code, isActive) in group {
                    if isActive { activeCodes.append(code) }
                }
            }
            await MainActor.run {
                if !activeCodes.isEmpty {
                    let vc = WolfSpectatorViewController()
                    vc.sessionCode = ""
                    self.navigationController?.pushViewController(vc, animated: true)
                } else {
                    UserDefaults.standard.removeObject(forKey: self.watchedSessionsKey)
                    self.showWatchLiveAlert()
                }
            }
        }
    }

    private func showWatchLiveAlert() {
        let alert = UIAlertController(
            title: "Watch Live",
            message: "Enter the 6-character code shared by the scorekeeper",
            preferredStyle: .alert
        )
        alert.addTextField { tf in
            tf.placeholder = "e.g. ABC123"
            tf.autocapitalizationType = .allCharacters
            tf.autocorrectionType = .no
            tf.returnKeyType = .go
            NotificationCenter.default.addObserver(
                forName: UITextField.textDidChangeNotification,
                object: tf,
                queue: .main
            ) { _ in
                if let text = tf.text, text.count > 6 { tf.text = String(text.prefix(6)) }
            }
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Watch", style: .default) { [weak self, weak alert] _ in
            let code = (alert?.textFields?.first?.text ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
            guard !code.isEmpty else { return }
            self?.fetchAndOpenSession(code: code)
        })
        present(alert, animated: true)
    }

    private func fetchAndOpenSession(code: String) {
        Task {
            do {
                let session = try await SupabaseService.shared.fetchWolfSessionByCode(code: code)
                await MainActor.run {
                    let vc = WolfSpectatorViewController()
                    vc.sessionCode = session.code
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            } catch {
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Code Not Found",
                        message: "Check the code and try again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    // MARK: - Helpers

    private func showError(_ message: String) {
        let ac = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}
