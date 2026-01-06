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
    // MARK: - State
    private var shouldPromptForName = false

    // MARK: - Home Course Prompt Key
    private let didPromptHomeCourseKey = "profile.didPromptHomeCourse_v1"

    private var didPromptHomeCourse: Bool {
        get { UserDefaults.standard.bool(forKey: didPromptHomeCourseKey) }
        set { UserDefaults.standard.set(newValue, forKey: didPromptHomeCourseKey) }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        configureImageButtons()
        configurePlayButtonTitle()

        seedProfileNameIfNeeded()
        updateWelcome()
        fixIconButton(editCourseButton)
        

    }
    private func fixIconButton(_ b: UIButton) {
        b.imageView?.contentMode = .scaleAspectFit
        b.contentHorizontalAlignment = .fill
        b.contentVerticalAlignment = .fill
        b.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateWelcome()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        runFirstLaunchPromptsIfNeeded()
    }

    // MARK: - Actions (Stats)
    @IBAction func myStatsTapped(_ sender: UIButton) {
        showMyStatsAlert(anchor: sender)
    }

    @IBAction func friendsStatsTapped(_ sender: UIButton) {
        showFriendStatsAlert(anchor: sender)
    }

    // MARK: - Setup helpers
    private func seedProfileNameIfNeeded() {
        if ProfileStore.name == nil {
            ProfileStore.name = "Player 1"
            shouldPromptForName = true
        }
    }

    private func configurePlayButtonTitle() {
        playGameButton.titleLabel?.textAlignment = .center
        playGameButton.titleLabel?.numberOfLines = 2
        playGameButton.titleLabel?.lineBreakMode = .byWordWrapping
        playGameButton.contentHorizontalAlignment = .center
        playGameButton.contentVerticalAlignment = .center
        playGameButton.titleLabel?.adjustsFontForContentSizeCategory = true
    }

    private func runFirstLaunchPromptsIfNeeded() {
        // Don’t stack alerts.
        guard presentedViewController == nil else { return }

        // 1) Prompt for name (first)
        if shouldPromptForName || (ProfileStore.name == "Player 1") {
            shouldPromptForName = false
            promptForName { [weak self] in
                self?.runHomeCoursePromptIfNeeded()
            }
            return
        }

        // 2) Then prompt for Home Course (if needed)
        runHomeCoursePromptIfNeeded()
    }

    // MARK: - Welcome
    private func updateWelcome() {
        let name = (ProfileStore.name ?? "Player 1")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        welcomeLabel.text = "      Welcome, \(name)"
        welcomeLabel.textAlignment = .center
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

    // MARK: - Home course prompt
    private func hasHomeCourseSet() -> Bool {
        let id = (ProfileStore.homeCourseID ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return UUID(uuidString: id) != nil
    }

    private func runHomeCoursePromptIfNeeded() {
        guard presentedViewController == nil else { return }
        guard !didPromptHomeCourse else { return }

        // If already set, mark prompted and stop
        guard !hasHomeCourseSet() else {
            didPromptHomeCourse = true
            return
        }

        didPromptHomeCourse = true
        setEditCourseGlow(true)

        let ac = UIAlertController(
            title: "Set your Home Course?",
            message: "Home Course is used for tracking Hole Stats and Friend Stats. Want to set it now?",
            preferredStyle: .alert
        )

        ac.addAction(UIAlertAction(title: "Not now", style: .cancel) { [weak self] _ in
            self?.setEditCourseGlow(false)
        })

        ac.addAction(UIAlertAction(title: "Yes", style: .default) { [weak self] _ in
            self?.setEditCourseGlow(false)
            self?.openCourseSetup(nil)
        })

        present(ac, animated: true)
    }

    // MARK: - Glow
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

    // MARK: - Button appearance
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

    // MARK: - Navigation
    @IBAction private func openCourseSetup(_ sender: Any? = nil) {
        // Keep using your existing storyboard ID for Edit Course flow
        performSegue(withIdentifier: "showCourseHC", sender: sender)
    }

    private func pushGameVC() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "GameViewController")

        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
        }
    }

    // MARK: - Start Modes
    @IBAction private func startWolfTapped(_ sender: UIButton) {
        GameManager.shared.startNewGame()
        GameManager.shared.update { g in
            g.gameType = .wolf
            g.normalize()
        }
        pushGameVC()
    }

    @IBAction private func startScotchTapped(_ sender: UIButton) {
        GameManager.shared.startNewGame()
        GameManager.shared.update { g in
            g.gameType = .sixPointScotch
            g.normalize()
        }
        pushGameVC()
    }

    // MARK: - Actions (your original ones)
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
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CourseSummaryViewController")
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            vc.modalPresentationStyle = .formSheet
            present(vc, animated: true)
        }
    }

    @IBAction private func startNewGameTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "showPlayerSetup", sender: self)
    }

    @IBAction private func loadSavedGameTapped(_ sender: UIButton) {
        if GameManager.shared.loadLastOpened() {
            performSegue(withIdentifier: "showGame", sender: self)
        } else {
            let ac = UIAlertController(
                title: "No Saved Game",
                message: "You don’t have a saved game yet. Start a new one?",
                preferredStyle: .alert
            )
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            ac.addAction(UIAlertAction(title: "Start New", style: .default) { [weak self] _ in
                self?.performSegue(withIdentifier: "showPlayerSetup", sender: self)
            })
            present(ac, animated: true)
        }
    }

    @IBAction private func editCourseTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "showCourseHC", sender: self)
    }
}

// MARK: - Stats helpers (adds back showMyStatsAlert / showFriendStatsAlert)
extension ViewController {

    func showMyStatsAlert(anchor: UIView) {
        let ac = UIAlertController(title: "My Stats", message: nil, preferredStyle: .actionSheet)

        ac.addAction(UIAlertAction(title: "Open My Stats", style: .default) { [weak self] _ in
            self?.openMyStatsScreen()
        })

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presentActionSheet(ac, anchor: anchor)
    }

    func showFriendStatsAlert(anchor: UIView) {
        let ac = UIAlertController(title: "Friend Stats", message: nil, preferredStyle: .actionSheet)

        ac.addAction(UIAlertAction(title: "Open Friend Stats", style: .default) { [weak self] _ in
            self?.openFriendStatsScreen()
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

    private func pushOrPresent(_ vc: UIViewController) {
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            let wrap = UINavigationController(rootViewController: vc)
            wrap.modalPresentationStyle = .pageSheet
            present(wrap, animated: true)
        }
    }

    private func openMyStatsScreen() {
        let vc = MyStatsViewController()
        vc.mode = .me
        pushOrPresent(vc)
    }

    private func openFriendStatsScreen() {
        let vc = MyStatsViewController()
        vc.mode = .friends
        pushOrPresent(vc)
    }
    @IBAction private func deleteHistoryTapped(_ sender: UIButton) {
        print("✅ deleteHistoryTapped fired") // remove after testing

        // Nothing to delete? (optional)
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
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Force full screen on iPad for these flows
        if UIDevice.current.userInterfaceIdiom == .pad {
            switch segue.identifier {
            case "showGame", "showPlayerSetup", "showCourseHC":
                if let nav = segue.destination as? UINavigationController {
                    nav.modalPresentationStyle = .fullScreen
                } else {
                    segue.destination.modalPresentationStyle = .fullScreen
                }
            default:
                break
            }
        }
    }

}
