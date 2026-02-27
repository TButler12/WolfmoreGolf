//
import UIKit

final class ManagePlayersViewController: UIViewController,
                                         UITableViewDataSource,
                                         UITableViewDelegate,
                                         UITextFieldDelegate {

    // MARK: - Types

    enum Mode { case preRound, inRound }

    // MARK: - Config

    private let maxActivePlayers = 5
    private let trackingLimitPerCourse = 30

    // MARK: - Public

    var mode: Mode = .preRound
    var onDone: (() -> Void)?

    // MARK: - Outlets

    @IBOutlet private weak var tableView: UITableView!

    // MARK: - Data

    private var friends: [Friend] { FriendStore.shared.friends }

    // MARK: - UI refs

    private weak var addUIButton: UIButton?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = (mode == .preRound) ? "Add Players" : "Edit Player Tracking"
        configureNavBar()
        configureTable()
        configureKeyboardDismissTap()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    // MARK: - Setup

    private func configureNavBar() {
        navigationItem.prompt = nil

        switch mode {
        case .preRound:
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: makeGlowingAddButton())
            navigationItem.leftBarButtonItem = nil

            // if you truly want to lock navigation during setup
            navigationItem.hidesBackButton = true
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false

        case .inRound:
            navigationItem.rightBarButtonItem = nil
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .done,
                target: self,
                action: #selector(doneTapped)
            )
            navigationItem.hidesBackButton = true
        }
    }

    private func configureTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
    }

    private func configureKeyboardDismissTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditingTap))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    // MARK: - Nav actions

    @objc private func doneTapped() {
        dismiss(animated: true)
        onDone?()
    }

    @objc private func endEditingTap() {
        view.endEditing(true)
    }

    // MARK: - Add button (glow)

    private func makeGlowingAddButton() -> UIButton {
        let b = UIButton(type: .system)
        b.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        b.layer.cornerRadius = 18
        b.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.92)

        b.setImage(UIImage(systemName: "plus"), for: .normal)
        b.tintColor = .systemGreen
        b.addTarget(self, action: #selector(addFriendTapped), for: .touchUpInside)

        setAddGlow(true, on: b)
        addUIButton = b
        return b
    }

    private func setAddGlow(_ on: Bool, on button: UIButton) {
        if on {
            button.layer.shadowColor = UIColor.systemGreen.cgColor
            button.layer.shadowRadius = 12
            button.layer.shadowOpacity = 0.85
            button.layer.shadowOffset = .zero

            let pulse = CABasicAnimation(keyPath: "shadowOpacity")
            pulse.fromValue = 0.15
            pulse.toValue = 0.9
            pulse.duration = 0.8
            pulse.autoreverses = true
            pulse.repeatCount = .infinity
            button.layer.add(pulse, forKey: "addGlowPulse")
        } else {
            button.layer.removeAnimation(forKey: "addGlowPulse")
            button.layer.shadowOpacity = 0
            button.layer.shadowRadius = 0
        }
    }

    private func flashNavPrompt(_ text: String, seconds: TimeInterval = 1.6) {
        let old = navigationItem.prompt
        navigationItem.prompt = text
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
            self?.navigationItem.prompt = old
        }
    }

    // MARK: - Alerts

    private func showActiveLimitAlert() {
        let ac = UIAlertController(
            title: "Player Limit",
            message: "You can only activate up to \(maxActivePlayers) players.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    // MARK: - Add Player flow (Name + Phone -> HC -> Save)

    @objc private func addFriendTapped() {
        showNamePrompt(prefillName: nil)
    }

    private func showNamePrompt(prefillName: String?) {
        let ac = UIAlertController(title: "Add Player", message: nil, preferredStyle: .alert)

        ac.addTextField { tf in
            tf.placeholder = "Player name"
            tf.autocapitalizationType = .words
            tf.text = prefillName
            tf.returnKeyType = .next
        }

        ac.addTextField { tf in
            tf.placeholder = "Mobile (optional)"
            tf.keyboardType = .phonePad
            tf.clearButtonMode = .whileEditing
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        ac.addAction(UIAlertAction(title: "Next", style: .default) { [weak self] _ in
            guard let self else { return }

            let name = (ac.textFields?[0].text ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let rawPhone = ac.textFields?[1].text ?? ""
            let phone = rawPhone.filter(\.isNumber)

            guard !name.isEmpty else { return }
            self.showHCPrompt(name: name, phone: phone, prefillHC: nil)
        })

        present(ac, animated: true)
    }

    private func showHCPrompt(name: String, phone: String, prefillHC: Int?) {
        let ac = UIAlertController(
            title: "Handicap",
            message: "Enter HC for \(name)",
            preferredStyle: .alert
        )

        ac.addTextField { tf in
            tf.placeholder = "HC"
            tf.keyboardType = .numberPad
            if let prefillHC { tf.text = "\(prefillHC)" }
        }

        ac.addAction(UIAlertAction(title: "Back", style: .default) { [weak self] _ in
            self?.showNamePrompt(prefillName: name)
        })

        ac.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self else { return }

            let hcText = (ac.textFields?.first?.text ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let hc = Int(hcText) ?? 0

            let savedFriend = self.upsertFriend(name: name, phone: phone, defaultHC: hc)
            self.tableView.reloadData()
            self.promptAddToStatTracking(friend: savedFriend)
        })

        present(ac, animated: true)
    }

    private func upsertFriend(name: String, phone: String, defaultHC: Int) -> Friend {
        if var existing = FriendStore.shared.friends.first(where: {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .caseInsensitiveCompare(name) == .orderedSame
        }) {
            existing.defaultHC = defaultHC
            if !phone.isEmpty { existing.phone = phone }
            FriendStore.shared.upsert(existing)
            return existing
        } else {
            let newFriend = Friend(name: name, defaultHC: defaultHC, phone: phone)
            FriendStore.shared.upsert(newFriend)
            return newFriend
        }
    }

    // MARK: - Stat Tracking prompt (FriendTrackStore)

    private func promptAddToStatTracking(friend: Friend) {
        let courseID = ProfileStore.homeCourseID.trimmingCharacters(in: .whitespacesAndNewlines)

        guard UUID(uuidString: courseID) != nil else {
            let ac = UIAlertController(
                title: "Set Home Course First",
                message: "Stat Tracking is tied to your Home Course. Set it now?",
                preferredStyle: .alert
            )
            ac.addAction(UIAlertAction(title: "Not now", style: .cancel))
            ac.addAction(UIAlertAction(title: "Set Home Course", style: .default) { [weak self] _ in
                self?.goToHomeCourseSetup()
            })
            present(ac, animated: true)
            return
        }

        if FriendTrackStore.shared.isTracked(friendID: friend.id, courseID: courseID) {
            flashNavPrompt("\(friend.name) already tracked ✅")
            return
        }

        let ac = UIAlertController(
            title: "Add to Stat Tracking?",
            message: "Track \(friend.name) for Friend Stats / Hole Stats on your Home Course?",
            preferredStyle: .alert
        )

        ac.addAction(UIAlertAction(title: "Not now", style: .cancel))

        ac.addAction(UIAlertAction(title: "Add to Tracking", style: .default) { [weak self] _ in
            guard let self else { return }

            let ok = FriendTrackStore.shared.toggle(
                friendID: friend.id,
                courseID: courseID,
                limit: self.trackingLimitPerCourse
            )

            if ok {
                self.flashNavPrompt("Added to Stat Tracking ✅")
            } else {
                let full = UIAlertController(
                    title: "Tracking Limit Reached",
                    message: "You can track up to \(self.trackingLimitPerCourse) friends for this Home Course.",
                    preferredStyle: .alert
                )
                full.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(full, animated: true)
            }
        })

        present(ac, animated: true)
    }

    private func goToHomeCourseSetup() {
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

    // MARK: - TableView Data Source

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        friends.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "FriendCell",
            for: indexPath
        ) as? ManagePlayerCell else {
            return UITableViewCell()
        }

        let friend = friends[indexPath.row]
        let friendID = friend.id
        let seat = indexPath.row

        // Name
        cell.nameLabel.text = friend.name

        // HC
        cell.hcField.text = (friend.defaultHC == 0) ? "" : String(friend.defaultHC)

        // ✅ Highlight rule:
        // - preRound: highlight when activated AND HC empty (best UX)
        // - inRound: no highlight
        let needsHC = (mode == .preRound) && (friend.defaultHC == 0)
        cell.applyHCStyle(isRequired: needsHC)

        // Activate switch state
        if mode == .preRound {
            cell.activeSwitch.isOn = friend.preselectForRound
        } else {
            cell.activeSwitch.isOn = GameManager.shared.currentGame?.playerActivated[safe: seat] ?? false
        }

        // HC change callback
        cell.hcChanged = { [weak self, weak cell] newHC in
            guard let self else { return }
            if self.mode == .preRound {
                FriendStore.shared.update(friendID: friendID, defaultHC: newHC)

                // keep highlight accurate while editing
                let stillNeeds = FriendStore.shared.friends.first(where: { $0.id == friendID })?.preselectForRound ?? false
                cell?.applyHCStyle(isRequired: stillNeeds)
            }
        }

        // Activate callback
        cell.activeChanged = { [weak self, weak cell] isOn in
            guard let self else { return }

            if self.mode == .preRound {
                if isOn {
                    let currentActive = FriendStore.shared.preselectedCount
                    if currentActive >= self.maxActivePlayers {
                        cell?.activeSwitch.setOn(false, animated: true)
                        self.showActiveLimitAlert()
                        return
                    }
                }

                FriendStore.shared.update(friendID: friendID, preselectForRound: isOn)

                // ✅ If activated, HC becomes "required" → highlight if empty
                cell?.applyHCStyle(isRequired: isOn)
                return
            }

            // inRound: update the live game activation state
            GameManager.shared.update { g in
                guard seat < g.playerActivated.count else { return }
                g.playerActivated[seat] = isOn
            }
            NotificationCenter.default.post(name: .reloadUI, object: nil)
        }

        return cell
    }

    // MARK: - Delete

    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {

        guard editingStyle == .delete else { return }

        let friend = friends[indexPath.row]
        FriendStore.shared.remove(friendID: friend.id)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }

    // MARK: - Close (if you still use it)

    @IBAction private func closeTapped(_ sender: Any) {
        if let nav = navigationController, nav.presentingViewController != nil {
            nav.dismiss(animated: true)
            return
        }
        if navigationController != nil {
            navigationController?.popViewController(animated: true)
            return
        }
        dismiss(animated: true)
    }

    // MARK: - Start Round (unchanged logic, cleaned slightly)

    @IBAction private func startRoundTapped(_ sender: Any) {
        let selected = FriendStore.shared.friends.filter { $0.preselectForRound }
        guard !selected.isEmpty else {
            let ac = UIAlertController(
                title: "No Players Selected",
                message: "Turn on at least one Activate switch, then try again.",
                preferredStyle: .alert
            )
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            return
        }

        let active = Array(selected.prefix(maxActivePlayers))

        if hasInProgressRound() {
            let ac = UIAlertController(
                title: "Start New Round?",
                message: "This will reorder players and clear the current round data.",
                preferredStyle: .alert
            )
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            ac.addAction(UIAlertAction(title: "Start New Round", style: .destructive) { [weak self] _ in
                guard let self else { return }

                if GameManager.shared.currentGame != nil {
                    GameManager.shared.resetForNewRoundPreservingCourseAndRoster()
                    GameManager.shared.canRandomizeTeams = true
                } else {
                    GameManager.shared.startNewGame(name: "New Game")
                }

                self.configureGameRosterAndPresentRoundNav(with: active)
            })
            present(ac, animated: true)
        } else {
            configureGameRosterAndPresentRoundNav(with: active)
        }
    }

    private func hasInProgressRound() -> Bool {
        guard let g = GameManager.shared.currentGame else { return false }
        return g.scores.contains { row in row.contains(where: { $0 != nil }) }
    }

    private func configureGameRosterAndPresentRoundNav(with active: [Friend]) {
        if GameManager.shared.currentGame == nil {
            GameManager.shared.startNewGame(name: "New Game")
        }

        GameManager.shared.update { g in
            if g.playerNames.count != maxActivePlayers     { g.playerNames     = Array(repeating: "",    count: maxActivePlayers) }
            if g.hcPlayers.count != maxActivePlayers       { g.hcPlayers       = Array(repeating: 0,     count: maxActivePlayers) }
            if g.playerActivated.count != maxActivePlayers { g.playerActivated = Array(repeating: false, count: maxActivePlayers) }

            for (seat, friend) in active.enumerated() {
                g.playerNames[seat]     = friend.name
                g.hcPlayers[seat]       = friend.defaultHC
                g.playerActivated[seat] = true
            }

            if active.count < maxActivePlayers {
                for seat in active.count..<maxActivePlayers {
                    g.playerNames[seat]     = ""
                    g.hcPlayers[seat]       = 0
                    g.playerActivated[seat] = false
                }
            }

            g.hole = 0
        }

        guard let roundNav = storyboard?.instantiateViewController(withIdentifier: "RoundNav") as? UINavigationController else {
            print("⚠️ Could not find RoundNav in storyboard")
            return
        }

        present(roundNav, animated: true)
    }
}

// MARK: - Safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
