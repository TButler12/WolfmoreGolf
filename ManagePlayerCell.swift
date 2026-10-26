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

    override func awakeFromNib() {
        super.awakeFromNib()
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.7
    }

    // Makes nameLabel fill all space left by the fixed-width HC field and switch,
    // mirroring what applyAdaptiveColumnLayout does on the scoring screen.
    override func layoutSubviews() {
        super.layoutSubviews()
        let w = contentView.bounds.width
        guard w > 10 else { return }
        let rightMargin: CGFloat = 8
        let switchW: CGFloat = 61; let switchGap: CGFloat = 41
        let hcW: CGFloat = 50;    let nameGap: CGFloat = 8
        let nameX: CGFloat = 46
        let switchX = w - rightMargin - switchW
        let hcX     = switchX - switchGap - hcW
        let nameW   = max(60, hcX - nameGap - nameX)
        activeSwitch.frame = CGRect(x: switchX, y: 11, width: switchW, height: 28)
        hcField.frame      = CGRect(x: hcX,     y: 2,  width: hcW,    height: 34)
        nameLabel.frame    = CGRect(x: nameX,    y: 12, width: nameW,  height: 21)
    }
}

