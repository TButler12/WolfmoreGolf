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

        refreshCourseButtonTitle()
        refreshPlayArea()
        refreshBottomButtons()

        fixIconButton(editCourseButton)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(noop),
            name: .roundSaveBlockedNeedsPro,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateWelcome()
        refreshCourseButtonTitle()
        refreshPlayArea()
        refreshBottomButtons()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        runFirstLaunchPromptsIfNeeded()
        refreshPlayArea()
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
        let name = CourseLibrary.shared.selectedCourseName ?? "Choose Course"
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
            ProfileStore.name = "Player 1"
            shouldPromptForName = true
        }
    }

    // MARK: - Welcome

    private func updateWelcome() {
        let name = (ProfileStore.name ?? "Player 1")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        welcomeLabel.text = "       Welcome, \(name)"
        welcomeLabel.textAlignment = .center
        welcomeLabel.adjustsFontForContentSizeCategory = true
        welcomeLabel.adjustsFontSizeToFitWidth = true
        welcomeLabel.minimumScaleFactor = 0.8
    }

    // MARK: - First Launch / Onboarding Flow

    private func runFirstLaunchPromptsIfNeeded() {
        guard presentedViewController == nil else { return }

        if shouldPromptForName || (ProfileStore.name == "Player 1") {
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
            title: "    Welcome!",
            message: "What should we call you?",
            preferredStyle: .alert
        )

        ac.addTextField { tf in
            tf.placeholder = "Your name"
            tf.text = (ProfileStore.name == "Player 1") ? "" : ProfileStore.name
            tf.autocapitalizationType = .words
            tf.clearButtonMode = .whileEditing
        }

        ac.addAction(UIAlertAction(title: "Skip", style: .cancel) { _ in
            completion()
        })

        ac.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            let name = (ac.textFields?.first?.text ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !name.isEmpty {
                ProfileStore.name = name
                self?.updateWelcome()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
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
        let vc = sb.instantiateViewController(withIdentifier: "CourseSetupVC")
        navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction private func courseButtonTapped(_ sender: Any) {
        let sb = UIStoryboard(name: "Main", bundle: nil)

        guard let picker = sb.instantiateViewController(withIdentifier: "CoursePickerVC") as? CoursePickerViewController else {
            assertionFailure("CoursePickerVC storyboard id / class mismatch")
            return
        }

        picker.onPickCourse = { [weak self] id in
            CourseLibrary.shared.selectedCourseID = id

            if let c = CourseLibrary.shared.get(id: id) {
                GameManager.shared.update { g in
                    g.course.pars = Array(c.pars.prefix(STANDARD_HOLES))
                    g.course.holeHandicaps = Array(c.hcs.prefix(STANDARD_HOLES))
                }
            }

            self?.refreshCourseButtonTitle()
            self?.dismiss(animated: true)
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
            self?.presentManagePlayers()
        })

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
        }

        present(ac, animated: true)
    }

    @IBAction private func playNewGameTapped(_ sender: UIButton) {
        presentManagePlayers()
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

        ac.addAction(UIAlertAction(title: "Explore the Rules", style: .default) { [weak self] _ in
            self?.openRules()
        })

        ac.addAction(UIAlertAction(title: "Delete History", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.deleteHistoryTapped(sender)
        })

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
            pop.permittedArrowDirections = [.up, .down]
        }

        present(ac, animated: true)
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
        config.baseForegroundColor = .black
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
            config.baseForegroundColor = .black
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
