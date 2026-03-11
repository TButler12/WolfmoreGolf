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
    // ✅ Legacy storyboard connection safety (prevents crash if something is still wired to playTapped:)
   
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

    // MARK: - Home Course Prompt Key
    private let didPromptHomeCourseKey = "profile.didPromptHomeCourse_v1"

    private var didPromptHomeCourse: Bool {
        get { UserDefaults.standard.bool(forKey: didPromptHomeCourseKey) }
        set { UserDefaults.standard.set(newValue, forKey: didPromptHomeCourseKey) }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Lifecycle
  
    override func viewDidLoad() {
        super.viewDidLoad()
        // Apple-ish nav
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
               selector: #selector(showProPaywall),
               name: .roundSaveBlockedNeedsPro,
               object: nil
           )
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
            selector: #selector(showProPaywall),
            name: .roundSaveBlockedNeedsPro,
            object: nil
        )
    }
    private func refreshCourseButtonTitle() {
        let name = CourseLibrary.shared.selectedCourseName ?? "Choose Course"
        courseButton.configuration = styledButton(title: name, style: .secondaryChevron)
    }
    private func styleCourseButton() {
        // Match your other pill buttons
        courseButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        courseButton.titleLabel?.adjustsFontForContentSizeCategory = true
        courseButton.titleLabel?.adjustsFontSizeToFitWidth = true
        courseButton.titleLabel?.minimumScaleFactor = 0.85
        courseButton.titleLabel?.lineBreakMode = .byTruncatingTail
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateWelcome()
        refreshCourseButtonTitle()
        refreshPlayArea()
        refreshBottomButtons()
    }
    private func updatePlayButtonTitle() {
        if GameManager.shared.hasSavedGame {
            playGameButton.setTitle("Continue Game", for: .normal)
        } else {
            playGameButton.setTitle("Start New Game", for: .normal)
        }
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
    private func openAddCourse() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "CourseSetupVC")
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // ✅ Legacy storyboard connection safety (prevents crash if something is still wired to playTapped:)
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
    
    private func yellowPillConfig(title: String, trailingChevron: Bool = false) -> UIButton.Configuration {
        var config = UIButton.Configuration.filled()

        config.baseBackgroundColor = .systemYellow
        config.baseForegroundColor = .black
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)

        // ✅ Center + single-line truncation
        let p = NSMutableParagraphStyle()
        p.alignment = .center
        p.lineBreakMode = .byTruncatingTail

        let attrs = AttributeContainer([
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .paragraphStyle: p
        ])

        config.attributedTitle = AttributedString(title, attributes: attrs)

        // ✅ iOS 15+ supported
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

        // font
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

    private func refreshPlayArea() {
        playGameButton.configuration = styledButton(title: "Play Game", style: .primary)

        playNewGameButton?.isHidden = true
        continueButton?.isHidden = true
    }
    private func refreshBottomButtons() {
        contactsButton.configuration = styledButton(title: "Contacts", style: .utilityChip)
        statsButton.configuration    = styledButton(title: "Stats", style: .utilityChip)
        moreButton.configuration     = styledButton(title: "More", style: .utilityChip)
    }
    private var wolfGreen: UIColor {
        UIColor(red: 0.12, green: 0.28, blue: 0.14, alpha: 1.0) // deep green
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
                    g.course.pars = Array(c.pars.prefix(18))
                    g.course.holeHandicaps = Array(c.hcs.prefix(18))
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

    // MARK: - Paywall
    @IBAction private func joinProTapped(_ sender: UIButton) {
        showProPaywall()
    }

    @objc private func showProPaywall() {
        let vc = ProGateViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet

        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }

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

        welcomeLabel.text = "       Welcome, \(name)"
        welcomeLabel.textAlignment = .center
        welcomeLabel.adjustsFontForContentSizeCategory = true
        welcomeLabel.adjustsFontSizeToFitWidth = true
        welcomeLabel.minimumScaleFactor = 0.8
    }

    // MARK: - First launch prompts
    private func runFirstLaunchPromptsIfNeeded() {
        guard presentedViewController == nil else { return }

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
    // Keep BOTH names so any old storyboard wiring won’t crash.
    @IBAction func friendsStatsTapped(_ sender: UIButton) { handleFriendStatsTapped(sender) }
    @IBAction func friendStatsTapped(_ sender: UIButton) { handleFriendStatsTapped(sender) }

    private func handleFriendStatsTapped(_ sender: UIButton) {
        if !Entitlements.shared.isPro {
            showStatsUpgradeBubble(anchor: sender)
            return
        }
        openFriendStatsScreen()
    }
    @IBAction func textHubTapped(_ sender: UIButton) {
        contactsTapped(sender) // reuse the new menu
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
        // Keep your current Pro gating behavior
        if !Entitlements.shared.isPro {
            showStatsUpgradeBubble(anchor: anchor)
            return
        }
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
    // MARK: - Delete History ✅ INCLUDED
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
    // MARK: - Button Styles (Clean Apple Utility)

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

        // Shared pill shape + typography
        config.cornerStyle = .capsule
        config.titleAlignment = .center
        config.titleLineBreakMode = .byTruncatingTail

        // Centered, single-line attributed title
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
            config.baseBackgroundColor = wolfPrimaryGreen   // ✅ was .systemGreen
            config.baseForegroundColor = .white
            config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 18, bottom: 12, trailing: 18)
            setTitle(title, size: 16, weight: .medium)

        case .secondaryChevron:
            config.baseBackgroundColor = wolfGold
            config.baseForegroundColor = .black

            // ✅ Course pill sizing (bigger than chips) + extra trailing for chevron centering
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

        // Optional leading/trailing image support if you want later
        if let systemImage {
            config.image = UIImage(systemName: systemImage)
        }

        return config
    }
    private var wolfPrimaryGreen: UIColor {
        UIColor(red: 0.10, green: 0.33, blue: 0.18, alpha: 1.0)
    }

    private var wolfGold: UIColor {
        UIColor(red: 0.93, green: 0.74, blue: 0.10, alpha: 1.0)
    }
    // MARK: - Upsell Bubble
    private func showStatsUpgradeBubble(anchor: UIView) {
        let ac = UIAlertController(
            title: "WolfMore Pro Annual",
            message: "Unlock full stats and unlimited history.",
            preferredStyle: .actionSheet
        )

        ac.addAction(UIAlertAction(title: "Open Friend Stats (Limited)", style: .default) { [weak self] _ in
            self?.openFriendStatsScreen()
        })

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

        guard let vc = sb.instantiateViewController(withIdentifier: "CourseSetupVC") as? CourseSetupViewController else {
            assertionFailure("CourseSetupVC storyboard id / class mismatch")
            return
        }

        // ✅ If user already chose a course on Home, load it
        vc.loadCourseID = CourseLibrary.shared.selectedCourseID

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
    @IBAction func moreTapped(_ sender: UIButton) {
        let ac = UIAlertController(title: "More", message: nil, preferredStyle: .actionSheet)

        ac.addAction(UIAlertAction(title: "Explore the Rules", style: .default) { [weak self] _ in
            self?.openRules()
        })

        ac.addAction(UIAlertAction(title: "Join Pro-Stat Access", style: .default) { [weak self] _ in
            self?.showProPaywall()
        })

        ac.addAction(UIAlertAction(title: "Delete History", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            // reuse your existing delete flow
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
        let rules = RulesViewController()
        if let nav = navigationController {
            nav.pushViewController(rules, animated: true)
        } else {
            let wrap = UINavigationController(rootViewController: rules)
            wrap.modalPresentationStyle = .pageSheet
            present(wrap, animated: true)
        }
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
        pushOrPresent(vc)
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
