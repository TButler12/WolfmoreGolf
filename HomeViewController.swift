//
//
//  ViewController.swift
//  Wolfmore
//
//  Created by Tom BUTLER on 9/24/25.
//
import UIKit

final class ViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet private weak var welcomeLabel: UILabel!
    @IBOutlet private weak var courseButton: UIButton!
    @IBOutlet private weak var contactsButton: UIButton!
    @IBOutlet private weak var statsButton: UIButton!
    @IBOutlet private weak var moreButton: UIButton!
    @IBOutlet private weak var editCourseButton: UIButton!
    @IBOutlet private weak var playGameButton: UIButton!
    @IBOutlet private weak var playNewGameButton: UIButton?
    @IBOutlet private weak var continueButton: UIButton?
    @IBOutlet private weak var joinProButton: UIButton!

    // MARK: - State
    private var shouldPromptForName = false
    private weak var tournamentButton: UIButton?
    private weak var teeGamesButton: UIButton?
    private weak var watchLiveButton: UIButton?

    // MARK: - Keys
    private let didPromptHomeCourseKey = "profile.didPromptHomeCourse_v1"
    private let suppressWelcomeTipsKey = "onboarding.suppressWelcomeTips_v1"

    private var didPromptHomeCourse: Bool {
        get { UserDefaults.standard.bool(forKey: didPromptHomeCourseKey) }
        set { UserDefaults.standard.set(newValue, forKey: didPromptHomeCourseKey) }
    }

    private var suppressWelcomeTips: Bool {
        get { UserDefaults.standard.bool(forKey: suppressWelcomeTipsKey) }
        set { UserDefaults.standard.set(newValue, forKey: suppressWelcomeTipsKey) }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "WolfMore"
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = false

        CourseLibrary.shared.seedIfNeeded()
        migrateHomeCourseIfNeeded()

        seedProfileNameIfNeeded()
        updateWelcome()

        let tap = UITapGestureRecognizer(target: self, action: #selector(welcomeLabelTapped))
        welcomeLabel.addGestureRecognizer(tap)

        refreshCourseButtonTitle()
        refreshPlayArea()
        refreshBottomButtons()

        fixIconButton(editCourseButton)
        buildTournamentButton()
        buildTeeGamesButton()
        buildWatchLiveButton()
        buildQuickStartButton()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(noop),
            name: .roundSaveBlockedNeedsPro,
            object: nil
        )
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let tgb = teeGamesButton {
            courseButton.frame.origin.y = tgb.frame.maxY + 16
        } else if let tb = tournamentButton {
            courseButton.frame.origin.y = tb.frame.maxY + 16
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateWelcome()
        refreshCourseButtonTitle()
        refreshPlayArea()
        refreshBottomButtons()
        refreshWatchLiveButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        runFirstLaunchPromptsIfNeeded()
        refreshPlayArea()
        UpdateChecker.shared.check(from: self)
    }

    // MARK: - Migration

    private func migrateHomeCourseIfNeeded() {
        let raw = ProfileStore.homeCourseID.trimmingCharacters(in: .whitespacesAndNewlines)
        if !raw.isEmpty, UUID(uuidString: raw) == nil {
            ProfileStore.homeCourseID = ""
            UserDefaults.standard.removeObject(forKey: didPromptHomeCourseKey)
        }
    }

    // MARK: - UI Refresh

    private func refreshCourseButtonTitle() {
        let name: String
        if let g = GameManager.shared.currentGame {
            let stored = g.course.name.trimmingCharacters(in: .whitespacesAndNewlines)
            name = stored.isEmpty ? (CourseLibrary.shared.selectedCourseName ?? "Choose Course") : stored
        } else {
            name = CourseLibrary.shared.selectedCourseName ?? "Choose Course"
        }
        courseButton.configuration = styledButton(title: name, style: .secondaryChevron)
    }

    private func styleCourseButton() {
        courseButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        courseButton.titleLabel?.adjustsFontForContentSizeCategory = true
        courseButton.titleLabel?.adjustsFontSizeToFitWidth = true
        courseButton.titleLabel?.minimumScaleFactor = 0.85
        courseButton.titleLabel?.lineBreakMode = .byTruncatingTail
    }

    private func updatePlayButtonTitle() {
        if GameManager.shared.hasSavedGame {
            playGameButton.setTitle("Continue Game", for: .normal)
        } else {
            playGameButton.setTitle("Start New Game", for: .normal)
        }
    }

    private func refreshPlayArea() {
        playGameButton.configuration = styledButton(title: "Play Game", style: .primary)
        playNewGameButton?.isHidden = true
        continueButton?.isHidden = true
    }

    private func refreshBottomButtons() {
        contactsButton.configuration = styledButton(title: "Contacts", style: .utilityChip)
        statsButton.configuration = styledButton(title: "Stats", style: .utilityChip)
        moreButton.configuration = styledButton(title: "More", style: .utilityChip)
    }

    // MARK: - Setup Helpers

    private func seedProfileNameIfNeeded() {
        if ProfileStore.name == nil {
            shouldPromptForName = true
        }
    }

    // MARK: - Welcome

    private func updateWelcome() {
        let name = (ProfileStore.name ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if name.isEmpty || name == "Player 1" {
            welcomeLabel.text = "       Tap to set your scoring name"
        } else {
            welcomeLabel.text = "       Welcome, \(name)"
        }
        welcomeLabel.isUserInteractionEnabled = true
        welcomeLabel.textAlignment = .center
        welcomeLabel.adjustsFontForContentSizeCategory = true
        welcomeLabel.adjustsFontSizeToFitWidth = true
        welcomeLabel.minimumScaleFactor = 0.8
    }

    // MARK: - First Launch / Onboarding Flow

    private func runFirstLaunchPromptsIfNeeded() {
        guard presentedViewController == nil else { return }

        let storedName = (ProfileStore.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if shouldPromptForName || storedName.isEmpty || storedName == "Player 1" {
            shouldPromptForName = false
            promptForName { [weak self] in
                self?.runPostNamePrompts()
            }
            return
        }

        runPostNamePrompts()
    }

    private func runPostNamePrompts() {
        guard presentedViewController == nil else { return }

        if !didPromptHomeCourse && !hasHomeCourseSet() {
            runHomeCoursePromptIfNeeded()
            return
        }

        runOnboardingIfNeeded()
    }

    private func runOnboardingIfNeeded() {
        guard presentedViewController == nil else { return }
        guard !suppressWelcomeTips else { return }

        showOnboardingAlert()
    }

    private func showOnboardingAlert() {
        let ac = UIAlertController(
            title: "Getting Started",
            message: "Load players from Contacts to start games faster.\n\nYou can also explore Rules to learn Wolf, Nassau, and scoring.",
            preferredStyle: .alert
        )

        ac.addAction(UIAlertAction(title: "Load Contacts", style: .default) { [weak self] _ in
            self?.openContactsManager()
        })

        ac.addAction(UIAlertAction(title: "View Rules", style: .default) { [weak self] _ in
            self?.openRules()
        })

        ac.addAction(UIAlertAction(title: "Don't Show Again", style: .destructive) { [weak self] _ in
            self?.suppressWelcomeTips = true
        })

        ac.addAction(UIAlertAction(title: "Later", style: .cancel))

        present(ac, animated: true)
    }

    private func promptForName(completion: @escaping () -> Void) {
        let ac = UIAlertController(
            title: "Choose Your Scoring Name",
            message: "This name appears on every scorecard you play and in your friends' matches. Use the nickname your golf group already knows you by — not your full legal name.",
            preferredStyle: .alert
        )

        ac.addTextField { tf in
            tf.placeholder = "e.g. McTommy, Bucky, Hollandaise"
            let stored = ProfileStore.name ?? ""
            tf.text = (stored == "Player 1" || stored.isEmpty) ? "" : stored
            tf.autocapitalizationType = .words
            tf.clearButtonMode = .whileEditing
            tf.returnKeyType = .done
        }

        ac.addAction(UIAlertAction(title: "Skip for now", style: .cancel) { _ in
            completion()
        })

        ac.addAction(UIAlertAction(title: "Use This Name", style: .default) { [weak self] _ in
            guard let self = self else { completion(); return }
            let raw = (ac.textFields?.first?.text ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if raw.contains(" ") && raw.split(separator: " ").count >= 2 {
                self.confirmFullNameUsage(typedName: raw, completion: completion)
                return
            }

            if !raw.isEmpty {
                ProfileStore.name = raw
                self.updateWelcome()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            completion()
        })

        present(ac, animated: true)
    }

    private func confirmFullNameUsage(typedName: String, completion: @escaping () -> Void) {
        let ac = UIAlertController(
            title: "Use \"\(typedName)\" on every scorecard?",
            message: "Most golfers prefer a shorter nickname here so it fits cleanly in the scorecard row.",
            preferredStyle: .alert
        )

        ac.addAction(UIAlertAction(title: "Pick a Nickname Instead", style: .cancel) { [weak self] _ in
            self?.promptForName(completion: completion)
        })

        ac.addAction(UIAlertAction(title: "Use \"\(typedName)\"", style: .default) { [weak self] _ in
            ProfileStore.name = typedName
            self?.updateWelcome()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            completion()
        })

        present(ac, animated: true)
    }

    // MARK: - Home Course Prompt

    private func hasHomeCourseSet() -> Bool {
        let id = ProfileStore.homeCourseID.trimmingCharacters(in: .whitespacesAndNewlines)
        return UUID(uuidString: id) != nil
    }

    private func runHomeCoursePromptIfNeeded() {
        guard presentedViewController == nil else { return }
        guard !didPromptHomeCourse else { return }

        guard !hasHomeCourseSet() else {
            didPromptHomeCourse = true
            runOnboardingIfNeeded()
            return
        }

        setEditCourseGlow(true)

        let ac = UIAlertController(
            title: "Set your Home Course?",
            message: "Home Course is used for tracking Hole Stats and Friend Stats. Want to set it now?",
            preferredStyle: .alert
        )

        ac.addAction(UIAlertAction(title: "Not now", style: .cancel) { [weak self] _ in
            self?.didPromptHomeCourse = true
            self?.setEditCourseGlow(false)
            self?.runOnboardingIfNeeded()
        })

        ac.addAction(UIAlertAction(title: "Yes", style: .default) { [weak self] _ in
            self?.didPromptHomeCourse = true
            self?.setEditCourseGlow(false)
            self?.openCourseSetup(nil)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self?.runOnboardingIfNeeded()
            }
        })

        present(ac, animated: true)
    }

    private func setEditCourseGlow(_ on: Bool) {
        if on {
            editCourseButton.layer.shadowColor = UIColor.systemYellow.cgColor
            editCourseButton.layer.shadowRadius = 12
            editCourseButton.layer.shadowOpacity = 0.9
            editCourseButton.layer.shadowOffset = .zero

            let pulse = CABasicAnimation(keyPath: "shadowOpacity")
            pulse.fromValue = 0.2
            pulse.toValue = 0.95
            pulse.duration = 0.7
            pulse.autoreverses = true
            pulse.repeatCount = .infinity
            editCourseButton.layer.add(pulse, forKey: "homeCourseGlowPulse")
        } else {
            editCourseButton.layer.removeAnimation(forKey: "homeCourseGlowPulse")
            editCourseButton.layer.shadowOpacity = 0
            editCourseButton.layer.shadowRadius = 0
        }
    }

    // MARK: - Course Actions

    private func openAddCourse() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "CourseSetupVC") as? CourseSetupViewController else { return }
        vc.prefillTemplate = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction private func courseButtonTapped(_ sender: Any) {
        let sb = UIStoryboard(name: "Main", bundle: nil)

        guard let picker = sb.instantiateViewController(withIdentifier: "CoursePickerVC") as? CoursePickerViewController else {
            assertionFailure("CoursePickerVC storyboard id / class mismatch")
            return
        }

        picker.onPickCourse = { [weak self] id in
            guard let self else { return }
            guard let newCourse = CourseLibrary.shared.get(id: id) else {
                CourseLibrary.shared.selectedCourseID = id
                self.refreshCourseButtonTitle()
                self.dismiss(animated: true)
                return
            }

            guard let currentGame = GameManager.shared.currentGame else {
                // No game in progress — apply directly
                CourseLibrary.shared.selectedCourseID = id
                GameManager.shared.update { g in
                    g.course.pars          = Array(newCourse.pars.prefix(STANDARD_HOLES))
                    g.course.holeHandicaps = Array(newCourse.hcs.prefix(STANDARD_HOLES))
                    g.course.name          = newCourse.name
                    g.course.id            = newCourse.id
                }
                self.refreshCourseButtonTitle()
                self.dismiss(animated: true)
                return
            }

            let curName = currentGame.course.name.trimmingCharacters(in: .whitespacesAndNewlines)

            // Same course — nothing to confirm
            if curName == newCourse.name {
                CourseLibrary.shared.selectedCourseID = id
                self.refreshCourseButtonTitle()
                self.dismiss(animated: true)
                return
            }

            let alert = UIAlertController(
                title: "Change Course?",
                message: "Switch from \(curName) to \(newCourse.name)?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Switch", style: .default) { _ in
                CourseLibrary.shared.selectedCourseID = id
                GameManager.shared.update { g in
                    g.course.pars          = Array(newCourse.pars.prefix(STANDARD_HOLES))
                    g.course.holeHandicaps = Array(newCourse.hcs.prefix(STANDARD_HOLES))
                    g.course.name          = newCourse.name
                    g.course.id            = newCourse.id
                }
                GameManager.shared.saveCurrent()
                self.refreshCourseButtonTitle()
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.dismiss(animated: true) {
                self.present(alert, animated: true)
            }
        }

        picker.onTapAddCourse = { [weak self] in
            self?.dismiss(animated: true) {
                self?.openAddCourse()
            }
        }

        let nav = UINavigationController(rootViewController: picker)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    @IBAction private func openCourseSetup(_ sender: Any? = nil) {
        let sb = UIStoryboard(name: "Main", bundle: nil)

        guard let vc = sb.instantiateViewController(withIdentifier: "CourseSetupVC") as? CourseSetupViewController else {
            assertionFailure("CourseSetupVC storyboard id / class mismatch")
            return
        }

        vc.loadCourseID = CourseLibrary.shared.selectedCourseID

        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            let wrap = UINavigationController(rootViewController: vc)
            wrap.modalPresentationStyle = .fullScreen
            present(wrap, animated: true)
        }
    }

    @IBAction private func editCourseTapped(_ sender: UIButton) {
        openCourseSetup(sender)
    }

    // MARK: - Play Game

    @IBAction func playTapped(_ sender: UIButton) {
        playGameTapped(sender)
    }

    @IBAction func playGameTapped(_ sender: UIButton) {
        guard GameManager.shared.hasSavedGame else {
            presentManagePlayers()
            return
        }

        let ac = UIAlertController(title: "Play Game", message: nil, preferredStyle: .actionSheet)

        ac.addAction(UIAlertAction(title: "Continue Last Game", style: .default) { [weak self] _ in
            self?.performSegue(withIdentifier: "showPlayerSetup", sender: self)
        })

        ac.addAction(UIAlertAction(title: "Start New Game", style: .default) { [weak self] _ in
            self?.confirmStartNewGame()
        })

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
        }

        present(ac, animated: true)
    }

    @IBAction private func playNewGameTapped(_ sender: UIButton) {
        confirmStartNewGame()
    }

    private func confirmStartNewGame() {
        let isTournamentActive = (GameManager.shared.currentGame?.resolvedGameType == .tournament)
            && (GameManager.shared.currentGame?.holeCommitted.contains(true) ?? false)
        let message = isTournamentActive
            ? "This will delete your current Stableford round."
            : "This will delete your previous game data."
        let ac = UIAlertController(title: "Start New Game?", message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Start New Game", style: .destructive) { [weak self] _ in
            // Archive all remote matches from this game session
            let idsToArchive = GameManager.shared.currentGame?.remoteMatchIds ?? []
            Task { for id in idsToArchive { try? await SupabaseService.shared.archiveMatch(id: id) } }
            GameManager.shared.resetForNewRoundPreservingCourseAndRoster()
            self?.presentManagePlayers()
        })
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }

    @IBAction private func continueGameTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "showPlayerSetup", sender: self)
    }

    func makeSharedRound(for playerIndex: Int) -> SharedRound? {
        guard let g = GameManager.shared.currentGame else { return nil }
        guard playerIndex < g.playerNames.count else { return nil }
        guard playerIndex < g.scorePerHole.count else { return nil }
        guard playerIndex < g.fairwayHit.count else { return nil }
        guard playerIndex < g.girHit.count else { return nil }
        guard playerIndex < g.puttsPerHole.count else { return nil }

        return SharedRound(
            playerName: g.playerNames[playerIndex],
            courseName: g.course.name,
            pars: Array(g.course.pars.prefix(STANDARD_HOLES)),
            hcs: Array(g.course.holeHandicaps.prefix(STANDARD_HOLES)),
            scores: Array(g.scores[playerIndex].prefix(STANDARD_HOLES)).map { $0 ?? 0 },
            fairways: Array(g.fairwayHit[playerIndex].prefix(STANDARD_HOLES)),
            girs: Array(g.girHit[playerIndex].prefix(STANDARD_HOLES)),
            putts: Array(g.puttsPerHole[playerIndex].prefix(STANDARD_HOLES)),
            courseHandicap: playerIndex < g.hcPlayers.count ? g.hcPlayers[playerIndex] : 0
        )
    }

    // MARK: - Paywall (removed — all features free)

    @IBAction private func joinProTapped(_ sender: UIButton) {}

    @objc private func welcomeLabelTapped() {
        promptForName(completion: {})
    }

    @objc private func showProPaywall() {}
    @objc private func noop() {}

    // MARK: - Contacts

    @IBAction func contactsTapped(_ sender: UIButton) {
        let ac = UIAlertController(title: "Contacts", message: nil, preferredStyle: .actionSheet)

        ac.addAction(UIAlertAction(title: "Text Contacts", style: .default) { [weak self] _ in
            self?.openTextHub()
        })

        ac.addAction(UIAlertAction(title: "Manage Contacts", style: .default) { [weak self] _ in
            self?.openContactsManager()
        })

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
            pop.permittedArrowDirections = [.up, .down]
        }

        present(ac, animated: true)
    }

    @IBAction func textHubTapped(_ sender: UIButton) {
        contactsTapped(sender)
    }

    private func openTextHub() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "TextVC")
        navigationController?.pushViewController(vc, animated: true)
    }

    private func openContactsManager() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "ContactsViewController")
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Stats

    @IBAction func friendsStatsTapped(_ sender: UIButton) { handleFriendStatsTapped(sender) }
    @IBAction func friendStatsTapped(_ sender: UIButton) { handleFriendStatsTapped(sender) }

    private func handleFriendStatsTapped(_ sender: UIButton) {
        openFriendStatsScreen()
    }

    @IBAction func myStatsTapped(_ sender: UIButton) {
        showMyStatsAlert(anchor: sender)
    }

    @IBAction func statsTapped(_ sender: UIButton) {
        let ac = UIAlertController(title: "Stats", message: nil, preferredStyle: .actionSheet)

        ac.addAction(UIAlertAction(title: "Player Stats", style: .default) { [weak self] _ in
            self?.openPlayerStats(anchor: sender)
        })

        ac.addAction(UIAlertAction(title: "Home Course Summary", style: .default) { [weak self] _ in
            self?.openCourseSummaryScreen()
        })

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
            pop.permittedArrowDirections = [.up, .down]
        }

        present(ac, animated: true)
    }

    private func openPlayerStats(anchor: UIView) {
        openFriendStatsScreen()
    }

    private func openCourseSummaryScreen() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "CourseSummaryViewController")
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            vc.modalPresentationStyle = .formSheet
            present(vc, animated: true)
        }
    }

    private func openFriendStatsScreen() {
        let vc = MyStatsViewController()
        vc.mode = .friends
        pushOrPresent(vc)
    }

    private func showStatsUpgradeBubble(anchor: UIView) {
        openFriendStatsScreen()
    }

    // MARK: - More

    @IBAction func moreTapped(_ sender: UIButton) {
        let ac = UIAlertController(title: "More", message: nil, preferredStyle: .actionSheet)

        ac.addAction(UIAlertAction(title: "Past Games", style: .default) { [weak self] _ in
            self?.openPastGames()
        })

        ac.addAction(UIAlertAction(title: "Explore the Rules", style: .default) { [weak self] _ in
            self?.openRules()
        })

        ac.addAction(UIAlertAction(title: "Delete History", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.deleteHistoryTapped(sender)
        })

        ac.addAction(UIAlertAction(title: "Check for Updates", style: .default) { [weak self] _ in
            guard let self else { return }
            UpdateChecker.shared.checkManually(from: self)
        })

        ac.addAction(UIAlertAction(title: "Rate WolfMore ★", style: .default) { _ in
            if let url = URL(string: "itms-apps://itunes.apple.com/app/id6755116882?action=write-review") {
                UIApplication.shared.open(url)
            }
        })

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
            pop.permittedArrowDirections = [.up, .down]
        }

        present(ac, animated: true)
    }

    private func openPastGames() {
        let vc = PastGamesViewController()
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }

    private func openRules() {
        let rules = RulesViewController()
        if let nav = navigationController {
            nav.pushViewController(rules, animated: true)
        } else {
            let wrap = UINavigationController(rootViewController: rules)
            wrap.modalPresentationStyle = .pageSheet
            present(wrap, animated: true)
        }
    }

    @IBAction private func rulesTapped(_ sender: UIButton) {
        openRules()
    }

    @IBAction private func courseSummaryTapped(_ sender: UIButton) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "CourseSummaryViewController")
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            vc.modalPresentationStyle = .formSheet
            present(vc, animated: true)
        }
    }

    // MARK: - Delete History

    @IBAction private func deleteHistoryTapped(_ sender: UIButton) {
        guard !RoundStore.shared.rounds.isEmpty else {
            let ac = UIAlertController(title: "No History", message: "No saved rounds yet.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            return
        }

        let ac = UIAlertController(
            title: "Delete History?",
            message: "This will permanently delete all saved rounds and stats on this device.",
            preferredStyle: .alert
        )

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            RoundStore.shared.clearAll()
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            let done = UIAlertController(title: "Deleted", message: "History cleared.", preferredStyle: .alert)
            done.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(done, animated: true)
        })

        present(ac, animated: true)
    }

    // MARK: - Tournament entry point

    private func buildTournamentButton() {
        let btn = UIButton(type: .system)
        var cfg = styledButton(title: "Stableford", style: .primary)
        cfg.baseBackgroundColor = UIColor(red: 0.22, green: 0.62, blue: 0.34, alpha: 1.0)
        btn.configuration = cfg
        btn.addTarget(self, action: #selector(tournamentTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        tournamentButton = btn
        view.addSubview(btn)
        // Anchor below courseButton (y≈542), which sits in the 148-pt gap before the chip row.
        // Anchoring below playGameButton (y≈461) would overlap courseButton at y=482.
        NSLayoutConstraint.activate([
            btn.centerXAnchor.constraint(equalTo: playGameButton.centerXAnchor),
            btn.topAnchor.constraint(equalTo: playGameButton.bottomAnchor, constant: 16),
            btn.widthAnchor.constraint(equalTo: playGameButton.widthAnchor),
        ])
    }

    // MARK: - Tee Games entry point

    private func buildTeeGamesButton() {
        guard let stablefordBtn = tournamentButton else { return }
        let btn = UIButton(type: .system)
        var cfg = styledButton(title: "Tee Games", style: .primary)
        cfg.baseBackgroundColor = UIColor(red: 0.20, green: 0.47, blue: 0.78, alpha: 1.0)
        btn.configuration = cfg
        btn.addTarget(self, action: #selector(teeGamesTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        teeGamesButton = btn
        view.addSubview(btn)
        NSLayoutConstraint.activate([
            btn.centerXAnchor.constraint(equalTo: playGameButton.centerXAnchor),
            btn.topAnchor.constraint(equalTo: stablefordBtn.bottomAnchor, constant: 10),
            btn.widthAnchor.constraint(equalTo: playGameButton.widthAnchor),
        ])
    }

    @objc private func teeGamesTapped() {
        let vc = TeeGamesViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }

    @objc private func tournamentTapped() {
        // Ensure the saved game is loaded into memory so we can inspect its type.
        if GameManager.shared.currentGame == nil {
            _ = GameManager.shared.loadLastOpened(notify: false)
        }
        let current = GameManager.shared.currentGame

        if current?.resolvedGameType == .tournament {
            let hasHolesPlayed = current?.holeCommitted.contains(true) ?? false
            if hasHolesPlayed {
                // Active tournament — offer continue or new
                let ac = UIAlertController(title: "Tournament in Progress",
                                           message: nil, preferredStyle: .actionSheet)
                ac.addAction(UIAlertAction(title: "Continue Tournament", style: .default) { [weak self] _ in
                    self?.performSegue(withIdentifier: "showPlayerSetup", sender: self)
                })
                ac.addAction(UIAlertAction(title: "New Tournament", style: .destructive) { [weak self] _ in
                    self?.confirmNewTournament()
                })
                ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                if let pop = ac.popoverPresentationController {
                    pop.sourceView = tournamentButton ?? view
                    pop.sourceRect = tournamentButton?.bounds ?? view.bounds
                }
                present(ac, animated: true)
            } else {
                // Tournament set up but no holes played yet — go straight to player setup
                performSegue(withIdentifier: "showPlayerSetup", sender: self)
            }
        } else if GameManager.shared.hasSavedGame {
            // Different game type in progress — warn before wiping
            let ac = UIAlertController(
                title: "Start Stableford?",
                message: "This will delete your previous game data.",
                preferredStyle: .alert
            )
            ac.addAction(UIAlertAction(title: "Start Stableford", style: .destructive) { [weak self] _ in
                self?.launchTournament()
            })
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(ac, animated: true)
        } else {
            launchTournament()
        }
    }

    private func confirmNewTournament() {
        let ac = UIAlertController(
            title: "Start New Tournament?",
            message: "This will delete your current tournament data.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "Start New", style: .destructive) { [weak self] _ in
            self?.launchTournament()
        })
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }

    private func launchTournament() {
        if GameManager.shared.currentGame == nil {
            GameManager.shared.startNewGame()
        } else {
            GameManager.shared.resetForNewRoundPreservingCourseAndRoster()
        }
        GameManager.shared.update { g in g.gameType = .tournament }
        presentManagePlayers()
    }

    // MARK: - Quick Start

    private weak var quickStartButton: UIButton?

    private func buildQuickStartButton() {
        var cfg = UIButton.Configuration.tinted()
        cfg.title = "⚡ Quick Start"
        cfg.subtitle = "Skip contacts · type player names on next screen"
        cfg.baseBackgroundColor = .systemOrange
        cfg.baseForegroundColor = .systemOrange
        cfg.cornerStyle = .large
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs; a.font = UIFont.systemFont(ofSize: 15, weight: .semibold); return a
        }
        cfg.subtitleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs; a.font = UIFont.systemFont(ofSize: 12, weight: .regular); return a
        }
        let btn = UIButton(configuration: cfg)
        btn.addTarget(self, action: #selector(quickStartHomeTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        quickStartButton = btn
        view.addSubview(btn)
        NSLayoutConstraint.activate([
            btn.centerXAnchor.constraint(equalTo: playGameButton.centerXAnchor),
            btn.bottomAnchor.constraint(equalTo: playGameButton.topAnchor, constant: -12),
            btn.widthAnchor.constraint(equalTo: playGameButton.widthAnchor),
        ])
    }

    @objc private func quickStartHomeTapped() {
        guard GameManager.shared.hasSavedGame else {
            doQuickStart()
            return
        }
        let alert = UIAlertController(
            title: "Quick Start",
            message: "Your current game data will be cleared. Continue?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Clear & Start", style: .destructive) { [weak self] _ in
            self?.doQuickStart()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func doQuickStart() {
        let rawName = (ProfileStore.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let name = (rawName.isEmpty || rawName == "Player 1") ? "Player 1" : rawName

        let idsToArchive = GameManager.shared.currentGame?.remoteMatchIds ?? []
        Task { for id in idsToArchive { try? await SupabaseService.shared.archiveMatch(id: id) } }

        GameManager.shared.startNewGame(name: "New Game")
        GameManager.shared.update { g in
            g.playerNames     = Array(repeating: "",    count: MAX_PLAYERS)
            g.hcPlayers       = Array(repeating: 0,     count: MAX_PLAYERS)
            g.playerActivated = Array(repeating: false, count: MAX_PLAYERS)

            g.playerNames[0]     = name
            g.hcPlayers[0]       = ProfileStore.myHC
            g.playerActivated[0] = true

            if let cid = CourseLibrary.shared.selectedCourseID,
               let course = CourseLibrary.shared.get(id: cid) {
                g.course.pars          = Array(course.pars.prefix(STANDARD_HOLES))
                g.course.holeHandicaps = Array(course.hcs.prefix(STANDARD_HOLES))
                g.course.name          = course.name
                g.course.id            = course.id
            }

            g.nassauState = NassauEngine.makeDefaultState(
                playerNames: g.playerNames,
                activeFlags: g.playerActivated
            )
            if var ns = g.nassauState {
                NassauEngine.recalculate(state: &ns, gameData: g)
                g.nassauState = ns
            }
            g.hole = 0
        }

        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let roundNav = sb.instantiateViewController(withIdentifier: "RoundNav") as? UINavigationController else { return }
        present(roundNav, animated: true)
    }

    // MARK: - Watch Live

    private let watchedSessionsKey = "watchedWolfSessions"

    private func buildWatchLiveButton() {
        let btn = UIButton(type: .system)
        btn.addTarget(self, action: #selector(watchLiveTapped), for: .touchUpInside)
        let lp = UILongPressGestureRecognizer(target: self, action: #selector(watchLiveLongPressed))
        btn.addGestureRecognizer(lp)
        btn.translatesAutoresizingMaskIntoConstraints = false
        watchLiveButton = btn
        view.addSubview(btn)
        NSLayoutConstraint.activate([
            btn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            btn.topAnchor.constraint(equalTo: moreButton.bottomAnchor, constant: 12),
        ])
        refreshWatchLiveButton()
    }

    @objc private func watchLiveLongPressed(_ gr: UILongPressGestureRecognizer) {
        guard gr.state == .began else { return }
        let saved = UserDefaults.standard.stringArray(forKey: watchedSessionsKey) ?? []
        guard !saved.isEmpty else { return }
        let alert = UIAlertController(
            title: "Clear Saved Sessions?",
            message: "Stop watching \(saved.count) saved game(s).",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Clear All", style: .destructive) { [weak self] _ in
            guard let self else { return }
            UserDefaults.standard.removeObject(forKey: self.watchedSessionsKey)
            self.refreshWatchLiveButton()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func refreshWatchLiveButton() {
        guard let btn = watchLiveButton else { return }
        let saved = UserDefaults.standard.stringArray(forKey: watchedSessionsKey) ?? []
        let title = saved.isEmpty ? "Watch Live" : "● Watch Live"
        btn.configuration = styledButton(title: title, style: .utilityChip)
    }

    @objc private func watchLiveTapped() {
        let saved = UserDefaults.standard.stringArray(forKey: watchedSessionsKey) ?? []

        guard !saved.isEmpty else {
            showWatchLiveAlert()
            return
        }

        // Concurrently check which saved sessions are still active
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

            DispatchQueue.main.async {
                if !activeCodes.isEmpty {
                    // Go directly — spectator VC will reload from UserDefaults
                    let vc = WolfSpectatorViewController()
                    vc.sessionCode = ""
                    self.navigationController?.pushViewController(vc, animated: true)
                } else {
                    // All saved sessions ended — clear and show alert
                    UserDefaults.standard.removeObject(forKey: self.watchedSessionsKey)
                    self.refreshWatchLiveButton()
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
                DispatchQueue.main.async {
                    let vc = WolfSpectatorViewController()
                    vc.sessionCode = session.code
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            } catch {
                DispatchQueue.main.async {
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

    private func presentManagePlayers() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let manage = sb.instantiateViewController(withIdentifier: "ManagePlayersVC") as! ManagePlayersViewController
        let nav = UINavigationController(rootViewController: manage)
        nav.modalPresentationStyle = .fullScreen
        nav.isModalInPresentation = true
        present(nav, animated: true)
    }

    private func pushOrPresent(_ vc: UIViewController) {
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            let wrap = UINavigationController(rootViewController: vc)
            wrap.modalPresentationStyle = .pageSheet
            present(wrap, animated: true)
        }
    }

    // MARK: - UI Helpers

    private func fixIconButton(_ b: UIButton) {
        b.imageView?.contentMode = .scaleAspectFit
        b.contentHorizontalAlignment = .fill
        b.contentVerticalAlignment = .fill
        b.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }

    private func configurePlayButtonTitle() {
        playGameButton.titleLabel?.textAlignment = .center
        playGameButton.titleLabel?.numberOfLines = 2
        playGameButton.titleLabel?.lineBreakMode = .byWordWrapping
        playGameButton.contentHorizontalAlignment = .center
        playGameButton.contentVerticalAlignment = .center
        playGameButton.titleLabel?.adjustsFontForContentSizeCategory = true
    }

    private func configureImageButtons() {
        configureImageButton(editCourseButton, imageName: "EditCourse")
        configureImageButton(playGameButton, imageName: "PlayGame")
    }

    private func configureImageButton(_ button: UIButton, imageName: String) {
        button.setImage(UIImage(named: imageName), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
    }

    private func yellowPillConfig(title: String, trailingChevron: Bool = false) -> UIButton.Configuration {
        var config = UIButton.Configuration.filled()

        config.baseBackgroundColor = .systemYellow
        config.baseForegroundColor = .label
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)

        let p = NSMutableParagraphStyle()
        p.alignment = .center
        p.lineBreakMode = .byTruncatingTail

        let attrs = AttributeContainer([
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .paragraphStyle: p
        ])

        config.attributedTitle = AttributedString(title, attributes: attrs)
        config.titleAlignment = .center
        config.titleLineBreakMode = .byTruncatingTail

        if trailingChevron {
            config.image = UIImage(systemName: "chevron.down")
            config.imagePlacement = .trailing
            config.imagePadding = 8
        }

        return config
    }

    private func makePillConfig(
        title: String,
        fill: UIColor,
        text: UIColor,
        bordered: Bool,
        trailingChevron: Bool = false
    ) -> UIButton.Configuration {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = fill
        config.baseForegroundColor = text
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 18, bottom: 12, trailing: 18)

        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
            return out
        }

        if bordered {
            config.background.strokeColor = UIColor.systemGray4
            config.background.strokeWidth = 1
        }

        if trailingChevron {
            config.image = UIImage(systemName: "chevron.down")
            config.imagePlacement = .trailing
            config.imagePadding = 8
        }

        return config
    }

    private enum ButtonStyle {
        case primary
        case secondaryChevron
        case utilityChip
    }

    private func styledButton(
        title: String,
        style: ButtonStyle,
        systemImage: String? = nil
    ) -> UIButton.Configuration {
        var config = UIButton.Configuration.filled()

        config.cornerStyle = .capsule
        config.titleAlignment = .center
        config.titleLineBreakMode = .byTruncatingTail

        let p = NSMutableParagraphStyle()
        p.alignment = .center
        p.lineBreakMode = .byTruncatingTail

        func setTitle(_ text: String, size: CGFloat, weight: UIFont.Weight) {
            let attrs = AttributeContainer([
                .font: UIFont.systemFont(ofSize: size, weight: weight),
                .paragraphStyle: p
            ])
            config.attributedTitle = AttributedString(text, attributes: attrs)
        }

        switch style {
        case .primary:
            config.baseBackgroundColor = wolfPrimaryGreen
            config.baseForegroundColor = .white
            config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 18, bottom: 12, trailing: 18)
            setTitle(title, size: 16, weight: .medium)

        case .secondaryChevron:
            config.baseBackgroundColor = wolfGold
            config.baseForegroundColor = .label
            config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 28)
            setTitle(title, size: 16, weight: .semibold)
            config.image = UIImage(systemName: "chevron.down")
            config.imagePlacement = .trailing
            config.imagePadding = 10

        case .utilityChip:
            config.baseBackgroundColor = .systemGray5
            config.baseForegroundColor = .label
            config.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
            setTitle(title, size: 13.5, weight: .medium)
        }

        if let systemImage {
            config.image = UIImage(systemName: systemImage)
        }

        return config
    }

    private var wolfGreen: UIColor {
        UIColor(red: 0.12, green: 0.28, blue: 0.14, alpha: 1.0)
    }

    private var wolfPrimaryGreen: UIColor {
        UIColor(red: 0.10, green: 0.33, blue: 0.18, alpha: 1.0)
    }

    private var wolfGold: UIColor {
        UIColor(red: 0.93, green: 0.74, blue: 0.10, alpha: 1.0)
    }
}

// MARK: - Stats Helpers
extension ViewController {

    func showMyStatsAlert(anchor: UIView) {
        let ac = UIAlertController(title: "My Stats", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Open My Stats", style: .default) { [weak self] _ in
            self?.openMyStatsScreen()
        })
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presentActionSheet(ac, anchor: anchor)
    }

    private func presentActionSheet(_ ac: UIAlertController, anchor: UIView) {
        if let pop = ac.popoverPresentationController {
            pop.sourceView = anchor
            pop.sourceRect = anchor.bounds
            pop.permittedArrowDirections = [.up, .down]
        }
        present(ac, animated: true)
    }

    private func openMyStatsScreen() {
        let vc = MyStatsViewController()
        vc.mode = .me
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            let wrap = UINavigationController(rootViewController: vc)
            wrap.modalPresentationStyle = .pageSheet
            present(wrap, animated: true)
        }
    }
}
