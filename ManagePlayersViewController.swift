//
//  ManagePlayersViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 11/27/25.
//
import UIKit

final class ManagePlayersViewController: UIViewController,
                                         UITableViewDataSource,
                                         UITableViewDelegate,
                                         UITextFieldDelegate {

    // MARK: - Limits
    private let maxActivePlayers = 5
    private let trackingLimitPerCourse = 30

    // MARK: - Outlets
    @IBOutlet private weak var tableView: UITableView!

    // Set by LiveConnectedViewController when presenting immediately after a scorer joins.
    // Triggers a success banner + auto-opens the roster picker on first appearance.
    var joinSuccessMessage: String? = nil

    // MARK: - Data
    private var friends: [Friend] { FriendStore.shared.friends }
    // Cached roster names for tournament mode — used to filter selectedCount correctly.
    private var tournamentRosterNames: Set<String> = []

    // MARK: - UI refs
    private weak var addUIButton: UIButton?
    private weak var startRoundButton: UIButton?
    private weak var quickStartButton: UIButton?
    private weak var rosterPickerButton: UIButton?
    private var groupsBarItem: UIBarButtonItem?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavBar()
        configureTable()
        configureKeyboardDismissTap()

        if let btn = button(forAction: #selector(startRoundTapped)) {
            startRoundButton = btn
            styleStartButton(btn)
        }

        buildQuickStartFooter()
        applyAdaptiveConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        buildNavTitle()
        buildTableHeader()
        tableView.reloadData()
        refreshStartButton()
        refreshRosterPickerButton()
        loadTournamentRosterNamesIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let msg = joinSuccessMessage else { return }
        joinSuccessMessage = nil   // one-shot: clears so returning here later doesn't re-fire
        flashNavPrompt(msg, seconds: 3.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.rosterPickerTapped()
        }
    }

    // MARK: - Setup
    private func configureNavBar() {
        let addButton = makeGlowingAddButton()
        addUIButton = addButton

        let groupsButton = UIBarButtonItem(title: "Groups", style: .plain, target: self, action: #selector(groupsTapped))
        groupsButton.tintColor = UIColor(red: 0.10, green: 0.33, blue: 0.18, alpha: 1.0)
        groupsBarItem = groupsButton

        navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: addButton), groupsButton]
        navigationItem.hidesBackButton = true
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    @objc private func groupsTapped() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "TextVC")
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 18
        }
        present(nav, animated: true)
    }

    private func buildNavTitle() {
        let titleFont  = UIFont.preferredFont(forTextStyle: .headline)
        let courseFont = UIFont.preferredFont(forTextStyle: .caption1)
        let infoFont   = UIFont.preferredFont(forTextStyle: .caption2)

        let titleLabel = UILabel()
        titleLabel.text = "Players"
        titleLabel.font = titleFont
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center

        let storedCourse = GameManager.shared.currentGame?.course.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let courseName = storedCourse.isEmpty ? (CourseLibrary.shared.selectedCourseName ?? "No Course") : storedCourse
        let courseLabel = UILabel()
        courseLabel.text = courseName
        courseLabel.font = courseFont
        courseLabel.textColor = .label
        courseLabel.textAlignment = .center
        courseLabel.numberOfLines = 1
        courseLabel.lineBreakMode = .byTruncatingTail

        let g = GameManager.shared.currentGame
        let gameTypeName = g?.gameType?.displayName ?? "Casual"
        let stake = g.map { "$\($0.baseGameStake)" } ?? ""
        let gameLabel = UILabel()
        gameLabel.text = stake.isEmpty ? gameTypeName : "\(gameTypeName)  ·  \(stake)/pt"
        gameLabel.font = infoFont
        gameLabel.textColor = .secondaryLabel
        gameLabel.textAlignment = .center
        gameLabel.numberOfLines = 1

        let spacing: CGFloat = 1
        let totalHeight = ceil(titleFont.lineHeight)
                        + spacing + ceil(courseFont.lineHeight)
                        + spacing + ceil(infoFont.lineHeight)

        let stack = UIStackView(arrangedSubviews: [titleLabel, courseLabel, gameLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = spacing
        stack.frame = CGRect(x: 0, y: 0, width: min(UIScreen.main.bounds.width * 0.6, 400), height: totalHeight)

        navigationItem.titleView = stack
    }

    private func buildTableHeader() {
        tableView.tableHeaderView = nil

        let container = UIView()
        container.backgroundColor = .clear

        let playerLabel = makeColHeaderLabel("Player")
        let hcLabel = makeColHeaderLabel("HC")
        hcLabel.textAlignment = .center

        container.addSubview(playerLabel)
        container.addSubview(hcLabel)

        // Mirror exact storyboard cell positions: nameLabel x=46, hcField x=233 width=50
        NSLayoutConstraint.activate([
            playerLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 46),
            playerLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            hcLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 233),
            hcLabel.widthAnchor.constraint(equalToConstant: 50),
            hcLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])

        let width = tableView.bounds.width > 0 ? tableView.bounds.width : UIScreen.main.bounds.width
        container.frame = CGRect(x: 0, y: 0, width: width, height: 28)
        tableView.tableHeaderView = container
    }

    private func makeColHeaderLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = UIFont.preferredFont(forTextStyle: .caption1)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    private func configureTable() {
        tableView.dataSource = self
        tableView.delegate = self
    }

    private func configureKeyboardDismissTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditingTap))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
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
            guard let self else { return }
            self.navigationItem.prompt = old
        }
    }

    // MARK: - Keyboard
    @objc private func endEditingTap() {
        view.endEditing(true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
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

    // MARK: - Add Player flow (Name + Phone -> Next -> HC -> Add)
    @objc private func addFriendTapped() {
        let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        ac.addAction(UIAlertAction(title: "Add Manually", style: .default) { [weak self] _ in
            self?.showNamePrompt(prefillName: nil)
        })
        ac.addAction(UIAlertAction(title: "Manage Contacts", style: .default) { [weak self] _ in
            self?.openContactsImport()
        })
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.sourceView = addUIButton ?? view
            pop.sourceRect = addUIButton?.bounds ?? CGRect(x: view.bounds.midX, y: 60, width: 1, height: 1)
        }
        present(ac, animated: true)
    }

    private func openContactsImport() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "ContactsViewController")
        navigationController?.pushViewController(vc, animated: true)
    }

    private func enterEditMode() {
        tableView.setEditing(true, animated: true)
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(exitEditMode))
        navigationItem.rightBarButtonItems = [doneItem, groupsBarItem].compactMap { $0 }
    }

    @objc private func exitEditMode() {
        tableView.setEditing(false, animated: true)
        let newAddButton = makeGlowingAddButton()
        addUIButton = newAddButton
        var items: [UIBarButtonItem] = [UIBarButtonItem(customView: newAddButton)]
        if let g = groupsBarItem { items.append(g) }
        navigationItem.rightBarButtonItems = items
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
            let phone = rawPhone.filter { $0.isNumber }

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

            // ✅ Upsert friend with HC + phone (only overwrite phone if provided)
            if var existing = FriendStore.shared.friends.first(where: {
                $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    .caseInsensitiveCompare(name) == .orderedSame
            }) {
                existing.defaultHC = hc
                if !phone.isEmpty { existing.phone = phone }
                FriendStore.shared.upsert(existing)
            } else {
                let friend = Friend(name: name, defaultHC: hc, phone: phone)
                FriendStore.shared.upsert(friend)
            }

            self.tableView.reloadData()

            // Fetch saved friend (post-save)
            guard let savedFriend = FriendStore.shared.friends.last(where: {
                $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    .caseInsensitiveCompare(name) == .orderedSame
            }) else { return }

            self.promptAddToStatTracking(friend: savedFriend)
        })

        present(ac, animated: true)
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

        if FriendTrackStore.shared.isTracked(friend.id, on: courseID) {
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

            let ok = FriendTrackStore.shared.toggle(friend.id,
                                                   courseID: courseID,
                                                   limit: self.trackingLimitPerCourse)
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

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1 + friends.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "FriendCell",
            for: indexPath
        ) as? ManagePlayerCell else {
            return UITableViewCell()
        }

        cell.activeSwitch.isHidden = true
        cell.selectionStyle = .none

        if indexPath.row == 0 {
            let name = (ProfileStore.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let displayName = (name.isEmpty || name == "Player 1") ? "Set your scoring name" : name
            cell.nameLabel.text = "\(displayName) (You)"
            cell.hcField.text = ProfileStore.myHC == 0 ? "" : String(ProfileStore.myHC)
            cell.backgroundColor = ProfileStore.myPreselectForRound
                ? UIColor.systemYellow.withAlphaComponent(0.25)
                : .systemBackground
            cell.hcChanged = { newHC in ProfileStore.myHC = newHC }
            cell.activeChanged = nil
            return cell
        }

        let friend = friends[indexPath.row - 1]
        let friendID = friend.id

        cell.nameLabel.text = friend.name
        cell.hcField.text = friend.defaultHC == 0 ? "" : String(friend.defaultHC)
        cell.backgroundColor = friend.preselectForRound
            ? UIColor.systemYellow.withAlphaComponent(0.25)
            : .systemBackground
        cell.hcChanged = { newHC in FriendStore.shared.update(friendID: friendID, defaultHC: newHC) }
        cell.activeChanged = nil

        return cell
    }

    // MARK: - Tap to select
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let nowOn = !ProfileStore.myPreselectForRound
            if nowOn && selectedCount >= maxActivePlayers {
                showActiveLimitAlert(); return
            }
            ProfileStore.myPreselectForRound = nowOn
        } else {
            let friend = friends[indexPath.row - 1]
            let nowOn = !friend.preselectForRound
            if nowOn && selectedCount >= maxActivePlayers {
                showActiveLimitAlert(); return
            }
            FriendStore.shared.update(friendID: friend.id, preselectForRound: nowOn)
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
        refreshStartButton()
    }

    // MARK: - Delete (swipe to delete)
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {

        guard editingStyle == .delete, indexPath.row > 0 else { return }

        let friend = friends[indexPath.row - 1]
        FriendStore.shared.remove(friendID: friend.id)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        refreshStartButton()
    }

    // MARK: - Close
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

    // MARK: - Start Round
    @IBAction func startRoundTapped(_ sender: Any) {
        var selected = FriendStore.shared.friends.filter { $0.preselectForRound }

        if let code = GameManager.shared.currentGame?.tournamentCode {
            // Tournament path: filter selected against the live roster so stale
            // preselectForRound entries from unrelated rounds can't leak through.
            // Device owner is never auto-inserted here.
            Task {
                do {
                    let entries = try await SupabaseService.shared.fetchRoster(code: code)
                    let rosterNames = Set(entries.map { $0.canonicalName })
                    let active = Array(selected.filter { rosterNames.contains($0.name) }.prefix(MAX_PLAYERS))
                    await MainActor.run { self.proceedWithStart(active: active) }
                } catch {
                    // Roster fetch failed — proceed unfiltered rather than blocking the round
                    await MainActor.run { self.proceedWithStart(active: Array(selected.prefix(MAX_PLAYERS))) }
                }
            }
        } else {
            // Non-tournament path: include device owner if preselected
            if ProfileStore.myPreselectForRound,
               let myName = ProfileStore.name,
               !myName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               myName != "Player 1" {
                let me = Friend(name: myName, defaultHC: ProfileStore.myHC)
                selected.insert(me, at: 0)
            }
            proceedWithStart(active: Array(selected.prefix(MAX_PLAYERS)))
        }
    }

    private func proceedWithStart(active: [Friend]) {
        guard !active.isEmpty else {
            let ac = UIAlertController(
                title: "No Players Selected",
                message: "Tap at least one player row to add them to the round.",
                preferredStyle: .alert
            )
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            return
        }
        if hasInProgressRound() {
            let ac = UIAlertController(
                title: "Start New Round?",
                message: "This will reorder players and clear the current round data.",
                preferredStyle: .alert
            )
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            ac.addAction(UIAlertAction(title: "Start New Round", style: .destructive) { [weak self] _ in
                if GameManager.shared.currentGame != nil {
                    GameManager.shared.resetForNewRoundPreservingCourseAndRoster()
                    GameManager.shared.canRandomizeTeams = true
                } else {
                    GameManager.shared.startNewGame(name: "New Game")
                }
                self?.clearStaleTournamentPreselects(keeping: active)
                self?.configureGameRosterAndPresentRoundNav(with: active)
            })
            present(ac, animated: true)
        } else {
            clearStaleTournamentPreselects(keeping: active)
            configureGameRosterAndPresentRoundNav(with: active)
        }
    }

    private func clearStaleTournamentPreselects(keeping active: [Friend]) {
        guard GameManager.shared.currentGame?.tournamentCode != nil else { return }
        let activeNames = Set(active.map { $0.name })
        for friend in FriendStore.shared.friends where !activeNames.contains(friend.name) {
            FriendStore.shared.update(friendID: friend.id, preselectForRound: false)
        }
    }

    private func hasInProgressRound() -> Bool {
        guard let g = GameManager.shared.currentGame else { return false }
        for row in g.scores where row.contains(where: { $0 != nil }) {
            return true
        }
        return false
    }

    // MARK: - Start button helpers

    private var selectedCount: Int {
        if GameManager.shared.currentGame?.tournamentCode != nil {
            // In tournament mode only count preselected friends who are in this tournament's roster.
            if tournamentRosterNames.isEmpty {
                return 0
            }
            return FriendStore.shared.friends.filter {
                $0.preselectForRound && tournamentRosterNames.contains($0.name)
            }.count
        }
        let ownerCount = ProfileStore.myPreselectForRound ? 1 : 0
        return FriendStore.shared.preselectedCount + ownerCount
    }

    private func loadTournamentRosterNamesIfNeeded() {
        guard let code = GameManager.shared.currentGame?.tournamentCode else {
            tournamentRosterNames = []
            return
        }
        Task {
            guard let entries = try? await SupabaseService.shared.fetchRoster(code: code) else { return }
            await MainActor.run {
                self.tournamentRosterNames = Set(entries.map { $0.canonicalName })
                self.refreshStartButton()
            }
        }
    }

    private func styleStartButton(_ btn: UIButton) {
        var cfg = UIButton.Configuration.filled()
        cfg.baseBackgroundColor = UIColor(red: 0.10, green: 0.33, blue: 0.18, alpha: 1.0)
        cfg.baseForegroundColor = .white
        cfg.cornerStyle = .capsule
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs; a.font = UIFont.systemFont(ofSize: 17, weight: .semibold); return a
        }
        btn.configuration = cfg
    }

    private func refreshStartButton() {
        guard let btn = startRoundButton else { return }
        let count = selectedCount
        var cfg = btn.configuration ?? UIButton.Configuration.filled()
        cfg.title = count < 2 ? "Select at least 2 players" : "Start Round (\(count) players)"
        btn.configuration = cfg
        btn.isEnabled = count >= 2
    }

    private func button(forAction action: Selector) -> UIButton? {
        let name = NSStringFromSelector(action)
        func search(_ v: UIView) -> UIButton? {
            for sub in v.subviews {
                if let btn = sub as? UIButton,
                   btn.actions(forTarget: self, forControlEvent: .touchUpInside)?.contains(name) == true {
                    return btn
                }
                if let found = search(sub) { return found }
            }
            return nil
        }
        return search(view)
    }

    // MARK: - Tournament Roster Picker Button

    private func refreshRosterPickerButton() {
        let code = GameManager.shared.currentGame?.tournamentCode
        if let code, !code.isEmpty {
            if rosterPickerButton == nil { buildRosterPickerButton(code: code) }
            rosterPickerButton?.isHidden = false
        } else {
            rosterPickerButton?.isHidden = true
        }
    }

    private func buildRosterPickerButton(code: String) {
        var cfg = UIButton.Configuration.tinted()
        cfg.title = "Pick from Tournament Roster"
        cfg.image = UIImage(systemName: "list.bullet")
        cfg.imagePadding = 8
        cfg.baseBackgroundColor = UIColor(red: 0.10, green: 0.33, blue: 0.18, alpha: 1.0)
        cfg.baseForegroundColor = UIColor(red: 0.10, green: 0.33, blue: 0.18, alpha: 1.0)
        cfg.cornerStyle = .large
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs; a.font = UIFont.systemFont(ofSize: 15, weight: .semibold); return a
        }
        let btn = UIButton(configuration: cfg)
        btn.addTarget(self, action: #selector(rosterPickerTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        rosterPickerButton = btn
        view.addSubview(btn)

        guard let quickBtn = quickStartButton,
              let homeBtn = button(forAction: #selector(closeTapped(_:))) else { return }
        NSLayoutConstraint.activate([
            btn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            btn.topAnchor.constraint(equalTo: quickBtn.bottomAnchor, constant: 10),
            btn.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            btn.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            btn.heightAnchor.constraint(equalToConstant: 60),
            btn.bottomAnchor.constraint(equalTo: homeBtn.topAnchor, constant: -12),
        ])
    }

    @objc private func rosterPickerTapped() {
        guard let code = GameManager.shared.currentGame?.tournamentCode else { return }
        let isOrganizer = GameManager.shared.currentGame?.tournamentIsOrganizer == true
        let past = TournamentHistoryStore.shared.all().filter { $0.code != code }

        if isOrganizer && !past.isEmpty {
            let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            ac.addAction(UIAlertAction(title: "Pick from This Tournament's Roster", style: .default) { [weak self] _ in
                self?.openRosterPicker(code: code)
            })
            ac.addAction(UIAlertAction(title: "Load from Past Tournament", style: .default) { [weak self] _ in
                self?.showPastTournamentPicker(past, currentCode: code)
            })
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(ac, animated: true)
        } else {
            openRosterPicker(code: code)
        }
    }

    private func openRosterPicker(code: String) {
        let picker = TournamentRosterPickerViewController(tournamentCode: code)
        picker.maxPlayers = maxActivePlayers
        picker.myGroupCode = GameManager.shared.currentGame?.groupCode
        picker.preSelectedNames = Set(FriendStore.shared.friends
            .filter { $0.preselectForRound }
            .map { $0.name })
        picker.onSelect = { [weak self] name, hc in
            guard let self else { return }
            self.assignNextOpenSlot(name: name, hc: hc)
        }
        picker.onDeselect = { [weak self] name in
            guard let self else { return }
            if let friend = FriendStore.shared.friends.first(where: {
                $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    .caseInsensitiveCompare(name) == .orderedSame
            }) {
                FriendStore.shared.update(friendID: friend.id, preselectForRound: false)
                self.tableView.reloadData()
                self.refreshStartButton()
            }
        }
        let nav = UINavigationController(rootViewController: picker)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    private func showPastTournamentPicker(_ entries: [TournamentHistoryEntry], currentCode: String) {
        let ac = UIAlertController(
            title: "Load from Past Tournament",
            message: "All players from that tournament will be added to this roster and pre-selected.",
            preferredStyle: .actionSheet)
        for entry in entries {
            ac.addAction(UIAlertAction(title: "\(entry.name)  ·  Day \(entry.lastDay)", style: .default) { [weak self] _ in
                self?.importPlayersFromPastTournament(code: entry.code, name: entry.name, into: currentCode)
            })
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }

    private func importPlayersFromPastTournament(code: String, name: String, into currentCode: String) {
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
                    // Also add each player to the current tournament's roster so they appear
                    // pre-checked when the roster picker is opened.
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
                        self.tableView.reloadData()
                        self.refreshStartButton()
                    }
                }
            } catch {
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        let ac = UIAlertController(
                            title: "Import Failed",
                            message: "Could not load players from that tournament.",
                            preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ac, animated: true)
                    }
                }
            }
        }
    }

    private func assignNextOpenSlot(name: String, hc: Int) {
        // In tournament context the picker's remainingSelections already enforces the cap;
        // selectedCount only counts roster members so it stays accurate.
        tournamentRosterNames.insert(name)
        if GameManager.shared.currentGame?.tournamentCode == nil {
            guard selectedCount < maxActivePlayers else {
                showActiveLimitAlert()
                return
            }
        }
        if let existing = FriendStore.shared.friends.first(where: {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .caseInsensitiveCompare(name) == .orderedSame
        }) {
            FriendStore.shared.update(friendID: existing.id, defaultHC: hc)
            FriendStore.shared.update(friendID: existing.id, preselectForRound: true)
        } else {
            let friend = Friend(name: name, defaultHC: hc)
            FriendStore.shared.upsert(friend)
            if let saved = FriendStore.shared.friends.first(where: {
                $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    .caseInsensitiveCompare(name) == .orderedSame
            }) {
                FriendStore.shared.update(friendID: saved.id, preselectForRound: true)
            }
        }
        tableView.reloadData()
        refreshStartButton()
    }

    // MARK: - Quick Start

    private func buildQuickStartFooter() {
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
        btn.addTarget(self, action: #selector(quickStartTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        quickStartButton = btn

        view.addSubview(btn)

        // Anchor between the Start Round button and the Home/Close button.
        // The storyboard Start Round button sits at y≈630 and the Home button at y≈762,
        // so this centreX + midpoint placement lands in that gap on all device sizes.
        guard let startBtn = startRoundButton else { return }

        NSLayoutConstraint.activate([
            btn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            btn.topAnchor.constraint(equalTo: startBtn.bottomAnchor, constant: 14),
            btn.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            btn.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            btn.heightAnchor.constraint(equalToConstant: 60),
        ])
    }

    // Replaces storyboard fixed frames with safe-area-relative constraints so the
    // layout fills the full width on iPad.
    private func applyAdaptiveConstraints() {
        guard let startBtn = startRoundButton,
              let homeBtn  = button(forAction: #selector(closeTapped(_:))) else { return }

        tableView.translatesAutoresizingMaskIntoConstraints = false
        startBtn.translatesAutoresizingMaskIntoConstraints = false
        homeBtn.translatesAutoresizingMaskIntoConstraints  = false

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            // TableView fills full width; height driven by button chain below
            tableView.topAnchor.constraint(equalTo: guide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: startBtn.topAnchor, constant: -8),

            // Start Round button spans usable width
            startBtn.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            startBtn.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),
            startBtn.heightAnchor.constraint(equalToConstant: 50),

            // Home button pinned to safe-area bottom, centered
            homeBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            homeBtn.leadingAnchor.constraint(greaterThanOrEqualTo: guide.leadingAnchor, constant: 20),
            homeBtn.trailingAnchor.constraint(lessThanOrEqualTo: guide.trailingAnchor, constant: -20),
            homeBtn.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -16),
            homeBtn.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    @objc private func quickStartTapped() {
        let rawName = (ProfileStore.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let name = (rawName.isEmpty || rawName == "Player 1") ? "Player 1" : rawName
        let me = Friend(name: name, defaultHC: ProfileStore.myHC)
        configureGameRosterAndPresentRoundNav(with: [me])
    }

    private func configureGameRosterAndPresentRoundNav(with active: [Friend]) {
        if GameManager.shared.currentGame == nil {
            GameManager.shared.startNewGame(name: "New Game")
        }

        GameManager.shared.update { g in
            if g.playerNames.count != MAX_PLAYERS     { g.playerNames     = Array(repeating: "",    count: MAX_PLAYERS) }
            if g.hcPlayers.count != MAX_PLAYERS       { g.hcPlayers       = Array(repeating: 0,     count: MAX_PLAYERS) }
            if g.playerActivated.count != MAX_PLAYERS { g.playerActivated = Array(repeating: false, count: MAX_PLAYERS) }

            // clear old seats first
            g.playerNames = Array(repeating: "", count: MAX_PLAYERS)
            g.hcPlayers = Array(repeating: 0, count: MAX_PLAYERS)
            g.playerActivated = Array(repeating: false, count: MAX_PLAYERS)

            for (seat, friend) in active.enumerated() {
                g.playerNames[seat]     = friend.name
                g.hcPlayers[seat]       = friend.defaultHC
                g.playerActivated[seat] = true
            }

            // build Nassau automatically from the active players
            g.nassauState = NassauEngine.makeDefaultState(
                playerNames: g.playerNames,
                activeFlags: g.playerActivated
            )

            if var ns = g.nassauState {
                NassauEngine.recalculate(state: &ns, gameData: g)
                g.nassauState = ns
            }
        

            if active.count < MAX_PLAYERS {
                for seat in active.count..<MAX_PLAYERS {
                    g.playerNames[seat]     = ""
                    g.hcPlayers[seat]       = 0
                    g.playerActivated[seat] = false
                }
            }

            g.hole = 0

            // Try CourseLibrary.selectedCourseID first, then fall back to ProfileStore.homeCourseID
            let resolvedProfile: CourseProfile? = {
                if let id = CourseLibrary.shared.selectedCourseID,
                   let p = CourseLibrary.shared.get(id: id) { return p }
                let raw = ProfileStore.homeCourseID.trimmingCharacters(in: .whitespacesAndNewlines)
                if let id = UUID(uuidString: raw),
                   let p = CourseLibrary.shared.get(id: id) { return p }
                return nil
            }()

            if let profile = resolvedProfile {
                g.course = Course(id: profile.id,
                                  name: profile.name,
                                  pars: Array(profile.pars.prefix(STANDARD_HOLES)),
                                  holeHandicaps: Array(profile.hcs.prefix(STANDARD_HOLES)))
            }
        }

        guard let roundNav = storyboard?.instantiateViewController(withIdentifier: "RoundNav") as? UINavigationController else {
            print("⚠️ Could not find RoundNav in storyboard")
            return
        }

        roundNav.modalPresentationStyle = .fullScreen
        present(roundNav, animated: true)
    }
}
