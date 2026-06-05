//
//  NassauSettingsViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 3/26/26.
import UIKit
import MessageUI

final class NassauSettingsViewController: UIViewController, UITextFieldDelegate, MFMessageComposeViewControllerDelegate {

    var gameData: GameData!

    @IBOutlet private weak var baseStakeField: UITextField!
    @IBOutlet private weak var pressModeSegmentedControl: UISegmentedControl!
    @IBOutlet private weak var triggerField: UITextField!
    @IBOutlet private weak var triggerLabel: UILabel!

    private var scrollView: UIScrollView!
    private var contentStack: UIStackView!
    private weak var saveButton: UIButton?
    private weak var triggerSection: UIStackView?
    private weak var editPlayersButton: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Nassau Settings"
        view.backgroundColor = .systemBackground

        if gameData.nassauState == nil {
            gameData.nassauState = NassauState(
                settings: NassauSettings(),
                oneVsOneMatches: [],
                twoVsTwoMatches: []
            )
        }

        buildScrollLayout()

        let settings = gameData.nassauState!.settings
        baseStakeField.text = String(format: "%.2f", settings.baseStake)
        triggerField.text = String(settings.autoPressTriggerDown)
        pressModeSegmentedControl.selectedSegmentIndex = (settings.pressMode == .auto) ? 0 : 1

        updateTriggerVisibility()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        saveButton?.configuration = wmStyledButton(title: "Save", style: .primary)
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

        // Base Stake section
        let stakeField = UITextField()
        stakeField.keyboardType = .decimalPad
        stakeField.borderStyle = .roundedRect
        stakeField.placeholder = "Base stake"
        stakeField.font = UIFont.preferredFont(forTextStyle: .body)
        stakeField.adjustsFontForContentSizeCategory = true
        stakeField.delegate = self
        stakeField.translatesAutoresizingMaskIntoConstraints = false
        stakeField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        baseStakeField = stakeField
        main.addArrangedSubview(vSection("Base Stake ($)", body: stakeField))

