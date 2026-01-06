//
import UIKit

// MARK: - Cell

final class RosterPlayerCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var hcField: UITextField!
    @IBOutlet weak var activeSwitch: UISwitch!
    @IBOutlet weak var trackButton: UIButton!

    /// Called when the star is tapped; Bool is the NEW on/off value.
    var trackToggled: ((Bool) -> Void)?
    /// Called when the active switch changes; Bool is the NEW on/off value.
    var activeToggled: ((Bool) -> Void)?

    @IBAction private func trackButtonTapped(_ sender: UIButton) {
        sender.isSelected.toggle()
        trackToggled?(sender.isSelected)
    }

    @IBAction private func activeSwitchChanged(_ sender: UISwitch) {
        activeToggled?(sender.isOn)
    }
}

// MARK: - View controller

final class RosterAndTrackingViewController: UIViewController,
                                            UITableViewDataSource,
                                            UITableViewDelegate,
                                            UITextFieldDelegate {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var goToGameButton: UIButton!
    @IBOutlet private weak var courseLabel: UILabel!

    private struct RowModel {
        var friend: Friend
        var hc: Int
        var isActive: Bool
        var isTracked: Bool
    }

    private var rows: [RowModel] = []
    private let trackLimit = 30
    private let maxActivePlayers = 5

    private var courseID: String {
        let stored = ProfileStore.homeCourseID
        return stored.isEmpty ? "HOME-COURSE" : stored
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Players & Tracking"

           navigationItem.rightBarButtonItem = UIBarButtonItem(
               title: "Player History",
               style: .plain,
               target: self,
               action: #selector(trackFriendsTapped)
           )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Player History",
            style: .plain,
            target: self,
            action: #selector(trackFriendsTapped)
        )

        
        
        title = "Players & Tracking"

        tableView.dataSource = self
        tableView.delegate   = self
        tableView.keyboardDismissMode = .onDrag
        tableView.tableFooterView = UIView()

        // Make sure we have a game
        if GameManager.shared.currentGame == nil {
            if !GameManager.shared.loadLastOpened() {
                GameManager.shared.startNewGame()
            }
        }

        seedFriendsFromCurrentGameIfNeeded()
        rebuildRowsFromStores()
        updateCourseLabel()
        updateGoButtonState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // In case home course / tracking changed elsewhere
        rebuildRowsFromStores()
        updateCourseLabel()
        updateGoButtonState()
    }

    // MARK: - Seed + Build rows

    private func seedFriendsFromCurrentGameIfNeeded() {
        guard FriendStore.shared.friends.isEmpty,
              let g = GameManager.shared.currentGame else { return }

        let names = g.playerNames
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if !names.isEmpty {
            FriendStore.shared.merge(names: names)
        }
    }

    private func rebuildRowsFromStores() {
        let friends = FriendStore.shared.friends.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }

        let g = GameManager.shared.currentGame

        rows = friends.map { friend in
            var hc = 0
            var isActive = false

            if let g = g {
                let seats = 0..<min(5, min(g.playerNames.count,
                                           min(g.playerActivated.count, g.hcPlayers.count)))

                if let seat = seats.first(where: { i in
                    g.playerNames[i]
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .caseInsensitiveCompare(friend.name) == .orderedSame
                }) {
                    hc = g.hcPlayers[seat]
                    isActive = g.playerActivated[seat]
                }
            }

            let tracked = FriendTrackStore.shared.isTracked(friend.id, on: courseID)
            return RowModel(friend: friend, hc: hc, isActive: isActive, isTracked: tracked)
        }

        tableView.reloadData()
    }

    // MARK: - Course label

    private func updateCourseLabel() {
        guard let g = GameManager.shared.currentGame else {
            courseLabel.text = "Course: (none)"
            return
        }

        let currentPars = Array(g.course.pars.prefix(18))
        let currentHCs  = Array(g.course.holeHandicaps.prefix(18))

        let match = CourseLibrary.shared.courses.first { c in
            Array(c.pars.prefix(18)) == currentPars &&
            Array(c.hcs.prefix(18))  == currentHCs
        }

        if let course = match {
            let isHome = (course.id.uuidString == ProfileStore.homeCourseID)
            courseLabel.text = isHome ? "Course: ⭐ \(course.name)" : "Course: \(course.name)"
        } else {
            courseLabel.text = "Course: Custom"
        }
    }

    // MARK: - TableView DataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "RosterPlayerCell",
            for: indexPath
        ) as? RosterPlayerCell else {
            return UITableViewCell()
        }

        let row = rows[indexPath.row]

        // Name
        cell.nameLabel.text = row.friend.name

        // HC field
        cell.hcField.text = row.hc == 0 ? "" : String(row.hc)
        cell.hcField.keyboardType = .numberPad
        cell.hcField.delegate = self
        cell.hcField.tag = indexPath.row

        // Active switch (NO addTarget; use the cell's IBAction + closure)
        cell.activeSwitch.isOn = row.isActive
        cell.activeToggled = { [weak self, weak cell] isOn in
            guard let self = self, let cell = cell,
                  let idx = self.tableView.indexPath(for: cell)?.row,
                  self.rows.indices.contains(idx) else { return }

            self.rows[idx].isActive = isOn
            self.updateGoButtonState()
        }

        // ⭐ tracking star
        cell.trackButton.isSelected = row.isTracked
        cell.trackToggled = { [weak self, weak cell] desiredOn in
            guard let self = self, let cell = cell,
                  let idx = self.tableView.indexPath(for: cell)?.row,
                  self.rows.indices.contains(idx) else { return }

            let friend = self.rows[idx].friend
            let prev = self.rows[idx].isTracked

            let ok = FriendTrackStore.shared.setTracked(
                desiredOn,
                friend.id,
                courseID: self.courseID,
                limit: self.trackLimit
            )

            if ok {
                self.rows[idx].isTracked = desiredOn
            } else {
                self.rows[idx].isTracked = prev
                cell.trackButton.isSelected = prev
                self.showTrackLimitAlert()
            }
        }

        return cell
    }

    // MARK: - HC editing

    func textFieldDidEndEditing(_ textField: UITextField) {
        let idx = textField.tag
        guard rows.indices.contains(idx) else { return }

        let raw = (textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let val = Int(raw) ?? 0
        rows[idx].hc = max(0, val)

        // (Optional) If this person is active, you can re-evaluate Go button state
        updateGoButtonState()
    }

    // MARK: - Go button state

    private func updateGoButtonState() {
        let activeCount = rows.filter { $0.isActive }.count

        // Allow 1...5
        let ok = (activeCount >= 1 && activeCount <= maxActivePlayers)
        goToGameButton.isEnabled = ok
        goToGameButton.alpha = ok ? 1.0 : 0.4
    }

    // MARK: - Alerts

    private func showTrackLimitAlert() {
        let ac = UIAlertController(
            title: "Limit Reached",
            message: "You can track up to \(trackLimit) friends for this course.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    private func showTooManyActiveAlert(_ count: Int) {
        let ac = UIAlertController(
            title: "Too Many Active Players",
            message: "You selected \(count) active players. Only \(maxActivePlayers) can be active for a round.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    // MARK: - Add Player (optional)

    @IBAction private func addPlayerTapped(_ sender: Any) {
        let ac = UIAlertController(title: "Add Player", message: nil, preferredStyle: .alert)

        ac.addTextField { tf in
            tf.placeholder = "Player name"
            tf.autocapitalizationType = .words
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        ac.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self else { return }

            let name = (ac.textFields?.first?.text ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return }

            // Save friend + refresh table
            FriendStore.shared.merge(names: [name])
            self.rebuildRowsFromStores()

            // Find the friend record we just added/merged
            guard let friend = FriendStore.shared.friends.first(where: {
                $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    .caseInsensitiveCompare(name) == .orderedSame
            }) else { return }

            // If already tracked, don't ask again
            if FriendTrackStore.shared.isTracked(friend.id, on: self.courseID) { return }

            // ✅ Present AFTER the "Add Player" alert finishes dismissing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.promptTrackNewFriend(friend)
            }
        })

        safePresent(ac)

    }
    private func safePresent(_ vc: UIViewController) {
        if let presented = presentedViewController {
            presented.dismiss(animated: false) { [weak self] in
                self?.present(vc, animated: true)
            }
        } else {
            present(vc, animated: true)
        }
    }

    private func promptTrackNewFriend(_ friend: Friend) {
        

        print("✅ promptTrackNewFriend for:", friend.name)

        let ac = UIAlertController(
            title: "Track this player?",
            message: "Track \(friend.name) for ⭐ Home Course stats?",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "Not now", style: .cancel))
        ac.addAction(UIAlertAction(title: "Track", style: .default) { [weak self] _ in
            guard let self = self else { return }
            _ = FriendTrackStore.shared.setTracked(true, friend.id, courseID: self.courseID, limit: self.trackLimit)
            self.rebuildRowsFromStores()
        })
        present(ac, animated: true)
    }

    // MARK: - Go to Game

    @IBAction private func goToGameTapped(_ sender: UIButton) {
        let activeRows = rows.filter { $0.isActive }
        guard !activeRows.isEmpty else { return }

        if activeRows.count > maxActivePlayers {
            showTooManyActiveAlert(activeRows.count)
            return
        }

        // Pack actives into seats 0...4 (simple + predictable)
        GameManager.shared.update { g in
            g.normalize(holes: 18)

            // Ensure sizes (adjust if your capacity differs)
            if g.playerNames.count != 5 { g.playerNames = Array(g.playerNames.prefix(5)) + Array(repeating: "", count: max(0, 5 - g.playerNames.count)) }
            if g.hcPlayers.count != 5 { g.hcPlayers = Array(g.hcPlayers.prefix(5)) + Array(repeating: 0, count: max(0, 5 - g.hcPlayers.count)) }
            if g.playerActivated.count != 5 { g.playerActivated = Array(g.playerActivated.prefix(5)) + Array(repeating: false, count: max(0, 5 - g.playerActivated.count)) }

            for seat in 0..<5 {
                if seat < activeRows.count {
                    g.playerNames[seat] = activeRows[seat].friend.name
                    g.hcPlayers[seat] = activeRows[seat].hc
                    g.playerActivated[seat] = true
                } else {
                    g.playerNames[seat] = ""
                    g.hcPlayers[seat] = 0
                    g.playerActivated[seat] = false
                }
            }
        }

        performSegue(withIdentifier: "showGame", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showGame" else { return }

        if let nav = segue.destination as? UINavigationController,
           let dest = nav.topViewController as? GameViewController {
            dest.playersFallback = nil
        } else if let dest = segue.destination as? GameViewController {
            dest.playersFallback = nil
        }
    }
}

// MARK: - FriendTrackStore helper

extension FriendTrackStore {
    /// Ensures tracking matches `desired`. Returns false only if trying to turn ON but limit blocks it.
    func setTracked(_ desired: Bool,
                    _ friendID: UUID,
                    courseID: String,
                    limit: Int) -> Bool {
        let current = isTracked(friendID, on: courseID)
        if desired == current { return true }
        return toggle(friendID, courseID: courseID, limit: limit)
    }
}
 
extension RosterAndTrackingViewController {

    @objc func trackFriendsTapped() {
        let allRounds = RoundStore.shared.rounds
        guard !allRounds.isEmpty else {
            let ac = UIAlertController(
                title: "Player History",
                message: "No rounds have been recorded yet.",
                preferredStyle: .alert
            )
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            return
        }

        let trackedFriends = FriendStore.shared.friends.filter {
            FriendTrackStore.shared.isTracked($0.id, on: courseID)
        }

        guard !trackedFriends.isEmpty else {
            let ac = UIAlertController(
                title: "Player History",
                message: "No tracked players yet.\nTap ⭐ next to a player to track them.",
                preferredStyle: .alert
            )
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            return
        }

        var blocks: [String] = []

        for friend in trackedFriends {
            guard let stats = RoundStore.shared.stats(forPlayerNamed: friend.name) else { continue }

            blocks.append("""
            • \(friend.name):
              \(stats.rounds) rds, avg $\(String(format: "%.1f", stats.avgMoneyPerRound)) per 18
              prox \(String(format: "%.1f", stats.avgProxPerRound)) per 18
            """)
        }

        let ac = UIAlertController(
            title: "Player History (all-time)",
            message: blocks.isEmpty ? "No history yet for tracked players." : blocks.joined(separator: "\n\n"),
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}


