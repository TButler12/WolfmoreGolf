import UIKit

final class PlayerSetupViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Outlets (row orders must align by TAG: 0..4)
    @IBOutlet private weak var courseLabel: UILabel!

    @IBOutlet private var nameFields: [UITextField]!
    @IBOutlet private var handicapFields: [UITextField]!
    @IBOutlet private var activeSwitches: [UISwitch]!
    @IBOutlet private var strokeLabels: [UILabel]!

    @IBOutlet private weak var randomizeButton: UIButton!
    @IBOutlet private weak var goToGameButton: UIButton!
   
    var isInRoundEdit: Bool = false   // ✅ NEW

    
       

    // Optional
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

        // Ensure model arrays are 5-wide
        GameManager.shared.update { g in
            self.ensureModelHasCapacity(&g)
        }

        CourseLibrary.shared.seedIfNeeded()

        // Sort/retag UI rows 0..4
        normalizeAndTagRows()
        hideExtraRowsBeyondCapacity()

        // Wiring
        wireNameFields()
        wireHCFields()
        wireActiveSwitches()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadFromModel),
            name: .reloadUI,
            object: nil
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Edit Player Tracking",
            style: .plain,
            target: self,
            action: #selector(trackFriendsTapped)
        )
        configureGoToGameButton()
        
        // Initial paint
        updateCourseLabel()
        populateFromModel()
        recalcStrokesFromModel()
        enforceActivationCap()
        updateGoButtonEnabled()
        refreshRandomizeEnabled()
    }
    enum Mode { case preRound, inRound }
       var mode: Mode = .preRound
       var onDone: (() -> Void)?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCourseLabel()
        
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    private func closeToHome(animated: Bool = true) {

        // 1) If we're inside a modally-presented navigation stack, dismiss the whole stack
        if let nav = navigationController, nav.presentingViewController != nil {
            nav.dismiss(animated: animated)
            return
        }

        // 2) If we're presented over something (your sheet case), dismiss self,
        // then pop the underlying nav back to root (Home)
        if let presenter = presentingViewController {
            let presenterNav = presenter.navigationController
            dismiss(animated: animated) {
                presenterNav?.popToRootViewController(animated: animated)
            }
            return
        }

        // 3) Fallback: just pop to root if we're pushed
        navigationController?.popToRootViewController(animated: animated)
    }

    private func pushManagePlayers() {
           let sb = UIStoryboard(name: "Main", bundle: nil)
           let mp = sb.instantiateViewController(withIdentifier: "ManagePlayersVC")
           navigationController?.pushViewController(mp, animated: false)
       }

       private func pushGame() {
           let sb = UIStoryboard(name: "Main", bundle: nil)
           let game = sb.instantiateViewController(withIdentifier: "GameViewController")
           navigationController?.pushViewController(game, animated: true)
       }
    // MARK: - Row normalization
    private func normalizeAndTagRows() {
        func sortViews<T: UIView>(_ views: [T]) -> [T] {
            let tags = views.map { $0.tag }
            let hasUsefulTags = Set(tags).count > 1 || tags.contains(where: { $0 != 0 })
            if hasUsefulTags {
                return views.sorted { $0.tag < $1.tag }
            } else {
                return views.sorted { $0.frame.minY < $1.frame.minY }
            }
        }

        nameFields     = sortViews(nameFields)
        handicapFields = sortViews(handicapFields)
        activeSwitches = sortViews(activeSwitches)
        strokeLabels   = sortViews(strokeLabels)

        let n = min(nameFields.count, handicapFields.count, activeSwitches.count, strokeLabels.count)
        for i in 0..<n {
            nameFields[i].tag = i
            handicapFields[i].tag = i
            activeSwitches[i].tag = i
            strokeLabels[i].tag = i
        }
    }

    private var uiCount: Int {
        min(capacity, nameFields.count, handicapFields.count, activeSwitches.count, strokeLabels.count)
    }

    private func hideExtraRowsBeyondCapacity() {
        for i in uiCount..<nameFields.count { nameFields[i].isHidden = true }
        for i in uiCount..<handicapFields.count { handicapFields[i].isHidden = true }
        for i in uiCount..<activeSwitches.count { activeSwitches[i].isHidden = true }
        for i in uiCount..<strokeLabels.count { strokeLabels[i].isHidden = true }
    }

    // MARK: - Model sizing
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

            let bar = UIToolbar(); bar.sizeToFit()
            bar.items = [
                .flexibleSpace(),
                UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKB))
            ]
            f.inputAccessoryView = bar
        }
    }

    private func wireActiveSwitches() {
        for i in 0..<uiCount {
            activeSwitches[i].addTarget(self, action: #selector(activeSwitchChanged(_:)), for: .valueChanged)
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
            activeSwitches[i].isOn = on
            activeSwitches[i].isEnabled = true

            setRowEnabled(i, enabled: on)
        }
    }

    // MARK: - Row enable/disable styling
    private func setRowEnabled(_ i: Int, enabled: Bool) {
        let alpha: CGFloat = enabled ? 1.0 : 0.35

        nameFields[i].alpha = alpha
        handicapFields[i].alpha = alpha
        strokeLabels[i].alpha = alpha

        // Keep the switch readable
        activeSwitches[i].alpha = 1.0

        // Inactive rows can’t be edited (but can be re-enabled)
        nameFields[i].isEnabled = enabled
        handicapFields[i].isEnabled = enabled
    }

    // MARK: - Strokes
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
        let active = (0..<uiCount).filter { activeSwitches[$0].isOn }
        guard !active.isEmpty else {
            for i in 0..<uiCount { strokeLabels[i].text = "" }
            return
        }

        let hcs = active.map { Int(handicapFields[$0].text ?? "") ?? 0 }
        let minHC = hcs.min() ?? 0

        for i in 0..<uiCount {
            if activeSwitches[i].isOn {
                let hc = Int(handicapFields[i].text ?? "") ?? 0
                strokeLabels[i].text = String(max(0, hc - minHC))
            } else {
                strokeLabels[i].text = ""
            }
        }
    }
    private func configureGoToGameButton() {
        goToGameButton.configuration = wmStyledButton(title: "Go To Game", style: .primary)
    }
    // MARK: - Cap + buttons
    private func enforceActivationCap() {
        let activeCount = activeSwitches.prefix(uiCount).filter { $0.isOn }.count
        let lockOthers = activeCount >= maxActive

        for i in 0..<uiCount {
            let sw = activeSwitches[i]
            // If at cap, you can still turn OFF an ON switch, but can't turn ON more
            sw.isEnabled = sw.isOn || !lockOthers
        }
    }

    private func updateGoButtonEnabled() {
        let active = activeSwitches.prefix(uiCount).filter { $0.isOn }.count
        goToGameButton.isEnabled = active > 0
        goToGameButton.alpha = goToGameButton.isEnabled ? 1 : 0.5
    }

    private func refreshRandomizeEnabled() {
        let activeCount = activeSwitches.prefix(uiCount).filter { $0.isOn }.count
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

    @objc private func activeSwitchChanged(_ sender: UISwitch) {
        view.endEditing(true)

        let i = sender.tag
        guard (0..<uiCount).contains(i) else { return }

        // If trying to turn ON beyond cap, bounce it back OFF.
        if sender.isOn {
            let activeCount = activeSwitches.prefix(uiCount).filter { $0.isOn }.count
            if activeCount > maxActive {
                sender.setOn(false, animated: true)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                shake(sender)
                return
            }
        }

        GameManager.shared.update { g in
            self.ensureModelHasCapacity(&g)
            g.playerActivated[i] = sender.isOn
        }

        setRowEnabled(i, enabled: sender.isOn)

        enforceActivationCap()
        updateGoButtonEnabled()
        recalcStrokesFromModel()
        refreshRandomizeEnabled()
        persistEntireSetupFromUI()
    }

    @IBAction private func randomizePlayersTapped(_ sender: UIButton) {
        let activeCount = activeSwitches.prefix(uiCount).filter { $0.isOn }.count
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
                active: activeSwitches[i].isOn
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
            let on = (i < newActiveCount)
            activeSwitches[i].isEnabled = true
            activeSwitches[i].setOn(on, animated: true)
            setRowEnabled(i, enabled: on)
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

    @IBAction private func goToGameTapped(_ sender: Any) {
        if isInRoundEdit {
              dismiss(animated: true) { [weak self] in
                  self?.onDone?()
              }
              return
          }
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let game = sb.instantiateViewController(withIdentifier: "GameViewController")

        guard let nav = navigationController else { return }
        nav.pushViewController(game, animated: true)

        // Remove ManagePlayers so back goes to Home (not ManagePlayers)
        var vcs = nav.viewControllers
        vcs.removeAll { $0 is ManagePlayersViewController }
        nav.setViewControllers(vcs, animated: false)
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
                g.playerActivated[i] = activeSwitches[i].isOn
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

    private func shake(_ view: UIView) {
        let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
        anim.values = [-6, 6, -5, 5, -3, 3, 0]
        anim.duration = 0.25
        view.layer.add(anim, forKey: "shake")
    }

    // MARK: - Nav
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showGame" else { return }

        if let nav = segue.destination as? UINavigationController {
            nav.modalPresentationStyle = .fullScreen
            nav.modalTransitionStyle = .coverVertical
        } else {
            segue.destination.modalPresentationStyle = .fullScreen
            segue.destination.modalTransitionStyle = .coverVertical
        }
    }
}

