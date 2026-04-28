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

        let settings = gameData.nassauState!.settings

        baseStakeField.text = String(format: "%.2f", settings.baseStake)
        triggerField.text = String(settings.autoPressTriggerDown)

        // 0 = Auto, 1 = Manual
        pressModeSegmentedControl.selectedSegmentIndex = (settings.pressMode == .auto) ? 0 : 1

        baseStakeField.keyboardType = .decimalPad
        triggerField.keyboardType = .numberPad

        baseStakeField.borderStyle = .roundedRect
        triggerField.borderStyle = .roundedRect

        baseStakeField.placeholder = "Base stake"
        triggerField.placeholder = "Trigger"

        baseStakeField.delegate = self
        triggerField.delegate = self

        updateTriggerVisibility()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        installRemoteNassauButton()
    }

    private func installRemoteNassauButton() {
        let btn = UIButton(type: .custom)
        btn.translatesAutoresizingMaskIntoConstraints = false
        var cfg = UIButton.Configuration.filled()
        cfg.title = "Remote Nassau"
        cfg.baseBackgroundColor = UIColor(red: 0.967, green: 0.941, blue: 0.690, alpha: 1)
        cfg.baseForegroundColor = .black
        cfg.cornerStyle = .large
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
        btn.configuration = cfg
        btn.addTarget(self, action: #selector(remoteNassauTapped(_:)), for: .touchUpInside)
        view.addSubview(btn)
        NSLayoutConstraint.activate([
            btn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            btn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            btn.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            btn.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40),
        ])
    }

    // MARK: - Remote Nassau

    @objc private func remoteNassauTapped(_ sender: UIButton) {
        let ac = UIAlertController(title: "Remote Nassau", message: nil, preferredStyle: .actionSheet)

        ac.addAction(UIAlertAction(title: "Send Invite", style: .default) { [weak self] _ in
            self?.sendRemoteInvite()
        })
        ac.addAction(UIAlertAction(title: "Import Invite", style: .default) { [weak self] _ in
            self?.importRemoteInvite()
        })
        ac.addAction(UIAlertAction(title: "View Matches", style: .default) { [weak self] _ in
            let vc = RemoteMatchesViewController()
            self?.navigationController?.pushViewController(vc, animated: true)
        })
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
        }
        present(ac, animated: true)
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
        guard let myIndex = myPlayerIndex(in: g) else { return }

        let myRound = SharedRoundBuilder.make(from: g, playerIndex: myIndex)

        promptForRemoteStake { [weak self] stake in
            guard let self else { return }
            self.promptForRemoteRound { [weak self] opponentRound in
                guard let self else { return }

                guard !self.isSamePlayer(myRound.playerName, opponentRound.playerName) else {
                    self.showRemoteError("You pasted your own remote round code. Paste your opponent's code instead.")
                    return
                }

                let savedMatch = RemoteMatch(
                    myRound: myRound,
                    opponentName: opponentRound.playerName,
                    stakePerBet: stake,
                    inviteCode: nil,
                    isAccepted: true,
                    opponentRound: opponentRound
                )
                RemoteMatchStore.shared.add(savedMatch)

                let ac = UIAlertController(title: "Compare Mode", message: nil, preferredStyle: .actionSheet)
                ac.addAction(UIAlertAction(title: "Hole by Hole", style: .default) { [weak self] _ in
                    self?.sendAcceptanceAndOpen(savedMatch, mode: .holeByHole)
                })
                ac.addAction(UIAlertAction(title: "Front / Back 9 by HC", style: .default) { [weak self] _ in
                    self?.sendAcceptanceAndOpen(savedMatch, mode: .frontBackByHC)
                })
                ac.addAction(UIAlertAction(title: "18 Holes by HC", style: .default) { [weak self] _ in
                    self?.sendAcceptanceAndOpen(savedMatch, mode: .all18ByHC)
                })
                ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                self.present(ac, animated: true)
            }
        }
    }

    private func openRemoteMatch(_ match: RemoteMatch, mode: RemoteCompareMode) {
        guard let opponentRound = match.opponentRound, let result = match.result else {
            showRemoteError("Could not calculate Remote Nassau result.")
            return
        }
        let vc = RemoteNassauViewController()
        vc.myRound = match.myRound
        vc.opponentRound = opponentRound
        vc.result = result
        vc.compareMode = mode
        navigationController?.pushViewController(vc, animated: true)
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

    private func sendAcceptanceAndOpen(_ match: RemoteMatch, mode: RemoteCompareMode) {
        let body = buildAcceptanceMessage(match: match, mode: mode)
        if MFMessageComposeViewController.canSendText() {
            onMessageComposeDismissed = { [weak self] in
                self?.openRemoteMatch(match, mode: mode)
            }
            let composer = MFMessageComposeViewController()
            composer.messageComposeDelegate = self
            composer.body = body
            present(composer, animated: true)
        } else {
            openRemoteMatch(match, mode: mode)
        }
    }

    private func buildAcceptanceMessage(match: RemoteMatch, mode: RemoteCompareMode) -> String {
        let modeLabel: String
        switch mode {
        case .holeByHole:    modeLabel = "Hole by Hole"
        case .frontBackByHC: modeLabel = "Front/Back 9 by HC"
        case .all18ByHC:     modeLabel = "18 Holes by HC"
        }
        let opponentCourse = match.opponentRound?.courseName ?? "their course"
        return """
        WolfMore Remote Nassau — Challenge Accepted!
        \(match.myRound.playerName) @ \(match.myRound.courseName)
        vs \(match.opponentName) @ \(opponentCourse)
        Mode: \(modeLabel)
        Stake: $\(match.stakePerBet) per bet
        Game on!
        """
    }

    @IBAction private func pressModeChanged(_ sender: UISegmentedControl) {
        updateTriggerVisibility()
    }

    private func updateTriggerVisibility() {
        let isAuto = (pressModeSegmentedControl.selectedSegmentIndex == 0)
        triggerField.isHidden = !isAuto
        triggerLabel.isHidden = !isAuto
        
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
        state.settings.pressMode = (pressModeSegmentedControl.selectedSegmentIndex == 0) ? .auto : .manual
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
