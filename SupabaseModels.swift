// SupabaseModels.swift
import Foundation

struct MatchRecord: Codable {
    let id: String
    let code: String
    let courseA: String?
    let courseB: String?
    let stake: Double?
    let games: String?
    let status: String

    enum CodingKeys: String, CodingKey {
        case id, code, stake, games, status
        case courseA = "course_a"
        case courseB = "course_b"
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
