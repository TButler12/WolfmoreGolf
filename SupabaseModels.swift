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

    init(matchId: String, playerSlot: Int, hole: Int, grossScore: Int,
         playerName: String? = nil, holeHc: Int? = nil, playerHc: Int? = nil) {
        self.matchId    = matchId
        self.playerSlot = playerSlot
        self.hole       = hole
        self.grossScore = grossScore
        self.playerName = playerName
        self.holeHc     = holeHc
        self.playerHc   = playerHc
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
    let createdAt: String?
    // jsonb arrays — nullable in DB
    let scores: [Int]?
    let moneyDeltas: [Double]?
    let payouts: [Double]?
    // Booleans — stored inconsistently across rows (native Bool or "true"/"false" string)
    let teamWon: Bool?
    let wentAlone: Bool?
    let wolfPlayer: Int?
    let alone: Bool?
    // Integer fields
    let wolfSlot: Int?
    let partnerSlot: Int?
    let hammerMultiplier: Int?
    let hammerHolder: Int?
    // String fields
    let wolfName: String?
    let decision: String?
    let partnerName: String?
    let proxWinner: String?
    enum CodingKeys: String, CodingKey {
        case id, hole, scores, decision, payouts, alone
        case sessionId        = "session_id"
        case createdAt        = "created_at"
        case moneyDeltas      = "money_deltas"
        case teamWon          = "team_won"
        case wentAlone        = "went_alone"
        case wolfPlayer       = "wolf_player"
        case wolfSlot         = "wolf_slot"
        case wolfName         = "wolf_name"
        case partnerName      = "partner_name"
        case partnerSlot      = "partner_slot"
        case hammerMultiplier = "hammer_multiplier"
        case hammerHolder     = "hammer_holder"
        case proxWinner       = "prox_winner"
    }

    // Try Bool first; fall back to string comparison for inconsistently stored rows.
    private static func flexBool(
        _ c: KeyedDecodingContainer<CodingKeys>,
        _ key: CodingKeys
    ) -> Bool? {
        if let b = try? c.decodeIfPresent(Bool.self,   forKey: key) { return b }
        if let s = try? c.decodeIfPresent(String.self, forKey: key) { return s.lowercased() == "true" }
        if let i = try? c.decodeIfPresent(Int.self,    forKey: key) { return i != 0 }
        return nil
    }

    init(from decoder: Decoder) throws {
        let c        = try decoder.container(keyedBy: CodingKeys.self)
        id           = try c.decode(String.self, forKey: .id)
        sessionId    = try c.decode(String.self, forKey: .sessionId)
        hole         = try c.decode(Int.self,    forKey: .hole)
        createdAt    = try c.decodeIfPresent(String.self,   forKey: .createdAt)
        scores       = try c.decodeIfPresent([Int].self,    forKey: .scores)
        moneyDeltas  = try c.decodeIfPresent([Double].self, forKey: .moneyDeltas)
        payouts      = try c.decodeIfPresent([Double].self, forKey: .payouts)
        wolfSlot     = try c.decodeIfPresent(Int.self, forKey: .wolfSlot)
        partnerSlot  = try c.decodeIfPresent(Int.self, forKey: .partnerSlot)
        hammerMultiplier = try c.decodeIfPresent(Int.self, forKey: .hammerMultiplier)
        hammerHolder = try c.decodeIfPresent(Int.self, forKey: .hammerHolder)
        wolfName     = try c.decodeIfPresent(String.self, forKey: .wolfName)
        decision     = try c.decodeIfPresent(String.self, forKey: .decision)
        partnerName  = try c.decodeIfPresent(String.self, forKey: .partnerName)
        proxWinner   = try c.decodeIfPresent(String.self, forKey: .proxWinner)
        teamWon    = Self.flexBool(c, .teamWon)
        wentAlone  = Self.flexBool(c, .wentAlone)
        wolfPlayer = try? c.decodeIfPresent(Int.self, forKey: .wolfPlayer)
        alone      = Self.flexBool(c, .alone)
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

// Tee Game tournament record (tournaments table)
struct TournamentRecord: Codable {
    let id: String
    let code: String
    let name: String
    let gameType: String    // "wolf", "skins", or "stableford"
    let scoring: String     // "gross" or "net"
    let stake: Double?
    let wolfStake: Double?
    let potAmount: Double?  // skins pot mode: total prize pool divided by skins won
    let carryTies: Bool?
    let createdBy: String
    let createdAt: String?
    let courseName: String?
    let currentDay: Int?
    let coOrganizerCode: String?
    let coOrganizerDevices: [String]?

    enum CodingKeys: String, CodingKey {
        case id, code, name, stake, scoring
        case wolfStake         = "wolf_stake"
        case potAmount         = "pot_amount"
        case gameType          = "game_type"
        case carryTies         = "carry_ties"
        case createdBy         = "created_by"
        case createdAt         = "created_at"
        case courseName        = "course_name"
        case currentDay        = "current_day"
        case coOrganizerCode    = "co_organizer_code"
        case coOrganizerDevices = "co_organizer_devices"
    }
}

// Per-hole scores read from hole_scores for tournament leaderboard.
// Columns written as strings by submitTournamentHoleScore; custom decoder handles both.
struct TournamentHoleScoreRow: Codable {
    let matchId: String
    let playerName: String
    let hole: Int
    let grossScore: Int
    let netScore: Int?
    let holeMoney: Double?
    let totalMoney: Double?
    let day: Int?
    let gameType: String?
    let skinsWon: Int?

    private enum CodingKeys: String, CodingKey {
        case matchId    = "match_id"
        case playerName = "player_name"
        case hole
        case grossScore = "gross_score"
        case netScore   = "net_score"
        case holeMoney  = "hole_money"
        case totalMoney = "total_money"
        case day
        case gameType   = "game_type"
        case skinsWon   = "skins_won"
    }

    init(from decoder: Decoder) throws {
        let c       = try decoder.container(keyedBy: CodingKeys.self)
        matchId     = try c.decode(String.self, forKey: .matchId)
        playerName  = try c.decode(String.self, forKey: .playerName)
        hole        = Self.intOrStr(c, key: .hole)
        grossScore  = Self.intOrStr(c, key: .grossScore)
        netScore    = Self.intOrStrOpt(c, key: .netScore)
        holeMoney   = try? c.decodeIfPresent(Double.self, forKey: .holeMoney)
        totalMoney  = try? c.decodeIfPresent(Double.self, forKey: .totalMoney)
        day         = Self.intOrStrOpt(c, key: .day) ?? 1
        gameType    = try? c.decodeIfPresent(String.self, forKey: .gameType)
        skinsWon    = Self.intOrStrOpt(c, key: .skinsWon)
    }

    private static func intOrStr(_ c: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> Int {
        if let v = try? c.decode(Int.self,    forKey: key) { return v }
        if let s = try? c.decode(String.self, forKey: key), let i = Int(s) { return i }
        return 0
    }
    private static func intOrStrOpt(_ c: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> Int? {
        if let v = try? c.decode(Int.self,    forKey: key) { return v }
        if let s = try? c.decode(String.self, forKey: key) { return Int(s) }
        return nil
    }
}

// Shared tournament roster — one row per player, keyed by tournament_code.
// Table: tournament_roster — upsert key: id
struct TournamentRosterEntry: Codable, Identifiable {
    let id: UUID
    let tournamentCode: String
    let canonicalName: String
    let handicap: Int
    let addedBy: String   // "organizer" | "scorer"
    let groupCode: String?  // non-nil when claimed by a scorer group

    enum CodingKeys: String, CodingKey {
        case id
        case tournamentCode = "tournament_code"
        case canonicalName  = "canonical_name"
        case handicap
        case addedBy        = "added_by"
        case groupCode      = "group_code"
    }
}

// Player money offsets per day (manual adjustments by organizer).
// Table: player_offsets — upsert key: (tournament_code, day, player_name)
struct PlayerOffsetRow: Codable {
    let playerName:    String
    let offsetAmount:  Double

    enum CodingKeys: String, CodingKey {
        case playerName   = "player_name"
        case offsetAmount = "offset_amount"
    }
}

// Per-hole scores for Remote Nassau batch comparison.
// Table: remote_nassau_hole_scores — upsert key: (match_id, side, hole)
struct RemoteNassauHoleScore: Codable {
    let matchId:    String
    let side:       String   // "A" = host/creator, "B" = joiner/opponent
    let hole:       Int      // 1-based hole number
    let grossScore: Int
    let handicap:   Int      // hole HC difficulty rank (1 = hardest)
    let playerHc:   Int?     // player course handicap
    let playerName: String?

    enum CodingKeys: String, CodingKey {
        case side, hole, handicap
        case matchId    = "match_id"
        case grossScore = "gross_score"
        case playerHc   = "player_hc"
        case playerName = "player_name"
    }

    /// Convert to the common HoleScoreRecord used by LiveNassauViewController's display pipeline.
    /// side "A" → playerSlot 0, side "B" → playerSlot 1; hole is converted to 0-based.
    func toHoleScoreRecord() -> HoleScoreRecord {
        HoleScoreRecord(
            matchId:    matchId,
            playerSlot: side == "A" ? 0 : 1,
            hole:       hole - 1,
            grossScore: grossScore,
            playerName: playerName,
            holeHc:     handicap,
            playerHc:   playerHc
        )
    }
}
