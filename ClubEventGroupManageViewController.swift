import UIKit

/// Per-group management screen for the organizer: Replace, Withdraw, or Remove a player.
/// Reached by tapping a group row in ClubEventOrganizerHomeViewController.
final class ClubEventGroupManageViewController: UITableViewController {

    static let darkGreen = UIColor(red: 0.118, green: 0.227, blue: 0.165, alpha: 1.0)

    private let event:   ClubEventRecord
    private let group:   GroupSummary
    private var players: [ClubEventPlayer]   // mutable; reloaded after each action
    private var roster:  [ClubEventPlayer]   // full event roster (for replacement candidates)

    struct GroupSummary {
        let code:    String
        let players: [ClubEventPlayer]
    }

    init(event: ClubEventRecord, group: GroupSummary, fullRoster: [ClubEventPlayer]) {
        self.event   = event
        self.group   = group
        self.players = group.players.sorted { $0.playerName < $1.playerName }
        self.roster  = fullRoster
        super.init(style: .insetGrouped)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Group \(group.code)"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.largeTitleDisplayMode = .never
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }

    // MARK: - Table

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tv: UITableView, titleForHeaderInSection section: Int) -> String? {
        "PLAYERS"
    }

    override func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        players.count
    }

    override func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let p = players[indexPath.row]
        var cfg = cell.defaultContentConfiguration()
        cfg.text = p.playerName + (p.isWithdrawn ? " (WD)" : "")
        cfg.secondaryText = p.displayHandicap
        cfg.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = cfg
        cell.accessoryType  = (event.status == "finished") ? .none : .disclosureIndicator
        cell.selectionStyle = (event.status == "finished") ? .none : .default
        return cell
    }

    override func tableView(_ tv: UITableView, didSelectRowAt indexPath: IndexPath) {
        tv.deselectRow(at: indexPath, animated: true)
        guard event.status != "finished" else { return }
        showActionSheet(for: players[indexPath.row])
    }

    // MARK: - Action sheet

    private func showActionSheet(for player: ClubEventPlayer) {
        let sheet = UIAlertController(title: player.playerName, message: nil, preferredStyle: .actionSheet)

        sheet.addAction(UIAlertAction(title: "Replace…", style: .default) { [weak self] _ in
            self?.startReplace(player: player)
        })

        if !player.isWithdrawn {
            sheet.addAction(UIAlertAction(title: "Withdraw (WD)", style: .default) { [weak self] _ in
                self?.confirmWithdraw(player: player)
            })
        }

        sheet.addAction(UIAlertAction(title: "Remove & Delete Scores", style: .destructive) { [weak self] _ in
            self?.confirmRemove(player: player)
        })

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        sheet.popoverPresentationController?.sourceView = view
        present(sheet, animated: true)
    }

    // MARK: - Replace

    private func startReplace(player: ClubEventPlayer) {
        let candidates = roster.filter {
            $0.groupCode == nil && $0.id != player.id && !$0.isWithdrawn
        }.sorted { $0.playerName < $1.playerName }

        guard !candidates.isEmpty else {
            showAlert(title: "No Available Players",
                      message: "All roster players are already in groups. Add more players to the roster first.")
            return
        }

        let picker = UIAlertController(title: "Replace \(player.playerName)",
                                       message: "Choose the replacement player:", preferredStyle: .actionSheet)
        for candidate in candidates {
            picker.addAction(UIAlertAction(title: "\(candidate.playerName) · \(candidate.displayHandicap)",
                                           style: .default) { [weak self] _ in
                self?.performReplace(old: player, new: candidate)
            })
        }
        picker.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        picker.popoverPresentationController?.sourceView = view
        present(picker, animated: true)
    }

    private func performReplace(old: ClubEventPlayer, new: ClubEventPlayer) {
        let spinner = UIAlertController(title: nil, message: "Replacing player…", preferredStyle: .alert)
        present(spinner, animated: true)
        Task {
            do {
                let result = try await SupabaseService.shared.replaceClubEventPlayer(
                    tournamentId: event.id, oldPlayerId: old.id,
                    newPlayerId: new.id, groupCode: group.code)
                let moved = result["scores_moved"] ?? 0
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.showAlert(title: "Replaced",
                                       message: "\(old.playerName) replaced by \(new.playerName). \(moved) score\(moved == 1 ? "" : "s") moved.")
                        { self.reloadPlayers() }
                    }
                }
            } catch {
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.showAlert(title: "Replace Failed", message: error.localizedDescription)
                    }
                }
            }
        }
    }

    // MARK: - Withdraw

    private func confirmWithdraw(player: ClubEventPlayer) {
        let ac = UIAlertController(
            title: "Withdraw \(player.playerName)?",
            message: "Scores on holes already played will be kept and may still count for skins. The player will be marked WD on leaderboards.",
            preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Withdraw", style: .destructive) { [weak self] _ in
            self?.performWithdraw(player: player)
        })
        present(ac, animated: true)
    }

    private func performWithdraw(player: ClubEventPlayer) {
        let spinner = UIAlertController(title: nil, message: "Withdrawing…", preferredStyle: .alert)
        present(spinner, animated: true)
        Task {
            do {
                try await SupabaseService.shared.withdrawClubEventPlayer(
                    tournamentId: event.id, playerId: player.id)
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.showAlert(title: "Withdrawn",
                                       message: "\(player.playerName) has been marked as withdrawn.") {
                            self.reloadPlayers()
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.showAlert(title: "Withdraw Failed", message: error.localizedDescription)
                    }
                }
            }
        }
    }

    // MARK: - Remove

    private func confirmRemove(player: ClubEventPlayer) {
        let spinner = UIAlertController(title: nil, message: "Checking scores…", preferredStyle: .alert)
        present(spinner, animated: true)
        Task {
            let scores = (try? await SupabaseService.shared.fetchClubEventGroupScores(
                tournamentId: event.id, playerIds: [player.id])) ?? []
            let n = scores.count
            await MainActor.run {
                spinner.dismiss(animated: false) {
                    let ac = UIAlertController(
                        title: "Remove \(player.playerName)?",
                        message: "This will permanently delete \(n) score\(n == 1 ? "" : "s") and remove the player from their group and teams. This cannot be undone.",
                        preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                    ac.addAction(UIAlertAction(title: "Remove & Delete \(n) Score\(n == 1 ? "" : "s")",
                                               style: .destructive) { [weak self] _ in
                        self?.performRemove(player: player)
                    })
                    self.present(ac, animated: true)
                }
            }
        }
    }

    private func performRemove(player: ClubEventPlayer) {
        let spinner = UIAlertController(title: nil, message: "Removing…", preferredStyle: .alert)
        present(spinner, animated: true)
        Task {
            do {
                try await SupabaseService.shared.removeClubEventPlayerScores(
                    tournamentId: event.id, playerId: player.id)
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.showAlert(title: "Removed",
                                       message: "\(player.playerName) has been removed from the group.") {
                            self.reloadPlayers()
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.showAlert(title: "Remove Failed", message: error.localizedDescription)
                    }
                }
            }
        }
    }

    // MARK: - Reload

    private func reloadPlayers() {
        Task {
            let fresh = (try? await SupabaseService.shared.fetchClubEventRoster(
                tournamentId: event.id)) ?? []
            await MainActor.run {
                self.roster  = fresh
                self.players = fresh.filter { $0.groupCode == self.group.code }
                    .sorted { $0.playerName < $1.playerName }
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - Helpers

    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in completion?() })
        present(ac, animated: true)
    }
}
