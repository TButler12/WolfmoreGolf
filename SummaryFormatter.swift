//
//  SummaryFormatter.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 2/8/26.
//

import Foundation
private func buildTextSummary(from rows: [RoundSummary], courseName: String? = nil) -> String {
    let date = rows.map(\.date).max() ?? Date()
    let df = DateFormatter()
    df.dateStyle = .short
    df.timeStyle = .none

    let titleCourse = (courseName?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }
    let header = "WolfMore Summary" + (titleCourse != nil ? " — \(titleCourse!)" : "") + " (\(df.string(from: date)))"

    // Sort players by money high -> low
    let sorted = rows.sorted { $0.totalMoney > $1.totalMoney }

    func moneyString(_ v: Int) -> String {
        let sign = v > 0 ? "+" : ""
        return "\(sign)$\(v)"
    }

    // Totals lines
    var lines: [String] = []
    lines.append(header)
    lines.append("")

    lines.append("Totals:")
    for r in sorted {
        let proxPart = r.totalProx > 0 ? "  • Prox \(r.totalProx)" : ""
        let scorePart = (r.totalScore != nil) ? "  • Score \(r.totalScore!)" : ""
        lines.append("\(r.playerName): \(moneyString(r.totalMoney))\(proxPart)\(scorePart)")
    }

    // Optional: quick highlight
    if let leader = sorted.first, let last = sorted.last, sorted.count >= 2 {
        lines.append("")
        lines.append("Top/Bottom: \(leader.playerName) \(moneyString(leader.totalMoney)) | \(last.playerName) \(moneyString(last.totalMoney))")
    }

    lines.append("")
    lines.append("Sent from WolfMore")

    return lines.joined(separator: "\n")
}
