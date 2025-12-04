//
//  ViewController.swift
//  Wolfmore
//
//  Created by Tom BUTLER on 9/24/25.
import UIKit

final class ViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet private weak var welcomeLabel: UILabel!
    @IBOutlet private weak var editCourseButton: UIButton!   // map / “Set Course” button
    @IBOutlet private weak var playGameButton: UIButton!     // green “Play Game” button

    // MARK: - State

    private var shouldPromptForName = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureImageButtons()          // ⬅️ make the buttons look right

        if ProfileStore.name == nil {    // first launch, no name yet
            ProfileStore.name = "Player 1"
            shouldPromptForName = true   // ask right after first show
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if shouldPromptForName || (ProfileStore.name == "Player 1") {
            shouldPromptForName = false
            promptForName()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateWelcome()
    }

    // MARK: - Name + Welcome

    private func promptForName() {
        let ac = UIAlertController(
            title: "Welcome!",
            message: "What should we call you?",
            preferredStyle: .alert
        )
        ac.addTextField { tf in
            tf.placeholder = "Your name"
            tf.autocapitalizationType = .words
            tf.clearButtonMode = .whileEditing
        }
        ac.addAction(UIAlertAction(title: "Skip", style: .cancel))
        ac.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            ProfileStore.name = ac.textFields?.first?.text
            self?.updateWelcome()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        })
        present(ac, animated: true)
    }

    private func updateWelcome() {
        let name = (ProfileStore.name ?? "Player 1")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        welcomeLabel.text = "Welcome, \(name)"
    }

    // MARK: - Button appearance

    private func configureImageButtons() {
        // Use your asset names here:
        configureImageButton(editCourseButton, imageName: "EditCourse")  // map icon
        configureImageButton(playGameButton, imageName: "PlayGame")      // flag icon
    }

    private func configureImageButton(_ button: UIButton, imageName: String) {
        button.setImage(UIImage(named: imageName), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill

        // If you have separate labels under the images, clear the button title:
        // button.setTitle("", for: .normal)
    }

    // MARK: - Actions

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

    @IBAction private func deleteHistoryTapped(_ sender: UIButton) {
        guard !RoundStore.shared.rounds.isEmpty else {
            let a = UIAlertController(
                title: "No History",
                message: "You don’t have any saved rounds yet.",
                preferredStyle: .alert
            )
            a.addAction(UIAlertAction(title: "OK", style: .default))
            present(a, animated: true)
            return
        }

        let ac = UIAlertController(
            title: "Delete History",
            message: "Choose what to delete.",
            preferredStyle: .alert
        )

        ac.addAction(UIAlertAction(title: "Delete Last Round", style: .destructive) { _ in
            RoundStore.shared.deleteLast()
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            let done = UIAlertController(
                title: "Last Round Deleted",
                message: "The most recent round was removed from history.",
                preferredStyle: .alert
            )
            done.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(done, animated: true)
        })

        ac.addAction(UIAlertAction(title: "Delete ALL Rounds", style: .destructive) { _ in
            RoundStore.shared.clearAll()
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            let done = UIAlertController(
                title: "History Deleted",
                message: "All saved rounds were removed.",
                preferredStyle: .alert
            )
            done.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(done, animated: true)
        })

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }

    @IBAction private func trackFriendsButtonTapped(_ sender: UIButton) {
        print("Roster / Tracking tapped")

        guard let vc = storyboard?.instantiateViewController(
            withIdentifier: "RosterAndTrackingVC"
        ) as? RosterAndTrackingViewController else {
            print("⚠️ Could not find RosterAndTrackingVC")
            return
        }

        navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction private func managePlayersTapped(_ sender: UIButton) {
        print("Manage Players tapped")

        guard let vc = storyboard?.instantiateViewController(
            withIdentifier: "RosterAndTrackingVC"
        ) as? RosterAndTrackingViewController else {
            print("⚠️ Could not find RosterAndTrackingVC")
            return
        }

        navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction private func myStatsTapped(_ sender: UIButton) {
        let allRounds = RoundStore.shared.rounds
        let cal = Calendar.current
        let now = Date()
        let cutoff = cal.date(byAdding: .year, value: -1, to: now) ?? now

        let myName = (ProfileStore.name ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let myRounds = allRounds.filter {
            $0.date >= cutoff &&
            $0.playerName.caseInsensitiveCompare(myName) == .orderedSame
        }

        let myCount = myRounds.count
        let myTotalMoney = myRounds.reduce(0) { $0 + $1.totalMoney }
        let myTotalProx  = myRounds.reduce(0) { $0 + $1.totalProx }
        let myTotalHoles = myRounds.reduce(0) { $0 + max($1.holesPlayed, 1) }

        let myAvgMoneyPer18: Double = myTotalHoles > 0
            ? Double(myTotalMoney) / Double(myTotalHoles) * 18.0
            : 0

        let myAvgProxPer18: Double = myTotalHoles > 0
            ? Double(myTotalProx) / Double(myTotalHoles) * 18.0
            : 0

        let myScores = myRounds.compactMap { $0.totalScore }
        let myAvgScore = myScores.isEmpty
            ? nil
            : Double(myScores.reduce(0, +)) / Double(myScores.count)

        let recentMine = myRounds
            .sorted { $0.date > $1.date }
            .prefix(5)

        let df = DateFormatter()
        df.dateStyle = .medium

        var message = ""
        message += "Rounds (last 12 months): \(myCount)\n"
        message += String(
            format: "Net money: %+d  (avg %+0.1f per 18 holes)\n",
            myTotalMoney, myAvgMoneyPer18
        )
        message += String(
            format: "Prox wins: %d  (avg %0.1f per 18 holes)\n",
            myTotalProx, myAvgProxPer18
        )

        if let avgScore = myAvgScore {
            message += String(format: "Avg score: %0.1f\n", avgScore)
        }

        message += "\nRecent rounds:\n"
        for r in recentMine {
            let d = df.string(from: r.date)
            let line = String(
                format: "• %@  %+d, prox %d%@\n",
                d,
                r.totalMoney,
                r.totalProx,
                r.totalScore != nil ? ", score \(r.totalScore!)" : ""
            )
            message += line
        }

        let ac = UIAlertController(
            title: "My Stats (last 12 months)",
            message: message,
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    @IBAction private func courseSummaryTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(
            withIdentifier: "CourseSummaryViewController"
        )

        // If home is inside a navigation controller, push:
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            // Otherwise present modally
            vc.modalPresentationStyle = .formSheet
            present(vc, animated: true)
        }
    }

    @IBAction private func friendStatsTapped(_ sender: UIButton) {
        let allRounds = RoundStore.shared.rounds

        if allRounds.isEmpty {
            let ac = UIAlertController(
                title: "Friend Stats",
                message: "No rounds have been recorded yet.",
                preferredStyle: .alert
            )
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            return
        }

        let courseID: String = {
            let stored = ProfileStore.homeCourseID
            if !stored.isEmpty { return stored }
            if let b = CourseLibrary.shared.biltmore() {
                return b.id.uuidString
            }
            return "HOME-COURSE"
        }()

        let trackedFriends = FriendStore.shared.friends.filter {
            FriendTrackStore.shared.isTracked($0.id, on: courseID)
        }

        guard !trackedFriends.isEmpty else {
            let ac = UIAlertController(
                title: "Friend Stats",
                message: "You haven't selected any friends to track yet.\nUse Track Friends to choose who to track.",
                preferredStyle: .alert
            )
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            return
        }

        var lines: [String] = []

        for friend in trackedFriends {
            guard let stats = RoundStore.shared.stats(forPlayerNamed: friend.name) else {
                continue
            }

            let line = String(
                format: "• %@: %d rds, avg $%0.1f per 18, prox %0.1f per 18",
                friend.name,
                stats.rounds,
                stats.avgMoneyPerRound,
                stats.avgProxPerRound
            )
            lines.append(line)
        }

        if lines.isEmpty {
            let ac = UIAlertController(
                title: "Friend Stats",
                message: "Your tracked friends don't have any recorded rounds yet.",
                preferredStyle: .alert
            )
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            return
        }

        let ac = UIAlertController(
            title: "Friend Stats (all-time)",
            message: lines.joined(separator: "\n"),
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    @IBAction private func managePlayersButtonTapped(_ sender: UIButton) {
        print("Manage Players tapped")

        guard let vc = storyboard?.instantiateViewController(
            withIdentifier: "ManagePlayersVC"
        ) as? ManagePlayersViewController else {
            print("⚠️ Could not find ManagePlayersVC")
            return
        }

        navigationController?.pushViewController(vc, animated: true)
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

    @IBAction private func editPlayerTapped(_ sender: UIButton) {
        let current = ProfileStore.name ?? ""
        let ac = UIAlertController(
            title: "Your Name",
            message: "This name is used to track your stats.",
            preferredStyle: .alert
        )
        ac.addTextField { tf in
            tf.placeholder = "Enter your name"
            tf.text = current
            tf.autocapitalizationType = .words
            tf.clearButtonMode = .whileEditing
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            let newName = ac.textFields?.first?.text
            ProfileStore.name = newName
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        })
        present(ac, animated: true)
    }

    @IBAction private func editCourseTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "showCourseHC", sender: self)
    }
}
