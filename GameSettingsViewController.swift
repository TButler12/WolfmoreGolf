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
    private weak var goLiveButton: UIButton?
    private var scrollView: UIScrollView!
    private var contentStack: UIStackView!

    var gameData: GameData?

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
        installGoLiveButton()
        saveButton.configuration = wmStyledButton(title: "Save", style: .primary)

        addKeyboardObservers()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboardObservers()
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

    private func refreshGoLiveButton() {
        guard let btn = goLiveButton else { return }
        let isLive = GameManager.shared.currentGame?.liveSessionId != nil
        let title = isLive ? "Stop Live" : "Go Live"
        let style: WMButtonStyle = isLive ? .destructive : .secondary
        btn.configuration = wmStyledButton(title: title, style: style)
    }

    @objc private func goLiveTapped() {
        guard let g = GameManager.shared.currentGame else { return }

        if let sessionId = g.liveSessionId {
            // Already live — offer to reshare or stop
            let code = g.liveSessionCode ?? ""
            let alert = UIAlertController(
                title: "Live Session Active",
                message: code.isEmpty ? nil : "Code: \(code)",
                preferredStyle: .alert
            )
            if !code.isEmpty {
                alert.addAction(UIAlertAction(title: "Share Code", style: .default) { [weak self] _ in
                    self?.showGoLiveCreatedAlert(code: code)
                })
            }
            alert.addAction(UIAlertAction(title: "Stop Live", style: .destructive) { [weak self] _ in
                self?.stopLiveSession(id: sessionId)
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
        } else {
            let names = (0..<MAX_PLAYERS).compactMap { s -> String? in
                guard g.playerActivated[safe: s] == true else { return nil }
                return g.playerNames[safe: s] ?? ""
            }
            let course = g.course.name.isEmpty ? "Custom Course" : g.course.name
            Task {
                do {
                    let session = try await SupabaseService.shared.createWolfSession(
                        playerNames: names,
                        courseName: course
                    )
                    GameManager.shared.update { g in
                        g.liveSessionId = session.id
                        g.liveSessionCode = session.code
                    }
                    GameManager.shared.saveCurrent()
                    DispatchQueue.main.async {
                        self.refreshGoLiveButton()
                        self.showGoLiveCreatedAlert(code: session.code)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.showAlert(title: "Go Live Failed", message: error.localizedDescription)
                    }
                }
            }
        }
    }

    private func stopLiveSession(id: String) {
        Task {
            do {
                try await SupabaseService.shared.archiveWolfSession(id: id)
            } catch {
                print("ERROR archiveWolfSession: \(error)")
            }
            GameManager.shared.update { g in
                g.liveSessionId = nil
                g.liveSessionCode = nil
            }
            GameManager.shared.saveCurrent()
            DispatchQueue.main.async { self.refreshGoLiveButton() }
        }
    }

    private func showGoLiveCreatedAlert(code: String) {
        let link = "wolfmore://watch?code=\(code)"
        let alert = UIAlertController(
            title: "Live Session Created",
            message: "Share this link with spectators:\n\(link)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Copy Code", style: .default) { _ in
            UIPasteboard.general.string = code
        })
        alert.addAction(UIAlertAction(title: "Share", style: .default) { [weak self] _ in
            guard let self else { return }
            let av = UIActivityViewController(activityItems: [link], applicationActivities: nil)
            self.present(av, animated: true)
        })
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
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
                g.course.pars = picked.pars
                g.course.holeHandicaps = picked.hcs
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
        if !stored.isEmpty && stored != "WolfMore" {
            courseNameLabel.text = stored
            return
        }

        let currentPars = Array(g.course.pars.prefix(STANDARD_HOLES))
        let currentHCs  = Array(g.course.holeHandicaps.prefix(STANDARD_HOLES))

        let match = CourseLibrary.shared.courses.first {
            Array($0.pars.prefix(STANDARD_HOLES)) == currentPars &&
            Array($0.hcs.prefix(STANDARD_HOLES)) == currentHCs
        }

        courseNameLabel.text = match?.name ?? "Custom Course"
    }

    private func refreshUmbrellaButtonUI() {
        let title = umbrellaMuted ? "Umbrella: OFF" : "Umbrella: ON"
        let bg = umbrellaMuted ? UIColor.systemBrown : UIColor.systemOrange

        if #available(iOS 15.0, *) {
            var cfg = umbrellaButton.configuration ?? UIButton.Configuration.filled()
            cfg.title = title
            cfg.baseBackgroundColor = bg
            cfg.baseForegroundColor = .label

            cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
                outgoing.foregroundColor = UIColor.label
                return outgoing
            }

            umbrellaButton.configuration = cfg
            umbrellaButton.setTitleColor(.label, for: .normal)
            umbrellaButton.setTitleColor(.label, for: .highlighted)
            umbrellaButton.setTitleColor(.label, for: .selected)
            umbrellaButton.setTitleColor(.label, for: .disabled)
        } else {
            umbrellaButton.setTitle(title, for: .normal)
            umbrellaButton.backgroundColor = bg
            umbrellaButton.setTitleColor(.label, for: .normal)
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