        // Press Mode section
        let segment = UISegmentedControl(items: ["Auto", "Off"])
        segment.addTarget(self, action: #selector(pressModeChanged(_:)), for: .valueChanged)
        pressModeSegmentedControl = segment
        main.addArrangedSubview(vSection("Press Mode", body: segment))

        // Trigger section (shown only in Auto mode)
        let trigLbl = UILabel()
        trigLbl.text = "Auto-press when down by:"
        trigLbl.font = UIFont.preferredFont(forTextStyle: .body)
        trigLbl.adjustsFontForContentSizeCategory = true
        triggerLabel = trigLbl

        let trigField = UITextField()
        trigField.keyboardType = .numberPad
        trigField.borderStyle = .roundedRect
        trigField.placeholder = "Trigger"
        trigField.font = UIFont.preferredFont(forTextStyle: .body)
        trigField.adjustsFontForContentSizeCategory = true
        trigField.delegate = self
        trigField.translatesAutoresizingMaskIntoConstraints = false
        trigField.widthAnchor.constraint(equalToConstant: 80).isActive = true
        triggerField = trigField

        let trigRow = UIStackView(arrangedSubviews: [trigLbl, trigField])
        trigRow.axis = .horizontal
        trigRow.spacing = 12
        trigRow.alignment = .center
        trigLbl.setContentHuggingPriority(.defaultLow, for: .horizontal)
        trigField.setContentHuggingPriority(.required, for: .horizontal)

        let trigSect = vSection("Auto Press Trigger", body: trigRow)
        main.addArrangedSubview(trigSect)
        triggerSection = trigSect

        // Edit Players In button
        let editBtn = UIButton(type: .system)
        editBtn.configuration = {
            var cfg = UIButton.Configuration.filled()
            cfg.title = "Edit Players In"
            cfg.baseBackgroundColor = .systemGray5
            cfg.baseForegroundColor = .label
            cfg.cornerStyle = .capsule
            cfg.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)
            return cfg
        }()
        editBtn.addTarget(self, action: #selector(editPlayersTapped), for: .touchUpInside)
        editPlayersButton = editBtn
        main.addArrangedSubview(editBtn)

        // Remote Nassau button
        let remoteBtn = UIButton(type: .custom)
        remoteBtn.translatesAutoresizingMaskIntoConstraints = false
        remoteBtn.heightAnchor.constraint(equalToConstant: 48).isActive = true
        var remoteCfg = UIButton.Configuration.filled()
        remoteCfg.title = "Remote Nassau"
        remoteCfg.baseBackgroundColor = UIColor(red: 0.967, green: 0.941, blue: 0.690, alpha: 1)
        remoteCfg.baseForegroundColor = .label
        remoteCfg.cornerStyle = .large
        remoteCfg.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
        remoteBtn.configuration = remoteCfg
        remoteBtn.addTarget(self, action: #selector(remoteNassauTapped(_:)), for: .touchUpInside)
        main.addArrangedSubview(remoteBtn)

        // Save button
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

    // MARK: - Remote Nassau

    @objc private func remoteNassauTapped(_ sender: UIButton) {
        let ac = UIAlertController(title: "Remote Nassau", message: nil, preferredStyle: .actionSheet)

        ac.addAction(UIAlertAction(title: "▶ Start Live Match", style: .default) { [weak self] _ in
            self?.startLiveMatchTapped()
        })
        ac.addAction(UIAlertAction(title: "↩ Join Live Match", style: .default) { [weak self] _ in
            self?.joinLiveMatchTapped()
        })
        ac.addAction(UIAlertAction(title: "View Matches", style: .default) { [weak self] _ in
            let vc = RemoteMatchesViewController()
            self?.navigationController?.pushViewController(vc, animated: true)
        })
        let hasMatch = GameManager.shared.currentGame?.remoteMatchId != nil
        let shareTitle = hasMatch ? "Share Match Code" : "Share Match Code (no active match)"
        let shareAction = UIAlertAction(title: shareTitle, style: .default) { [weak self] _ in
            self?.shareMatchCode()
        }
        shareAction.isEnabled = hasMatch
        ac.addAction(shareAction)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
        }
        present(ac, animated: true)
    }

    private func startLiveMatchTapped() {
        guard let g = GameManager.shared.currentGame else { return }
        let nassau     = g.nassauState
        let stake      = nassau?.settings.baseStake ?? Double(g.baseGameStake)
        let courseName = g.course.name

        // Build confirmation message from current nassauState
        let stakeText: String = stake == floor(stake)
            ? "$\(Int(stake))"
            : String(format: "$%.2f", stake)

        let pressModeText: String
        switch nassau?.settings.pressMode ?? .auto {
        case .auto:   pressModeText = "Auto"
        case .manual: pressModeText = "Manual"
        case .off:    pressModeText = "Off"
        }

        let trigger = nassau?.settings.autoPressTriggerDown ?? 2

        let included: [String] = (0..<MAX_PLAYERS).compactMap { idx in
            guard idx < g.playerActivated.count, g.playerActivated[idx],
                  idx < g.playerNames.count else { return nil }
            let name = g.playerNames[idx].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            let isIncluded = nassau.map { idx < $0.playerIncluded.count && $0.playerIncluded[idx] } ?? true
            return isIncluded ? name : nil
        }

        let playersText = included.isEmpty ? "None" : included.joined(separator: ", ")

        let message = """
            Stake: \(stakeText)
            Press Mode: \(pressModeText)
            Trigger: \(trigger) down
            Players: \(playersText)
            """

        let confirm = UIAlertController(
            title: "Start Live Match",
            message: message,
            preferredStyle: .alert
        )
        confirm.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        confirm.addAction(UIAlertAction(title: "Confirm", style: .default) { [weak self] _ in
            guard let self else { return }
            Task {
                do {
                    let match = try await SupabaseService.shared.createMatch(
                        courseA: courseName,
                        courseB: "",
                        stake: stake,
                        games: ["nassau"]
                    )
                    GameManager.shared.update { g in
                        g.remoteMatchId = match.id
                        if !g.remoteMatchIds.contains(match.id) { g.remoteMatchIds.append(match.id) }
                    }
                    NotificationCenter.default.post(name: NSNotification.Name("RemoteMatchDidStart"), object: nil)
                    await MainActor.run {
                        let alert = UIAlertController(
                            title: "Live Match Created",
                            message: "Share this code with your opponent:\n\n\(match.code)",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "Copy Code", style: .default) { _ in
                            UIPasteboard.general.string = match.code
                        })
                        alert.addAction(UIAlertAction(title: "Share", style: .default) { [weak self] _ in
                            guard let self else { return }
                            let text = "Join my Nassau game on WolfMore! Match code: \(match.code)"
                            let avc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
                            if let pop = avc.popoverPresentationController {
                                pop.sourceView = self.view
                                pop.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                                pop.permittedArrowDirections = []
                            }
                            self.present(avc, animated: true)
                        })
                        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                        self.present(alert, animated: true)
                    }
                } catch {
                    await MainActor.run { self.showLiveMatchError(error) }
                }
            }
        })
        present(confirm, animated: true)
    }

