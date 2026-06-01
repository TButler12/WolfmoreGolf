// SupabaseModels.swift
import Foundation

struct MatchRecord: Codable {
    let id: String
    let code: String
    let courseA: String?
    let courseB: String?
    let stake: Double?
    let games: [String]?
    let status: String
    let pressMode: String?
    let trigger: Int?
    let playerIncluded: [Bool]?
    let hostName: String?
    let opponentName: String?       // legacy single-opponent field (kept for backward compat)
    let opponentNames: [String]?    // hub-and-spoke: all joiners in order
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, code, stake, games, status, trigger
        case courseA        = "course_a"
        case courseB        = "course_b"
        case pressMode      = "press_mode"
        case playerIncluded = "player_included"
        case hostName       = "host_name"
        case opponentName   = "opponent_name"
        case opponentNames  = "opponent_names"
        case createdAt      = "created_at"
    }
}

struct HoleScoreRecord: Codable {
    let matchId: String
    let playerSlot: Int
    let hole: Int
    let grossScore: Int
    let playerName: String?
    let holeHc: Int?        // HC difficulty rank (1=hardest); nil on legacy rows
    let playerHc: Int?      // submitting player's course handicap; nil on legacy rows

    private enum CodingKeys: String, CodingKey {
        case matchId    = "match_id"
        case playerSlot = "player_slot"
        case hole
        case grossScore = "gross_score"
        case playerName = "player_name"
        case holeHc     = "hole_hc"
        case playerHc   = "player_hc"
    }

    // hole_scores inserts numerics as strings; handle both text and int DB columns
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        matchId     = try c.decode(String.self, forKey: .matchId)
        playerSlot  = Self.decodeIntOrString(c, key: .playerSlot)
        hole        = Self.decodeIntOrString(c, key: .hole)
        grossScore  = Self.decodeIntOrString(c, key: .grossScore)
        playerName  = try? c.decode(String.self, forKey: .playerName)
        holeHc      = Self.decodeIntOrStringOptional(c, key: .holeHc)
        playerHc    = Self.decodeIntOrStringOptional(c, key: .playerHc)
    }

    private static func decodeIntOrString(
        _ c: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) -> Int {
        if let v = try? c.decode(Int.self,    forKey: key) { return v }
        if let s = try? c.decode(String.self, forKey: key) { return Int(s) ?? 0 }
        return 0
    }

    private static func decodeIntOrStringOptional(
        _ c: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) -> Int? {
        if let v = try? c.decode(Int.self,    forKey: key) { return v }
        if let s = try? c.decode(String.self, forKey: key) { return Int(s) }
        return nil
    }
}

struct WolfSession: Codable {
    let id: String
    let code: String
    let hostName: String
    let playerNames: [String]
    let courseName: String
    let status: String
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, code, status
        case hostName    = "host_name"
        case playerNames = "player_names"
        case courseName  = "course_name"
        case createdAt   = "created_at"
    }
}

struct WolfHoleResult: Codable {
    let id: String
    let sessionId: String
    let hole: Int
    let scores: [Int]
    let wolfPlayer: Int?
    let wentAlone: Bool
    let teamWon: Bool
    let payouts: [Double]

    enum CodingKeys: String, CodingKey {
        case id, hole, scores, payouts
        case sessionId  = "session_id"
        case wolfPlayer = "wolf_player"
        case wentAlone  = "went_alone"
        case teamWon    = "team_won"
    }
}

struct HoleResultRecord: Codable {
    let id: String
    let matchId: String
    let hole: Int
    let winnerSlot: Int?
    let pointsExchanged: Double
    let revealedAt: String

    enum CodingKeys: String, CodingKey {
        case id, hole
        case matchId        = "match_id"
        case winnerSlot     = "winner_slot"
        case pointsExchanged = "points_exchanged"
        case revealedAt     = "revealed_at"
    }
}
