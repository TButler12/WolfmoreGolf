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
    let opponentName: String?

    enum CodingKeys: String, CodingKey {
        case id, code, stake, games, status, trigger
        case courseA        = "course_a"
        case courseB        = "course_b"
        case pressMode      = "press_mode"
        case playerIncluded = "player_included"
        case hostName       = "host_name"
        case opponentName   = "opponent_name"
    }
}

struct HoleScoreRecord: Codable {
    let matchId: String
    let playerSlot: Int
    let hole: Int
    let grossScore: Int
    let playerName: String?

    private enum CodingKeys: String, CodingKey {
        case matchId    = "match_id"
        case playerSlot = "player_slot"
        case hole
        case grossScore = "gross_score"
        case playerName = "player_name"
    }

    // hole_scores inserts these as strings; handle both text and int DB columns
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        matchId     = try c.decode(String.self, forKey: .matchId)
        playerSlot  = Self.decodeIntOrString(c, key: .playerSlot)
        hole        = Self.decodeIntOrString(c, key: .hole)
        grossScore  = Self.decodeIntOrString(c, key: .grossScore)
        playerName  = try? c.decode(String.self, forKey: .playerName)
    }

    private static func decodeIntOrString(
        _ c: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) -> Int {
        if let v = try? c.decode(Int.self,    forKey: key) { return v }
        if let s = try? c.decode(String.self, forKey: key) { return Int(s) ?? 0 }
        return 0
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
