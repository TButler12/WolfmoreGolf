//
//  NassauSettingsViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 3/26/26.
import UIKit

final class NassauSettingsViewController: UIViewController, UITextFieldDelegate {

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
