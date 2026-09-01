//
//  GameSettingsViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 3/28/26.
//

import UIKit

final class GameSettingsViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var baseStakeField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var umbrellaButton: UIButton!
    @IBOutlet weak var courseNameLabel: UILabel!
    @IBOutlet weak var changeCourseButton: UIButton!

    private var umbrellaMuted = false
    private weak var wolfScoringSegment: UISegmentedControl?
    private weak var pressStyleSegment: UISegmentedControl?
    private weak var hammerStyleSegment: UISegmentedControl?
    private weak var pressStyleSection: UIStackView?
    private weak var hammerStyleSection: UIStackView?
    private weak var matchPlayTeamsSection: UIStackView?
    private weak var matchPlayTeamsInner: UIStackView?
    private weak var matchPlay36Switch: UISwitch?
    private weak var dualMatchSwitch: UISwitch?
    private weak var matchPlaySubModeSegment: UISegmentedControl?
    private weak var goLiveButton: UIButton?
    private var scrollView: UIScrollView!
    private var contentStack: UIStackView!

    var gameData: GameData?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let darkGreen = UIColor(red: 0.118, green: 0.227, blue: 0.165, alpha: 1.0)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = darkGreen
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        appearance.backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Game Settings"
        view.backgroundColor = .systemBackground

        buildScrollLayout()

        baseStakeField.delegate = self
        baseStakeField.keyboardType = .decimalPad

        let bar = UIToolbar()
        bar.sizeToFit()
        bar.items = [
            .flexibleSpace(),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneTapped))
        ]
        baseStakeField.inputAccessoryView = bar

        if let g = GameManager.shared.currentGame {
            baseStakeField.text = formatMoney(Double(g.baseGameStake))
            umbrellaMuted = g.isUmbrella
        } else {
            baseStakeField.text = "2"
            umbrellaMuted = false
        }

        refreshCourseLabel()
        refreshUmbrellaButtonUI()
        installWolfScoringSegment()
        installPressStyleSegment()
        installHammerStyleSegment()
        installMatchPlayTeamsSection()
        refreshMatchPlayUI()
        installGoLiveButton()
        NotificationCenter.default.addObserver(self, selector: #selector(refreshGoLiveButton), name: .reloadUI, object: nil)
        saveButton.configuration = wmStyledButton(title: "Save", style: .primary)

        addKeyboardObservers()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboardObservers()
        NotificationCenter.default.removeObserver(self, name: .reloadUI, object: nil)
        let restored = UINavigationBarAppearance()
        restored.configureWithDefaultBackground()
        navigationController?.navigationBar.standardAppearance = restored
        navigationController?.navigationBar.scrollEdgeAppearance = restored
        navigationController?.navigationBar.tintColor = nil
    }

    // MARK: - Scroll Layout

    private func buildScrollLayout() {
        view.subviews.forEach { $0.isHidden = true }

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
        scrollView = scroll

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
        main.spacing = 20
        main.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(main)
        NSLayoutConstraint.activate([
            main.topAnchor.constraint(equalTo: content.topAnchor, constant: 24),
            main.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            main.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            main.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -30),
        ])
        contentStack = main

        // Stake section
        let stakeField = UITextField()
        stakeField.borderStyle = .roundedRect
        stakeField.font = UIFont.preferredFont(forTextStyle: .body)
        stakeField.adjustsFontForContentSizeCategory = true
        stakeField.translatesAutoresizingMaskIntoConstraints = false
        stakeField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        baseStakeField = stakeField
        main.addArrangedSubview(vSection("Base Stake ($)", body: stakeField))

        // Umbrella button
        let umbrella = UIButton(type: .system)
        umbrella.translatesAutoresizingMaskIntoConstraints = false
        umbrella.heightAnchor.constraint(equalToConstant: 48).isActive = true
        umbrella.addTarget(self, action: #selector(umbrellaTapped(_:)), for: .touchUpInside)
        umbrellaButton = umbrella
        main.addArrangedSubview(umbrella)

        // Course section
        let nameLabel = UILabel()
        nameLabel.font = UIFont.preferredFont(forTextStyle: .body)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.textColor = .label
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        courseNameLabel = nameLabel

        let changeBtn = UIButton(type: .system)
        changeBtn.setTitle("Change Course", for: .normal)
        changeBtn.titleLabel?.font = UIFont.preferredFont(forTextStyle: .callout)
        changeBtn.setContentHuggingPriority(.required, for: .horizontal)
        changeBtn.addTarget(self, action: #selector(changeCourseTapped(_:)), for: .touchUpInside)
        changeCourseButton = changeBtn

        let courseRow = UIStackView(arrangedSubviews: [nameLabel, changeBtn])
        courseRow.axis = .horizontal
        courseRow.spacing = 8
        courseRow.alignment = .center
        main.addArrangedSubview(vSection("Course", body: courseRow))

        // Save button (wolf segment inserts before this in installWolfScoringSegment)
        let save = UIButton(type: .system)
        save.translatesAutoresizingMaskIntoConstraints = false
        save.heightAnchor.constraint(equalToConstant: 52).isActive = true
        save.addTarget(self, action: #selector(saveTapped(_:)), for: .touchUpInside)
        saveButton = save
        main.addArrangedSubview(save)
    }

    private func sectionHeader(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = UIFont.preferredFont(forTextStyle: .subheadline)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = .secondaryLabel
        return l
    }

    private func vSection(_ title: String, body: UIView) -> UIStackView {
        let s = UIStackView(arrangedSubviews: [sectionHeader(title), body])
        s.axis = .vertical
        s.spacing = 8
        return s
    }

    // MARK: - Keyboard

    private func addKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(
            self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(
            self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ n: Notification) {
        guard let frame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let inset = frame.height - view.safeAreaInsets.bottom
        scrollView.contentInset.bottom = inset
        scrollView.verticalScrollIndicatorInsets.bottom = inset
    }

    @objc private func keyboardWillHide(_ n: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }

    // MARK: - Wolf Scoring segment

    private func installWolfScoringSegment() {
        let header = sectionHeader("Wolf Scoring Options")

        let segment = UISegmentedControl(items: ["6-Point", "Wolf 2pt", "LowBall", "Match Play"])
        segment.addTarget(self, action: #selector(wolfScoringChanged(_:)), for: .valueChanged)

        segment.backgroundColor = .systemGray6
        segment.selectedSegmentTintColor = .wolfMoreGreen
        segment.setTitleTextAttributes([
            .foregroundColor: UIColor.secondaryLabel,
            .font: UIFont.systemFont(ofSize: 13, weight: .regular)
        ], for: .normal)
        segment.setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold)
        ], for: .selected)
        segment.layer.borderColor = UIColor.systemGray4.cgColor
        segment.layer.borderWidth = 1

        if let g = GameManager.shared.currentGame {
            switch g.resolvedGameType {
            case .sixPointScotch: segment.selectedSegmentIndex = 0
            case .wolf:           segment.selectedSegmentIndex = 1
            case .wolfLowBall:    segment.selectedSegmentIndex = 2
            case .matchPlay:      segment.selectedSegmentIndex = 3
            case .bestBall:       segment.selectedSegmentIndex = 3
            case .hammer:         segment.selectedSegmentIndex = 0
            case .tournament:     break
            }
            // Disable Match Play for odd player counts (teams need equal sides)
            let activePlayers = g.playerNames.enumerated()
                .filter { g.playerActivated[$0.offset] && !$0.element.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .count
            if activePlayers % 2 != 0 { segment.setEnabled(false, forSegmentAt: 3) }
        }

        let wolfSection = UIStackView(arrangedSubviews: [header, segment])
        wolfSection.axis = .vertical
        wolfSection.spacing = 8

        let insertIndex = max(0, contentStack.arrangedSubviews.count - 1)
        contentStack.insertArrangedSubview(wolfSection, at: insertIndex)

        wolfScoringSegment = segment
    }

    @objc private func wolfScoringChanged(_ sender: UISegmentedControl) {
        let newType: GameType
        switch sender.selectedSegmentIndex {
        case 0: newType = .sixPointScotch
        case 1: newType = .wolf
        case 2: newType = .wolfLowBall
        default:
            // Keep .bestBall if already in that sub-mode; default to .matchPlay for new switches.
            newType = (GameManager.shared.currentGame?.resolvedGameType == .bestBall) ? .bestBall : .matchPlay
        }
        GameManager.shared.update { g in
            g.gameType = newType
            g.normalize()
            if newType != .sixPointScotch { g.isUmbrella = false }
            // Auto-set stake to $1 when switching to Match Play / Best Ball
            if newType.isMatchPlay {
                g.baseGameStake = 1
                g.gameHoleDollarsArray = Array(repeating: 1.0, count: g.totalHoles)
                g.holeBaseAmount       = Array(repeating: 1.0, count: g.totalHoles)
            }
            // Initialize default team split when switching to Match Play / Best Ball
            if newType.isMatchPlay, g.matchPlayTeamA == nil {
                let active = g.playerNames.enumerated()
                    .filter { g.playerActivated[$0.offset] && !$0.element.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                    .map { $0.offset }
                let half = active.count / 2
                g.matchPlayTeamA = Array(active.prefix(half))
                g.matchPlayTeamB = Array(active.dropFirst(half))
            }
        }
        if newType.isMatchPlay { baseStakeField.text = "1" }
        NotificationCenter.default.post(name: .reloadUI, object: nil)
        umbrellaButton.alpha = (sender.selectedSegmentIndex == 0) ? 1.0 : 0.4
        refreshMatchPlayUI()
    }

    // MARK: - Press Style segment

    private func installPressStyleSegment() {
        let segment = UISegmentedControl(items: ["Doubling", "Additive"])
        segment.addTarget(self, action: #selector(pressStyleChanged(_:)), for: .valueChanged)
        segment.backgroundColor          = .systemGray6
        segment.selectedSegmentTintColor = UIColor(displayP3Red: 0.751, green: 0.819, blue: 0.370, alpha: 1)
        segment.setTitleTextAttributes([
            .foregroundColor: UIColor.secondaryLabel,
            .font: UIFont.systemFont(ofSize: 14, weight: .regular)
        ], for: .normal)
        segment.setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
        ], for: .selected)
        segment.layer.borderColor = UIColor.systemGray4.cgColor
        segment.layer.borderWidth = 1

        let style = GameManager.shared.currentGame?.pressStyle ?? .doubling
        segment.selectedSegmentIndex = (style == .additive) ? 1 : 0

        let note = UILabel()
        note.font          = UIFont.preferredFont(forTextStyle: .caption1)
        note.textColor     = .secondaryLabel
        note.numberOfLines = 0
        note.text          = "Doubling: ×2, ×4, ×8… each tap  •  Additive: +$base each tap (×2, ×3, ×4…)"

        let section = UIStackView(arrangedSubviews: [sectionHeader("Press Style"), segment, note])
        section.axis    = .vertical
        section.spacing = 6

        let insertIndex = max(0, contentStack.arrangedSubviews.count - 1)
        contentStack.insertArrangedSubview(section, at: insertIndex)
        pressStyleSegment = segment
        pressStyleSection = section
    }

    @objc private func pressStyleChanged(_ sender: UISegmentedControl) {
        let style: HammerStyle = (sender.selectedSegmentIndex == 1) ? .additive : .doubling
        GameManager.shared.update { g in g.pressStyle = style }
        NotificationCenter.default.post(name: .reloadUI, object: nil)
    }

    // MARK: - Hammer Style segment

    private func installHammerStyleSegment() {
        let segment = UISegmentedControl(items: ["Doubling", "Additive"])
        segment.addTarget(self, action: #selector(hammerStyleChanged(_:)), for: .valueChanged)
        segment.backgroundColor          = .systemGray6
        segment.selectedSegmentTintColor = UIColor(displayP3Red: 0.751, green: 0.819, blue: 0.370, alpha: 1)
        segment.setTitleTextAttributes([
            .foregroundColor: UIColor.secondaryLabel,
            .font: UIFont.systemFont(ofSize: 14, weight: .regular)
        ], for: .normal)
        segment.setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
        ], for: .selected)
        segment.layer.borderColor = UIColor.systemGray4.cgColor
        segment.layer.borderWidth = 1

        let style = GameManager.shared.currentGame?.hammerStyle ?? .additive
        segment.selectedSegmentIndex = (style == .additive) ? 1 : 0

        let note = UILabel()
        note.font          = UIFont.preferredFont(forTextStyle: .caption1)
        note.textColor     = .secondaryLabel
        note.numberOfLines = 0
        note.text          = "Doubling: ×2, ×4, ×8… each tap  •  Additive: +$base each tap (×2, ×3, ×4…)"

        let section = UIStackView(arrangedSubviews: [sectionHeader("Hammer Style"), segment, note])
        section.axis    = .vertical
        section.spacing = 6

        let insertIndex = max(0, contentStack.arrangedSubviews.count - 1)
        contentStack.insertArrangedSubview(section, at: insertIndex)
        hammerStyleSegment = segment
        hammerStyleSection = section
    }

    @objc private func hammerStyleChanged(_ sender: UISegmentedControl) {
        let style: HammerStyle = (sender.selectedSegmentIndex == 1) ? .additive : .doubling
        GameManager.shared.update { g in g.hammerStyle = style }
        NotificationCenter.default.post(name: .reloadUI, object: nil)
    }

    // MARK: - Match Play Teams

    private func installMatchPlayTeamsSection() {
        let header = sectionHeader("Match Play Teams")

        let inner = UIStackView()
        inner.axis    = .vertical
        inner.spacing = 10
        matchPlayTeamsInner = inner

        let container = UIStackView(arrangedSubviews: [header, inner])
        container.axis    = .vertical
        container.spacing = 8
        container.isHidden = true
        matchPlayTeamsSection = container

        let insertIndex = max(0, contentStack.arrangedSubviews.count - 1)
        contentStack.insertArrangedSubview(container, at: insertIndex)
    }

    private func refreshMatchPlayTeamsContent() {
        guard let inner = matchPlayTeamsInner else { return }
        inner.arrangedSubviews.forEach { $0.removeFromSuperview() }

        guard let g = GameManager.shared.currentGame else { return }

        // ── Sub-mode: Match Play (holes up/down) vs Best Ball (stroke total) ──
        let subModeSeg = UISegmentedControl(items: ["Match Play", "Best Ball"])
        subModeSeg.selectedSegmentIndex = (g.resolvedGameType == .bestBall) ? 1 : 0
        subModeSeg.backgroundColor          = .systemGray6
        subModeSeg.selectedSegmentTintColor = .wolfMoreGreen
        subModeSeg.setTitleTextAttributes([
            .foregroundColor: UIColor.secondaryLabel,
            .font: UIFont.systemFont(ofSize: 13, weight: .regular)
        ], for: .normal)
        subModeSeg.setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold)
        ], for: .selected)
        subModeSeg.addTarget(self, action: #selector(matchPlaySubModeChanged(_:)), for: .valueChanged)
        matchPlaySubModeSegment = subModeSeg
        inner.addArrangedSubview(subModeSeg)

        let sep0 = UIView()
        sep0.backgroundColor = .separator
        sep0.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        inner.addArrangedSubview(sep0)

        // ── 36-Hole toggle ───────────────────────────────────────────────────
        let switchLbl = UILabel()
        switchLbl.text = "36-Hole Round"
        switchLbl.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        switchLbl.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let sw = UISwitch()
        sw.onTintColor = .wolfMoreGreen
        sw.isOn = g.matchPlay36Holes
        sw.addTarget(self, action: #selector(matchPlay36Toggled(_:)), for: .valueChanged)
        matchPlay36Switch = sw

        let switchRow = UIStackView(arrangedSubviews: [switchLbl, sw])
        switchRow.axis = .horizontal; switchRow.alignment = .center; switchRow.spacing = 8
        inner.addArrangedSubview(switchRow)

        let switchNote = UILabel()
        switchNote.text = "Holes 19–36 replay the same course as holes 1–18."
        switchNote.font = UIFont.systemFont(ofSize: 12)
        switchNote.textColor = .secondaryLabel
        switchNote.numberOfLines = 0
        inner.addArrangedSubview(switchNote)

        // ── Separator ────────────────────────────────────────────────────────
        let sep = UIView()
        sep.backgroundColor = .separator
        sep.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        inner.addArrangedSubview(sep)

        // ── Dual Match toggle ────────────────────────────────────────────────
        let dualLbl = UILabel()
        dualLbl.text = "Dual Match"
        dualLbl.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        dualLbl.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let isBestBall = g.resolvedGameType == .bestBall

        let dualSw = UISwitch()
        dualSw.onTintColor = .wolfMoreGreen
        dualSw.isOn = g.isDualMatch
        dualSw.isEnabled = !isBestBall
        dualSw.alpha = isBestBall ? 0.4 : 1.0
        dualSw.addTarget(self, action: #selector(dualMatchToggled(_:)), for: .valueChanged)
        dualMatchSwitch = dualSw

        dualLbl.alpha = isBestBall ? 0.4 : 1.0

        let dualRow = UIStackView(arrangedSubviews: [dualLbl, dualSw])
        dualRow.axis = .horizontal; dualRow.alignment = .center; dualRow.spacing = 8
        inner.addArrangedSubview(dualRow)

        let dualNote = UILabel()
        dualNote.text = isBestBall
            ? "Not available for Best Ball — needs 2+ players per team."
            : "Two matches at once (e.g. McTommy vs Test AND G vs Y)."
        dualNote.font = UIFont.systemFont(ofSize: 12)
        dualNote.textColor = .secondaryLabel
        dualNote.numberOfLines = 0
        inner.addArrangedSubview(dualNote)

        let sep2 = UIView()
        sep2.backgroundColor = .separator
        sep2.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        inner.addArrangedSubview(sep2)

        // ── Team assignment ──────────────────────────────────────────────────
        let active = g.playerNames.enumerated()
            .filter { g.playerActivated[$0.offset] && !$0.element.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { ($0.offset, $0.element) }

        let isDual   = g.isDualMatch
        let teamASet = Set(g.matchPlayTeamA  ?? [])
        let teamA2   = Set(g.matchPlayTeamA2 ?? [])
        let teamB2   = Set(g.matchPlayTeamB2 ?? [])

        let segItems: [String] = isDual ? ["1:A", "1:B", "2:A", "2:B"] : ["Team A", "Team B"]
        let segWidth: CGFloat  = isDual ? 220 : 160

        for (seat, name) in active {
            let nameLbl = UILabel()
            nameLbl.text = name
            nameLbl.font = UIFont.systemFont(ofSize: 15, weight: .medium)
            nameLbl.setContentHuggingPriority(.defaultLow, for: .horizontal)

            let seg = UISegmentedControl(items: segItems)
            if isDual {
                if teamASet.contains(seat)  { seg.selectedSegmentIndex = 0 }
                else if teamA2.contains(seat) { seg.selectedSegmentIndex = 2 }
                else if teamB2.contains(seat) { seg.selectedSegmentIndex = 3 }
                else                         { seg.selectedSegmentIndex = 1 }  // default M1-B
            } else {
                seg.selectedSegmentIndex = teamASet.contains(seat) ? 0 : 1
            }
            seg.tag = seat
            seg.backgroundColor          = .systemGray6
            seg.selectedSegmentTintColor = .wolfMoreGreen
            seg.setTitleTextAttributes([
                .foregroundColor: UIColor.secondaryLabel,
                .font: UIFont.systemFont(ofSize: 12, weight: .regular)
            ], for: .normal)
            seg.setTitleTextAttributes([
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 12, weight: .semibold)
            ], for: .selected)
            seg.addTarget(self, action: #selector(matchPlayTeamChanged(_:)), for: .valueChanged)
            seg.setContentHuggingPriority(.required, for: .horizontal)
            seg.widthAnchor.constraint(equalToConstant: segWidth).isActive = true

            let row = UIStackView(arrangedSubviews: [nameLbl, seg])
            row.axis      = .horizontal
            row.spacing   = 8
            row.alignment = .center
            inner.addArrangedSubview(row)
        }
    }

    private func refreshMatchPlayUI() {
        let isMatchPlay = wolfScoringSegment?.selectedSegmentIndex == 3
        pressStyleSection?.isHidden  = isMatchPlay
        hammerStyleSection?.isHidden = isMatchPlay
        if isMatchPlay {
            refreshMatchPlayTeamsContent()
            matchPlayTeamsSection?.isHidden = false
        } else {
            matchPlayTeamsSection?.isHidden = true
        }
    }

    @objc private func matchPlayTeamChanged(_ sender: UISegmentedControl) {
        let movingSeat = sender.tag
        let newSlot    = sender.selectedSegmentIndex  // 0=1:A 1=1:B 2=2:A 3=2:B

        GameManager.shared.update { g in
            guard g.isDualMatch else {
                // Non-dual: simple 2-slot assignment, teams can share players.
                var a1 = g.matchPlayTeamA ?? []
                var b1 = g.matchPlayTeamB ?? []
                a1.removeAll { $0 == movingSeat }
                b1.removeAll { $0 == movingSeat }
                if newSlot == 0 { a1.append(movingSeat) } else { b1.append(movingSeat) }
                g.matchPlayTeamA = a1.sorted()
                g.matchPlayTeamB = b1.sorted()
                return
            }

            // Dual match: 4-slot exclusive picker — each slot must have exactly one player.
            // Enforce this by swapping: whoever is in the destination slot moves to the
            // moving player's old slot.
            var a1 = g.matchPlayTeamA  ?? []
            var b1 = g.matchPlayTeamB  ?? []
            var a2 = g.matchPlayTeamA2 ?? []
            var b2 = g.matchPlayTeamB2 ?? []

            func currentSlot(of seat: Int) -> Int? {
                if a1.contains(seat) { return 0 }
                if b1.contains(seat) { return 1 }
                if a2.contains(seat) { return 2 }
                if b2.contains(seat) { return 3 }
                return nil
            }
            func playersIn(slot: Int) -> [Int] {
                switch slot { case 0: return a1; case 1: return b1; case 2: return a2; default: return b2 }
            }
            func place(_ seat: Int, in slot: Int) {
                switch slot {
                case 0: a1.append(seat); case 1: b1.append(seat)
                case 2: a2.append(seat); default: b2.append(seat)
                }
            }
            func removeFromAll(_ seat: Int) {
                a1.removeAll { $0 == seat }; b1.removeAll { $0 == seat }
                a2.removeAll { $0 == seat }; b2.removeAll { $0 == seat }
            }

            let oldSlot   = currentSlot(of: movingSeat) ?? -1
            guard oldSlot != newSlot else { return }  // already here — no-op

            // Whoever occupies the destination slot gets bumped to the vacated slot (swap).
            let displaced = playersIn(slot: newSlot).filter { $0 != movingSeat }

            for seat in [movingSeat] + displaced { removeFromAll(seat) }

            place(movingSeat, in: newSlot)
            for d in displaced { if oldSlot >= 0 { place(d, in: oldSlot) } }

            g.matchPlayTeamA  = a1.sorted()
            g.matchPlayTeamB  = b1.sorted()
            g.matchPlayTeamA2 = a2.sorted()
            g.matchPlayTeamB2 = b2.sorted()
        }
        // Rebuild all segment controls so the displaced player's control also updates visually.
        refreshMatchPlayTeamsContent()
    }

    @objc private func matchPlaySubModeChanged(_ sender: UISegmentedControl) {
        let newType: GameType = (sender.selectedSegmentIndex == 1) ? .bestBall : .matchPlay
        GameManager.shared.update { g in
            g.gameType = newType
            // Dual Match requires 2+ players per team — incompatible with Best Ball.
            if newType == .bestBall, g.isDualMatch {
                var a1 = g.matchPlayTeamA ?? []
                var b1 = g.matchPlayTeamB ?? []
                for s in (g.matchPlayTeamA2 ?? []) where !a1.contains(s) { a1.append(s) }
                for s in (g.matchPlayTeamB2 ?? []) where !b1.contains(s) { b1.append(s) }
                g.matchPlayTeamA  = a1.sorted()
                g.matchPlayTeamB  = b1.sorted()
                g.matchPlayTeamA2 = nil
                g.matchPlayTeamB2 = nil
            }
        }
        NotificationCenter.default.post(name: .reloadUI, object: nil)
        refreshMatchPlayTeamsContent()
    }

    @objc private func dualMatchToggled(_ sender: UISwitch) {
        GameManager.shared.update { g in
            if sender.isOn {
                let teamA = (g.matchPlayTeamA ?? []).sorted()
                let teamB = (g.matchPlayTeamB ?? []).sorted()
                let inMatch1 = Set(teamA + teamB)
                let active = g.playerNames.indices.filter {
                    g.playerActivated[$0] && !g.playerNames[$0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                }.sorted()
                let notInMatch1 = active.filter { !inMatch1.contains($0) }

                if !notInMatch1.isEmpty {
                    // Spare players not yet in Match 1 — seed Match 2 from them
                    let half = max(1, notInMatch1.count / 2)
                    g.matchPlayTeamA2 = Array(notInMatch1.prefix(half))
                    g.matchPlayTeamB2 = Array(notInMatch1.suffix(from: half))
                } else {
                    // All players are in Match 1 (2v2) — split into two 1v1 matches.
                    // Keep the first player from each side in Match 1; move the rest to Match 2.
                    g.matchPlayTeamA  = teamA.count > 0 ? [teamA[0]] : []
                    g.matchPlayTeamB  = teamB.count > 0 ? [teamB[0]] : []
                    g.matchPlayTeamA2 = teamA.count > 1 ? Array(teamA.dropFirst()) : (teamB.count > 1 ? [] : [])
                    g.matchPlayTeamB2 = teamB.count > 1 ? Array(teamB.dropFirst()) : []
                }
            } else {
                // Merge Match 2 players back into Match 1 before clearing
                var a1 = g.matchPlayTeamA ?? []
                var b1 = g.matchPlayTeamB ?? []
                for s in (g.matchPlayTeamA2 ?? []) where !a1.contains(s) { a1.append(s) }
                for s in (g.matchPlayTeamB2 ?? []) where !b1.contains(s) { b1.append(s) }
                g.matchPlayTeamA  = a1.sorted()
                g.matchPlayTeamB  = b1.sorted()
                g.matchPlayTeamA2 = nil
                g.matchPlayTeamB2 = nil
            }
        }
        refreshMatchPlayTeamsContent()
    }

    @objc private func matchPlay36Toggled(_ sender: UISwitch) {
        GameManager.shared.update { g in
            g.matchPlay36Holes = sender.isOn
            g.extendToTotalHoles()
        }
        NotificationCenter.default.post(name: .reloadUI, object: nil)
    }

    // MARK: - Go Live

    private func installGoLiveButton() {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.heightAnchor.constraint(equalToConstant: 48).isActive = true
        btn.addTarget(self, action: #selector(goLiveTapped), for: .touchUpInside)
        goLiveButton = btn

        let insertIndex = max(0, contentStack.arrangedSubviews.count - 1)
        contentStack.insertArrangedSubview(btn, at: insertIndex)

        refreshGoLiveButton()
    }

    @objc private func refreshGoLiveButton() {
        guard let btn = goLiveButton else { return }
        let isLive = GameManager.shared.currentGame?.liveSessionId != nil
        let title = isLive ? "Stop Live" : "Go Live"
        let style: WMButtonStyle = isLive ? .destructive : .secondary
        btn.configuration = wmStyledButton(title: title, style: style)
    }

    @objc private func goLiveTapped() {
        WolfActions.presentGoLive(from: self)
    }

    @objc private func doneTapped() {
        view.endEditing(true)
    }

    @IBAction func umbrellaTapped(_ sender: UIButton) {
        umbrellaMuted.toggle()
        refreshUmbrellaButtonUI()
    }

    @IBAction func saveTapped(_ sender: UIButton) {
        saveSettings()
    }

    @IBAction func changeCourseTapped(_ sender: UIButton) {
        let sb = UIStoryboard(name: "Main", bundle: nil)

        guard let vc = sb.instantiateViewController(withIdentifier: "CoursePickerVC") as? CoursePickerViewController else {
            return
        }

        vc.onPickCourse = { [weak self] courseID in
            guard let self else { return }

            guard let picked = CourseLibrary.shared.courses.first(where: { $0.id == courseID }) else {
                return
            }

            GameManager.shared.update { g in
                g.course.pars          = picked.pars
                g.course.holeHandicaps = picked.hcs
                g.course.name          = picked.name
                g.course.id            = picked.id
            }

            CourseLibrary.shared.selectedCourseID = picked.id
            GameManager.shared.saveCurrent()
            NotificationCenter.default.post(name: .reloadUI, object: nil)

            self.refreshCourseLabel()
            self.navigationController?.popViewController(animated: true)
        }

        navigationController?.pushViewController(vc, animated: true)
    }

    private func saveSettings() {
        let clean = (baseStakeField.text ?? "")
            .replacingOccurrences(of: "$", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let stake = Double(clean), stake > 0 else {
            showAlert(title: "Invalid Stake", message: "Enter a valid dollar amount greater than 0.")
            return
        }

        GameManager.shared.update { g in
            g.baseGameStake = Int(stake)
            g.isUmbrella = umbrellaMuted
            g.gameHoleDollarsArray = Array(repeating: stake, count: STANDARD_HOLES)
            g.holeBaseAmount       = Array(repeating: stake, count: STANDARD_HOLES)
        }

        GameManager.shared.saveCurrent()
        navigationController?.popViewController(animated: true)
    }

    private func refreshCourseLabel() {
        guard let g = GameManager.shared.currentGame else {
            courseNameLabel.text = "No Course"
            return
        }

        let stored = g.course.name.trimmingCharacters(in: .whitespacesAndNewlines)
        courseNameLabel.text = stored.isEmpty ? "Custom Course" : stored
    }

    private func refreshUmbrellaButtonUI() {
        let title = umbrellaMuted ? "Umbrella: OFF" : "Umbrella: ON"
        let appGreen = UIColor(red: 0.10, green: 0.33, blue: 0.18, alpha: 1.0)
        let bg = umbrellaMuted ? UIColor.systemGray4 : appGreen

        if #available(iOS 15.0, *) {
            var cfg = umbrellaButton.configuration ?? UIButton.Configuration.filled()
            cfg.title = title
            cfg.baseBackgroundColor = bg
            cfg.baseForegroundColor = .white

            cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
                outgoing.foregroundColor = UIColor.white
                return outgoing
            }

            umbrellaButton.configuration = cfg
            umbrellaButton.setTitleColor(.white, for: .normal)
            umbrellaButton.setTitleColor(.white, for: .highlighted)
            umbrellaButton.setTitleColor(.white, for: .selected)
            umbrellaButton.setTitleColor(.white, for: .disabled)
        } else {
            umbrellaButton.setTitle(title, for: .normal)
            umbrellaButton.backgroundColor = bg
            umbrellaButton.setTitleColor(.white, for: .normal)
            umbrellaButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            umbrellaButton.alpha = 1.0
        }
    }

    private func formatMoney(_ value: Double) -> String {
        if value == floor(value) {
            return String(Int(value))
        } else {
            return String(format: "%.2f", value)
        }
    }

    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
