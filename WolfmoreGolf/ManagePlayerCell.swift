//
//  ManagePlayerCell.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 11/27/25.
//
import UIKit

final class ManagePlayerCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var hcField: UITextField!
    @IBOutlet weak var activeSwitch: UISwitch!

    /// Callbacks so the VC can update FriendStore
    var hcChanged: ((Int) -> Void)?
    var activeChanged: ((Bool) -> Void)?

    @IBAction private func hcEditingDidEnd(_ sender: UITextField) {
        let value = Int(sender.text ?? "") ?? 0
        hcChanged?(value)
    }

    @IBAction private func activeSwitchChanged(_ sender: UISwitch) {
        activeChanged?(sender.isOn)
    }
    func applyHCStyle(isRequired: Bool) {
        let isEmpty = (hcField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if isRequired && isEmpty {
            hcField.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.25)
            hcField.layer.cornerRadius = 8
            hcField.layer.borderWidth = 1
            hcField.layer.borderColor = UIColor.systemYellow.withAlphaComponent(0.8).cgColor
        } else {
            hcField.backgroundColor = .clear
            hcField.layer.borderWidth = 0
            hcField.layer.borderColor = UIColor.clear.cgColor
        }
    }
}

