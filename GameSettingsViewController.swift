//
//  GameSettingsViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 3/28/26.
//

import UIKit

final class GameSettingsViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var baseStakeField: UITextField?
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
    private weak var standaloneTeamTeeSection: UIStackView?
    private weak var standaloneSkinsSection: UIStackView?
    private weak var goLiveButton: UIButton?
    private weak var teamTeeSwitch: UISwitch?
    private weak var teamTeeConfigureButton: UIButton?
    private weak var skinsCarryoverSegment: UISegmentedControl?
    private weak var loneWolfSegment: UISegmentedControl?
    private weak var loneWolfSection: UIStackView?
    private weak var sfModeSegment: UISegmentedControl?
    private weak var sfModifiedSettingsStack: UIStackView?
    private var sfSettingsStepperValues: [Int: Int] = [0: 8, 1: 4, 2: 2, 3: 0, 4: -1, 5: -3]
    private var scrollView: UIScrollView!
    private var contentStack: UIStackView!

    var gameData: GameData?
    var onPop: (() -> Void)?

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

        baseStakeField?.delegate = self
        baseStakeField?.keyboardType = .decimalPad

        let bar = UIToolbar()
        bar.sizeToFit()
        bar.items = [
            .flexibleSpace(),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneTapped))
        ]
        baseStakeField?.inputAccessoryView = bar

        if let g = GameManager.shared.currentGame {
            baseStakeField?.text = formatMoney(Double(g.baseGameStake))
            umbrellaMuted = g.isUmbrella
        } else {
            baseStakeField?.text = "2"
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
        installLoneWolfTeamScoreSegment()
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
        if isMovingFromParent { onPop?() }
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

        // Umbrella section header with ⓘ
        main.addArrangedSubview(labeledHeaderRow(
            title: "Umbrella",
            infoTitle: "Umbrella",
            infoMessage: "Umbrella On: win 6 or more points on a hole and the points double."
        ))

        // Umbrella button
        let umbrella = UIButton(type: .system)
        umbrella.translatesAutoresizingMaskIntoConstraints = false
        umbrella.heightAnchor.constraint(equalToConstant: 48).isActive = true
        umbrella.addTarget(self, action: #selector(umbrellaTapped(_:)), for: .touchUpInside)
        let umbrellaLPR = UILongPressGestureRecognizer(target: self, action: #selector(umbrellaLongPressed(_:)))
        umbrella.addGestureRecognizer(umbrellaLPR)
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

        var subviews: [UIView] = [sectionHeader("Game Type")]

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

            var matchPlayAllowed = true
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
                let activePlayers = g.playerNames.enumerated()
                    .filter { g.playerActivated[$0.offset] && !$0.element.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                    .count
                matchPlayAllowed = activePlayers == 2 || activePlayers == 4
                if !matchPlayAllowed { segment.setEnabled(false, forSegmentAt: 3) }
            }

            subviews.append(segment)
            wolfScoringSegment = segment

            let mpNote = UILabel()
            mpNote.text = "Match Play needs 2 or 4 players."
            mpNote.font = UIFont.systemFont(ofSize: 12)
            mpNote.textColor = .secondaryLabel
            mpNote.numberOfLines = 0
            mpNote.isHidden = matchPlayAllowed
            subviews.append(mpNote)
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
            let cur = GameManager.shared.currentGame?.resolvedGameType
            newType = (cur == .bestBall || cur == .fourball) ? cur! : .matchPlay
        }

        // Block switching to Match Play when player count isn't 2 or 4.
        if !newType.supportsSevenPlayers {
            let current = GameManager.shared.currentGame
            let activeCount = (0..<WOLF_MAX_PLAYERS).filter { i in
                (current?.playerActivated[safe: i] ?? false) &&
                !(current?.playerNames[safe: i] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }.count
            if activeCount != 2 && activeCount != 4 {
                let revert: Int
                switch current?.resolvedGameType {
                case .wolf:        revert = 1
                case .wolfLowBall: revert = 2
                default:           revert = 0
                }
                sender.selectedSegmentIndex = revert
                let ac = UIAlertController(
                    title: "Format Not Available",
                    message: "Match Play needs 2 or 4 players. You have \(activeCount) active players.",
                    preferredStyle: .alert
                )
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                present(ac, animated: true)
                return
            }
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
            // Initialize default team split when switching to Match Play
            if newType.isMatchPlay, g.matchPlayTeamA == nil {
                let active = g.playerNames.enumerated()
                    .filter { g.playerActivated[$0.offset] && !$0.element.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                    .map { $0.offset }
                if active.count == 4 && newType == .matchPlay {
                    g.matchPlayTeamA  = [active[0]]
                    g.matchPlayTeamB  = [active[1]]
                    g.matchPlayTeamA2 = [active[2]]
                    g.matchPlayTeamB2 = [active[3]]
                } else {
                    let half = max(1, active.count / 2)
                    g.matchPlayTeamA = Array(active.prefix(half))
                    g.matchPlayTeamB = Array(active.dropFirst(half))
                }
            }
        }
        if newType.isMatchPlay { baseStakeField?.text = "1" }
        NotificationCenter.default.post(name: .reloadUI, object: nil)
        umbrellaButton.alpha = (sender.selectedSegmentIndex == 0) ? 1.0 : 0.4
        refreshMatchPlayUI()
    }

    // MARK: - Lone Wolf Team Score segment

    private static let loneWolfInfoTitle   = "Lone Wolf Team Score"
    private static let loneWolfInfoMessage = "When a player goes alone, their team total is compared to the other team's total. Ghost Partner: your score plus an imaginary partner halfway between your score and bogey (3 on a par 3 → 3 + 3.5 = 6.5). Double Score: your score counts twice (3 → 6)."

    private func installLoneWolfTeamScoreSegment() {
        guard GameManager.shared.currentGame?.tournamentCode == nil else { return }
        let segment = UISegmentedControl(items: ["Ghost Partner", "Double Score"])
        segment.addTarget(self, action: #selector(loneWolfTeamScoreChanged(_:)), for: .valueChanged)
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

        let current = GameManager.shared.currentGame?.loneWolfTeamScore ?? .ghostPartner
        segment.selectedSegmentIndex = (current == .doubleScore) ? 1 : 0

        let lpr = UILongPressGestureRecognizer(target: self, action: #selector(loneWolfSegmentLongPressed(_:)))
        segment.addGestureRecognizer(lpr)

        let note = UILabel()
        note.font          = UIFont.preferredFont(forTextStyle: .caption1)
        note.textColor     = .secondaryLabel
        note.numberOfLines = 0
        note.text          = "Ghost: 3 on a par 3 → 6.5 · Double: 3 → 6"

        let header = labeledHeaderRow(
            title: Self.loneWolfInfoTitle,
            infoTitle: Self.loneWolfInfoTitle,
            infoMessage: Self.loneWolfInfoMessage
        )

        let section = UIStackView(arrangedSubviews: [header, segment, note])
        section.axis    = .vertical
        section.spacing = 6

        let insertIndex = max(0, contentStack.arrangedSubviews.count - 1)
        contentStack.insertArrangedSubview(section, at: insertIndex)
        loneWolfSegment = segment
        loneWolfSection = section
    }

    @objc private func loneWolfTeamScoreChanged(_ sender: UISegmentedControl) {
        let value: LoneWolfTeamScore = (sender.selectedSegmentIndex == 1) ? .doubleScore : .ghostPartner
        GameManager.shared.update { g in g.loneWolfTeamScore = value }
        NotificationCenter.default.post(name: .reloadUI, object: nil)
    }

    @objc private func loneWolfSegmentLongPressed(_ gr: UILongPressGestureRecognizer) {
        guard gr.state == .began else { return }
        showInfoAlert(title: Self.loneWolfInfoTitle, message: Self.loneWolfInfoMessage)
    }

    @objc private func umbrellaLongPressed(_ gr: UILongPressGestureRecognizer) {
        guard gr.state == .began else { return }
        showInfoAlert(
            title: "Umbrella",
            message: "Umbrella On: win 6 or more points on a hole and the points double."
        )
    }

    // MARK: - Info helpers

    private func labeledHeaderRow(title: String, infoTitle: String, infoMessage: String) -> UIView {
        let label = sectionHeader(title)

        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "info.circle"), for: .normal)
        btn.tintColor = .secondaryLabel
        btn.addAction(UIAction { [weak self] _ in
            self?.showInfoAlert(title: infoTitle, message: infoMessage)
        }, for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            btn.widthAnchor.constraint(equalToConstant: 24),
            btn.heightAnchor.constraint(equalToConstant: 24),
        ])

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [label, spacer, btn])
        row.axis      = .horizontal
        row.alignment = .center
        row.spacing   = 4
        return row
    }

    private func showInfoAlert(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    // MARK: - Press Style segment

    private static let pressInfoTitle   = "Press Style"
    private static let pressInfoMessage = "A press raises the bet for the rest of the nine. Press Style sets how it grows when pressed again. Doubling: ×2, ×4, ×8. Additive: ×2, ×3, ×4."

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

        let lpr = UILongPressGestureRecognizer(target: self, action: #selector(pressSegmentLongPressed(_:)))
        segment.addGestureRecognizer(lpr)

        let note = UILabel()
        note.font          = UIFont.preferredFont(forTextStyle: .caption1)
        note.textColor     = .secondaryLabel
        note.numberOfLines = 0
        note.text          = "Doubling: ×2, ×4, ×8… each tap  •  Additive: +$base each tap (×2, ×3, ×4…)"

        let header = labeledHeaderRow(
            title: Self.pressInfoTitle,
            infoTitle: Self.pressInfoTitle,
            infoMessage: Self.pressInfoMessage
        )
        let section = UIStackView(arrangedSubviews: [header, segment, note])
        section.axis    = .vertical
        section.spacing = 6

        let insertIndex = max(0, contentStack.arrangedSubviews.count - 1)
        contentStack.insertArrangedSubview(section, at: insertIndex)
        pressStyleSegment = segment
        pressStyleSection = section
    }

    @objc private func pressSegmentLongPressed(_ gr: UILongPressGestureRecognizer) {
        guard gr.state == .began else { return }
        showInfoAlert(title: Self.pressInfoTitle, message: Self.pressInfoMessage)
    }

    @objc private func pressStyleChanged(_ sender: UISegmentedControl) {
        let style: HammerStyle = (sender.selectedSegmentIndex == 1) ? .additive : .doubling
        GameManager.shared.update { g in g.pressStyle = style }
        NotificationCenter.default.post(name: .reloadUI, object: nil)
    }

    // MARK: - Hammer Style segment

    private static let hammerInfoTitle   = "Hammer Style"
    private static let hammerInfoMessage = "Throw a hammer to raise the hole bet. The other team accepts or concedes the hole at the current stake. Hammer Style sets how the bet grows with each accepted hammer. Doubling: ×2, ×4, ×8. Additive: ×2, ×3, ×4."

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

        let lpr = UILongPressGestureRecognizer(target: self, action: #selector(hammerSegmentLongPressed(_:)))
        segment.addGestureRecognizer(lpr)

        let note = UILabel()
        note.font          = UIFont.preferredFont(forTextStyle: .caption1)
        note.textColor     = .secondaryLabel
        note.numberOfLines = 0
        note.text          = "Doubling: ×2, ×4, ×8… each tap  •  Additive: +$base each tap (×2, ×3, ×4…)"

        let header = labeledHeaderRow(
            title: Self.hammerInfoTitle,
            infoTitle: Self.hammerInfoTitle,
            infoMessage: Self.hammerInfoMessage
        )
        let section = UIStackView(arrangedSubviews: [header, segment, note])
        section.axis    = .vertical
        section.spacing = 6

        let insertIndex = max(0, contentStack.arrangedSubviews.count - 1)
        contentStack.insertArrangedSubview(section, at: insertIndex)
        hammerStyleSegment = segment
        hammerStyleSection = section
    }

    @objc private func hammerSegmentLongPressed(_ gr: UILongPressGestureRecognizer) {
        guard gr.state == .began else { return }
        showInfoAlert(title: Self.hammerInfoTitle, message: Self.hammerInfoMessage)
    }

    @objc private func hammerStyleChanged(_ sender: UISegmentedControl) {
        let style: HammerStyle = (sender.selectedSegmentIndex == 1) ? .additive : .doubling
        GameManager.shared.update { g in g.hammerStyle = style }
        NotificationCenter.default.post(name: .reloadUI, object: nil)
    }

    // MARK: - Match Play Teams

    private func installMatchPlayTeamsSection() {
        let inner = UIStackView()
        inner.axis    = .vertical
        inner.spacing = 10
        matchPlayTeamsInner = inner

        let container = UIStackView(arrangedSubviews: [inner])
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

        let active = g.playerNames.enumerated()
            .filter { g.playerActivated[$0.offset] && !$0.element.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { ($0.offset, $0.element) }
        let activeCount = active.count
        let matchPlayAllowed = activeCount == 2 || activeCount == 4
        let fourAllowed      = activeCount == 4

        // ── FORMAT ─────────────────────────────────────────────────────────────
        inner.addArrangedSubview(sectionHeader("FORMAT"))

        let singlesDesc = fourAllowed ? "Head-to-head. 4 players = 2 matches." : "Head-to-head. One match."
        let formats: [(String, String, GameType, Bool)] = [
            ("Singles",          singlesDesc,                                        .matchPlay, matchPlayAllowed),
            ("Fourball",         "2 vs 2. Best net ball wins the hole.",              .fourball,  fourAllowed),
            ("Team Stroke Play", "2 vs 2. Best ball totals, settled at the end.",     .bestBall,  fourAllowed),
        ]
        for (title, desc, gtype, enabled) in formats {
            let isSelected: Bool
            switch g.resolvedGameType {
            case .matchPlay: isSelected = (gtype == .matchPlay)
            case .fourball:  isSelected = (gtype == .fourball)
            case .bestBall:  isSelected = (gtype == .bestBall)
            default:         isSelected = false
            }
            inner.addArrangedSubview(mpFormatCard(title: title, desc: desc, gameType: gtype, selected: isSelected, enabled: enabled))
        }

        guard matchPlayAllowed else {
            let note = UILabel()
            note.text = "Match Play needs 2 or 4 players."
            note.font = .systemFont(ofSize: 12)
            note.textColor = .secondaryLabel
            note.numberOfLines = 0
            inner.addArrangedSubview(note)
            return
        }

        // ── MATCHUPS ────────────────────────────────────────────────────────────
        let matchupsLbl = sectionHeader("MATCHUPS")
        let swapHint    = UILabel()
        swapHint.text      = "Tap a name to swap"
        swapHint.font      = .systemFont(ofSize: 12)
        swapHint.textColor = .secondaryLabel
        swapHint.setContentHuggingPriority(.required, for: .horizontal)
        let matchupsRow = UIStackView(arrangedSubviews: [matchupsLbl, swapHint])
        matchupsRow.axis      = .horizontal
        matchupsRow.alignment = .lastBaseline
        inner.addArrangedSubview(matchupsRow)

        let teamA  = g.matchPlayTeamA  ?? []
        let teamB  = g.matchPlayTeamB  ?? []
        let teamA2 = g.matchPlayTeamA2 ?? []
        let teamB2 = g.matchPlayTeamB2 ?? []

        let strokesNote = UILabel()
        strokesNote.font       = .systemFont(ofSize: 12)
        strokesNote.textColor  = .secondaryLabel
        strokesNote.numberOfLines = 0

        switch g.resolvedGameType {
        case .matchPlay:
            let a1 = teamA.first  ?? (active[safe: 0]?.0 ?? 0)
            let b1 = teamB.first  ?? (active[safe: 1]?.0 ?? 1)
            inner.addArrangedSubview(mpSinglesCard(label: "MATCH 1", aSeat: a1, bSeat: b1, active: active, g: g))
            if g.isDualMatch {
                let a2 = teamA2.first ?? (active[safe: 2]?.0 ?? 2)
                let b2 = teamB2.first ?? (active[safe: 3]?.0 ?? 3)
                inner.addArrangedSubview(mpSinglesCard(label: "MATCH 2", aSeat: a2, bSeat: b2, active: active, g: g))
                strokesNote.text = "Strokes use only the two players in each match. Each match is paid separately."
            } else {
                strokesNote.text = "Strokes use only the two players in this match."
            }
            inner.addArrangedSubview(strokesNote)

        case .fourball, .bestBall:
            let a0 = teamA[safe: 0] ?? (active[safe: 0]?.0 ?? 0)
            let a1 = teamA[safe: 1] ?? (active[safe: 2]?.0 ?? 2)
            let b0 = teamB[safe: 0] ?? (active[safe: 1]?.0 ?? 1)
            let b1 = teamB[safe: 1] ?? (active[safe: 3]?.0 ?? 3)
            let allFour = [a0, a1, b0, b1]
            inner.addArrangedSubview(mpTeamCard(label: "TEAM A", seats: [a0, a1], allSeats: allFour, active: active, g: g))
            let vsLbl = UILabel()
            vsLbl.text          = "vs"
            vsLbl.textAlignment = .center
            vsLbl.font          = .systemFont(ofSize: 13)
            vsLbl.textColor     = .secondaryLabel
            inner.addArrangedSubview(vsLbl)
            inner.addArrangedSubview(mpTeamCard(label: "TEAM B", seats: [b0, b1], allSeats: allFour, active: active, g: g))
            let minHC   = allFour.compactMap { g.hcPlayers[safe: $0] }.min() ?? 0
            let minName = active.first(where: { g.hcPlayers[safe: $0.0] == minHC })?.1 ?? ""
            let shortMin = minName.components(separatedBy: " ").first ?? minName
            strokesNote.text = "Strokes are measured from the lowest handicap of the four players (\(shortMin), \(minHC)). One match, one pot."
            inner.addArrangedSubview(strokesNote)

        default: break
        }

        // ── OPTIONS ─────────────────────────────────────────────────────────────
        inner.addArrangedSubview(sectionHeader("OPTIONS"))
        let optCard = UIView()
        optCard.backgroundColor  = .secondarySystemBackground
        optCard.layer.cornerRadius = 10
        let optStack = UIStackView()
        optStack.axis    = .vertical
        optStack.spacing = 0
        optStack.translatesAutoresizingMaskIntoConstraints = false
        optCard.addSubview(optStack)
        NSLayoutConstraint.activate([
            optStack.topAnchor.constraint(equalTo: optCard.topAnchor, constant: 4),
            optStack.bottomAnchor.constraint(equalTo: optCard.bottomAnchor, constant: -4),
            optStack.leadingAnchor.constraint(equalTo: optCard.leadingAnchor),
            optStack.trailingAnchor.constraint(equalTo: optCard.trailingAnchor),
        ])

        if !g.matchPlay36Holes {
            let nineSw = UISwitch()
            nineSw.isOn       = g.isNineHoleMatch
            nineSw.onTintColor = .wolfMoreGreen
            nineSw.addTarget(self, action: #selector(nineHoleMatchToggled(_:)), for: .valueChanged)
            nineHoleSwitch = nineSw
            optStack.addArrangedSubview(mpOptionRow(title: "9-Hole Match",
                                                    desc: "Front or back 9, based on the starting hole",
                                                    sw: nineSw))
            if g.isNineHoleMatch {
                let shLbl = UILabel()
                shLbl.text  = "Starting Hole"
                shLbl.font  = .systemFont(ofSize: 14)
                shLbl.textColor = .secondaryLabel
                shLbl.setContentHuggingPriority(.defaultLow, for: .horizontal)

                let valLbl = UILabel()
                valLbl.text          = "\(g.nineHoleStartingHole)"
                valLbl.font          = .systemFont(ofSize: 14, weight: .semibold)
                valLbl.textAlignment = .right
                valLbl.widthAnchor.constraint(equalToConstant: 28).isActive = true
                nineHoleStartingHoleLabel = valLbl

                let stepper = UIStepper()
                stepper.minimumValue = 1
                stepper.maximumValue = Double(STANDARD_HOLES)
                stepper.stepValue    = 1
                stepper.value        = Double(g.nineHoleStartingHole)
                stepper.addTarget(self, action: #selector(nineHoleStartingHoleChanged(_:)), for: .valueChanged)

                let shRow = UIStackView(arrangedSubviews: [shLbl, valLbl, stepper])
                shRow.axis = .horizontal; shRow.alignment = .center; shRow.spacing = 8
                shRow.layoutMargins = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
                shRow.isLayoutMarginsRelativeArrangement = true
                optStack.addArrangedSubview(shRow)

                let isFront  = g.nineHoleStartingHole <= 9
                let seq      = g.nineHoleSequence.map { "\($0 + 1)" }.joined(separator: ", ")
                let halfNote = UILabel()
                halfNote.text      = "\(isFront ? "Front" : "Back") 9 · Hole order: \(seq)"
                halfNote.font      = .systemFont(ofSize: 12)
                halfNote.textColor = .secondaryLabel
                halfNote.numberOfLines = 0
                halfNote.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
                nineHoleHalfNoteLabel  = halfNote
                let halfWrap = UIStackView(arrangedSubviews: [halfNote])
                halfWrap.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 8, right: 16)
                halfWrap.isLayoutMarginsRelativeArrangement = true
                optStack.addArrangedSubview(halfWrap)
            }
            optStack.addArrangedSubview(mpSeparator())
        }

        if !g.isNineHoleMatch {
            let thirtySixSw = UISwitch()
            thirtySixSw.isOn       = g.matchPlay36Holes
            thirtySixSw.onTintColor = .wolfMoreGreen
            thirtySixSw.addTarget(self, action: #selector(matchPlay36Toggled(_:)), for: .valueChanged)
            matchPlay36Switch = thirtySixSw
            optStack.addArrangedSubview(mpOptionRow(title: "36-Hole Round",
                                                    desc: "Holes 19–36 replay the same course",
                                                    sw: thirtySixSw))
        }
        inner.addArrangedSubview(optCard)

        // ── SIDE GAMES ──────────────────────────────────────────────────────────
        inner.addArrangedSubview(sectionHeader("SIDE GAMES"))
        let sideCard = UIView()
        sideCard.backgroundColor   = .secondarySystemBackground
        sideCard.layer.cornerRadius = 10
        let sideStack = UIStackView()
        sideStack.axis    = .vertical
        sideStack.spacing = 0
        sideStack.translatesAutoresizingMaskIntoConstraints = false
        sideCard.addSubview(sideStack)
        NSLayoutConstraint.activate([
            sideStack.topAnchor.constraint(equalTo: sideCard.topAnchor, constant: 4),
            sideStack.bottomAnchor.constraint(equalTo: sideCard.bottomAnchor, constant: -4),
            sideStack.leadingAnchor.constraint(equalTo: sideCard.leadingAnchor),
            sideStack.trailingAnchor.constraint(equalTo: sideCard.trailingAnchor),
        ])

        let isTeamTeeEnabled = g.teamTeeSettings?.isEnabled ?? false
        let teamTeeSw = UISwitch()
        teamTeeSw.isOn       = isTeamTeeEnabled
        teamTeeSw.onTintColor = .wolfMoreGreen
        teamTeeSw.addTarget(self, action: #selector(teamTeeSwitchChanged(_:)), for: .valueChanged)
        teamTeeSwitch = teamTeeSw
        sideStack.addArrangedSubview(mpOptionRow(title: "Team Tee Game",
                                                 desc: "Lowest net scores per hole across the group",
                                                 sw: teamTeeSw))
        if isTeamTeeEnabled {
            let cfg = UIButton(type: .system)
            cfg.setTitle("Configure Count Rules →", for: .normal)
            cfg.titleLabel?.font = .systemFont(ofSize: 13)
            cfg.contentHorizontalAlignment = .left
            cfg.addTarget(self, action: #selector(teamTeeConfigureTapped), for: .touchUpInside)
            teamTeeConfigureButton = cfg
            let cfgWrap = UIStackView(arrangedSubviews: [cfg])
            cfgWrap.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 6, right: 16)
            cfgWrap.isLayoutMarginsRelativeArrangement = true
            sideStack.addArrangedSubview(cfgWrap)
        }

        let hasSkins = g.skinsState?.settings.isEnabled == true
        if hasSkins {
            sideStack.addArrangedSubview(mpSeparator())
            let skinsLbl = UILabel()
            skinsLbl.text = "Skins ties"
            skinsLbl.font = .systemFont(ofSize: 16, weight: .semibold)
            let skinsTitleWrap = UIStackView(arrangedSubviews: [skinsLbl])
            skinsTitleWrap.layoutMargins = UIEdgeInsets(top: 10, left: 16, bottom: 4, right: 16)
            skinsTitleWrap.isLayoutMarginsRelativeArrangement = true
            sideStack.addArrangedSubview(skinsTitleWrap)

            let seg = UISegmentedControl(items: ["No Carry", "Carry Ties"])
            seg.selectedSegmentIndex = (g.skinsState?.settings.carryoversEnabled == true) ? 1 : 0
            seg.addTarget(self, action: #selector(skinsCarryoverChanged(_:)), for: .valueChanged)
            skinsCarryoverSegment = seg
            let segWrap = UIStackView(arrangedSubviews: [seg])
            segWrap.layoutMargins = UIEdgeInsets(top: 4, left: 16, bottom: 10, right: 16)
            segWrap.isLayoutMarginsRelativeArrangement = true
            sideStack.addArrangedSubview(segWrap)
        }
        inner.addArrangedSubview(sideCard)
    }

    private func refreshMatchPlayUI() {
        let isMatchPlay = wolfScoringSegment?.selectedSegmentIndex == 3
        pressStyleSection?.isHidden  = isMatchPlay
        hammerStyleSection?.isHidden = isMatchPlay
        standaloneTeamTeeSection?.isHidden = isMatchPlay
        standaloneSkinsSection?.isHidden   = isMatchPlay
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

    // MARK: - Match Play card actions

    @objc private func formatCardTapped(_ sender: UIButton) {
        guard let g = GameManager.shared.currentGame else { return }
        let active = g.playerNames.enumerated()
            .filter { g.playerActivated[$0.offset] && !$0.element.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { $0.offset }

        GameManager.shared.update { g in
            switch sender.tag {
            case 0: // Singles
                g.gameType = .matchPlay
                if active.count == 4 {
                    g.matchPlayTeamA  = [active[0]]
                    g.matchPlayTeamB  = [active[1]]
                    g.matchPlayTeamA2 = [active[2]]
                    g.matchPlayTeamB2 = [active[3]]
                } else if active.count == 2 {
                    g.matchPlayTeamA  = [active[0]]
                    g.matchPlayTeamB  = [active[1]]
                    g.matchPlayTeamA2 = nil
                    g.matchPlayTeamB2 = nil
                }
            case 1: // Fourball
                g.gameType = .fourball
                if active.count >= 4 {
                    g.matchPlayTeamA  = [active[0], active[2]]
                    g.matchPlayTeamB  = [active[1], active[3]]
                    g.matchPlayTeamA2 = nil
                    g.matchPlayTeamB2 = nil
                }
            default: // Team Stroke Play
                g.gameType = .bestBall
                if active.count >= 4 {
                    g.matchPlayTeamA  = [active[0], active[2]]
                    g.matchPlayTeamB  = [active[1], active[3]]
                    g.matchPlayTeamA2 = nil
                    g.matchPlayTeamB2 = nil
                }
            }
        }
        NotificationCenter.default.post(name: .reloadUI, object: nil)
        refreshMatchPlayTeamsContent()
    }

    private func swapMatchPlaySeats(_ seatA: Int, _ seatB: Int) {
        GameManager.shared.update { g in
            func swp(_ arr: inout [Int]) {
                for i in arr.indices {
                    if arr[i] == seatA      { arr[i] = seatB }
                    else if arr[i] == seatB { arr[i] = seatA }
                }
            }
            var a1 = g.matchPlayTeamA  ?? []
            var b1 = g.matchPlayTeamB  ?? []
            var a2 = g.matchPlayTeamA2 ?? []
            var b2 = g.matchPlayTeamB2 ?? []
            swp(&a1); swp(&b1); swp(&a2); swp(&b2)
            g.matchPlayTeamA  = a1
            g.matchPlayTeamB  = b1
            g.matchPlayTeamA2 = a2.isEmpty ? nil : a2
            g.matchPlayTeamB2 = b2.isEmpty ? nil : b2
        }
        refreshMatchPlayTeamsContent()
    }

    // MARK: - Match Play card builders

    private func mpFormatCard(title: String, desc: String, gameType: GameType, selected: Bool, enabled: Bool) -> UIView {
        let card = UIView()
        card.backgroundColor   = selected ? UIColor.wolfMoreGreen.withAlphaComponent(0.06) : .secondarySystemBackground
        card.layer.cornerRadius = 10
        card.layer.borderWidth  = selected ? 2 : 1
        card.layer.borderColor  = selected ? UIColor.wolfMoreGreen.cgColor : UIColor.systemGray4.cgColor
        card.alpha              = enabled ? 1.0 : 0.4

        let radio = UIImageView(image: UIImage(systemName: selected ? "largecircle.fill.circle" : "circle"))
        radio.tintColor     = selected ? .wolfMoreGreen : .systemGray3
        radio.contentMode   = .scaleAspectFit
        radio.translatesAutoresizingMaskIntoConstraints = false
        radio.widthAnchor.constraint(equalToConstant: 22).isActive  = true
        radio.heightAnchor.constraint(equalToConstant: 22).isActive = true

        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = .systemFont(ofSize: 16, weight: .semibold)

        let descLbl = UILabel()
        descLbl.text          = desc
        descLbl.font          = .systemFont(ofSize: 13)
        descLbl.textColor     = .secondaryLabel
        descLbl.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [titleLbl, descLbl])
        textStack.axis    = .vertical
        textStack.spacing = 2

        let hStack = UIStackView(arrangedSubviews: [radio, textStack])
        hStack.axis      = .horizontal
        hStack.spacing   = 12
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            hStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            hStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            hStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
        ])

        if enabled {
            let typeTag: Int
            switch gameType {
            case .matchPlay: typeTag = 0
            case .fourball:  typeTag = 1
            default:         typeTag = 2
            }
            let btn = UIButton()
            btn.tag = typeTag
            btn.addTarget(self, action: #selector(formatCardTapped(_:)), for: .touchUpInside)
            btn.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(btn)
            NSLayoutConstraint.activate([
                btn.topAnchor.constraint(equalTo: card.topAnchor),
                btn.bottomAnchor.constraint(equalTo: card.bottomAnchor),
                btn.leadingAnchor.constraint(equalTo: card.leadingAnchor),
                btn.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            ])
        }
        return card
    }

    private func mpSinglesCard(label: String, aSeat: Int, bSeat: Int, active: [(Int, String)], g: GameData) -> UIView {
        let card = UIView()
        card.backgroundColor   = .secondarySystemBackground
        card.layer.cornerRadius = 10

        let matchLbl = UILabel()
        matchLbl.text      = label
        matchLbl.font      = .systemFont(ofSize: 11, weight: .semibold)
        matchLbl.textColor = .secondaryLabel

        let aBtn = mpPlayerButton(seat: aSeat, allActive: active)
        let vsLbl = UILabel()
        vsLbl.text          = "vs"
        vsLbl.font          = .systemFont(ofSize: 13)
        vsLbl.textColor     = .secondaryLabel
        vsLbl.textAlignment = .center
        vsLbl.setContentHuggingPriority(.required, for: .horizontal)
        let bBtn = mpPlayerButton(seat: bSeat, allActive: active)

        let playersRow = UIStackView(arrangedSubviews: [aBtn, vsLbl, bBtn])
        playersRow.axis         = .horizontal
        playersRow.spacing      = 8
        playersRow.alignment    = .center
        playersRow.distribution = .fillProportionally

        let strokesLbl = UILabel()
        strokesLbl.text          = mpSinglesStrokesText(aSeat: aSeat, bSeat: bSeat, g: g)
        strokesLbl.font          = .systemFont(ofSize: 13)
        strokesLbl.textColor     = .secondaryLabel
        strokesLbl.numberOfLines = 0

        let content = UIStackView(arrangedSubviews: [matchLbl, playersRow, strokesLbl])
        content.axis    = .vertical
        content.spacing = 8
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
        ])
        return card
    }

    private func mpTeamCard(label: String, seats: [Int], allSeats: [Int], active: [(Int, String)], g: GameData) -> UIView {
        let card = UIView()
        card.backgroundColor   = .secondarySystemBackground
        card.layer.cornerRadius = 10

        let teamLbl = UILabel()
        teamLbl.text      = label
        teamLbl.font      = .systemFont(ofSize: 11, weight: .semibold)
        teamLbl.textColor = .wolfMoreGreen

        let btnsRow = UIStackView()
        btnsRow.axis         = .horizontal
        btnsRow.spacing      = 8
        btnsRow.distribution = .fillEqually
        for seat in seats {
            btnsRow.addArrangedSubview(mpPlayerButton(seat: seat, allActive: active))
        }

        let strokesLbl = UILabel()
        strokesLbl.text          = mpTeamStrokesText(seats: seats, allSeats: allSeats, active: active, g: g)
        strokesLbl.font          = .systemFont(ofSize: 13)
        strokesLbl.textColor     = .secondaryLabel
        strokesLbl.numberOfLines = 0

        let content = UIStackView(arrangedSubviews: [teamLbl, btnsRow, strokesLbl])
        content.axis    = .vertical
        content.spacing = 8
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
        ])
        return card
    }

    private func mpPlayerButton(seat: Int, allActive: [(Int, String)]) -> UIButton {
        let name = allActive.first(where: { $0.0 == seat })?.1 ?? "?"
        var config = UIButton.Configuration.plain()
        config.title           = name
        config.image           = UIImage(systemName: "chevron.down")
        config.imagePlacement  = .trailing
        config.imagePadding    = 6
        config.baseForegroundColor = .label
        config.contentInsets   = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 10)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs; a.font = UIFont.systemFont(ofSize: 15, weight: .semibold); return a
        }
        let btn = UIButton(configuration: config)
        btn.layer.borderWidth  = 1
        btn.layer.borderColor  = UIColor.systemGray4.cgColor
        btn.layer.cornerRadius = 8

        let others  = allActive.filter { $0.0 != seat }
        let actions = others.map { (otherSeat, otherName) in
            UIAction(title: otherName) { [weak self] _ in self?.swapMatchPlaySeats(seat, otherSeat) }
        }
        if !actions.isEmpty {
            btn.menu = UIMenu(children: actions)
            btn.showsMenuAsPrimaryAction = true
        }
        return btn
    }

    private func mpSinglesStrokesText(aSeat: Int, bSeat: Int, g: GameData) -> String {
        let hcA    = g.hcPlayers[safe: aSeat] ?? 0
        let hcB    = g.hcPlayers[safe: bSeat] ?? 0
        let strokes = abs(hcA - hcB)
        let nameA   = (g.playerNames[safe: aSeat] ?? "P\(aSeat+1)").trimmingCharacters(in: .whitespacesAndNewlines)
        let nameB   = (g.playerNames[safe: bSeat] ?? "P\(bSeat+1)").trimmingCharacters(in: .whitespacesAndNewlines)
        let shortA  = nameA.components(separatedBy: " ").first ?? nameA
        let shortB  = nameB.components(separatedBy: " ").first ?? nameB
        if strokes == 0 { return "Dead even \u{00B7} \(shortA) \(hcA), \(shortB) \(hcB)" }
        let receiver = hcA > hcB ? shortA : shortB
        return "\(receiver) gets \(strokes) stroke\(strokes == 1 ? "" : "s") \u{00B7} \(shortA) \(hcA), \(shortB) \(hcB)"
    }

    private func mpTeamStrokesText(seats: [Int], allSeats: [Int], active: [(Int, String)], g: GameData) -> String {
        let base  = allSeats.compactMap { g.hcPlayers[safe: $0] }.min() ?? 0
        let parts = seats.map { seat -> String in
            let hc     = g.hcPlayers[safe: seat] ?? 0
            let stks   = hc - base
            let name   = active.first(where: { $0.0 == seat })?.1 ?? "P\(seat+1)"
            let short  = name.components(separatedBy: " ").first ?? name
            return "\(short) \(stks)"
        }
        return parts.joined(separator: " \u{00B7} ") + " strokes"
    }

    private func mpOptionRow(title: String, desc: String, sw: UISwitch) -> UIView {
        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = .systemFont(ofSize: 16, weight: .semibold)

        let descLbl = UILabel()
        descLbl.text          = desc
        descLbl.font          = .systemFont(ofSize: 13)
        descLbl.textColor     = .secondaryLabel
        descLbl.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [titleLbl, descLbl])
        textStack.axis    = .vertical
        textStack.spacing = 2
        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        sw.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [textStack, sw])
        row.axis      = .horizontal
        row.spacing   = 12
        row.alignment = .center
        row.layoutMargins = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        row.isLayoutMarginsRelativeArrangement = true
        return row
    }

    private func mpSeparator() -> UIView {
        let sep = UIView()
        sep.backgroundColor = .separator
        sep.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return sep
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
                g.scores        = Array(repeating: Array(repeating: nil, count: STANDARD_HOLES), count: WOLF_MAX_PLAYERS)
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
            g.scores        = Array(repeating: Array(repeating: nil, count: STANDARD_HOLES), count: WOLF_MAX_PLAYERS)
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

        standaloneTeamTeeSection = section
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

        standaloneSkinsSection = section
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

        let clean = (baseStakeField?.text ?? "")
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
