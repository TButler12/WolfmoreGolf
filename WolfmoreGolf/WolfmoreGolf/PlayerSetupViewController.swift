import UIKit

final class PlayerSetupViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Outlets (row orders must align by TAG: 0..4)
    @IBOutlet private weak var courseLabel: UILabel!

    @IBOutlet private var nameFields: [UITextField]!
    @IBOutlet private var handicapFields: [UITextField]!
    @IBOutlet private var activateButtons: [UIButton]!
    @IBOutlet private var strokeLabels: [UILabel]!

    @IBOutlet private weak var randomizeButton: UIButton!
    @IBOutlet private weak var goToGameButton: UIButton!

    // (Optional) if you still have these on the screen
    @IBOutlet private weak var plusPointDollars: UIButton?
    @IBOutlet private weak var minusPointDollars: UIButton?

    // MARK: - Constants
    private let capacity = 5
    private var maxActive: Int { capacity }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Ensure we have a game first
        if GameManager.shared.currentGame == nil {
            if !GameManager.shared.loadLastOpened() {
                GameManager.shared.startNewGame()
            }
        }

        // Make sure model arrays are 5-wide for this build
        GameManager.shared.update { g in
            self.ensureModelHasCapacity(&g)
        }

        // Seed course library (so Biltmore etc. exist)
        CourseLibrary.shared.seedIfNeeded()

        // Sort + retag UI rows to 0..4 and hide extras (if storyboard still has 9 rows)
        normalizeAndTagRows()
        hideExtraRowsBeyondCapacity()

        // Wiring
        wireNameFields()
        wireHCFields()
        wireActivateButtons()

        // Observe model/UI reloads (from CourseSetup etc.)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadFromModel),
            name: .reloadUI,
            object: nil
        )

        // Nav button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Track",
            style: .plain,
            target: self,
            action: #selector(trackFriendsTapped)
        )

        // Initial paint
        updateCourseLabel()
        populateFromModel()
        recalcStrokesFromModel()
        enforceActivationCap()
        updateGoButtonEnabled()
        refreshRandomizeEnabled()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCourseLabel()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Row normalization (IMPORTANT)
    /// Best practice: set tags 0..4 in storyboard for each row.
    /// This function also tries to recover by sorting rows and assigning tags.
    private func normalizeAndTagRows() {
        // Prefer tag order if tags look sane; otherwise fallback to vertical position.
        func sortViews<T: UIView>(_ views: [T]) -> [T] {
            let tags = views.map { $0.tag }
            let hasUsefulTags = Set(tags).count > 1 || tags.contains(where: { $0 != 0 })
            if hasUsefulTags {
                return views.sorted { $0.tag < $1.tag }
            } else {
                return views.sorted { $0.frame.minY < $1.frame.minY }
            }
        }

        nameFields      = sortViews(nameFields)
        handicapFields  = sortViews(handicapFields)
        activateButtons = sortViews(activateButtons)
        strokeLabels    = sortViews(strokeLabels)

        // Force consistent tags 0..N so all collections align.
        let n = min(nameFields.count, handicapFields.count, activateButtons.count, strokeLabels.count)
        for i in 0..<n {
            nameFields[i].tag = i
            handicapFields[i].tag = i
            activateButtons[i].tag = i
            strokeLabels[i].tag = i
        }
    }

    private var uiCount: Int {
        min(capacity, nameFields.count, handicapFields.count, activateButtons.count, strokeLabels.count)
    }

    private func hideExtraRowsBeyondCapacity() {
        for i in uiCount..<nameFields.count { nameFields[i].isHidden = true }
        for i in uiCount..<handicapFields.count { handicapFields[i].isHidden = true }
        for i in uiCount..<activateButtons.count { activateButtons[i].isHidden = true }
        for i in uiCount..<strokeLabels.count { strokeLabels[i].isHidden = true }
    }

    // MARK: - Model sizing (5-man)
    private func ensureModelHasCapacity(_ g: inout GameData) {
        func resize<T>(_ arr: inout [T], fill: T) {
            if arr.count < capacity { arr += Array(repeating: fill, count: capacity - arr.count) }
            if arr.count > capacity { arr = Array(arr.prefix(capacity)) }
        }
        resize(&g.playerNames, fill: "")
        resize(&g.hcPlayers, fill: 0)
        resize(&g.playerActivated, fill: false)
    }

    // MARK: - Course label
    private func updateCourseLabel() {
        CourseLibrary.shared.seedIfNeeded()

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

    // MARK: - Wiring
    private func wireNameFields() {
        for i in 0..<uiCount {
            let f = nameFields[i]
            f.delegate = self
            f.returnKeyType = .done
            f.autocapitalizationType = .words
            f.addTarget(self, action: #selector(playerNameEdited(_:)), for: .editingDidEnd)
        }
    }

    private func wireHCFields() {
        for i in 0..<uiCount {
            let f = handicapFields[i]
            f.keyboardType = .numberPad
            f.delegate = self
            f.addTarget(self, action: #selector(hcChanged(_:)), for: .editingChanged)
            f.addTarget(self, action: #selector(hcEdited(_:)), for: .editingDidEnd)

            // number pad "Done"
            let bar = UIToolbar(); bar.sizeToFit()
            bar.items = [
                .flexibleSpace(),
                UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKB))
            ]
            f.inputAccessoryView = bar
        }
    }

    private func wireActivateButtons() {
        for i in 0..<uiCount {
            styleActivate(activateButtons[i])
        }
    }

    // MARK: - UI Refresh
    @objc private func reloadFromModel() {
        GameManager.shared.update { g in
            self.ensureModelHasCapacity(&g)
        }
        updateCourseLabel()
        populateFromModel()
        recalcStrokesFromModel()
        enforceActivationCap()
        updateGoButtonEnabled()
        refreshRandomizeEnabled()
    }

    private func populateFromModel() {
        guard let g = GameManager.shared.currentGame else { return }

        for i in 0..<uiCount {
            nameFields[i].text = g.playerNames[safe: i] ?? ""
            handicapFields[i].text = String(g.hcPlayers[safe: i] ?? 0)

            let on = g.playerActivated[safe: i] ?? false
            activateButtons[i].isSelected = on
            activateButtons[i].isEnabled = true
            styleActivate(activateButtons[i])
        }
    }

    private func recalcStrokesFromModel() {
        guard let g = GameManager.shared.currentGame else { return }

        let active = (0..<uiCount).filter { g.playerActivated[safe: $0] == true }
        guard !active.isEmpty else {
            for i in 0..<uiCount { strokeLabels[i].text = "" }
            return
        }

        let minHC = active.map { g.hcPlayers[safe: $0] ?? 0 }.min() ?? 0
        for i in 0..<uiCount {
            let on = g.playerActivated[safe: i] ?? false
            strokeLabels[i].text = on ? String(max(0, (g.hcPlayers[safe: i] ?? 0) - minHC)) : ""
        }
    }

    private func recalcStrokesFromUI() {
        let active = (0..<uiCount).filter { activateButtons[$0].isSelected }
        guard !active.isEmpty else {
            for i in 0..<uiCount { strokeLabels[i].text = "" }
            return
        }

        let hcs = active.map { Int(handicapFields[$0].text ?? "") ?? 0 }
        let minHC = hcs.min() ?? 0

        for i in 0..<uiCount {
            if activateButtons[i].isSelected {
                let hc = Int(handicapFields[i].text ?? "") ?? 0
                strokeLabels[i].text = String(max(0, hc - minHC))
            } else {
                strokeLabels[i].text = ""
            }
        }
    }

    private func enforceActivationCap() {
        let activeCount = activateButtons.prefix(uiCount).filter { $0.isSelected }.count
        let lockOthers = activeCount >= maxActive

        for i in 0..<uiCount {
            let b = activateButtons[i]
            b.isEnabled = b.isSelected || !lockOthers
            styleActivate(b)
        }
    }

    private func updateGoButtonEnabled() {
        let active = activateButtons.prefix(uiCount).filter { $0.isSelected }.count
        goToGameButton.isEnabled = active > 0
        goToGameButton.alpha = goToGameButton.isEnabled ? 1 : 0.5
    }

    private func refreshRandomizeEnabled() {
        let activeCount = activateButtons.prefix(uiCount).filter { $0.isSelected }.count
        let canRand = GameManager.shared.canRandomizeTeams && activeCount >= 2
        randomizeButton.isEnabled = canRand
        randomizeButton.alpha = canRand ? 1.0 : 0.5
    }

    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    // MARK: - Actions
    @objc private func trackFriendsTapped() {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "TrackFriendsVC")
                as? TrackFriendsViewController else { return }
        navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction private func activateTapped(_ sender: UIButton) {
        view.endEditing(true)

        let i = sender.tag
        guard (0..<uiCount).contains(i) else { return }

        let activeCount = activateButtons.prefix(uiCount).filter { $0.isSelected }.count
        if !sender.isSelected && activeCount >= maxActive {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            shake(sender)
            return
        }

        sender.isSelected.toggle()
        styleActivate(sender)

        GameManager.shared.update { g in
            self.ensureModelHasCapacity(&g)
            g.playerActivated[i] = sender.isSelected
        }

        enforceActivationCap()
        updateGoButtonEnabled()
        recalcStrokesFromModel()
        refreshRandomizeEnabled()
        persistEntireSetupFromUI()
    }

    @IBAction private func randomizePlayersTapped(_ sender: UIButton) {
        let activeCount = activateButtons.prefix(uiCount).filter { $0.isSelected }.count
        guard GameManager.shared.canRandomizeTeams, activeCount >= 2 else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            shake(sender)
            return
        }
        view.endEditing(true)

        struct Row { var name: String; var hc: Int; var active: Bool }

        var rows: [Row] = (0..<uiCount).map { i in
            Row(
                name: (nameFields[i].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
                hc:   Int(handicapFields[i].text ?? "") ?? 0,
                active: activateButtons[i].isSelected
            )
        }

        var activeRows = rows.filter { $0.active }
        let inactiveRows = rows.filter { !$0.active }
        activeRows.shuffle()

        let reordered = activeRows + inactiveRows
        let newActiveCount = activeRows.count

        for i in 0..<uiCount {
            nameFields[i].text = reordered[i].name
            handicapFields[i].text = String(reordered[i].hc)
        }

        for i in 0..<uiCount {
            let b = activateButtons[i]
            b.isEnabled = true
            b.isSelected = (i < newActiveCount)
            styleActivate(b)
        }

        enforceActivationCap()
        recalcStrokesFromUI()
        updateGoButtonEnabled()
        persistEntireSetupFromUI()

        GameManager.shared.canRandomizeTeams = false
        refreshRandomizeEnabled()
    }

    @IBAction private func resetGameTapped(_ sender: UIButton) {
        let style: UIAlertController.Style = (traitCollection.userInterfaceIdiom == .pad) ? .alert : .actionSheet
        let ac = UIAlertController(
            title: "Reset current game?",
            message: "Are you sure? This will clear present game data.",
            preferredStyle: style
        )
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        ac.addAction(UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in
            self?.performConfirmedReset()
        })

        if let pop = ac.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
        }
        present(ac, animated: true)
    }

    private func performConfirmedReset() {
        GameManager.shared.resetForNewRoundPreservingCourseAndRoster()
        GameManager.shared.canRandomizeTeams = true

        // Re-ensure 5-man sizing after reset
        GameManager.shared.update { g in
            self.ensureModelHasCapacity(&g)
        }

        populateFromModel()
        recalcStrokesFromModel()
        enforceActivationCap()
        updateGoButtonEnabled()
        refreshRandomizeEnabled()
        updateCourseLabel()

        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    @IBAction private func goToGameTapped(_ sender: UIButton) {
        view.endEditing(true)

        // Ensure game exists
        if GameManager.shared.currentGame == nil {
            if !GameManager.shared.loadLastOpened() {
                GameManager.shared.startNewGame()
            }
        }

        persistEntireSetupFromUI()

        // Validate at least one active, named player
        let hasActiveNamed = (0..<uiCount).contains { i in
            let on = activateButtons[i].isSelected
            let name = (nameFields[i].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return on && !name.isEmpty
        }
        guard hasActiveNamed else {
            showAlert(title: "No Players", message: "Activate at least one player with a name.")
            return
        }

        // Start at Hole 1
        GameManager.shared.update { g in
            g.hole = 0
        }

        // Navigate to game screen
        performSegue(withIdentifier: "showGame", sender: self)
    }

    // MARK: - Editing hooks
    @objc private func playerNameEdited(_ sender: UITextField) {
        let i = sender.tag
        guard (0..<uiCount).contains(i) else { return }

        let text = (sender.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        GameManager.shared.update { g in
            self.ensureModelHasCapacity(&g)
            g.playerNames[i] = text
        }

        if !text.isEmpty {
            GameManager.shared.addNameToRoster(text)
        }

        refreshRandomizeEnabled()
        updateGoButtonEnabled()
        persistEntireSetupFromUI()
    }

    @objc private func hcChanged(_ sender: UITextField) {
        recalcStrokesFromUI()
    }

    @objc private func hcEdited(_ sender: UITextField) {
        let i = sender.tag
        guard (0..<uiCount).contains(i) else { return }

        let hc = Int(sender.text ?? "") ?? 0

        GameManager.shared.update { g in
            self.ensureModelHasCapacity(&g)
            g.hcPlayers[i] = hc
        }

        recalcStrokesFromModel()
        persistEntireSetupFromUI()
    }

    // MARK: - Persistence
    private func persistEntireSetupFromUI() {
        GameManager.shared.update { g in
            self.ensureModelHasCapacity(&g)

            for i in 0..<uiCount {
                g.playerNames[i] = (nameFields[i].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                g.hcPlayers[i] = Int(handicapFields[i].text ?? "") ?? 0
                g.playerActivated[i] = activateButtons[i].isSelected
            }
        }
    }

    // MARK: - Helpers
    @objc private func dismissKB() { view.endEditing(true) }

    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    private func styleActivate(_ button: UIButton) {
        let on = button.isSelected

        if #available(iOS 15.0, *) {
            var cfg = UIButton.Configuration.filled()

            if !button.isEnabled {
                cfg.baseBackgroundColor = .systemGray3
                cfg.baseForegroundColor = .white
                cfg.title = "Max \(maxActive)"
            } else {
                cfg.baseBackgroundColor = on ? .systemBrown : .systemOrange
                cfg.baseForegroundColor = .white
                cfg.title = on ? "Active" : "Activate"
            }

            cfg.cornerStyle = .medium
            button.configuration = cfg
        } else {
            if !button.isEnabled {
                button.backgroundColor = .systemGray3
                button.setTitle("Max \(maxActive)", for: .normal)
            } else {
                button.backgroundColor = on ? .brown : .systemOrange
                button.setTitle(on ? "Active" : "Activate", for: .normal)
            }
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 8
            button.clipsToBounds = true
        }
    }

    private func shake(_ view: UIView) {
        let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
        anim.values = [-6, 6, -5, 5, -3, 3, 0]
        anim.duration = 0.25
        view.layer.add(anim, forKey: "shake")
    }

    // MARK: - Nav
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showGame" else { return }

        // If you ever pass anything forward, do it here.
        // (Your GameVC uses GameManager.shared.currentGame, so nothing is required.)
        _ = segue.destination
    }
}

// MARK: - Small Utilities
private extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
