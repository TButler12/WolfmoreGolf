import Foundation

/// Pure string formatting for live match board status lines.
/// Extracted from GameViewController so the logic can be unit-tested independently.
enum MatchStatusFormatter {

    struct MatchScoreLine {
        let diff: Int       // positive = A leads, negative = B leads, 0 = all square
        let played: Int     // holes committed
        let remaining: Int  // uncommitted holes left
        let aLabel: String  // e.g. "McTommy" or "McTommy/Ray"
        let bLabel: String
    }

    /// Status string for a single match, e.g. "McTommy 2 UP vs Pat · thru 2".
    static func singleMatchStatus(_ m: MatchScoreLine) -> String {
        let (diff, played, remaining, a, b) = (m.diff, m.played, m.remaining, m.aLabel, m.bLabel)
        if diff > 0, diff > remaining {
            let score = remaining == 0 ? "\(diff)" : "\(diff)&\(remaining)"
            return "\(a) won \(score) · Final"
        }
        if diff < 0, abs(diff) > remaining {
            let score = remaining == 0 ? "\(abs(diff))" : "\(abs(diff))&\(remaining)"
            return "\(b) won \(score) · Final"
        }
        if remaining == 0 {
            if diff == 0 { return "Halved · Final" }
            let score = "\(abs(diff))"
            return diff > 0 ? "\(a) won \(score) · Final" : "\(b) won \(score) · Final"
        }
        if diff == 0    { return "All Square · thru \(played)" }
        if  diff > 0, diff == remaining { return "\(a) Dormie" }
        if  diff < 0, abs(diff) == remaining { return "\(b) Dormie" }
        return diff > 0
            ? "\(a) \(diff) UP vs \(b) · thru \(played)"
            : "\(b) \(abs(diff)) UP vs \(a) · thru \(played)"
    }

    /// Status string for a dual match (two simultaneous singles or Fourball pairs),
    /// e.g. "McTommy 2 UP vs Pat · Ray 2 UP vs Doug · thru 2".
    static func dualMatchStatus(m1: MatchScoreLine, m2: MatchScoreLine) -> String {
        func segment(_ m: MatchScoreLine) -> String {
            let (diff, remaining, a, b) = (m.diff, m.remaining, m.aLabel, m.bLabel)
            if diff > 0, diff > remaining { return "\(a) won \(diff)&\(remaining)" }
            if diff < 0, abs(diff) > remaining { return "\(b) won \(abs(diff))&\(remaining)" }
            if remaining == 0 {
                if diff == 0 { return "Halved" }
                return diff > 0 ? "\(a) won \(abs(diff))" : "\(b) won \(abs(diff))"
            }
            if diff == 0 { return "All Square" }
            if diff > 0, diff == remaining { return "\(a) Dormie" }
            if diff < 0, abs(diff) == remaining { return "\(b) Dormie" }
            return diff > 0 ? "\(a) \(diff) UP vs \(b)" : "\(b) \(abs(diff)) UP vs \(a)"
        }
        func isDecided(_ m: MatchScoreLine) -> Bool {
            m.remaining == 0 || abs(m.diff) > m.remaining
        }
        let suffix = isDecided(m1) && isDecided(m2) ? "Final" : "thru \(m1.played)"
        return "\(segment(m1)) · \(segment(m2)) · \(suffix)"
    }
}
