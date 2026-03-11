//
//  ButtonStyles.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 3/2/26.
//

import UIKit

enum WMButtonStyle {
    case primary
    case secondary
}

func wmStyledButton(title: String, style: WMButtonStyle) -> UIButton.Configuration {
    var config = UIButton.Configuration.filled()

    config.title = title
    config.cornerStyle = .capsule
    config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 18)

    switch style {
    case .primary:
        config.baseBackgroundColor = .wolfMoreGreen
        config.baseForegroundColor = .white
    case .secondary:
        config.baseBackgroundColor = .systemGray5
        config.baseForegroundColor = .label
    }

    return config
}
extension UIColor {
    static var wolfPrimaryGreen: UIColor {
        UIColor(red: 0.10, green: 0.33, blue: 0.18, alpha: 1.0)
    }

    // ✅ Alias so any old references compile
    static var wolfMoreGreen: UIColor { .wolfPrimaryGreen }
}