    private func joinLiveMatchTapped() {
        let prompt = UIAlertController(
            title: "Join Live Match",
            message: "Enter the 6-character match code",
            preferredStyle: .alert
        )
        prompt.addTextField { tf in
            tf.placeholder            = "WOLF42"
            tf.autocapitalizationType = .allCharacters
        }
        prompt.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        prompt.addAction(UIAlertAction(title: "Join", style: .default) { [weak self] _ in
            guard let self,
                  let code = prompt.textFields?.first?.text?
                      .trimmingCharacters(in: .whitespacesAndNewlines),
                  !code.isEmpty else { return }
            Task {
                do {
                    let joinerCourse = GameManager.shared.currentGame?.course.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let match = try await SupabaseService.shared.joinMatch(code: code, courseB: joinerCourse)
                    GameManager.shared.update { g in
                        g.remoteMatchId = match.id
                        if !g.remoteMatchIds.contains(match.id) { g.remoteMatchIds.append(match.id) }
                    }
                    NotificationCenter.default.post(name: NSNotification.Name("RemoteMatchDidStart"), object: nil)
                    SupabaseService.shared.subscribeToResults(matchId: match.id) { [weak self] result in
                        self?.handleLiveResult(result)
                    }
                    await MainActor.run {
                        let alert = UIAlertController(
                            title: "Joined Match",
                            message: "Connected to live match \(match.code). Scores will sync as they come in.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                        self.present(alert, animated: true)
                    }
                } catch {
                    await MainActor.run { self.showLiveMatchError(error, code: code) }
                }
            }
        })
        present(prompt, animated: true)
    }

    private func shareMatchCode() {
        guard let matchId = GameManager.shared.currentGame?.remoteMatchId else { return }
        Task {
            do {
                let match = try await SupabaseService.shared.fetchMatch(id: matchId)
                await MainActor.run {
                    let text = "Join my Nassau game on WolfMore! Match code: \(match.code)"
                    let avc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
                    if let pop = avc.popoverPresentationController {
                        pop.sourceView = self.view
                        pop.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                        pop.permittedArrowDirections = []
                    }
                    self.present(avc, animated: true)
                }
            } catch {
                await MainActor.run {
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    private func handleLiveResult(_ result: HoleResultRecord) {
        // Placeholder: no live scoring UI in this VC yet.
    }

    private func showLiveMatchError(_ error: Error, code: String? = nil) {
        let msg = code.map { "Could not find match with code \($0)." } ?? error.localizedDescription
        let alert = UIAlertController(title: "Live Match Error", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    private func sendRemoteInvite() {
        guard let g = GameManager.shared.currentGame else { return }
        guard let myIndex = myPlayerIndex(in: g) else { return }

        let round = SharedRoundBuilder.make(from: g, playerIndex: myIndex)
        guard let encoded = RemoteRoundCodec.encode(round) else {
            showRemoteError("Could not create remote invite.")
            return
        }

        let messageBody = """
        WolfMore Remote Nassau Invite

        Player: \(round.playerName)
        Course: \(round.courseName)

        Paste this code into WolfMore:
        \(encoded)
        """

        if MFMessageComposeViewController.canSendText() {
            let composer = MFMessageComposeViewController()
            composer.messageComposeDelegate = self
            composer.body = messageBody
            present(composer, animated: true)
        } else {
            UIPasteboard.general.string = encoded
            let ac = UIAlertController(
                title: "Messages Unavailable",
                message: "This device cannot send texts. The invite code was copied to the clipboard instead.",
                preferredStyle: .alert
            )
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }

    private func importRemoteInvite() {
        guard let g = GameManager.shared.currentGame else { return }
        guard let myIndex = myPlayerIndex(in: g) else {
            showRemoteError("Set your name in Profile before importing a challenge.")
            return
        }

        promptForRemoteStake { [weak self] stake in
            guard let self else { return }
            self.promptForRemoteRound { [weak self] opponentRound in
                guard let self else { return }

                let myRound = SharedRoundBuilder.makeIdentity(from: g, playerIndex: myIndex)

                guard !self.isSamePlayer(myRound.playerName, opponentRound.playerName) else {
                    self.showRemoteError("You pasted your own remote round code. Paste your opponent's code instead.")
                    return
                }

                let ac = UIAlertController(title: "Compare Mode", message: nil, preferredStyle: .actionSheet)
                ac.addAction(UIAlertAction(title: "Hole by Hole", style: .default) { [weak self] _ in
                    self?.acceptChallenge(myRound: myRound, opponentRound: opponentRound, stake: stake, mode: .holeByHole)
                })
                ac.addAction(UIAlertAction(title: "Front / Back 9 by HC", style: .default) { [weak self] _ in
                    self?.acceptChallenge(myRound: myRound, opponentRound: opponentRound, stake: stake, mode: .frontBackByHC)
                })
                ac.addAction(UIAlertAction(title: "18 Holes by HC", style: .default) { [weak self] _ in
                    self?.acceptChallenge(myRound: myRound, opponentRound: opponentRound, stake: stake, mode: .all18ByHC)
                })
                ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                self.present(ac, animated: true)
            }
        }
    }

    private func acceptChallenge(myRound: SharedRound, opponentRound: SharedRound, stake: Int, mode: RemoteCompareMode) {
        let match = RemoteMatch(
            myRound: myRound,
            opponentName: opponentRound.playerName,
            stakePerBet: stake,
            inviteCode: nil,
            isAccepted: true,
            opponentRound: opponentRound,
            compareMode: mode,
            roundApplied: false
        )
        print("DEBUG RemoteNassau sameCourse: \(match.sameCourse) local: \(myRound.courseName) remote: \(opponentRound.courseName)")
        RemoteMatchStore.shared.add(match)
        sendAcceptanceMessage(match: match)
    }

    private func sendAcceptanceMessage(match: RemoteMatch) {
        let body = buildAcceptanceMessage(match: match)
        if MFMessageComposeViewController.canSendText() {
            onMessageComposeDismissed = { [weak self] in
                self?.showAcceptanceConfirmation()
            }
            let composer = MFMessageComposeViewController()
            composer.messageComposeDelegate = self
            composer.body = body
            present(composer, animated: true)
        } else {
            showAcceptanceConfirmation()
        }
    }

    private func showAcceptanceConfirmation() {
        let ac = UIAlertController(
            title: "Challenge Accepted! 🏌️",
            message: "Play your round, then open Remote Nassau → View Matches and tap \"Apply Round & Calculate Results\".",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "Let's Play!", style: .default))
        present(ac, animated: true)
    }

    private func promptForRemoteStake(completion: @escaping (Int) -> Void) {
        let ac = UIAlertController(
            title: "Nassau Stake",
            message: "Enter the stake per bet (Front / Back / Overall)",
            preferredStyle: .alert
        )
        ac.addTextField { tf in
            tf.placeholder = "10"; tf.text = "10"; tf.keyboardType = .numberPad
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Continue", style: .default) { _ in
            let raw = ac.textFields?.first?.text ?? "10"
            completion(max(1, Int(raw.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 10))
        })
        present(ac, animated: true)
    }

    private func promptForRemoteRound(completion: @escaping (SharedRound) -> Void) {
        let vc = ImportRemoteRoundViewController()
        vc.modalPresentationStyle = .formSheet
        vc.onImport = { [weak self, weak vc] rawText in
            guard let self else { return }
            let cleaned = rawText
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\n", with: "")
                .replacingOccurrences(of: "\r", with: "")
            let code: String
            if let range = cleaned.range(of: "WOLFMORE_REMOTE_NASSAU:") {
                code = String(cleaned[range.lowerBound...])
            } else {
                code = cleaned
            }
            guard !code.isEmpty else {
                vc?.dismiss(animated: true) { self.showRemoteError("Paste a shared round code first.") }
                return
            }
            guard let round = RemoteRoundCodec.decode(code) else {
                vc?.dismiss(animated: true) { self.showRemoteError("That shared round code could not be read.") }
                return
            }
            vc?.dismiss(animated: true) { completion(round) }
        }
        present(vc, animated: true)
    }

    private func myPlayerIndex(in g: GameData) -> Int? {
        let myName = (ProfileStore.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !myName.isEmpty else { return nil }
        return g.playerNames.firstIndex {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedCaseInsensitiveCompare(myName) == .orderedSame
        }
    }

    private func isSamePlayer(_ a: String, _ b: String) -> Bool {
        a.trimmingCharacters(in: .whitespacesAndNewlines)
            .localizedCaseInsensitiveCompare(b.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame
    }

    private func showRemoteError(_ message: String = "That shared round code could not be read.") {
        let ac = UIAlertController(title: "Import Failed", message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    private var onMessageComposeDismissed: (() -> Void)?

    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                      didFinishWith result: MessageComposeResult) {
        let failed = result == .failed
        controller.dismiss(animated: true) { [weak self] in
            if failed { self?.showRemoteError("Message failed to send.") }
            self?.onMessageComposeDismissed?()
            self?.onMessageComposeDismissed = nil
        }
    }

    private func buildAcceptanceMessage(match: RemoteMatch) -> String {
        let modeLabel: String
        switch match.compareMode {
        case .holeByHole:    modeLabel = "Hole by Hole"
        case .frontBackByHC: modeLabel = "Front/Back 9 by HC"
        case .all18ByHC:     modeLabel = "18 Holes by HC"
        }
        return """
        WolfMore Nassau — Challenge Accepted! 🏌️
        \(match.myRound.playerName) @ \(match.myRound.courseName)
        Mode: \(modeLabel)
        Stake: $\(match.stakePerBet) per bet
        Results coming after my round!
        """
    }

    // MARK: - Players In

    @objc private func editPlayersTapped() {
        guard let nassau = gameData.nassauState else { return }
        showPlayersInPicker(data: gameData, nassau: nassau)
    }

    private func showPlayersInPicker(data: GameData, nassau: NassauState) {
        let activeIndexes = data.playerActivated.enumerated().compactMap { $0.element ? $0.offset : nil }

        let ac = UIAlertController(title: "Players In", message: "Tap to add or remove players", preferredStyle: .actionSheet)

        for idx in activeIndexes {
            let name = nassauPlayerName(for: idx, in: data)
            let included = idx < nassau.playerIncluded.count && nassau.playerIncluded[idx]
            let title = "\(included ? "✓ " : "")\(name)"
            ac.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                guard let self else { return }
                var d = self.gameData!
                guard var s = d.nassauState else { return }
                if idx < s.playerIncluded.count {
                    s.playerIncluded[idx].toggle()
                }
                d.nassauState = s
                self.gameData = d
                GameManager.shared.currentGame = d
                GameManager.shared.saveCurrent()
                DispatchQueue.main.async { self.showPlayersInPicker(data: d, nassau: s) }
            })
        }

        ac.addAction(UIAlertAction(title: "Done", style: .cancel))

        if let pop = ac.popoverPresentationController, let btn = editPlayersButton {
            pop.sourceView = btn
            pop.sourceRect = btn.bounds
        }
        present(ac, animated: true)
    }

    private func nassauPlayerName(for index: Int, in data: GameData) -> String {
        guard index < data.playerNames.count else { return "Player \(index + 1)" }
        let name = data.playerNames[index].trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Player \(index + 1)" : name
    }

    @IBAction private func pressModeChanged(_ sender: UISegmentedControl) {
        updateTriggerVisibility()
    }

    private func updateTriggerVisibility() {
        let isAuto = (pressModeSegmentedControl.selectedSegmentIndex == 0)
        triggerSection?.isHidden = !isAuto
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @IBAction private func saveTapped(_ sender: UIButton) {
        dismissKeyboard()

        guard var state = gameData.nassauState else { return }

        let baseStake = Double(baseStakeField.text ?? "") ?? 1.0
        let trigger = Int(triggerField.text ?? "") ?? 2

        state.settings.baseStake = max(0, baseStake)
        state.settings.pressMode = (pressModeSegmentedControl.selectedSegmentIndex == 0) ? .auto : .off
        state.settings.autoPressTriggerDown = max(1, trigger)

        gameData.nassauState = state

        GameManager.shared.update { g in
            guard var updatedState = g.nassauState else { return }

            updatedState.settings.baseStake = state.settings.baseStake
            updatedState.settings.pressMode = state.settings.pressMode
            updatedState.settings.autoPressTriggerDown = state.settings.autoPressTriggerDown

            let newStake = updatedState.settings.baseStake

            updatedState.oneVsOneMatches = updatedState.oneVsOneMatches.map { match in
                var m = match
                m.stake = newStake
                m.presses = m.presses.map {
                    var p = $0
                    p.stake = newStake
                    return p
                }
                return m
            }

            updatedState.twoVsTwoMatches = updatedState.twoVsTwoMatches.map { match in
                var m = match
                m.stake = newStake
                m.presses = m.presses.map {
                    var p = $0
                    p.stake = newStake
                    return p
                }
                return m
            }

            g.nassauState = updatedState
        }

        navigationController?.popViewController(animated: true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
