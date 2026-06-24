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
    private weak var hammerStyleSegment: UISegmentedControl?
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
        installHammerStyleSegment()
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

        let segment = UISegmentedControl(items: ["6-Point", "Wolf 2pt", "Wolf LowBall"])
        segment.addTarget(self, action: #selector(wolfScoringChanged(_:)), for: .valueChanged)

        segment.backgroundColor = .systemGray6
        segment.selectedSegmentTintColor = .wolfMoreGreen
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

        if let g = GameManager.shared.currentGame {
            switch g.resolvedGameType {
            case .sixPointScotch: segment.selectedSegmentIndex = 0
            case .wolf:           segment.selectedSegmentIndex = 1
            case .wolfLowBall:    segment.selectedSegmentIndex = 2
            case .hammer:         segment.selectedSegmentIndex = 0
            case .tournament:     break  // TODO: tournament — segment hidden in this mode
            }
        }

        let wolfSection = UIStackView(arrangedSubviews: [header, segment])
        wolfSection.axis = .vertical
        wolfSection.spacing = 8

        // Insert before the save button (last arranged subview)
        let insertIndex = max(0, contentStack.arrangedSubviews.count - 1)
        contentStack.insertArrangedSubview(wolfSection, at: insertIndex)

        wolfScoringSegment = segment
    }

    @objc private func wolfScoringChanged(_ sender: UISegmentedControl) {
        let newType: GameType
        switch sender.selectedSegmentIndex {
        case 0: newType = .sixPointScotch
        case 1: newType = .wolf
        default: newType = .wolfLowBall
        }
        GameManager.shared.update { g in
            g.gameType = newType
            g.normalize()
            if newType != .sixPointScotch { g.isUmbrella = false }
        }
        NotificationCenter.default.post(name: .reloadUI, object: nil)
        umbrellaButton.alpha = (sender.selectedSegmentIndex == 0) ? 1.0 : 0.4
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
    }

    @objc private func hammerStyleChanged(_ sender: UISegmentedControl) {
        let style: HammerStyle = (sender.selectedSegmentIndex == 1) ? .additive : .doubling
        GameManager.shared.update { g in g.hammerStyle = style }
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

            if g.gameHoleDollarsArray.count != STANDARD_HOLES {
                g.gameHoleDollarsArray = Array(repeating: stake, count: STANDARD_HOLES)
            } else {
                for i in 0..<STANDARD_HOLES {
                    g.gameHoleDollarsArray[i] = stake
                }
            }
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
