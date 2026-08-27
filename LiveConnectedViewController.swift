import UIKit

final class LiveConnectedViewController: UITableViewController {

    private let watchedSessionsKey = "watchedWolfSessions"
    private let wolfGreen = UIColor(red: 0.10, green: 0.33, blue: 0.18, alpha: 1.0)

    private struct Row {
        let title: String
        let subtitle: String
        let icon: String        // SF Symbol name
        let tint: UIColor       // icon tint color
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
        title = "Live & Tournaments"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(closeTapped)
        )
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }

    // Tracks which tournament codes have a new day available (populated async)
    private var newDayAvailable: Set<String> = []

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        newDayAvailable = []
        buildSections()
        tableView.reloadData()
        checkRecentTournamentsForNewDay()
        syncTournamentSettingsIfScorer()
    }

    // Re-fetch the organizer's latest wolf/press/hammer settings for scorer devices so
    // setting changes made after the scorer joined are picked up automatically.
    private func syncTournamentSettingsIfScorer() {
        guard let code = GameManager.shared.currentGame?.tournamentCode,
              GameManager.shared.currentGame?.tournamentIsOrganizer == false else { return }
        Task {
            guard let record = try? await SupabaseService.shared.fetchTournament(code: code),
                  record.gameType == "wolf" else { return }
            await MainActor.run {
                GameManager.shared.update { g in
                    switch record.wolfVariant {
                    case "2pt":       g.gameType = .wolf
                    case "lowball":   g.gameType = .wolfLowBall
                    case "matchplay": g.gameType = .matchPlay
                    default:          g.gameType = .sixPointScotch
                    }
                    if let ps = record.pressStyle  { g.pressStyle  = ps == "additive" ? .additive : .doubling }
                    if let hs = record.hammerStyle { g.hammerStyle = hs == "additive" ? .additive : .doubling }
                    if let ws = record.wolfStake {
                        g.wolfStake = ws
                        g.gameHoleDollarsArray = Array(repeating: ws, count: STANDARD_HOLES)
                    }
                }
            }
        }
    }

    private func checkRecentTournamentsForNewDay() {
        let history = TournamentHistoryStore.shared.all()
        guard !history.isEmpty else { return }
        Task {
            var found: Set<String> = []
            for entry in history.prefix(5) {
                let savedDay = UserDefaults.standard.integer(forKey: "lastTournamentDay_\(entry.code)")
                let liveDay  = (try? await SupabaseService.shared.fetchTournament(code: entry.code))?.currentDay ?? 0
                if liveDay > max(savedDay, entry.lastDay) { found.insert(entry.code) }
            }
            guard !found.isEmpty else { return }
            await MainActor.run {
                self.newDayAvailable = found
                self.buildSections()
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - Build

    private func buildSections() {
        var result: [Section] = []

        result.append(Section(header: "JOIN", rows: [
            Row(title: "Join Tournament",
                subtitle: "Enter a code to join an existing tournament",
                icon: "trophy.fill",
                tint: wolfGreen) { [weak self] in
                self?.joinTournamentTapped()
            },
            Row(title: "Join Remote Nassau Match",
                subtitle: "Import an invite to join a live Nassau match",
                icon: "flag.2.crossed.fill",
                tint: .systemBlue) { [weak self] in
                guard let self else { return }
                WolfActions.joinLiveMatch(from: self)
            },
            Row(title: "Spectate Live Wolf",
                subtitle: "Watch a friend's round in real time",
                icon: "eye.fill",
                tint: .secondaryLabel) { [weak self] in
                self?.watchLiveTapped()
            },
            Row(title: "Enter Co-Organizer Code",
                subtitle: "Claim organizer access with a code from the tournament creator",
                icon: "key.fill",
                tint: .secondaryLabel) { [weak self] in
                self?.enterCoOrgCodeTapped()
            },
        ]))

        result.append(Section(header: "CREATE", rows: [
            Row(title: "Create Tournament",
                subtitle: "Set up a new tournament and share a join code",
                icon: "trophy.fill",
                tint: wolfGreen) { [weak self] in
                self?.createTournamentTapped()
            },
            Row(title: "Calcutta Pools",
                subtitle: "Manage auction pools, bids, and payouts",
                icon: "dollarsign.circle.fill",
                tint: .systemGreen) { [weak self] in
                self?.openCalcutta()
            },
            Row(title: "Create Remote Nassau Match",
                subtitle: "Start a live match and send an invite",
                icon: "flag.2.crossed.fill",
                tint: .systemBlue) { [weak self] in
                guard let self else { return }
                guard GameManager.shared.currentGame != nil else {
                    self.showError("Start a game first before creating a Nassau match.")
                    return
                }
                WolfActions.startLiveMatch(from: self)
            },
            Row(title: "Share Live Wolf",
                subtitle: "Broadcast your scores to spectators",
                icon: "antenna.radiowaves.left.and.right",
                tint: .secondaryLabel) { [weak self] in
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
                    subtitle: "Currently Day \(day)",
                    icon: "chart.bar.fill",
                    tint: wolfGreen) { [weak self] in
                    self?.manageTournamentTapped()
                },
            ]))
        }

        let history = TournamentHistoryStore.shared.all()
        if !history.isEmpty {
            let rows: [Row] = history.prefix(5).map { entry in
                let gameLabel: String
                switch entry.gameType {
                case "skins": gameLabel = "Skins"
                case "wolf":  gameLabel = "Wolf"
                default:      gameLabel = entry.gameType.capitalized
                }
                let hasNewDay = self.newDayAvailable.contains(entry.code)
                let subtitle = hasNewDay
                    ? "⚑ New day ready — tap to start"
                    : "Day \(entry.lastDay) · \(gameLabel) · \(entry.code)"
                return Row(
                    title: entry.name,
                    subtitle: subtitle,
                    icon: "clock.fill",
                    tint: .secondaryLabel
                ) { [weak self] in
                    self?.historyEntryTapped(entry)
                }
            }
            result.append(Section(header: "RECENT TOURNAMENTS", rows: rows))
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
        content.image = UIImage(systemName: row.icon)
        content.imageProperties.tintColor = row.tint
        content.imageProperties.maximumSize = CGSize(width: 24, height: 24)
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
        case "scramble":
            gameDesc = "Scramble"
        default:
            gameDesc = "Stableford · \(scoringLabel)"
        }
        let msg = "\"\(record.name)\"\n\(gameDesc)"
        let ac = UIAlertController(title: "Join This Tournament?", message: msg, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Watch as Spectator", style: .default) { [weak self] _ in
            guard let self else { return }
            let vc = TournamentLeaderboardViewController(code: record.code)
            self.navigationController?.pushViewController(vc, animated: true)
        })
        ac.addAction(UIAlertAction(title: "Join as Scorer", style: .default) { [weak self] _ in
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
        // Reuse IDs if rejoining the same tournament on the same day — preserves roster claims
        // and submitted score rows. Generate fresh IDs only for a new day or first join.
        let liveDay = record.currentDay ?? 1
        let existing = TournamentHistoryStore.shared.all().first { $0.code == record.code }
        let isSameDay = existing?.lastDay == liveDay
        let groupCode: String
        let tournamentMatchId: String
        if isSameDay, let savedGroup = existing?.groupCode, let savedMatch = existing?.tournamentMatchId {
            groupCode = savedGroup
            tournamentMatchId = savedMatch
        } else {
            groupCode = UUID().uuidString
            tournamentMatchId = UUID().uuidString
        }
        GameManager.shared.update { g in
            g.tournamentCode         = record.code
            g.groupCode              = groupCode
            g.tournamentMatchId      = tournamentMatchId
            g.tournamentName         = record.name
            g.tournamentGameType     = record.gameType
            g.tournamentScoringType  = record.scoring
            g.tournamentDay          = record.currentDay ?? 1
            g.tournamentIsCreator    = (record.createdBy == DeviceID.id)
            g.tournamentIsOrganizer  = g.tournamentIsCreator
                || (record.coOrganizerDevices?.contains(DeviceID.id) == true)
            g.tournamentPotAmount    = record.potAmount
            g.tournamentCarryTies    = record.carryTies
            if record.gameType == "skins", let stake = record.stake {
                var skins = g.skinsState ?? SkinsEngine.makeDefaultState()
                skins.settings.skinValue = stake
                g.skinsState = skins
            } else if record.gameType == "wolf", let wolfStake = record.wolfStake {
                g.wolfStake = wolfStake
                g.gameHoleDollarsArray = Array(repeating: wolfStake, count: STANDARD_HOLES)
            }
            g.stablefordBaseline          = StablefordBaseline(rawValue: record.stablefordBaseline ?? "par") ?? .par
            g.stablefordCountingPlayers   = record.stablefordTeamCount ?? 3
            g.tournamentStablefordEnabled = record.stablefordEnabled
            if record.gameType == "wolf" {
                switch record.wolfVariant {
                case "2pt":       g.gameType = .wolf
                case "lowball":   g.gameType = .wolfLowBall
                case "matchplay": g.gameType = .matchPlay
                default:          g.gameType = .sixPointScotch
                }
                if let ps = record.pressStyle  { g.pressStyle  = ps == "additive" ? .additive : .doubling }
                if let hs = record.hammerStyle { g.hammerStyle = hs == "additive" ? .additive : .doubling }
            }
        }
        let joinDay = record.currentDay ?? 1
        UserDefaults.standard.set(joinDay, forKey: "lastTournamentDay_\(record.code)")
        GameManager.shared.saveCurrent()
        let isOrg = GameManager.shared.currentGame?.tournamentIsOrganizer == true
        TournamentHistoryStore.shared.record(
            code: record.code, name: record.name,
            gameType: record.gameType, day: joinDay, isOrganizer: isOrg,
            groupCode: groupCode, tournamentMatchId: tournamentMatchId)
        NotificationCenter.default.post(name: .reloadUI, object: nil)

        let presenter = self.navigationController?.presentingViewController ?? presentingViewController
        let sb = UIStoryboard(name: "Main", bundle: nil)

        if record.gameType == "scramble" {
            // Scramble: skip roster picker — show team entry form, then go straight to scoring.
            let tCode       = record.code
            let tCourseName = record.courseName
            dismiss(animated: true) {
                guard let presenter else { return }
                let entryVC = ScrambleTeamEntryViewController()
                entryVC.allowSkip = false
                entryVC.submit = { vc, teamName, playerNames in
                    let spinner = UIAlertController(title: nil, message: "Setting up team…", preferredStyle: .alert)
                    vc.present(spinner, animated: true)
                    Task {
                        do {
                            _ = try await SupabaseService.shared.findOrCreateScrambleTeam(
                                tournamentCode: tCode, teamName: teamName, playerNames: playerNames)
                            await MainActor.run {
                                GameManager.shared.update { g in
                                    if let courseName = tCourseName,
                                       let profile = CourseLibrary.shared.courses.first(where: {
                                           $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                                               .caseInsensitiveCompare(courseName.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame
                                       }) {
                                        g.course = Course(id: profile.id, name: profile.name,
                                                         pars: Array(profile.pars.prefix(STANDARD_HOLES)),
                                                         holeHandicaps: Array(profile.hcs.prefix(STANDARD_HOLES)))
                                    }
                                    g.scrambleTeamName   = teamName
                                    g.playerNames[0]     = teamName
                                    for i in g.playerActivated.indices { g.playerActivated[i] = false }
                                    g.playerActivated[0] = true
                                    // Wipe previous round's scores so the new game starts clean.
                                    g.scores = Array(repeating: Array(repeating: nil, count: STANDARD_HOLES), count: MAX_PLAYERS)
                                }
                                GameManager.shared.seedScoresWithParsForActivePlayers()
                                GameManager.shared.saveCurrent()
                                let game = sb.instantiateViewController(withIdentifier: "GameViewController")
                                let hostNav = (presenter as? UINavigationController) ?? presenter.navigationController
                                spinner.dismiss(animated: false) {
                                    vc.navigationController?.dismiss(animated: true) {
                                        hostNav?.pushViewController(game, animated: true)
                                    }
                                }
                            }
                        } catch {
                            await MainActor.run {
                                spinner.dismiss(animated: false) {
                                    let err = UIAlertController(title: "Error",
                                        message: "Couldn't register team. Try again.\n\n\(error.localizedDescription)",
                                        preferredStyle: .alert)
                                    err.addAction(UIAlertAction(title: "OK", style: .default))
                                    vc.present(err, animated: true)
                                }
                            }
                        }
                    }
                }
                let nav = UINavigationController(rootViewController: entryVC)
                nav.modalPresentationStyle = .formSheet
                presenter.present(nav, animated: true)
            }
            return
        }

        // Non-scramble: surface ManagePlayersVC with the roster picker already opening.
        let day = record.currentDay ?? 1
        let successMsg = "Joined: \(record.name) · Day \(day)"
        dismiss(animated: true) {
            guard let presenter,
                  let manageVC = sb.instantiateViewController(withIdentifier: "ManagePlayersVC")
                      as? ManagePlayersViewController else { return }
            manageVC.joinSuccessMessage = successMsg
            let nav = UINavigationController(rootViewController: manageVC)
            nav.modalPresentationStyle = .pageSheet
            if let sheet = nav.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
            }
            presenter.present(nav, animated: true)
        }
    }

    // MARK: - Create Tournament

    private func createTournamentTapped() {
        let vc = TeeGameSetupViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    private func openCalcutta() {
        let vc = CalcuttaListViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Manage Tournament

    private func manageTournamentTapped() {
        let sheet = UIAlertController(title: "Manage Tournament", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "View Results", style: .default) { [weak self] _ in
            self?.viewOrganizerResults()
        })
        sheet.addAction(UIAlertAction(title: "AI Summary", style: .default) { [weak self] _ in
            self?.navigationController?.pushViewController(AISummaryViewController(), animated: true)
        })
        sheet.addAction(UIAlertAction(title: "Roster", style: .default) { [weak self] _ in
            self?.showRosterSheet()
        })
        if GameManager.shared.currentGame?.tournamentIsOrganizer == true {
            sheet.addAction(UIAlertAction(title: "Edit Game Settings", style: .default) { [weak self] _ in
                self?.editTournamentSettings()
            })
        }
        sheet.addAction(UIAlertAction(title: "Advance to Next Day", style: .default) { [weak self] _ in
            self?.advanceDay()
        })
        if GameManager.shared.currentGame?.tournamentIsCreator == true {
            sheet.addAction(UIAlertAction(title: "Share Organizer Access", style: .default) { [weak self] _ in
                self?.shareOrganizerAccess()
            })
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presentActionSheet(sheet)
    }

    private func showRosterSheet() {
        let sheet = UIAlertController(title: "Roster", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Edit Roster", style: .default) { [weak self] _ in
            self?.editRosterTapped()
        })
        sheet.addAction(UIAlertAction(title: "Permanent Roster", style: .default) { [weak self] _ in
            self?.openPermanentRoster()
        })
        if GameManager.shared.currentGame?.tournamentIsOrganizer == true {
            let currentCode = GameManager.shared.currentGame?.tournamentCode ?? ""
            let past = TournamentHistoryStore.shared.all().filter { $0.code != currentCode }
            if !past.isEmpty {
                sheet.addAction(UIAlertAction(title: "Load Roster from Past Tournament", style: .default) { [weak self] _ in
                    self?.showPastRosterImportSheet(past, into: currentCode)
                })
            }
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presentActionSheet(sheet)
    }

    private func showPastRosterImportSheet(_ entries: [TournamentHistoryEntry], into currentCode: String) {
        let ac = UIAlertController(
            title: "Load Roster from Past Tournament",
            message: "All players from that tournament will be added to this roster.",
            preferredStyle: .actionSheet)
        for entry in entries {
            ac.addAction(UIAlertAction(title: "\(entry.name)  ·  Day \(entry.lastDay)", style: .default) { [weak self] _ in
                self?.importRosterFromPastTournament(code: entry.code, name: entry.name, into: currentCode)
            })
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presentActionSheet(ac)
    }

    private func importRosterFromPastTournament(code: String, name: String, into currentCode: String) {
        let spinner = UIAlertController(title: nil, message: "Importing players from \(name)…", preferredStyle: .alert)
        present(spinner, animated: true)
        Task {
            do {
                let entries = try await SupabaseService.shared.fetchRoster(code: code)
                for entry in entries {
                    // Preserve existing FriendStore HC — only set preselectForRound.
                    if let existing = FriendStore.shared.friends.first(where: {
                        $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                            .caseInsensitiveCompare(entry.canonicalName) == .orderedSame
                    }) {
                        FriendStore.shared.update(friendID: existing.id, preselectForRound: true)
                    } else {
                        let friend = Friend(name: entry.canonicalName, defaultHC: entry.handicap)
                        FriendStore.shared.upsert(friend)
                        if let saved = FriendStore.shared.friends.first(where: {
                            $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                                .caseInsensitiveCompare(entry.canonicalName) == .orderedSame
                        }) {
                            FriendStore.shared.update(friendID: saved.id, preselectForRound: true)
                        }
                    }
                    let rosterEntry = TournamentRosterEntry(
                        id: UUID(),
                        tournamentCode: currentCode,
                        canonicalName: entry.canonicalName,
                        handicap: entry.handicap,
                        addedBy: "organizer",
                        groupCode: nil)
                    try? await SupabaseService.shared.upsertRosterEntry(rosterEntry)
                }
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        let ac = UIAlertController(
                            title: "Roster Loaded",
                            message: "\(entries.count) player\(entries.count == 1 ? "" : "s") imported from \(name).",
                            preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ac, animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.showError("Could not load players from that tournament.")
                    }
                }
            }
        }
    }

    private func editRosterTapped() {
        guard let code = GameManager.shared.currentGame?.tournamentCode,
              let name = GameManager.shared.currentGame?.tournamentName else { return }
        let vc = TournamentRosterViewController(code: code, name: name)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func openPermanentRoster() {
        let vc = PermanentRosterViewController()
        vc.tournamentCode = GameManager.shared.currentGame?.tournamentCode
        navigationController?.pushViewController(vc, animated: true)
    }

    private func editTournamentSettings() {
        let vc = TournamentSettingsViewController()
        navigationController?.pushViewController(vc, animated: true)
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
        let confirm = UIAlertController(
            title: "Advance to Next Day?",
            message: "This will clear all roster claims so scorers can re-pick players for the new day.",
            preferredStyle: .alert)
        confirm.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        confirm.addAction(UIAlertAction(title: "Advance", style: .destructive) { [weak self] _ in
            guard let self else { return }
            let spinner = UIAlertController(title: nil, message: "Advancing day…", preferredStyle: .alert)
            self.present(spinner, animated: true)
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
        })
        present(confirm, animated: true)
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
            title: "Spectate Live Wolf",
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

    // MARK: - Co-Organizer

    private func enterCoOrgCodeTapped() {
        let alert = UIAlertController(
            title: "Co-Organizer Code",
            message: "Enter the code shared by the tournament creator.",
            preferredStyle: .alert
        )
        alert.addTextField { tf in
            tf.placeholder = "ORG-XXXX"
            tf.autocapitalizationType = .allCharacters
            tf.autocorrectionType = .no
            tf.returnKeyType = .go
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Claim Access", style: .default) { [weak self, weak alert] _ in
            let raw = (alert?.textFields?.first?.text ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
            guard raw.hasPrefix("ORG-") && raw.count == 8 else {
                self?.showError("Enter a valid co-organizer code (e.g. ORG-ABCD).")
                return
            }
            self?.claimCoOrgAccess(code: raw)
        })
        present(alert, animated: true)
    }

    private func claimCoOrgAccess(code: String) {
        let spinner = UIAlertController(title: nil, message: "Verifying code…", preferredStyle: .alert)
        present(spinner, animated: true)
        Task {
            do {
                let record = try await SupabaseService.shared.claimCoOrganizerAccess(coOrgCode: code)
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        let current = GameManager.shared.currentGame
                        if current?.tournamentCode == record.code {
                            // Already in this tournament — just elevate access.
                            GameManager.shared.update { g in
                                g.tournamentIsOrganizer = true
                            }
                            GameManager.shared.saveCurrent()
                            NotificationCenter.default.post(name: .reloadUI, object: nil)
                            self.buildSections()
                            self.tableView.reloadData()
                            let ac = UIAlertController(
                                title: "Co-Organizer Access Granted",
                                message: "You now have organizer access to \(record.name).",
                                preferredStyle: .alert
                            )
                            ac.addAction(UIAlertAction(title: "OK", style: .default))
                            self.present(ac, animated: true)
                        } else {
                            // Not yet in this tournament — apply full join + organizer.
                            self.applyCoOrgJoin(record: record)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.showError("Code not found. Check it and try again.\n\n\(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func applyCoOrgJoin(record: TournamentRecord) {
        if GameManager.shared.currentGame == nil {
            _ = GameManager.shared.loadLastOpened(notify: false)
        }
        if GameManager.shared.currentGame == nil {
            GameManager.shared.startNewGame()
        }
        let groupCode = UUID().uuidString
        let matchId   = UUID().uuidString
        GameManager.shared.update { g in
            g.tournamentCode        = record.code
            g.groupCode             = groupCode
            g.tournamentMatchId     = matchId
            g.tournamentName        = record.name
            g.tournamentGameType    = record.gameType
            g.tournamentScoringType = record.scoring
            g.tournamentDay         = record.currentDay ?? 1
            g.tournamentIsCreator        = false
            g.tournamentIsOrganizer      = true
            g.tournamentPotAmount        = record.potAmount
            g.tournamentCarryTies        = record.carryTies
            g.stablefordBaseline          = StablefordBaseline(rawValue: record.stablefordBaseline ?? "par") ?? .par
            g.stablefordCountingPlayers   = record.stablefordTeamCount ?? 3
            g.tournamentStablefordEnabled = record.stablefordEnabled
        }
        let coOrgDay = record.currentDay ?? 1
        UserDefaults.standard.set(coOrgDay, forKey: "lastTournamentDay_\(record.code)")
        GameManager.shared.saveCurrent()
        TournamentHistoryStore.shared.record(
            code: record.code, name: record.name,
            gameType: record.gameType, day: coOrgDay, isOrganizer: true)
        NotificationCenter.default.post(name: .reloadUI, object: nil)
        buildSections()
        tableView.reloadData()
        let ac = UIAlertController(
            title: "Joined as Co-Organizer",
            message: "You've joined \"\(record.name)\" with full organizer access.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    private func shareOrganizerAccess() {
        guard let tournamentCode = GameManager.shared.currentGame?.tournamentCode,
              GameManager.shared.currentGame?.tournamentIsCreator == true else { return }

        let spinner = UIAlertController(title: nil, message: "Preparing code…", preferredStyle: .alert)
        present(spinner, animated: true)
        Task {
            do {
                // Reuse existing co-organizer code if one was already generated; create one otherwise.
                let record = try await SupabaseService.shared.fetchTournament(code: tournamentCode)
                let orgCode: String
                if let existing = record.coOrganizerCode, !existing.isEmpty {
                    orgCode = existing
                } else {
                    orgCode = try await SupabaseService.shared.generateCoOrgCode(tournamentCode: tournamentCode)
                }
                let name = record.name
                let shareText = "Your WolfMore co-organizer code for \(name): \(orgCode)"
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        let ac = UIAlertController(
                            title: "Co-Organizer Code",
                            message: "\(orgCode)",
                            preferredStyle: .alert
                        )
                        ac.addAction(UIAlertAction(title: "Copy", style: .default) { _ in
                            UIPasteboard.general.string = orgCode
                        })
                        ac.addAction(UIAlertAction(title: "Share…", style: .default) { [weak self] _ in
                            guard let self else { return }
                            let vc = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
                            if let pop = vc.popoverPresentationController {
                                pop.sourceView = self.view
                                pop.sourceRect = CGRect(x: self.view.bounds.midX, y: 100, width: 1, height: 1)
                            }
                            self.present(vc, animated: true)
                        })
                        ac.addAction(UIAlertAction(title: "Done", style: .cancel))
                        self.present(ac, animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.showError("Could not prepare code: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    // MARK: - Tournament History

    private func historyEntryTapped(_ entry: TournamentHistoryEntry) {
        let hasNewDay = newDayAvailable.contains(entry.code)
        let msg = hasNewDay ? "New day available — no code needed" : "Day \(entry.lastDay) · \(entry.code)"
        let sheet = UIAlertController(title: entry.name, message: msg, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "View Leaderboard", style: .default) { [weak self] _ in
            let vc = TournamentLeaderboardViewController(code: entry.code)
            self?.navigationController?.pushViewController(vc, animated: true)
        })
        let rejoinLabel = hasNewDay ? "Start New Day (no code needed)" : "Rejoin Tournament"
        sheet.addAction(UIAlertAction(title: rejoinLabel, style: .default) { [weak self] _ in
            self?.rejoinFromHistory(entry)
        })
        sheet.addAction(UIAlertAction(title: "Remove from History", style: .destructive) { [weak self] _ in
            TournamentHistoryStore.shared.remove(code: entry.code)
            self?.buildSections()
            self?.tableView.reloadData()
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presentActionSheet(sheet)
    }

    private func rejoinFromHistory(_ entry: TournamentHistoryEntry) {
        let spinner = UIAlertController(title: nil, message: "Rejoining…", preferredStyle: .alert)
        present(spinner, animated: true)
        Task {
            do {
                let record = try await SupabaseService.shared.fetchTournament(code: entry.code)
                let liveDay = record.currentDay ?? 1
                let savedDay = UserDefaults.standard.integer(forKey: "lastTournamentDay_\(entry.code)")
                let isNewDay = liveDay > savedDay && savedDay > 0
                let isOrg = (record.createdBy == DeviceID.id)
                    || (record.coOrganizerDevices?.contains(DeviceID.id) == true)
                if isNewDay && isOrg {
                    try? await SupabaseService.shared.clearRosterClaims(code: record.code)
                }
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.applyJoinedTournament(record: record)
                    }
                }
            } catch {
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.showError("Tournament not found. It may have ended.\n\n\(error.localizedDescription)")
                    }
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
