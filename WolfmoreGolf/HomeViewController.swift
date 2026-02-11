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
    @IBOutlet private weak var editCourseButton: UIButton!
    @IBOutlet private weak var playGameButton: UIButton!
    @IBOutlet private weak var playNewGameButton: UIButton!
    @IBOutlet private weak var continueButton: UIButton!
    @IBOutlet private weak var joinProButton: UIButton!

    // MARK: - State
    private var shouldPromptForName = false

    // ✅ Use ONE Pro source of truth everywhere
    private var isPro: Bool { Entitlements.shared.isPro }
    private var completedRounds: Int {
        RoundStore.shared.uniqueGameCount   // ✅ true round count
    }

    private var canUseStatsFreeTier: Bool {
        Entitlements.shared.isPro || completedRounds < 10
    }

    // MARK: - Home Course Prompt Key
    private let didPromptHomeCourseKey = "profile.didPromptHomeCourse_v1"

    private var didPromptHomeCourse: Bool {
        get { UserDefaults.standard.bool(forKey: didPromptHomeCourseKey) }
        set { UserDefaults.standard.set(newValue, forKey: didPromptHomeCourseKey) }
    }

    private var proObserver: NSObjectProtocol?

    deinit {
        if let proObserver { NotificationCenter.default.removeObserver(proObserver) }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        migrateHomeCourseIfNeeded()

        configureImageButtons()
        configurePlayButtonTitle()
        fixIconButton(editCourseButton)

        seedProfileNameIfNeeded()
        updateWelcome()

        // ✅ Safer than addObserver(selector:) + prevents duplicate observers
   
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateWelcome()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        runFirstLaunchPromptsIfNeeded()
    }

    // MARK: - Migration
    private func migrateHomeCourseIfNeeded() {
        let raw = ProfileStore.homeCourseID.trimmingCharacters(in: .whitespacesAndNewlines)
        if !raw.isEmpty, UUID(uuidString: raw) == nil {
            ProfileStore.homeCourseID = ""
            UserDefaults.standard.removeObject(forKey: didPromptHomeCourseKey)
        }
    }

    // MARK: - Paywall
    @IBAction private func joinProTapped(_ sender: UIButton) {
        showProPaywall()
    }

    @objc private func showProPaywall() {
        let vc = ProViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }

    // MARK: - UI helpers
    private func fixIconButton(_ b: UIButton) {
        b.imageView?.contentMode = .scaleAspectFit
        b.contentHorizontalAlignment = .fill
        b.contentVerticalAlignment = .fill
        b.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }

    private func configurePlayButtonTitle() {
        // NOTE: If you want multi-line title on an image button, do NOT set titleLabel?.text directly.
        // Keep this; it affects wrapping/centering.
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
        // If you have images for the others, add them here too.
    }

    private func configureImageButton(_ button: UIButton, imageName: String) {
        button.setImage(UIImage(named: imageName), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
    }

    // MARK: - Setup helpers
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

        welcomeLabel.text = "Welcome, \(name)"
        welcomeLabel.textAlignment = .center
        welcomeLabel.adjustsFontForContentSizeCategory = true
        welcomeLabel.adjustsFontSizeToFitWidth = true
        welcomeLabel.minimumScaleFactor = 0.8
    }

    // MARK: - First launch prompts
    private func runFirstLaunchPromptsIfNeeded() {
        // ✅ Don’t stack prompts or show over another modal
        guard presentedViewController == nil else { return }
        // ✅ Don’t show prompts if user navigated away immediately
        guard navigationController?.topViewController === self else { return }

        if shouldPromptForName || (ProfileStore.name == "Player 1") {
            shouldPromptForName = false
            promptForName { [weak self] in
                self?.runHomeCoursePromptIfNeeded()
            }
            return
        }

        runHomeCoursePromptIfNeeded()
    }

    private func promptForName(completion: @escaping () -> Void) {
        let ac = UIAlertController(
            title: "Welcome!",
            message: "What should we call you?",
            preferredStyle: .alert
        )

        ac.addTextField { tf in
            tf.placeholder = "Your name"
            tf.text = (ProfileStore.name == "Player 1") ? "" : ProfileStore.name
            tf.autocapitalizationType = .words
            tf.clearButtonMode = .whileEditing
        }

        ac.addAction(UIAlertAction(title: "Skip", style: .cancel) { _ in completion() })

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

    // MARK: - Home course prompt
    private func hasHomeCourseSet() -> Bool {
        let id = ProfileStore.homeCourseID.trimmingCharacters(in: .whitespacesAndNewlines)
        return UUID(uuidString: id) != nil
    }

    private func runHomeCoursePromptIfNeeded() {
        guard presentedViewController == nil else { return }
        guard !didPromptHomeCourse else { return }

        guard !hasHomeCourseSet() else {
            didPromptHomeCourse = true
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
        })

        ac.addAction(UIAlertAction(title: "Yes", style: .default) { [weak self] _ in
            self?.didPromptHomeCourse = true
            self?.setEditCourseGlow(false)
            self?.openCourseSetup(nil)
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

    // MARK: - Actions (Stats)
    // Keep BOTH names so old storyboard wiring won’t crash.
    @IBAction func friendsStatsTapped(_ sender: UIButton) { handleFriendStatsTapped(sender) }
    @IBAction func friendStatsTapped(_ sender: UIButton)  { handleFriendStatsTapped(sender) }

    private func handleFriendStatsTapped(_ sender: UIButton) {

        // ✅ If already Pro, just go straight in
        guard !ProStore.shared.isPro else {
            openFriendStatsScreen()
            return
        }

        // ✅ If NOT Pro, show choice popup first
        let ac = UIAlertController(
            title: "WolfMore Pro",
            message: "View stats now, or upgrade to unlock unlimited history + full stats.",
            preferredStyle: .actionSheet
        )

        ac.addAction(UIAlertAction(title: "View Stats", style: .default) { [weak self] _ in
            self?.openFriendStatsScreen()
        })

        ac.addAction(UIAlertAction(title: "Join Pro", style: .default) { [weak self] _ in
            self?.showProPaywall()
        })

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // iPad safe anchor
        if let pop = ac.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
            pop.permittedArrowDirections = [.up, .down]
        }

        present(ac, animated: true)
    }


    @IBAction func textHubTapped(_ sender: UIButton) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "TextVC")
        navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func myStatsTapped(_ sender: UIButton) {
        showMyStatsAlert(anchor: sender)
    }

    @IBAction func contactsTapped(_ sender: UIButton) {
        let vc = storyboard!.instantiateViewController(withIdentifier: "ContactsViewController")
        navigationController?.pushViewController(vc, animated: true)
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
        ac.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            RoundStore.shared.clearAll()
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            let done = UIAlertController(title: "Deleted", message: "History cleared.", preferredStyle: .alert)
            done.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(done, animated: true)
        })

        present(ac, animated: true)
    }

    // MARK: - Upsell Bubble
    private func showStatsUpgradeBubble(anchor: UIView) {
        let ac = UIAlertController(
            title: "WolfMore Pro",
            message: "Unlock full stats and unlimited history.",
            preferredStyle: .actionSheet
        )

        ac.addAction(UIAlertAction(title: "Upgrade to Pro", style: .default) { [weak self] _ in
            self?.showProPaywall()
        })

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.sourceView = anchor
            pop.sourceRect = anchor.bounds
            pop.permittedArrowDirections = [.up, .down]
        }

        present(ac, animated: true)
    }

    // MARK: - Navigation
    @IBAction private func openCourseSetup(_ sender: Any? = nil) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "CourseSetupVC")

        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            let wrap = UINavigationController(rootViewController: vc)
            wrap.modalPresentationStyle = .fullScreen
            present(wrap, animated: true)
        }
    }

    // Keep these names so old wiring won’t crash.
    @IBAction private func editCourseTapped(_ sender: UIButton) {
        openCourseSetup(sender)
    }

    @IBAction private func playNewGameTapped(_ sender: UIButton) {
        presentManagePlayers()
    }

    @IBAction private func continueGameTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "showPlayerSetup", sender: self)
    }

    @IBAction private func rulesTapped(_ sender: UIButton) {
        let rules = RulesViewController()
        pushOrPresent(rules, style: .pageSheet)
    }

    @IBAction private func courseSummaryTapped(_ sender: UIButton) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "CourseSummaryViewController")
        pushOrPresent(vc, style: .formSheet)
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

    private func openFriendStatsScreen() {
        let vc = MyStatsViewController()
        vc.mode = .friends
        pushOrPresent(vc, style: .pageSheet)
    }

    private func pushOrPresent(_ vc: UIViewController, style: UIModalPresentationStyle) {
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            let wrap = UINavigationController(rootViewController: vc)
            wrap.modalPresentationStyle = style
            present(wrap, animated: true)
        }
    }
    
}

// MARK: - Stats helpers
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
