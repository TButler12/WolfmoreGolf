import UIKit

final class TeeGamesViewController: UIViewController {

    // MARK: - UI

    private let stackView = UIStackView()
    private weak var rejoinButton: UIButton?
    private weak var manageButton: UIButton?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Tee Games"
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
        setupStack()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshRejoinButton()
        refreshManageButton()
        checkForNewDay()
    }

    // MARK: - Setup

    private func setupStack() {
        let createBtn = makeButton(title: "Create Tee Game", subtitle: "Set up a new tournament and get a join code", color: UIColor(red: 0.22, green: 0.62, blue: 0.34, alpha: 1.0))
        createBtn.addTarget(self, action: #selector(createTapped), for: .touchUpInside)

        let joinBtn = makeButton(title: "Join Tee Game", subtitle: "Enter a 6-letter code to join an existing tournament", color: UIColor(red: 0.20, green: 0.47, blue: 0.78, alpha: 1.0))
        joinBtn.addTarget(self, action: #selector(joinTapped), for: .touchUpInside)

        let rejoinBtn = makeButton(title: "Rejoin Tournament", subtitle: "", color: UIColor(red: 0.72, green: 0.45, blue: 0.08, alpha: 1.0))
        rejoinBtn.addTarget(self, action: #selector(rejoinTapped), for: .touchUpInside)
        rejoinBtn.isHidden = true
        rejoinButton = rejoinBtn

        let leaderboardBtn = makeButton(title: "View Leaderboard",
                                        subtitle: "See live standings for any tournament",
                                        color: UIColor(red: 0.12, green: 0.45, blue: 0.55, alpha: 1.0))
        leaderboardBtn.addTarget(self, action: #selector(leaderboardTapped), for: .touchUpInside)

        let manageBtn = makeButton(title: "Manage Tournament", subtitle: "Advance day, adjust settings", color: UIColor(red: 0.48, green: 0.18, blue: 0.62, alpha: 1.0))
        manageBtn.addTarget(self, action: #selector(manageTapped), for: .touchUpInside)
        manageBtn.isHidden = true
        manageButton = manageBtn

        let calcuttaSeparator = UILabel()
        calcuttaSeparator.text = "CALCUTTA"
        calcuttaSeparator.font = .systemFont(ofSize: 12, weight: .semibold)
        calcuttaSeparator.textColor = .secondaryLabel
        calcuttaSeparator.textAlignment = .center

        let calcuttaBtn = makeButton(
            title: "Calcutta Pools",
            subtitle: "Organizer setup, bids, payouts & results",
            color: UIColor(red: 0.52, green: 0.32, blue: 0.06, alpha: 1.0))
        calcuttaBtn.addTarget(self, action: #selector(calcuttaTapped), for: .touchUpInside)

        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(createBtn)
        stackView.addArrangedSubview(joinBtn)
        stackView.addArrangedSubview(rejoinBtn)
        stackView.addArrangedSubview(leaderboardBtn)
        stackView.addArrangedSubview(manageBtn)
        stackView.addArrangedSubview(calcuttaSeparator)
        stackView.addArrangedSubview(calcuttaBtn)
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
    }

    private func refreshRejoinButton(newDayAvailable: Int? = nil) {
        let ud = UserDefaults.standard
        let savedCode = ud.string(forKey: "lastTournamentCode")
        let savedName = ud.string(forKey: "lastTournamentName") ?? "Tournament"
        let currentCode = GameManager.shared.currentGame?.tournamentCode
        let shouldShow = savedCode != nil && currentCode == nil
        rejoinButton?.isHidden = !shouldShow
        if shouldShow {
            rejoinButton?.configuration?.title = "Rejoin \(savedName)"
            if let day = newDayAvailable {
                rejoinButton?.configuration?.subtitle = "Day \(day) is ready — tap to start!"
                rejoinButton?.configuration?.baseBackgroundColor = UIColor(red: 0.85, green: 0.35, blue: 0.10, alpha: 1.0)
            } else if let code = savedCode {
                rejoinButton?.configuration?.subtitle = "Code: \(code)"
                rejoinButton?.configuration?.baseBackgroundColor = UIColor(red: 0.72, green: 0.45, blue: 0.08, alpha: 1.0)
            }
        }
    }

    private func checkForNewDay() {
        let ud = UserDefaults.standard
        guard let code = ud.string(forKey: "lastTournamentCode"),
              GameManager.shared.currentGame?.tournamentCode == nil else { return }
        let savedDay = ud.integer(forKey: "lastTournamentDay_\(code)")
        Task {
            guard let record = try? await SupabaseService.shared.fetchTournament(code: code) else { return }
            let liveDay = record.currentDay ?? 1
            await MainActor.run {
                if liveDay > savedDay {
                    self.refreshRejoinButton(newDayAvailable: liveDay)
                }
            }
        }
    }

    private func makeButton(title: String, subtitle: String, color: UIColor) -> UIButton {
        var cfg = UIButton.Configuration.filled()
        cfg.baseBackgroundColor = color
        cfg.baseForegroundColor = .white
        cfg.cornerStyle = .large
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 18, leading: 20, bottom: 18, trailing: 20)
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs
            a.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
            return a
        }
        cfg.subtitleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs
            a.font = UIFont.systemFont(ofSize: 13, weight: .regular)
            return a
        }
        cfg.title = title
        cfg.subtitle = subtitle
        cfg.titleAlignment = .center
        let btn = UIButton(configuration: cfg)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func calcuttaTapped() {
        let vc = CalcuttaListViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func createTapped() {
        let vc = TeeGameSetupViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func joinTapped() {
        let ac = UIAlertController(
            title: "Join Tee Game",
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

    // MARK: - Join flow

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
                print("❌ fetchTournament error: \(error)")
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
            let valueStr: String
            if let pot = record.potAmount {
                valueStr = "Pot $\(Int(pot))"
            } else if let s = record.stake {
                valueStr = "$\(Int(s))/skin"
            } else {
                valueStr = ""
            }
            gameDesc = "Skins · \(scoringLabel) · \(carry)\(valueStr.isEmpty ? "" : " · \(valueStr)")"
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
        let groupCode        = UUID().uuidString
        let tournamentMatchId = UUID().uuidString
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
        }
        let joinDay = record.currentDay ?? 1
        UserDefaults.standard.set(joinDay, forKey: "lastTournamentDay_\(record.code)")
        GameManager.shared.saveCurrent()
        let isOrg = (record.createdBy == DeviceID.id)
            || (record.coOrganizerDevices?.contains(DeviceID.id) == true)
        TournamentHistoryStore.shared.record(
            code: record.code, name: record.name,
            gameType: record.gameType, day: joinDay, isOrganizer: isOrg)
        NotificationCenter.default.post(name: .reloadUI, object: nil)
        #if DEBUG
        print("🏆 joined tournament: code=\(record.code) groupCode=\(groupCode) matchId=\(tournamentMatchId)")
        #endif
        dismiss(animated: true)
    }

    @objc private func leaderboardTapped() {
        let ac = UIAlertController(
            title: "View Leaderboard",
            message: "Enter the 6-letter tournament code.",
            preferredStyle: .alert
        )
        ac.addTextField { tf in
            tf.placeholder = "XXXXXX"
            tf.autocapitalizationType = .allCharacters
            tf.autocorrectionType = .no
            tf.returnKeyType = .go
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "View", style: .default) { [weak self, weak ac] _ in
            let raw = (ac?.textFields?.first?.text ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
            guard raw.count == 6 else {
                self?.showError("Please enter a 6-letter code.")
                return
            }
            let vc = TournamentLeaderboardViewController(code: raw)
            self?.navigationController?.pushViewController(vc, animated: true)
        })
        present(ac, animated: true)
    }

    @objc private func rejoinTapped() {
        let name = UserDefaults.standard.string(forKey: "lastTournamentName") ?? "Tournament"
        let ac = UIAlertController(
            title: "Rejoin \(name)?",
            message: "You will continue as the same group. Your previous scores are preserved.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Rejoin", style: .default) { [weak self] _ in
            self?.applyRejoin()
        })
        present(ac, animated: true)
    }

    private func applyRejoin() {
        let ud = UserDefaults.standard
        guard let code = ud.string(forKey: "lastTournamentCode") else { return }
        let savedMatchId = ud.string(forKey: "lastTournamentMatchId")
        let groupCode    = ud.string(forKey: "lastTournamentGroupCode")
        let name         = ud.string(forKey: "lastTournamentName")
        let gameType     = ud.string(forKey: "lastTournamentGameType")
        let scoring      = ud.string(forKey: "lastTournamentScoringType")
        let savedDay     = ud.integer(forKey: "lastTournamentDay_\(code)")

        let spinner = UIAlertController(title: nil, message: "Rejoining…", preferredStyle: .alert)
        present(spinner, animated: true)

        Task {
            do {
                let record  = try await SupabaseService.shared.fetchTournament(code: code)
                let liveDay = record.currentDay ?? (savedDay > 0 ? savedDay : 1)
                ud.set(liveDay, forKey: "lastTournamentDay_\(code)")

                // New day → new matchId so Day 2 rows don't collide with Day 1
                let isNewDay = liveDay > savedDay && savedDay > 0
                let matchId = isNewDay
                    ? UUID().uuidString
                    : (savedMatchId ?? UUID().uuidString)

                // Organizer clears all roster claims so everyone is available on the new day
                let isOrg = (record.createdBy == DeviceID.id)
                    || (record.coOrganizerDevices?.contains(DeviceID.id) == true)
                if isNewDay && isOrg {
                    try? await SupabaseService.shared.clearRosterClaims(code: record.code)
                }

                if GameManager.shared.currentGame == nil {
                    _ = GameManager.shared.loadLastOpened(notify: false)
                }
                if GameManager.shared.currentGame == nil {
                    GameManager.shared.startNewGame()
                }
                GameManager.shared.update { g in
                    g.tournamentCode        = record.code
                    g.tournamentMatchId     = matchId
                    g.groupCode             = groupCode
                    g.tournamentName        = record.name
                    g.tournamentGameType    = record.gameType
                    g.tournamentScoringType = record.scoring
                    g.tournamentDay         = liveDay
                    g.tournamentIsCreator   = (record.createdBy == DeviceID.id)
                    g.tournamentIsOrganizer = g.tournamentIsCreator
                        || (record.coOrganizerDevices?.contains(DeviceID.id) == true)
                    g.tournamentPotAmount   = record.potAmount
                    g.tournamentCarryTies   = record.carryTies
                    if record.gameType == "skins", let stake = record.stake {
                        var skins = g.skinsState ?? SkinsEngine.makeDefaultState()
                        skins.settings.skinValue = stake
                        g.skinsState = skins
                    } else if record.gameType == "wolf", let wolfStake = record.wolfStake {
                        g.wolfStake = wolfStake
                        g.gameHoleDollarsArray = Array(repeating: wolfStake, count: STANDARD_HOLES)
                    }
                }
                GameManager.shared.saveCurrent()
                let rejoinIsOrg = (record.createdBy == DeviceID.id)
                    || (record.coOrganizerDevices?.contains(DeviceID.id) == true)
                TournamentHistoryStore.shared.record(
                    code: record.code, name: record.name,
                    gameType: record.gameType, day: liveDay, isOrganizer: rejoinIsOrg)
                NotificationCenter.default.post(name: .reloadUI, object: nil)
                #if DEBUG
                print("🏆 rejoined tournament: code=\(record.code) matchId=\(matchId) day=\(liveDay)")
                #endif
                await MainActor.run {
                    spinner.dismiss(animated: false) { self.dismiss(animated: true) }
                }
            } catch {
                print("❌ applyRejoin fetchTournament error: \(error)")
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.showError("Could not rejoin tournament: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func refreshManageButton() {
        let isOrganizer = GameManager.shared.currentGame?.tournamentIsOrganizer == true
            && GameManager.shared.currentGame?.tournamentCode != nil
        manageButton?.isHidden = !isOrganizer
        if isOrganizer {
            let day = GameManager.shared.currentGame?.tournamentDay ?? 1
            manageButton?.configuration?.subtitle = "Currently Day \(day)"
        }
    }

    @objc private func manageTapped() {
        let sheet = UIAlertController(title: "Manage Tournament", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Advance to Next Day", style: .default) { [weak self] _ in
            self?.advanceDay()
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presentActionSheet(sheet, from: manageButton ?? view)
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
                        self.refreshManageButton()
                        let ac = UIAlertController(title: "Advanced to Day \(newDay)", message: nil, preferredStyle: .alert)
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

    private func showError(_ message: String) {
        let ac = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}
