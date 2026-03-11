//
//  ScoreStyle.swift
//  Wolfmore-5Man
//
//  Created by Tom BUTLER on 10/9/25.
//

// ScoreStyle.swift
import UIKit

enum ScoreZeroFormat { case E, zero }   // choose "E" or "0"

func applyScoreStyle(
    to label: UILabel,
    delta: Int?,
    zeroFormat: ScoreZeroFormat = .E,
    showPlusForPositives: Bool = true
) {
    // If nil, clear
    guard let v = delta else {
        label.text = ""
        label.textColor = .secondaryLabel
        return
    }

    // Use a true minus (U+2212) so it looks right typographically
    let minus = "−"   // not a hyphen!
    let text: String
    let color: UIColor

    switch v {
    case ..<0:
        text  = "\(minus)\(abs(v))"
        color = .systemRed                   // negatives (under-par) = red
    case 0:
        text  = (zeroFormat == .E) ? "E" : "0"
        color = .label                       // even = default text color
    default:
        text  = showPlusForPositives ? "+\(v)" : "\(v)"
        color = .label                       // positives (over-par) = default
    }

    // If you want bold for emphasis:
    let font = label.font ?? UIFont.preferredFont(forTextStyle: .body)
    let attr = NSMutableAttributedString(string: text, attributes: [
        .font: font,
        .foregroundColor: color
    ])
    label.attributedText = attr
}
