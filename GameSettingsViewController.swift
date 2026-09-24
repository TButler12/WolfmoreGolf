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
    private weak var nineHoleSwitch: UISwitch?
    private weak var nineHoleStartingHoleLabel: UILabel?
    private weak var nineHoleHalfNoteLabel: UILabel?
    private weak var dualMatchSwitch: UISwitch?
    private weak var matchPlaySubModeSegment: UISegmentedControl?
    private weak var goLiveButton: UIButton?
    private weak var teamTeeSwitch: UISwitch?
    private weak var teamTeeConfigureButton: UIButton?
    private weak var skinsCarryoverSegment: UISegmentedControl?
    private weak var sfModeSegment: UISegmentedControl?
    private weak var sfModifiedSettingsStack: UIStackView?
    private var sfSettingsStepperValues: [Int: Int] = [0: 8, 1: 4, 2: 2, 3: 0, 4: -1, 5: -3]
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
        if GameManager.shared.currentGame?.tournamentCode != nil {
            changeCourseButton.isHidden = true
        }
        refreshUmbrellaButtonUI()
        installWolfScoringSegment()
        installPressStyleSegment()
        installHammerStyleSegment()
        installMatchPlayTeamsSection()
        refreshMatchPlayUI()
        installTeamTeeSection()
        installSkinsCarryoverSection()
        installModifiedStablefordSection()
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
        let g0 = GameManager.shared.currentGame
        let stakeInTournament = g0?.tournamentCode != nil && g0?.tournamentGameType == "wolf"
        if stakeInTournament {
            let info = UILabel()
            info.numberOfLines = 0
            info.font = .preferredFont(forTextStyle: .footnote)
            info.textColor = .secondaryLabel
            let stakeVal = g0?.baseGameStake ?? 2
            info.text = "Set by tournament organizer — $\(stakeVal) per hole"
            main.addArrangedSubview(vSection("Base Stake", body: info))
            let dummy = UITextField()
            dummy.text = String(stakeVal)
            dummy.isHidden = true
            baseStakeField = dummy
        } else {
            let stakeField = UITextField()
            stakeField.borderStyle = .roundedRect
            stakeField.font = UIFont.preferredFont(forTextStyle: .body)
            stakeField.adjustsFontForContentSizeCategory = true
            stakeField.translatesAutoresizingMaskIntoConstraints = false
            stakeField.heightAnchor.constraint(equalToConstant: 44).isActive = true
            baseStakeField = stakeField
            main.addArrangedSubview(vSection("Base Stake ($)", body: stakeField))
        }

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
        let g = GameManager.shared.currentGame
        let inTournament = g?.tournamentCode != nil

        var subviews: [UIView] = [sectionHeader("Wolf Scoring Options")]

        if inTournament {
            let info = UILabel()
            info.numberOfLines = 0
            info.font = .preferredFont(forTextStyle: .footnote)
            info.textColor = .secondaryLabel
            let variantName: String
            switch g?.resolvedGameType {
            case .wolf:        variantName = "Wolf 2pt"
            case .wolfLowBall: variantName = "LowBall"
            case .matchPlay:   variantName = "Match Play"
            default:           variantName = "6-Point Scotch"
            }
            info.text = "Set by tournament organizer — \(variantName)"
            subviews.append(info)
        } else {
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

            if let g {
                switch g.resolvedGameType {
                case .sixPointScotch: segment.selectedSegmentIndex = 0
                case .wolf:           segment.selectedSegmentIndex = 1
                case .wolfLowBall:    segment.selectedSegmentIndex = 2
                case .matchPlay:      segment.selectedSegmentIndex = 3
                case .fourball:       segment.selectedSegmentIndex = 3
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

            subviews.append(segment)
            wolfScoringSegment = segment
        }

        let wolfSection = UIStackView(arrangedSubviews: subviews)
        wolfSection.axis = .vertical
        wolfSection.spacing = 8

        let insertIndex = max(0, contentStack.arrangedSubviews.count - 1)
        contentStack.insertArrangedSubview(wolfSection, at: insertIndex)
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
        let header = sectionHeader("Match Play Format")

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

        // ── Sub-mode: Individual / Fourball / FB Stroke Play ──
        let subModeSeg = UISegmentedControl(items: ["Individual", "Fourball", "FB Stroke Play"])
        subModeSeg.selectedSegmentIndex = g.resolvedGameType == .fourball ? 1
                                        : g.resolvedGameType == .bestBall  ? 2 : 0
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

        // ── 9-Hole Match toggle (hidden when 36-hole is active) ──────────────
        if !g.matchPlay36Holes {
            let nineLbl = UILabel()
            nineLbl.text = "9-Hole Match"
            nineLbl.font = UIFont.systemFont(ofSize: 15, weight: .medium)
            nineLbl.setContentHuggingPriority(.defaultLow, for: .horizontal)

            let nineSw = UISwitch()
            nineSw.onTintColor = .wolfMoreGreen
            nineSw.isOn = g.isNineHoleMatch
            nineSw.addTarget(self, action: #selector(nineHoleMatchToggled(_:)), for: .valueChanged)
            nineHoleSwitch = nineSw

            let nineRow = UIStackView(arrangedSubviews: [nineLbl, nineSw])
            nineRow.axis = .horizontal; nineRow.alignment = .center; nineRow.spacing = 8
            inner.addArrangedSubview(nineRow)

            let nineNote = UILabel()
            nineNote.text = "Confined to front 9 or back 9 based on starting hole."
            nineNote.font = UIFont.systemFont(ofSize: 12)
            nineNote.textColor = .secondaryLabel
            nineNote.numberOfLines = 0
            inner.addArrangedSubview(nineNote)

            if g.isNineHoleMatch {
                let shLbl = UILabel()
                shLbl.text = "Starting Hole"
                shLbl.font = UIFont.systemFont(ofSize: 15, weight: .medium)
                shLbl.setContentHuggingPriority(.defaultLow, for: .horizontal)

                let valLbl = UILabel()
                valLbl.text = "\(g.nineHoleStartingHole)"
                valLbl.font = UIFont.systemFont(ofSize: 15)
                valLbl.textColor = .label
                valLbl.textAlignment = .right
                valLbl.widthAnchor.constraint(equalToConstant: 28).isActive = true
                nineHoleStartingHoleLabel = valLbl

                let stepper = UIStepper()
                stepper.minimumValue = 1
                stepper.maximumValue = Double(STANDARD_HOLES)
                stepper.stepValue = 1
                stepper.value = Double(g.nineHoleStartingHole)
                stepper.addTarget(self, action: #selector(nineHoleStartingHoleChanged(_:)), for: .valueChanged)

                let shRow = UIStackView(arrangedSubviews: [shLbl, valLbl, stepper])
                shRow.axis = .horizontal; shRow.alignment = .center; shRow.spacing = 8
                inner.addArrangedSubview(shRow)

                let isFront = g.nineHoleStartingHole <= 9
                let seq = g.nineHoleSequence.map { $0 + 1 }.map { "\($0)" }.joined(separator: ", ")
                let halfNote = UILabel()
                halfNote.text = "\(isFront ? "Front" : "Back") 9 · Hole order: \(seq)"
                halfNote.font = UIFont.systemFont(ofSize: 12)
                halfNote.textColor = .secondaryLabel
                halfNote.numberOfLines = 0
                nineHoleHalfNoteLabel = halfNote
                inner.addArrangedSubview(halfNote)
            }

            let sepNine = UIView()
            sepNine.backgroundColor = .separator
            sepNine.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
            inner.addArrangedSubview(sepNine)
        }

        // ── 36-Hole toggle (hidden when 9-hole match is active) ──────────────
        if !g.isNineHoleMatch {
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

            let sep = UIView()
            sep.backgroundColor = .separator
            sep.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
            inner.addArrangedSubview(sep)
        }

        // ── Dual Match toggle ────────────────────────────────────────────────
        let dualLbl = UILabel()
        dualLbl.text = "1 vs 1"
        dualLbl.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        dualLbl.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let isIndividual = g.resolvedGameType == .matchPlay

        let dualSw = UISwitch()
        dualSw.onTintColor = .wolfMoreGreen
        dualSw.isOn = g.isDualMatch
        dualSw.isEnabled = isIndividual
        dualSw.alpha = isIndividual ? 1.0 : 0.4
        dualSw.addTarget(self, action: #selector(dualMatchToggled(_:)), for: .valueChanged)
        dualMatchSwitch = dualSw

        dualLbl.alpha = isIndividual ? 1.0 : 0.4

        let dualRow = UIStackView(arrangedSubviews: [dualLbl, dualSw])
        dualRow.axis = .horizontal; dualRow.alignment = .center; dualRow.spacing = 8
        inner.addArrangedSubview(dualRow)

        let dualNote = UILabel()
        dualNote.text = isIndividual
            ? "Two simultaneous 1v1 matches (e.g. McTommy vs Bob AND Todd vs G)."
            : "Only available in Individual mode."
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
        let newType: GameType
        switch sender.selectedSegmentIndex {
        case 1:  newType = .fourball
        case 2:  newType = .bestBall
        default: newType = .matchPlay
        }
        GameManager.shared.update { g in
            g.gameType = newType
            if newType == .matchPlay, !g.isDualMatch {
                // Default 1 vs 1 to ON when switching to Individual.
                let teamA = (g.matchPlayTeamA ?? []).sorted()
                let teamB = (g.matchPlayTeamB ?? []).sorted()
                let active = g.playerNames.indices.filter {
                    g.playerActivated[$0] && !g.playerNames[$0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                }.sorted()
                let notInMatch1 = active.filter { !Set(teamA + teamB).contains($0) }
                if !notInMatch1.isEmpty {
                    let half = max(1, notInMatch1.count / 2)
                    g.matchPlayTeamA2 = Array(notInMatch1.prefix(half))
                    g.matchPlayTeamB2 = Array(notInMatch1.suffix(from: half))
                } else {
                    g.matchPlayTeamA  = teamA.count > 0 ? [teamA[0]] : []
                    g.matchPlayTeamB  = teamB.count > 0 ? [teamB[0]] : []
                    g.matchPlayTeamA2 = teamA.count > 1 ? Array(teamA.dropFirst()) : []
                    g.matchPlayTeamB2 = teamB.count > 1 ? Array(teamB.dropFirst()) : []
                }
            } else if newType != .matchPlay, g.isDualMatch {
                // 1 vs 1 only available in Individual — clear it for Fourball / FB Stroke Play.
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
        if let sw = dualMatchSwitch {
            sw.setOn(newType == .matchPlay, animated: true)
        }
        NotificationCenter.default.post(name: .reloadUI, object: nil)
        refreshMatchPlayTeamsContent()
    }

    @objc private func dualMatchToggled(_ sender: UISwitch) {
        GameManager.shared.update { g in
            if sender.isOn {
                // Default: pair players in natural seat order.
                // Seat 0 vs Seat 1 = Match 1, Seat 2 vs Seat 3 = Match 2.
                let active = g.playerNames.indices.filter {
                    g.playerActivated[$0] && !g.playerNames[$0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                }.sorted()
                if active.count >= 4 {
                    g.matchPlayTeamA  = [active[0]]
                    g.matchPlayTeamB  = [active[1]]
                    g.matchPlayTeamA2 = [active[2]]
                    g.matchPlayTeamB2 = [active[3]]
                } else if active.count == 3 {
                    g.matchPlayTeamA  = [active[0]]
                    g.matchPlayTeamB  = [active[1]]
                    g.matchPlayTeamA2 = [active[2]]
                    g.matchPlayTeamB2 = []
                } else if active.count >= 2 {
                    g.matchPlayTeamA  = [active[0]]
                    g.matchPlayTeamB  = [active[1]]
                    g.matchPlayTeamA2 = []
                    g.matchPlayTeamB2 = []
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
            if sender.isOn { g.isNineHoleMatch = false }
            g.extendToTotalHoles()
        }
        NotificationCenter.default.post(name: .reloadUI, object: nil)
        refreshMatchPlayTeamsContent()
    }

    @objc private func nineHoleMatchToggled(_ sender: UISwitch) {
        GameManager.shared.update { g in
            g.isNineHoleMatch = sender.isOn
            if sender.isOn {
                g.matchPlay36Holes = false
                g.hole = 0
                g.startHole = nil
                g.scores        = Array(repeating: Array(repeating: nil, count: STANDARD_HOLES), count: MAX_PLAYERS)
                g.holeCommitted = Array(repeating: false, count: STANDARD_HOLES)
            }
        }
        NotificationCenter.default.post(name: .reloadUI, object: nil)
        refreshMatchPlayTeamsContent()
    }

    @objc private func nineHoleStartingHoleChanged(_ sender: UIStepper) {
        let val = Int(sender.value)
        GameManager.shared.update { g in
            g.nineHoleStartingHole = val
            g.hole = 0
            g.startHole = nil
            g.scores        = Array(repeating: Array(repeating: nil, count: STANDARD_HOLES), count: MAX_PLAYERS)
            g.holeCommitted = Array(repeating: false, count: STANDARD_HOLES)
        }
        refreshMatchPlayTeamsContent()
    }

    // MARK: - Team Tee Game

    private func installTeamTeeSection() {
        let g = GameManager.shared.currentGame
        let inTournament = g?.tournamentCode != nil

        var subviews: [UIView] = [sectionHeader("Team Tee Game")]

        if inTournament {
            // Read-only: show what the organizer configured.
            let info = UILabel()
            info.numberOfLines = 0
            info.font = .preferredFont(forTextStyle: .footnote)
            info.textColor = .secondaryLabel
            if let tt = g?.teamTeeSettings, tt.isEnabled {
                let modeStr: String
                switch tt.countMode {
                case .fixed: modeStr = "Fixed, count \(tt.fixedCount)"
                case .byPar: modeStr = "\(tt.par3Count)-\(tt.par4Count)-\(tt.par5Count) by par"
                }
                info.text = "Set by tournament organizer — \(modeStr)"
            } else {
                info.text = "Team Tee Game not enabled for this tournament."
            }
            subviews.append(info)
        } else {
            // Standalone: editable toggle + configure button.
            let isEnabled = g?.teamTeeSettings?.isEnabled ?? false

            let sw = UISwitch()
            sw.isOn = isEnabled
            sw.addTarget(self, action: #selector(teamTeeSwitchChanged(_:)), for: .valueChanged)
            teamTeeSwitch = sw

            let rowLbl = UILabel()
            rowLbl.text = "Track Team Tee Game"
            rowLbl.font = .systemFont(ofSize: 16)
            rowLbl.setContentHuggingPriority(.defaultLow, for: .horizontal)
            let toggleRow = UIStackView(arrangedSubviews: [rowLbl, sw])
            toggleRow.axis = .horizontal
            toggleRow.alignment = .center
            toggleRow.spacing = 8

            let cfg = UIButton(type: .system)
            cfg.setTitle("Configure Count Rules →", for: .normal)
            cfg.titleLabel?.font = .systemFont(ofSize: 14)
            cfg.contentHorizontalAlignment = .left
            cfg.addTarget(self, action: #selector(teamTeeConfigureTapped), for: .touchUpInside)
            cfg.isHidden = !isEnabled
            teamTeeConfigureButton = cfg

            let note = UILabel()
            note.text = "Scores the lowest N net scores per hole across the foursome, computed automatically from scores already entered."
            note.font = .preferredFont(forTextStyle: .caption1)
            note.textColor = .secondaryLabel
            note.numberOfLines = 0

            subviews += [toggleRow, cfg, note]
        }

        let section = UIStackView(arrangedSubviews: subviews)
        section.axis = .vertical
        section.spacing = 8

        let insertIndex = max(0, contentStack.arrangedSubviews.count - 1)
        contentStack.insertArrangedSubview(section, at: insertIndex)
    }

    private func installSkinsCarryoverSection() {
        let g = GameManager.shared.currentGame
        let isSkinsTournament = g?.tournamentGameType == "skins"
        let hasLocalSkins = g?.skinsState?.settings.isEnabled == true
        guard isSkinsTournament || hasLocalSkins else { return }

        let inTournament = g?.tournamentCode != nil
        var subviews: [UIView] = [sectionHeader("Skins: Tie Handling")]

        if inTournament {
            let info = UILabel()
            info.numberOfLines = 0
            info.font = .preferredFont(forTextStyle: .footnote)
            info.textColor = .secondaryLabel
            let carries = g?.tournamentCarryTies == true
            info.text = "Set by tournament organizer — \(carries ? "Carryover: tied holes carry their value to the next hole" : "No carryover: tied holes have no skin winner")"
            subviews.append(info)
        } else {
            let seg = UISegmentedControl(items: ["No Carry", "Carry Ties"])
            seg.selectedSegmentIndex = (g?.skinsState?.settings.carryoversEnabled == true) ? 1 : 0
            seg.addTarget(self, action: #selector(skinsCarryoverChanged(_:)), for: .valueChanged)
            skinsCarryoverSegment = seg

            let note = UILabel()
            note.text = "No Carry: tied holes have no skin winner. Carry Ties: a tie rolls the skin value into the next hole."
            note.font = .preferredFont(forTextStyle: .caption1)
            note.textColor = .secondaryLabel
            note.numberOfLines = 0

            subviews += [seg, note]
        }

        let section = UIStackView(arrangedSubviews: subviews)
        section.axis = .vertical
        section.spacing = 8

        let insertIndex = max(0, contentStack.arrangedSubviews.count - 1)
        contentStack.insertArrangedSubview(section, at: insertIndex)
    }

    // MARK: - Modified Stableford Section

    private func installModifiedStablefordSection() {
        let g = GameManager.shared.currentGame
        let isStablefordActive = g?.gameType == .tournament
            || g?.tournamentGameType == "stableford"
            || g?.tournamentStablefordEnabled == true
        guard isStablefordActive else { return }

        let inTournament = g?.tournamentCode != nil
        var subviews: [UIView] = [sectionHeader("Stableford Scoring Mode")]

        if inTournament {
            let info = UILabel()
            info.numberOfLines = 0
            info.font = .preferredFont(forTextStyle: .footnote)
            info.textColor = .secondaryLabel
            let mode = g?.stablefordMode ?? .standard
            if mode == .modified, let t = g.flatMap({ $0.modifiedStablefordTable }) {
                info.text = "Set by tournament organizer — Modified: Dbl Eagle+ = \(sfPtStr(t.doubleEagleOrBetter)), Eagle = \(sfPtStr(t.eagleOrBetter)), Birdie = \(sfPtStr(t.birdie)), Par = \(sfPtStr(t.par)), Bogey = \(sfPtStr(t.bogey)), Double+ = \(sfPtStr(t.doubleBogeyOrWorse))"
            } else {
                info.text = "Set by tournament organizer — Standard Stableford"
            }
            subviews.append(info)
        } else {
            let seg = UISegmentedControl(items: ["Standard", "Modified"])
            seg.selectedSegmentIndex = (g?.stablefordMode == .modified) ? 1 : 0
            seg.addTarget(self, action: #selector(sfModeSegmentChanged(_:)), for: .valueChanged)
            sfModeSegment = seg
            subviews.append(seg)

            let modStack = buildModifiedSFStack()
            sfModifiedSettingsStack = modStack
            modStack.isHidden = (g?.stablefordMode != .modified)
            subviews.append(modStack)
        }

        let section = UIStackView(arrangedSubviews: subviews)
        section.axis = .vertical
        section.spacing = 8
        let insertIndex = max(0, contentStack.arrangedSubviews.count - 1)
        contentStack.insertArrangedSubview(section, at: insertIndex)
    }

    private func sfPtStr(_ v: Int) -> String { v > 0 ? "+\(v)" : "\(v)" }

    @objc private func sfModeSegmentChanged(_ seg: UISegmentedControl) {
        let isModified = seg.selectedSegmentIndex == 1
        sfModifiedSettingsStack?.isHidden = !isModified
        GameManager.shared.update { g in
            g.stablefordMode = isModified ? .modified : .standard
        }
    }

    @objc private func sfSettingsStepperChanged(_ stepper: UIStepper) {
        let v = Int(stepper.value)
        sfSettingsStepperValues[stepper.tag] = v
        if let row = stepper.superview as? UIStackView,
           let lbl = row.arrangedSubviews.compactMap({ $0 as? UILabel }).first(where: { $0.tag == stepper.tag + 100 }) {
            lbl.text = sfPtStr(v)
            lbl.textColor = v >= 0 ? .systemGreen : .systemRed
        }
        GameManager.shared.update { g in
            var t = g.modifiedStablefordTable ?? ModifiedStablefordTable()
            switch stepper.tag {
            case 0: t.doubleEagleOrBetter = v
            case 1: t.eagleOrBetter       = v
            case 2: t.birdie              = v
            case 3: t.par                 = v
            case 4: t.bogey               = v
            case 5: t.doubleBogeyOrWorse  = v
            default: break
            }
            g.modifiedStablefordTable = t
        }
    }

    private func buildModifiedSFStack() -> UIStackView {
        let g = GameManager.shared.currentGame
        let t = g?.modifiedStablefordTable ?? ModifiedStablefordTable()
        let labels = ["Double Eagle+", "Eagle", "Birdie", "Par", "Bogey", "Double Bogey+"]
        let values = [t.doubleEagleOrBetter, t.eagleOrBetter, t.birdie, t.par, t.bogey, t.doubleBogeyOrWorse]
        sfSettingsStepperValues = Dictionary(uniqueKeysWithValues: zip(0..<6, values))
        let rows = (0..<6).map { i in makeSFSettingsStepperRow(label: labels[i], value: values[i], tag: i) }
        let stack = UIStackView(arrangedSubviews: rows)
        stack.axis    = .vertical
        stack.spacing = 10
        return stack
    }

    private func makeSFSettingsStepperRow(label text: String, value: Int, tag: Int) -> UIView {
        let nameLabel = UILabel()
        nameLabel.text = text
        nameLabel.font = .systemFont(ofSize: 14)
        nameLabel.textColor = .secondaryLabel
        nameLabel.setContentHuggingPriority(.required, for: .horizontal)

        let valueLabel = UILabel()
        valueLabel.text = sfPtStr(value)
        valueLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .semibold)
        valueLabel.textColor = value >= 0 ? .systemGreen : .systemRed
        valueLabel.textAlignment = .center
        valueLabel.tag = tag + 100
        valueLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true

        let stepper = UIStepper()
        stepper.minimumValue = -10
        stepper.maximumValue = 10
        stepper.stepValue = 1
        stepper.value = Double(value)
        stepper.tag = tag
        stepper.addTarget(self, action: #selector(sfSettingsStepperChanged(_:)), for: .valueChanged)

        let row = UIStackView(arrangedSubviews: [nameLabel, valueLabel, stepper])
        row.axis      = .horizontal
        row.spacing   = 8
        row.alignment = .center
        return row
    }

    @objc private func skinsCarryoverChanged(_ seg: UISegmentedControl) {
        GameManager.shared.update { g in
            if g.skinsState == nil { g.skinsState = SkinsEngine.makeDefaultState() }
            g.skinsState?.settings.carryoversEnabled = (seg.selectedSegmentIndex == 1)
        }
    }

    @objc private func teamTeeSwitchChanged(_ sw: UISwitch) {
        GameManager.shared.update { g in
            if g.teamTeeSettings == nil {
                g.teamTeeSettings = TeamTeeSettings()
            }
            g.teamTeeSettings?.isEnabled = sw.isOn
        }
        teamTeeConfigureButton?.isHidden = !sw.isOn
        NotificationCenter.default.post(name: .reloadUI, object: nil)
    }

    @objc private func teamTeeConfigureTapped() {
        let g = GameManager.shared.currentGame
        let current = g?.teamTeeSettings ?? TeamTeeSettings()
        let activePlayers = (0..<MAX_PLAYERS).filter {
            (g?.playerActivated[$0] ?? false) &&
            !(g?.playerNames[$0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        }.count
        let vc = TeamTeeSetupViewController(settings: current, maxCount: max(1, activePlayers))
        vc.onSave = { [weak self] updated in
            GameManager.shared.update { g in g.teamTeeSettings = updated }
            NotificationCenter.default.post(name: .reloadUI, object: nil)
            self?.teamTeeSwitch?.isOn = updated.isEnabled
        }
        navigationController?.pushViewController(vc, animated: true)
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
        let inWolfTournament = GameManager.shared.currentGame?.tournamentCode != nil
            && GameManager.shared.currentGame?.tournamentGameType == "wolf"

        if inWolfTournament {
            GameManager.shared.update { g in g.isUmbrella = umbrellaMuted }
            GameManager.shared.saveCurrent()
            navigationController?.popViewController(animated: true)
            return
        }

        let clean = (baseStakeField.text ?? "")
            .replacingOccurrences(of: "$", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let stakeRaw = Double(clean), stakeRaw >= 1 else {
            showAlert(title: "Invalid Stake", message: "Enter a whole dollar amount of $1 or more.")
            return
        }
        let stake = stakeRaw.rounded()   // snap to $1

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
