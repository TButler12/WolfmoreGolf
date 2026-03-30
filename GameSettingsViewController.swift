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
    
    private var umbrellaMuted = false   // true = OFF

    var gameData: GameData?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Game Settings"
        view.backgroundColor = .systemBackground

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

            if g.gameHoleDollarsArray.count != 18 {
                g.gameHoleDollarsArray = Array(repeating: stake, count: 18)
            } else {
                for i in 0..<18 {
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

        let currentPars = Array(g.course.pars.prefix(18))
        let currentHCs  = Array(g.course.holeHandicaps.prefix(18))

        let match = CourseLibrary.shared.courses.first {
            Array($0.pars.prefix(18)) == currentPars &&
            Array($0.hcs.prefix(18)) == currentHCs
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
            cfg.baseForegroundColor = .black

            cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
                outgoing.foregroundColor = UIColor.black
                return outgoing
            }

            umbrellaButton.configuration = cfg
            umbrellaButton.setTitleColor(.black, for: .normal)
            umbrellaButton.setTitleColor(.black, for: .highlighted)
            umbrellaButton.setTitleColor(.black, for: .selected)
            umbrellaButton.setTitleColor(.black, for: .disabled)
        } else {
            umbrellaButton.setTitle(title, for: .normal)
            umbrellaButton.backgroundColor = bg
            umbrellaButton.setTitleColor(.black, for: .normal)
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
