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

    
    var gameData: GameData!

    // Optional
    @IBOutlet private weak var plusPointDollars: UIButton?
    @IBOutlet private weak var minusPointDollars: UIButton?

    // MARK: - Constants
    private let capacity = 5
    private var maxActive: Int { capacity }
    private let settingsButton = UIButton(type: .system)
    private weak var gameInfoLabel: UILabel?
    private weak var stakeInfoLabel: UILabel?
   
 
    override func viewDidLoad() {
        super.viewDidLoad()

        if GameManager.shared.currentGame == nil {
            if !GameManager.shared.loadLastOpened() { GameManager.shared.startNewGame() }
        }
        GameManager.shared.update { g in self.ensureModelHasCapacity(&g) }
        CourseLibrary.shared.seedIfNeeded()

        // Configure settings button before layout (buildDynamicUI inserts it)
        var settingsCfg = UIButton.Configuration.filled()
        settingsCfg.title = "Edit Game Settings"
        settingsCfg.image = UIImage(systemName: "gearshape.fill")
        settingsCfg.imagePlacement = .leading
        settingsCfg.imagePadding = 8
        settingsCfg.baseBackgroundColor = UIColor(red: 0.10, green: 0.35, blue: 0.20, alpha: 1.0)
        settingsCfg.baseForegroundColor = .white
        settingsCfg.cornerStyle = .large
        settingsCfg.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        settingsCfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs; a.font = UIFont.preferredFont(forTextStyle: .callout); return a
        }
        settingsButton.configuration = settingsCfg
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)

        // Replace fixed-frame storyboard layout with Dynamic Type–aware layout
        buildDynamicUI()

        normalizeAndTagRows()
        hideExtraRowsBeyondCapacity()
        wireNameFields()
        wireHCFields()
        wireActiveSwitches()

        NotificationCenter.default.addObserver(
            self, selector: #selector(reloadFromModel), name: .reloadUI, object: nil)

        navigationItem.rightBarButtonItem = nil

        updateCourseLabel()
        populateFromModel()
        recalcStrokesFromModel()
        enforceActivationCap()
        updateGoButtonEnabled()
        refreshRandomizeEnabled()
    }

    // MARK: - Dynamic Layout

    private func buildDynamicUI() {
        // Hide every storyboard-placed subview; we take over completely
        view.subviews.forEach { $0.isHidden = true }

        // ── Create new outlet-backed views ────────────────────────────
        var nfs = [UITextField](), hfs = [UITextField]()
        var sws = [UISwitch](),    sls = [UILabel]()

        for i in 0..<capacity {
            let nf = makeEntryField(tag: i)
            nf.returnKeyType = .done
            nf.autocapitalizationType = .words
            nfs.append(nf)

            let hf = makeEntryField(tag: i)
            hf.keyboardType = .numberPad
            hf.textAlignment = .center
            hfs.append(hf)

            let sw = UISwitch(); sw.tag = i; sws.append(sw)

            let sl = UILabel()
            sl.tag = i
            sl.font = UIFont.preferredFont(forTextStyle: .body)
            sl.adjustsFontForContentSizeCategory = true
            sl.textAlignment = .right
            sl.setContentHuggingPriority(.required, for: .horizontal)
            sl.setContentCompressionResistancePriority(.required, for: .horizontal)
            sls.append(sl)
        }

        nameFields     = nfs
        handicapFields = hfs
        activeSwitches = sws
        strokeLabels   = sls

        let goBtn = makeFilledButton(title: "Go To Game", bg: .wolfMoreGreen, fg: .white)
        goBtn.addTarget(self, action: #selector(goToGameTapped(_:)), for: .touchUpInside)
        goToGameButton = goBtn

        let resetBtn = makeFilledButton(
            title: "Reset for New Game",
            bg: .systemGray,
            fg: .white)
        resetBtn.addTarget(self, action: #selector(resetGameTapped(_:)), for: .touchUpInside)

        let randBtn = makeFilledButton(title: "Randomize", bg: .systemBrown, fg: .white)
        randBtn.addTarget(self, action: #selector(randomizePlayersTapped(_:)), for: .touchUpInside)
        randomizeButton = randBtn

        let newCourseLabel = UILabel()
        newCourseLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        newCourseLabel.adjustsFontForContentSizeCategory = true
        newCourseLabel.numberOfLines = 0
        newCourseLabel.textColor = .secondaryLabel
        courseLabel = newCourseLabel

        // ── Scroll + content stack ─────────────────────────────────────
        let scroll = UIScrollView()
        scroll.alwaysBounceVertical = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
        ])

        let main = UIStackView()
        main.axis = .vertical
        main.spacing = 14
        main.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(main)
        NSLayoutConstraint.activate([
            main.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            main.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            main.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
            main.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -30),
        ])

        // Fixed column widths — wide enough for content, narrow enough to give name room
        let switchColW: CGFloat = 60
        let hcColW: CGFloat     = 50
        let strokeColW: CGFloat = 34

        // Header row
        let hdrRow = hRow()
        hdrRow.addArrangedSubview(fixedSpacer(switchColW))
        hdrRow.addArrangedSubview(hdrLabel("Player"))
        let hcH = hdrLabel("HC"); hcH.textAlignment = .center
        hcH.widthAnchor.constraint(equalToConstant: hcColW).isActive = true
        hdrRow.addArrangedSubview(hcH)
        let sH = hdrLabel("S"); sH.textAlignment = .right
        sH.widthAnchor.constraint(equalToConstant: strokeColW).isActive = true
        hdrRow.addArrangedSubview(sH)
        main.addArrangedSubview(hdrRow)
        main.addArrangedSubview(hairline())

        // Player rows
        for i in 0..<capacity {
            let row = hRow()

            // Switch in fixed-width container so column width never shifts
            let swWrap = UIView()
            swWrap.translatesAutoresizingMaskIntoConstraints = false
            swWrap.widthAnchor.constraint(equalToConstant: switchColW).isActive = true
            let sw = sws[i]
            sw.translatesAutoresizingMaskIntoConstraints = false
            swWrap.addSubview(sw)
            NSLayoutConstraint.activate([
                sw.centerXAnchor.constraint(equalTo: swWrap.centerXAnchor),
                sw.centerYAnchor.constraint(equalTo: swWrap.centerYAnchor),
                swWrap.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            ])

            nfs[i].translatesAutoresizingMaskIntoConstraints = false

            hfs[i].translatesAutoresizingMaskIntoConstraints = false
            hfs[i].widthAnchor.constraint(equalToConstant: hcColW).isActive = true

            sls[i].translatesAutoresizingMaskIntoConstraints = false
            sls[i].widthAnchor.constraint(equalToConstant: strokeColW).isActive = true

            [swWrap, nfs[i], hfs[i], sls[i]].forEach { row.addArrangedSubview($0) }
            main.addArrangedSubview(row)
        }

        let newGameLabel = UILabel()
        newGameLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        newGameLabel.adjustsFontForContentSizeCategory = true
        newGameLabel.numberOfLines = 0
        newGameLabel.textColor = .secondaryLabel
        gameInfoLabel = newGameLabel

        let newStakeLabel = UILabel()
        newStakeLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        newStakeLabel.adjustsFontForContentSizeCategory = true
        newStakeLabel.numberOfLines = 0
        newStakeLabel.textColor = .secondaryLabel
        stakeInfoLabel = newStakeLabel

        main.addArrangedSubview(hairline())
        main.addArrangedSubview(newCourseLabel)
        main.setCustomSpacing(2, after: newCourseLabel)
        main.addArrangedSubview(newGameLabel)
        main.setCustomSpacing(2, after: newGameLabel)
        main.addArrangedSubview(newStakeLabel)
        main.setCustomSpacing(20, after: newStakeLabel)
        main.addArrangedSubview(goBtn)
        main.setCustomSpacing(10, after: goBtn)
        main.addArrangedSubview(resetBtn)
        main.setCustomSpacing(10, after: resetBtn)
        main.addArrangedSubview(randBtn)
        main.setCustomSpacing(24, after: randBtn)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        main.addArrangedSubview(settingsButton)
    }

    // MARK: - Layout helpers

    private func makeEntryField(tag: Int) -> UITextField {
        let tf = UITextField()
        tf.tag = tag
        tf.font = UIFont.preferredFont(forTextStyle: .body)
        tf.adjustsFontForContentSizeCategory = true
        tf.backgroundColor = .systemBackground
        tf.borderStyle = .none
        tf.layer.borderColor = UIColor.systemGray4.cgColor
        tf.layer.borderWidth = 1
        tf.layer.cornerRadius = 7
        tf.layer.masksToBounds = true
        return tf
    }

    private func makeFilledButton(title: String, bg: UIColor, fg: UIColor) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.translatesAutoresizingMaskIntoConstraints = false
        var cfg = UIButton.Configuration.filled()
        cfg.title = title
        cfg.baseBackgroundColor = bg
        cfg.baseForegroundColor = fg
        cfg.cornerStyle = .large
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs
            a.font = UIFont.preferredFont(forTextStyle: .callout)
            return a
        }
        btn.configuration = cfg
        return btn
    }

    private func hRow() -> UIStackView {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 8
        s.alignment = .center
        s.distribution = .fill
        return s
    }

    private func hdrLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = UIFont.preferredFont(forTextStyle: .caption1)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = .secondaryLabel
        return l
    }

    private func hairline() -> UIView {
        let v = UIView()
        v.backgroundColor = .separator
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return v
    }

    private func fixedSpacer(_ width: CGFloat) -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.widthAnchor.constraint(equalToConstant: width).isActive = true
        return v
    }
    
    @IBAction func gameSettingsTapped(_ sender: UIButton) {
        guard let g = GameManager.shared.currentGame else { return }

        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "GameSettingsViewController") as! GameSettingsViewController
        vc.gameData = g
        navigationController?.pushViewController(vc, animated: true)
    }
    @objc private func settingsTapped() {
        let ac = UIAlertController(title: "Settings", message: "Choose settings to edit", preferredStyle: .actionSheet)

        ac.addAction(UIAlertAction(title: "Wolf Settings", style: .default) { _ in
            self.openGameSettings()
        })

        ac.addAction(UIAlertAction(title: "Nassau Settings", style: .default) { _ in
            self.openNassauSettings()
        })

        ac.addAction(UIAlertAction(title: "Skins Settings", style: .default) { _ in
            self.openSkinsSettings()
        })

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.sourceView = settingsButton
            pop.sourceRect = settingsButton.bounds
        }

        present(ac, animated: true)
    }
    private func openGameSettings() {
        guard let g = GameManager.shared.currentGame else { return }

        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "GameSettingsViewController") as? GameSettingsViewController else {
            return
        }

        vc.gameData = g
        navigationController?.pushViewController(vc, animated: true)
    }

    private func openNassauSettings() {
        guard GameManager.shared.currentGame != nil else { return }

        GameManager.shared.update { g in
            if g.nassauState == nil {
                g.nassauState = NassauState(
                    settings: NassauSettings(),
                    oneVsOneMatches: [],
                    twoVsTwoMatches: []
                )
            }
        }

        guard let updatedGame = GameManager.shared.currentGame else { return }

        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "NassauSettingsViewController") as? NassauSettingsViewController else {
            return
        }

        vc.gameData = updatedGame
        navigationController?.pushViewController(vc, animated: true)
    }

    private func openSkinsSettings() {
        guard GameManager.shared.currentGame != nil else { return }

        GameManager.shared.update { g in
            if g.skinsState == nil {
                g.skinsState = SkinsEngine.makeDefaultState()
            }
        }

        guard let updatedGame = GameManager.shared.currentGame else { return }

        let vc = SkinsSettingsViewController()
        vc.gameData = updatedGame
        navigationController?.pushViewController(vc, animated: true)
    }
    @objc private func baseStakeChanged() {
        guard let g = GameManager.shared.currentGame else { return }

      
       

       

        GameManager.shared.saveCurrent()
    }
    enum Mode { case preRound, inRound }
       var mode: Mode = .preRound
       var onDone: (() -> Void)?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCourseLabel()
        showPlayerSetupOnboardingIfNeeded()
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

        let currentPars = Array(g.course.pars.prefix(STANDARD_HOLES))
        let currentHCs  = Array(g.course.holeHandicaps.prefix(STANDARD_HOLES))

        let match = CourseLibrary.shared.courses.first { c in
            Array(c.pars.prefix(STANDARD_HOLES)) == currentPars &&
            Array(c.hcs.prefix(STANDARD_HOLES))  == currentHCs
        }

        if let course = match {
            let isHome = (course.id.uuidString == ProfileStore.homeCourseID)
            courseLabel.text = isHome ? "Course: ⭐ \(course.name)" : "Course: \(course.name)"
        } else {
            courseLabel.text = "Course: Custom"
        }

        gameInfoLabel?.text  = "Game:   \(g.gameType?.displayName ?? "Casual")"
        stakeInfoLabel?.text = "Stake:  $\(g.baseGameStake)"
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
        randomizeButton.alpha = 1.0
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
    @IBAction func nassauSettingsTapped(_ sender: UIButton) {
        guard GameManager.shared.currentGame != nil else { return }

        GameManager.shared.update { g in
            if g.nassauState == nil {
                g.nassauState = NassauState(
                    settings: NassauSettings(),
                    oneVsOneMatches: [],
                    twoVsTwoMatches: []
                )
            }
        }

        guard let updatedGame = GameManager.shared.currentGame else { return }

        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "NassauSettingsViewController") as! NassauSettingsViewController
        vc.gameData = updatedGame
        navigationController?.pushViewController(vc, animated: true)
    }
     @IBAction private func randomizePlayersTapped(_ sender: UIButton) {
        let activeCount = activeSwitches.prefix(uiCount).filter { $0.isOn }.count
        guard GameManager.shared.canRandomizeTeams, activeCount >= 2 else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            shake(sender)
            return
        }

        view.endEditing(true)

        struct Row {
            var name: String
            var hc: Int
            var active: Bool
        }

        let rows: [Row] = (0..<uiCount).map { i in
            Row(
                name: (nameFields[i].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
                hc: Int(handicapFields[i].text ?? "") ?? 0,
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
        rebuildNassauAfterRandomize()

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
        navigationController?.pushViewController(game, animated: true)
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
    private func rebuildNassauAfterRandomize() {
        GameManager.shared.update { g in
            self.ensureModelHasCapacity(&g)

            let existingSettings = g.nassauState?.settings ?? NassauSettings()

            var newState = NassauEngine.makeDefaultState(
                playerNames: g.playerNames,
                activeFlags: g.playerActivated
            )

            newState.settings = existingSettings
            newState.oneVsOneMatches = NassauEngine.makeAllOneVsOneMatches(
                playerNames: g.playerNames,
                activeFlags: g.playerActivated,
                scoringMode: .net,
                stake: existingSettings.baseStake
            )
            newState.twoVsTwoMatches = NassauEngine.makeDefaultTwoVsTwoMatches(
                playerNames: g.playerNames,
                activeFlags: g.playerActivated,
                scoringMode: .net,
                stake: existingSettings.baseStake
            )

            g.nassauState = newState
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
    private func showPlayerSetupOnboardingIfNeeded() {
        let key = "onboarding_player_setup_shown"
        let defaults = UserDefaults.standard

        if defaults.bool(forKey: key) { return }

        let ac = UIAlertController(
            title: "Before You Start",
            message: """
    Activate the golfers playing this round.

    Then open Stake and Game Settings to choose your game, stake, and options.
    """,
            preferredStyle: .alert
        )

        ac.addAction(UIAlertAction(title: "Activate Players", style: .default))

        ac.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            self.settingsTapped()
        })

        ac.addAction(UIAlertAction(title: "Later", style: .cancel))

        ac.addAction(UIAlertAction(title: "Don't Show Again", style: .destructive) { _ in
            defaults.set(true, forKey: key)
        })

        present(ac, animated: true)
    }
}

