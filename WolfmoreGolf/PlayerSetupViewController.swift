import UIKit
final class PlayerSetupViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Outlets (row orders must align)
    @IBOutlet private var nameFields: [UITextField]!
    @IBOutlet private var handicapFields: [UITextField]!
    @IBOutlet private var activateButtons: [UIButton]!
    @IBOutlet private var strokeLabels: [UILabel]!

    @IBOutlet private weak var randomizeButton: UIButton!
    @IBOutlet private weak var goToGameButton: UIButton!
    @IBOutlet private weak var plusPointDollars: UIButton!
    @IBOutlet private weak var minusPointDollars: UIButton!
    
    
    // MARK: - Constants / State
    private let maxActive = 5
    private var playersForNextGame: [Player] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Ensure we have a game
        if GameManager.shared.currentGame == nil {
            if !GameManager.shared.loadLastOpened() { GameManager.shared.startNewGame() }
        }

        // Wiring
        wireNameFields()
        wireHCFields()
        wireActivateButtons()
        addDismissTap()

        // Observe model/UI reloads
        NotificationCenter.default.addObserver(self, selector: #selector(reloadFromModel), name: .reloadUI, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshGatedButtons), name: .gameStateChanged, object: nil)

        // Initial paint
        populateFromModel()
        recalcStrokesFromModel()
        enforceActivationCap()
        updateGoButtonEnabled()
        refreshGatedButtons()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: - Wiring
    private func wireNameFields() {
        for (i, f) in nameFields.enumerated() {
            f.tag = i
            f.delegate = self
            f.returnKeyType = .done
            f.addTarget(self, action: #selector(playerNameEdited(_:)), for: .editingDidEnd)
        }
    }

    private func wireHCFields() {
        for (i, f) in handicapFields.enumerated() {
            f.tag = i
            f.keyboardType = .numberPad
            f.delegate = self
            f.addTarget(self, action: #selector(hcChanged(_:)), for: .editingChanged)
            f.addTarget(self, action: #selector(hcEdited(_:)),  for: .editingDidEnd)

            // number pad "Done"
            let bar = UIToolbar(); bar.sizeToFit()
            bar.items = [.flexibleSpace(), UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKB))]
            f.inputAccessoryView = bar
        }
    }

    private func wireActivateButtons() {
        for (i, b) in activateButtons.enumerated() {
            b.tag = i
            styleActivate(b)
        }
    }

    private func addDismissTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKB))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    // MARK: - UI Refresh
    @objc private func reloadFromModel() {
        populateFromModel()
        recalcStrokesFromModel()
        enforceActivationCap()
        updateGoButtonEnabled()
        refreshGatedButtons()
    }

    private func populateFromModel() {
        guard let g = GameManager.shared.currentGame else { return }

        for (i, f) in nameFields.enumerated()        where i < g.playerNames.count     { f.text = g.playerNames[i] }
        for (i, f) in handicapFields.enumerated()    where i < g.hcPlayers.count       { f.text = String(g.hcPlayers[i]) }
        for (i, b) in activateButtons.enumerated()   where i < g.playerActivated.count {
            b.isSelected = g.playerActivated[i]
            b.isEnabled  = true
            styleActivate(b)
        }
    }

    private func recalcStrokesFromModel() {
        guard let g = GameManager.shared.currentGame else { return }
        let actives = (0..<min(9, g.playerActivated.count)).filter { g.playerActivated[$0] }
        guard !actives.isEmpty else { strokeLabels.forEach { $0.text = "" }; return }

        let minHC = actives.map { g.hcPlayers[$0] }.min() ?? 0
        for i in 0..<min(strokeLabels.count, g.hcPlayers.count) {
            let on = (i < g.playerActivated.count) ? g.playerActivated[i] : false
            strokeLabels[i].text = on ? String(max(0, g.hcPlayers[i] - minHC)) : ""
        }
    }

    private func recalcStrokesFromUI() {
        // recompute using live UI contents
        var activeIdxs: [Int] = []
        for i in 0..<min(nameFields.count, handicapFields.count, activateButtons.count) where activateButtons[i].isSelected {
            activeIdxs.append(i)
        }
        guard !activeIdxs.isEmpty else { strokeLabels.forEach { $0.text = "" }; return }

        let hcs = activeIdxs.map { Int(handicapFields[$0].text ?? "") ?? 0 }
        let minHC = hcs.min() ?? 0

        for i in 0..<strokeLabels.count {
            if activeIdxs.contains(i) {
                let hc = Int(handicapFields[i].text ?? "") ?? 0
                strokeLabels[i].text = String(max(0, hc - minHC))
            } else {
                strokeLabels[i].text = ""
            }
        }
    }

    private func enforceActivationCap() {
        let active = activateButtons.filter { $0.isSelected }.count
        let lockOthers = active >= maxActive
        for b in activateButtons {
            b.isEnabled = b.isSelected || !lockOthers
            styleActivate(b)
        }
    }

    private func updateGoButtonEnabled() {
        let active = activateButtons.filter { $0.isSelected }.count
        goToGameButton.isEnabled = active > 0
        goToGameButton.alpha = goToGameButton.isEnabled ? 1 : 0.5
    }

    @objc private func refreshGatedButtons() {
        let canRand = GameManager.shared.canRandomizeTeams
        randomizeButton.isEnabled = canRand
        randomizeButton.alpha = canRand ? 1.0 : 0.5
    }

    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder(); return true
    }

    // MARK: - Actions
    @IBAction private func activateTapped(_ sender: UIButton) {
        let i = sender.tag
        let activeCount = activateButtons.filter { $0.isSelected }.count
        if !sender.isSelected && activeCount >= maxActive {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            shake(sender); return
        }

        sender.isSelected.toggle()
        styleActivate(sender)
        enforceActivationCap()
        updateGoButtonEnabled()

        GameManager.shared.update { g in
            if g.playerActivated.count != 9 { g.playerActivated = Array(repeating: false, count: 9) }
            if (0..<9).contains(i) { g.playerActivated[i] = sender.isSelected }
        }
        recalcStrokesFromModel()
    }

    @IBAction private func randomizePlayersTapped(_ sender: UIButton) {
        guard GameManager.shared.canRandomizeTeams else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            shake(sender)
            return
        }
        view.endEditing(true)

        // rows
        let rowCount = min(nameFields.count, handicapFields.count, activateButtons.count)
        struct Row { var name: String; var hc: Int; var active: Bool }
        var rows: [Row] = (0..<rowCount).map { i in
            Row(
                name: (nameFields[i].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
                hc:   Int(handicapFields[i].text ?? "") ?? 0,
                active: activateButtons[i].isSelected
            )
        }

        var activeRows = rows.filter { $0.active }
        let inactiveRows = rows.filter { !$0.active }
        if activeRows.count >= 2 { activeRows.shuffle() }

        let reordered = activeRows + inactiveRows
        let activeCount = activeRows.count

        // write back names/HC
        for i in 0..<rowCount {
            nameFields[i].text     = reordered[i].name
            handicapFields[i].text = String(reordered[i].hc)
        }

        // re-enable all, then set selected top N
        for b in activateButtons { b.isEnabled = true }
        for i in 0..<activateButtons.count {
            let b = activateButtons[i]
            b.isSelected = (i < activeCount)
            styleActivate(b)
        }
        enforceActivationCap()

        // repaint strokes using the active block
        let minHC = activeRows.map { $0.hc }.min() ?? 0
        for i in 0..<strokeLabels.count {
            if i < activeCount, i < reordered.count {
                let hc = reordered[i].hc
                strokeLabels[i].text = String(max(0, hc - minHC))
            } else {
                strokeLabels[i].text = ""
            }
        }

        updateGoButtonEnabled()
        persistEntireSetupFromUI()

        // allow only once per reset (optional)
        GameManager.shared.canRandomizeTeams = false
        NotificationCenter.default.post(name: .gameStateChanged, object: nil)
    }

    @IBAction private func resetGameTapped(_ sender: UIButton) {
        if let g = GameManager.shared.currentGame {
            print("Before reset → par1=\(g.course.pars.first ?? -1), hc1=\(g.course.holeHandicaps.first ?? -1)")
        }

        GameManager.shared.resetForNewRoundPreservingCourseAndRoster()

        if let g = GameManager.shared.currentGame {
            print("After  reset → par1=\(g.course.pars.first ?? -1), hc1=\(g.course.holeHandicaps.first ?? -1)")
        }

        // unlock Randomize after a reset
        GameManager.shared.canRandomizeTeams = true
        NotificationCenter.default.post(name: .gameStateChanged, object: nil)

        populateFromModel()
        recalcStrokesFromUI()
        updateGoButtonEnabled()
    }

    @IBAction private func goToGameTapped(_ sender: UIButton) {
        view.endEditing(true)

        if GameManager.shared.currentGame == nil {
            if !GameManager.shared.loadLastOpened() { GameManager.shared.startNewGame() }
        }

        persistEntireSetupFromUI()

        // validate
        let hasActiveNamed: Bool = (0..<min(nameFields.count, activateButtons.count)).contains { i in
            let on = activateButtons[safe: i]?.isSelected == true
            let name = (nameFields[safe: i]?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return on && !name.isEmpty
        }
        guard hasActiveNamed else {
            showAlert(title: "No Players", message: "Activate at least one player with a name.")
            return
        }

        // optional: start at Hole 1
        GameManager.shared.update { $0.hole = 0 }
        // segue happens in storyboard or elsewhere
    }

    // MARK: - Editing hooks
    @objc private func playerNameEdited(_ sender: UITextField) {
        let i = sender.tag
        let text = (sender.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard (0..<9).contains(i) else { return }

        GameManager.shared.update { g in
            if g.playerNames.count != 9 { g.playerNames = Array(repeating: "", count: 9) }
            g.playerNames[i] = text
        }
        GameManager.shared.addNameToRoster(text)
    }

    @objc private func hcChanged(_ sender: UITextField) {
        recalcStrokesFromUI()
    }

    @objc private func hcEdited(_ sender: UITextField) {
        let i = sender.tag
        let hc = Int(sender.text ?? "") ?? 0
        guard (0..<9).contains(i) else { return }

        GameManager.shared.update { g in
            if g.hcPlayers.count != 9 { g.hcPlayers = Array(repeating: 0, count: 9) }
            g.hcPlayers[i] = hc
        }
        recalcStrokesFromModel()
    }
    

    // MARK: - Persistence
    private func persistEntireSetupFromUI() {
        GameManager.shared.update { g in
            if g.playerNames.count != 9     { g.playerNames     = Array(repeating: "", count: 9) }
            if g.hcPlayers.count != 9       { g.hcPlayers       = Array(repeating: 0,  count: 9) }
            if g.playerActivated.count != 9 { g.playerActivated = Array(repeating: false, count: 9) }

            for (i, f) in nameFields.enumerated()      where i < 9 { g.playerNames[i]     = (f.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines) }
            for (i, f) in handicapFields.enumerated()  where i < 9 { g.hcPlayers[i]       = Int(f.text ?? "") ?? 0 }
            for (i, b) in activateButtons.enumerated() where i < 9 { g.playerActivated[i] = b.isSelected }
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
                cfg.title = "Max 5"
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
                button.setTitle("Max 5", for: .normal)
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

    // MARK: - Nav (if using programmatic segue)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showGame" else { return }
        if let nav = segue.destination as? UINavigationController,
           let dest = nav.topViewController as? GameViewController {
            dest.playersFallback = playersForNextGame
        } else if let dest = segue.destination as? GameViewController {
            dest.playersFallback = playersForNextGame
        }
    }
}

// MARK: - Small Utilities


private extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}

// MARK: - Required elsewhere
extension Notification.Name {
    static let gameStateChanged = Notification.Name("gameStateChanged")
}
