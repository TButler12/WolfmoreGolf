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

    /// Merges a live matchStatus string with a holes label ("thru N" or "Final"),
    /// suppressing duplication when the status already embeds the same information.
    /// Used by the Match Board to compose the cell's secondary text.
    static func boardSecondary(status: String, holes: String) -> String {
        guard !holes.isEmpty else { return status }
        if holes == "Final" {
            return status.contains("Final") ? status : "\(status)  ·  Final"
        }
        // "thru N" — skip if already present in status
        return status.contains(holes) ? status : "\(status)  ·  \(holes)"
    }

    // MARK: - Team Stroke Play

    struct TeamStrokeResult {
        let aDiff: Int      // aTotal − bTotal (negative = A leads, positive = B leads)
        let played: Int
        let total: Int
        let aLabel: String
        let bLabel: String
    }

    /// Status string for Team Stroke Play (best-net-to-par totals), e.g.
    /// "McTommy/Lester won by 20 · Final" or "Rex/Mike leads by 3 · thru 9".
    static func teamStrokeStatus(_ t: TeamStrokeResult) -> String {
        let remaining = t.total - t.played
        if remaining == 0 {
            if t.aDiff == 0 { return "Tied · Final" }
            let margin = abs(t.aDiff)
            return t.aDiff < 0 ? "\(t.aLabel) won by \(margin) · Final" : "\(t.bLabel) won by \(margin) · Final"
        }
        if t.aDiff == 0 { return "Even · thru \(t.played)" }
        return t.aDiff < 0
            ? "\(t.aLabel) leads by \(abs(t.aDiff)) · thru \(t.played)"
            : "\(t.bLabel) leads by \(abs(t.aDiff)) · thru \(t.played)"
    }

    // MARK: - Dual Match

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
