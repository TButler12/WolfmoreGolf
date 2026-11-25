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
    let pairing: [[Int]]?           // stored hole-pair indices [[courseA_idx, courseB_idx] × 18]

    enum CodingKeys: String, CodingKey {
        case id, code, stake, games, status, trigger, pairing
        case courseA        = "course_a"
        case courseB        = "course_b"
        case pressMode      = "press_mode"
        case playerIncluded = "player_included"
        case hostName       = "host_name"
        case opponentName   = "opponent_name"
        case opponentNames  = "opponent_names"
        case createdAt      = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c          = try decoder.container(keyedBy: CodingKeys.self)
        id             = try  c.decode(String.self,    forKey: .id)
        code           = try  c.decode(String.self,    forKey: .code)
        status         = try  c.decode(String.self,    forKey: .status)
        courseA        = try? c.decode(String.self,    forKey: .courseA)
        courseB        = try? c.decode(String.self,    forKey: .courseB)
        stake          = try? c.decode(Double.self,    forKey: .stake)
        games          = try? c.decode([String].self,  forKey: .games)
        pressMode      = try? c.decode(String.self,    forKey: .pressMode)
        trigger        = try? c.decode(Int.self,       forKey: .trigger)
        playerIncluded = try? c.decode([Bool].self,    forKey: .playerIncluded)
        hostName       = try? c.decode(String.self,    forKey: .hostName)
        opponentName   = try? c.decode(String.self,    forKey: .opponentName)
        opponentNames  = try? c.decode([String].self,  forKey: .opponentNames)
        createdAt      = try? c.decode(String.self,    forKey: .createdAt)
        pairing        = try? c.decode([[Int]].self,   forKey: .pairing)
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
    let playerHandicaps: [Int]?
    let nineHoleMatch: Bool?
    let nineHoleStartingHole: Int?
    let groupName: String?
    let matchStatus: String?
    let holesPlayed: Int?
    let eventCode: String?

    enum CodingKeys: String, CodingKey {
        case id, code, status
        case hostName             = "host_name"
        case playerNames          = "player_names"
        case courseName           = "course_name"
        case createdAt            = "created_at"
        case playerHandicaps      = "player_handicaps"
        case nineHoleMatch        = "nine_hole_match"
        case nineHoleStartingHole = "nine_hole_starting_hole"
        case groupName            = "group_name"
        case matchStatus          = "match_status"
        case holesPlayed          = "holes_played"
        case eventCode            = "event_code"
    }
}

struct LiveEvent: Codable {
    let id: String
    let code: String
    let name: String
    let status: String
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, code, name, status
        case createdAt = "created_at"
    }
}

struct LiveEventCreateResult: Codable {
    let eventId: String
    let eventCode: String
    let organizerToken: String

    enum CodingKeys: String, CodingKey {
        case eventId        = "r_event_id"
        case eventCode      = "r_event_code"
        case organizerToken = "r_organizer_token"
    }
}

struct WolfSessionCreateResult: Codable {
    let sessionId: String
    let creatorToken: String

    enum CodingKeys: String, CodingKey {
        case sessionId    = "session_id"
        case creatorToken = "creator_token"
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
    // Live-summary fields
    let skinWinner: String?
    let skinValue: Double?
    let nassauStatus: String?
    let skinCount: Int?
    let skinTiedSeats: String?
    let wolfVariant: String?
    // Explicit match-play seat assignments: "m1a,m1b[,m2a,m2b]" — nil on pre-v2 rows
    let mpSeats: String?
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
        case skinWinner       = "skin_winner"
        case skinValue        = "skin_value"
        case nassauStatus     = "nassau_status"
        case skinCount        = "skin_count"
        case skinTiedSeats    = "skin_tied_seats"
        case wolfVariant      = "wolf_variant"
        case mpSeats          = "mp_seats"
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
        partnerName  = try c.decodeIfPresent(String.self,   forKey: .partnerName)
        proxWinner   = try c.decodeIfPresent(String.self,   forKey: .proxWinner)
        skinWinner   = try c.decodeIfPresent(String.self,   forKey: .skinWinner)
        skinValue    = try c.decodeIfPresent(Double.self,   forKey: .skinValue)
        nassauStatus = try c.decodeIfPresent(String.self,   forKey: .nassauStatus)
        skinCount    = try c.decodeIfPresent(Int.self,      forKey: .skinCount)
        skinTiedSeats = try c.decodeIfPresent(String.self,  forKey: .skinTiedSeats)
        wolfVariant   = try c.decodeIfPresent(String.self,  forKey: .wolfVariant)
        mpSeats       = try c.decodeIfPresent(String.self,  forKey: .mpSeats)
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
    let finishedAt: String?          // set by end_tournament RPC; nil = still active
    let coOrganizerCode: String?
    let coOrganizerDevices: [String]?
    // Stableford-specific organizer rules
    let stablefordBaseline: String?    // "par" (default) or "bogey"
    let stablefordTeamCount: Int?      // 2, 3, or 4 — best-N scores count per hole
    // When true, Stableford rows are submitted alongside the primary money format (hybrid mode).
    let stablefordEnabled: Bool?
    let stablefordMode: String?          // "standard" or "modified" (nil = standard)
    let modifiedSfDoubleEagle: Int?
    let modifiedSfDoubleBogey: Int?
    let modifiedSfBogey:       Int?
    let modifiedSfPar:         Int?
    let modifiedSfBirdie:      Int?
    let modifiedSfEagle:       Int?
    // Wolf-specific organizer settings
    let wolfVariant: String?    // "6pt" | "2pt" | "lowball"
    let pressStyle: String?     // "doubling" | "additive"
    let hammerStyle: String?    // "doubling" | "additive"
    // Team Tee Game settings (nil when not configured for this tournament)
    let teamTeeEnabled:    Bool?
    let teamTeeCountMode:  String?  // "fixed" | "byPar"
    let teamTeeFixedCount: Int?
    let teamTeePar3Count:  Int?
    let teamTeePar4Count:  Int?
    let teamTeePar5Count:  Int?

    enum CodingKeys: String, CodingKey {
        case id, code, name, stake, scoring
        case wolfStake          = "wolf_stake"
        case potAmount          = "pot_amount"
        case gameType           = "game_type"
        case carryTies          = "carry_ties"
        case createdBy          = "created_by"
        case createdAt          = "created_at"
        case courseName         = "course_name"
        case currentDay         = "current_day"
        case finishedAt         = "finished_at"
        case coOrganizerCode    = "co_organizer_code"
        case coOrganizerDevices = "co_organizer_devices"
        case stablefordBaseline  = "stableford_baseline"
        case stablefordTeamCount = "stableford_team_count"
        case stablefordEnabled   = "stableford_enabled"
        case stablefordMode        = "stableford_mode"
        case modifiedSfDoubleEagle = "modified_sf_double_eagle"
        case modifiedSfDoubleBogey = "modified_sf_double_bogey"
        case modifiedSfBogey       = "modified_sf_bogey"
        case modifiedSfPar         = "modified_sf_par"
        case modifiedSfBirdie      = "modified_sf_birdie"
        case modifiedSfEagle       = "modified_sf_eagle"
        case wolfVariant         = "wolf_variant"
        case pressStyle          = "press_style"
        case hammerStyle         = "hammer_style"
        case teamTeeEnabled      = "team_tee_enabled"
        case teamTeeCountMode    = "team_tee_count_mode"
        case teamTeeFixedCount   = "team_tee_fixed_count"
        case teamTeePar3Count    = "team_tee_par3_count"
        case teamTeePar4Count    = "team_tee_par4_count"
        case teamTeePar5Count    = "team_tee_par5_count"
    }

    var teamTeeSettings: TeamTeeSettings? {
        guard teamTeeEnabled == true else { return nil }
        var s = TeamTeeSettings()
        s.isEnabled  = true
        s.countMode  = teamTeeCountMode == "fixed" ? .fixed : .byPar
        s.fixedCount = teamTeeFixedCount ?? 2
        s.par3Count  = teamTeePar3Count  ?? 4
        s.par4Count  = teamTeePar4Count  ?? 3
        s.par5Count  = teamTeePar5Count  ?? 2
        return s
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

// MARK: - Club Events (tournament_events / tournament_players)

struct ClubEventRecord: Codable {
    let id: UUID
    let code: String
    let name: String
    let organizerDeviceId: String
    let courseName: String?
    let teeSet: String?
    let numDays: Int
    let status: String
    let coursePars: [Int]?
    let courseHandicaps: [Int]?
    let courseSource: String

    init(id: UUID, code: String, name: String, organizerDeviceId: String,
         courseName: String? = nil, teeSet: String? = nil, numDays: Int, status: String,
         coursePars: [Int]? = nil, courseHandicaps: [Int]? = nil, courseSource: String = "builtin") {
        self.id = id; self.code = code; self.name = name
        self.organizerDeviceId = organizerDeviceId
        self.courseName = courseName; self.teeSet = teeSet
        self.numDays = numDays; self.status = status
        self.coursePars = coursePars; self.courseHandicaps = courseHandicaps
        self.courseSource = courseSource
    }

    enum CodingKeys: String, CodingKey {
        case id, code, name, status
        case organizerDeviceId = "organizer_device_id"
        case courseName        = "course_name"
        case teeSet            = "tee_set"
        case numDays           = "num_days"
        case coursePars        = "course_pars"
        case courseHandicaps   = "course_handicaps"
        case courseSource      = "course_source"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                = try  c.decode(UUID.self,    forKey: .id)
        code              = try  c.decode(String.self,  forKey: .code)
        name              = try  c.decode(String.self,  forKey: .name)
        organizerDeviceId = try  c.decode(String.self,  forKey: .organizerDeviceId)
        courseName        = try? c.decode(String.self,  forKey: .courseName)
        teeSet            = try? c.decode(String.self,  forKey: .teeSet)
        numDays           = try  c.decode(Int.self,     forKey: .numDays)
        status            = try  c.decode(String.self,  forKey: .status)
        coursePars        = try? c.decode([Int].self,   forKey: .coursePars)
        courseHandicaps   = try? c.decode([Int].self,   forKey: .courseHandicaps)
        courseSource      = (try? c.decode(String.self, forKey: .courseSource)) ?? "builtin"
    }
}

struct ClubEventPlayer: Codable, Identifiable {
    let id: UUID
    let tournamentId: UUID
    let playerName: String
    let handicap: Double
    var groupCode: String?
    var cardSubmitted: Bool
    var status: String   // 'active' | 'withdrawn'

    var isWithdrawn: Bool { status == "withdrawn" }

    var displayHandicap: String {
        let n = Int(handicap.rounded())
        if n == 0  { return "Scratch" }
        if n < 0   { return "+\(-n)" }
        return "HC \(n)"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case tournamentId  = "tournament_id"
        case playerName    = "player_name"
        case handicap
        case groupCode     = "group_code"
        case cardSubmitted = "card_submitted"
        case status
    }

    init(id: UUID, tournamentId: UUID, playerName: String, handicap: Double,
         groupCode: String? = nil, cardSubmitted: Bool = false, status: String = "active") {
        self.id = id
        self.tournamentId = tournamentId
        self.playerName = playerName
        self.handicap = handicap
        self.groupCode = groupCode
        self.cardSubmitted = cardSubmitted
        self.status = status
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id             = try c.decode(UUID.self,    forKey: .id)
        tournamentId   = try c.decode(UUID.self,    forKey: .tournamentId)
        playerName     = try c.decode(String.self,  forKey: .playerName)
        handicap       = try c.decode(Double.self,  forKey: .handicap)
        groupCode      = try? c.decode(String.self, forKey: .groupCode)
        cardSubmitted  = (try? c.decode(Bool.self,  forKey: .cardSubmitted)) ?? false
        status         = (try? c.decode(String.self, forKey: .status)) ?? "active"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,            forKey: .id)
        try c.encode(tournamentId,  forKey: .tournamentId)
        try c.encode(playerName,    forKey: .playerName)
        try c.encode(handicap,      forKey: .handicap)
        try c.encodeIfPresent(groupCode, forKey: .groupCode)
        try c.encode(cardSubmitted, forKey: .cardSubmitted)
        try c.encode(status,        forKey: .status)
    }
}

struct ClubEventRules: Decodable {
    let handicapAllowance:    Double
    let grossLeaderboard:     Bool
    let grossSkinsEnabled:    Bool
    let netSkinsEnabled:      Bool
    let skinsCarryover:       Bool
    let teamNetPerPlayer:     Double
    let teamGrossPerPlayer:   Double
    let grossSkinsPerPlayer:  Double
    let netSkinsPerPlayer:    Double
    let teamPlacesPaid:       Int
    let placePcts:            [Double]
    let allowDualTeam:        Bool
    // Added in migration 20261128 — decoded with defaults for backward compat
    let payoutMode:           String    // 'per_player' | 'fixed_total'
    let teamNetTotal:         Double
    let teamGrossTotal:       Double
    let grossSkinsTotal:      Double
    let netSkinsTotal:        Double

    enum CodingKeys: String, CodingKey {
        case handicapAllowance   = "handicap_allowance"
        case grossLeaderboard    = "gross_leaderboard"
        case grossSkinsEnabled   = "gross_skins_enabled"
        case netSkinsEnabled     = "net_skins_enabled"
        case skinsCarryover      = "skins_carryover"
        case teamNetPerPlayer    = "team_net_per_player"
        case teamGrossPerPlayer  = "team_gross_per_player"
        case grossSkinsPerPlayer = "gross_skins_per_player"
        case netSkinsPerPlayer   = "net_skins_per_player"
        case teamPlacesPaid      = "team_places_paid"
        case placePcts           = "place_pcts"
        case allowDualTeam       = "allow_dual_team"
        case payoutMode          = "payout_mode"
        case teamNetTotal        = "team_net_total"
        case teamGrossTotal      = "team_gross_total"
        case grossSkinsTotal     = "gross_skins_total"
        case netSkinsTotal       = "net_skins_total"
    }

    init(handicapAllowance: Double, grossLeaderboard: Bool,
         grossSkinsEnabled: Bool, netSkinsEnabled: Bool,
         skinsCarryover: Bool,
         teamNetPerPlayer: Double, teamGrossPerPlayer: Double,
         grossSkinsPerPlayer: Double, netSkinsPerPlayer: Double,
         teamPlacesPaid: Int, placePcts: [Double], allowDualTeam: Bool,
         payoutMode: String = "per_player",
         teamNetTotal: Double = 0, teamGrossTotal: Double = 0,
         grossSkinsTotal: Double = 0, netSkinsTotal: Double = 0) {
        self.handicapAllowance   = handicapAllowance
        self.grossLeaderboard    = grossLeaderboard
        self.grossSkinsEnabled   = grossSkinsEnabled
        self.netSkinsEnabled     = netSkinsEnabled
        self.skinsCarryover      = skinsCarryover
        self.teamNetPerPlayer    = teamNetPerPlayer
        self.teamGrossPerPlayer  = teamGrossPerPlayer
        self.grossSkinsPerPlayer = grossSkinsPerPlayer
        self.netSkinsPerPlayer   = netSkinsPerPlayer
        self.teamPlacesPaid      = teamPlacesPaid
        self.placePcts           = placePcts
        self.allowDualTeam       = allowDualTeam
        self.payoutMode          = payoutMode
        self.teamNetTotal        = teamNetTotal
        self.teamGrossTotal      = teamGrossTotal
        self.grossSkinsTotal     = grossSkinsTotal
        self.netSkinsTotal       = netSkinsTotal
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        handicapAllowance    = (try? c.decode(Double.self,   forKey: .handicapAllowance))  ?? 1.0
        grossLeaderboard     = (try? c.decode(Bool.self,     forKey: .grossLeaderboard))   ?? false
        grossSkinsEnabled    = (try? c.decode(Bool.self,     forKey: .grossSkinsEnabled))  ?? true
        netSkinsEnabled      = (try? c.decode(Bool.self,     forKey: .netSkinsEnabled))    ?? true
        skinsCarryover       = (try? c.decode(Bool.self,     forKey: .skinsCarryover))     ?? false
        teamNetPerPlayer     = (try? c.decode(Double.self,   forKey: .teamNetPerPlayer))   ?? 0
        teamGrossPerPlayer   = (try? c.decode(Double.self,   forKey: .teamGrossPerPlayer)) ?? 0
        grossSkinsPerPlayer  = (try? c.decode(Double.self,   forKey: .grossSkinsPerPlayer)) ?? 0
        netSkinsPerPlayer    = (try? c.decode(Double.self,   forKey: .netSkinsPerPlayer))   ?? 0
        teamPlacesPaid       = (try? c.decode(Int.self,      forKey: .teamPlacesPaid))     ?? 3
        placePcts            = (try? c.decode([Double].self, forKey: .placePcts))          ?? [50, 30, 20]
        allowDualTeam        = (try? c.decode(Bool.self,     forKey: .allowDualTeam))      ?? false
        payoutMode           = (try? c.decode(String.self,   forKey: .payoutMode))         ?? "per_player"
        teamNetTotal         = (try? c.decode(Double.self,   forKey: .teamNetTotal))       ?? 0
        teamGrossTotal       = (try? c.decode(Double.self,   forKey: .teamGrossTotal))     ?? 0
        grossSkinsTotal      = (try? c.decode(Double.self,   forKey: .grossSkinsTotal))    ?? 0
        netSkinsTotal        = (try? c.decode(Double.self,   forKey: .netSkinsTotal))      ?? 0
    }
}

struct ClubEventSetupResult: Decodable {
    let claimed: [UUID]
}

struct ClubEventGroupPlayer: Equatable {
    let id:          UUID
    let name:        String
    let handicap:    Double
    let teams:       [String]   // ["A"] | ["B"] | ["A","B"]
    var isWithdrawn: Bool = false
}

struct ClubEventHoleScore: Decodable {
    let tournamentPlayerId: UUID
    let day:                Int
    let holeNumber:         Int
    let grossScore:         Int?
    let netScoreType:       String?

    enum CodingKeys: String, CodingKey {
        case day
        case tournamentPlayerId = "tournament_player_id"
        case holeNumber         = "hole_number"
        case grossScore         = "gross_score"
        case netScoreType       = "net_score_type"
    }
}

struct ClubEventTeam: Decodable {
    let id:           UUID
    let teamName:     String
    let tournamentId: UUID

    enum CodingKeys: String, CodingKey {
        case id
        case teamName     = "team_name"
        case tournamentId = "tournament_id"
    }
}

struct ClubEventTeamMembership: Decodable {
    let teamId:            UUID
    let tournamentPlayerId: UUID

    init(teamId: UUID, tournamentPlayerId: UUID) {
        self.teamId             = teamId
        self.tournamentPlayerId = tournamentPlayerId
    }

    enum CodingKeys: String, CodingKey {
        case teamId            = "team_id"
        case tournamentPlayerId = "tournament_player_id"
    }
}

struct ClubEventChangeLogEntry: Decodable, Identifiable {
    let id:          UUID
    let changedAt:   Date
    let changedBy:   String?
    let changeType:  String   // 'replace_player' | 'withdraw_player' | 'remove_player' | 'update_settings' | 'update_handicap'
    let details:     [String: AnyCodable]

    enum CodingKeys: String, CodingKey {
        case id
        case changedAt  = "changed_at"
        case changedBy  = "changed_by"
        case changeType = "change_type"
        case details
    }

    var summary: String {
        switch changeType {
        case "replace_player":
            let old = details["old_player_name"]?.stringValue ?? "?"
            let new = details["new_player_name"]?.stringValue ?? "?"
            return "Replaced \(old) → \(new)"
        case "withdraw_player":
            let name = details["player_name"]?.stringValue ?? "?"
            let holes = details["holes_played"]?.intValue ?? 0
            return "Withdrew \(name) (\(holes) holes played)"
        case "remove_player":
            let name = details["player_name"]?.stringValue ?? "?"
            let n    = details["scores_deleted"]?.intValue ?? 0
            return "Removed \(name), \(n) score\(n == 1 ? "" : "s") deleted"
        case "update_settings":
            return "Settings updated"
        case "update_handicap":
            let name  = details["player_name"]?.stringValue ?? "?"
            let old   = details["old_handicap"]?.stringValue ?? "?"
            let new   = details["new_handicap"]?.stringValue ?? "?"
            return "Handicap \(name): \(old) → \(new)"
        default:
            return changeType
        }
    }
}

/// Minimal wrapper so JSONB details can be decoded without a fixed schema.
// MARK: - Shared skins input builder

/// Single source of truth for building FieldSkinsEngine inputs from club event data.
/// • Excludes unassigned players (empty groupCode) — their groupPosted is all-false
///   and would make every hole provisional even when all real groups have finished.
/// • Deduplicates by player UUID so a player who appears twice in the roster
///   (e.g. added under two workflows) only competes once.
func buildClubEventSkinInputs(
    players: [ClubEventPlayer],
    scoresByPlayer: [UUID: [Int: (gross: Int, pickedUp: Bool)]],
    postedByGroup: [String: Set<Int>],
    holeCount: Int
) -> [FieldSkinsEngine.PlayerInput] {
    var seen = Set<UUID>()
    return players
        .filter { !($0.groupCode ?? "").isEmpty }
        .filter { seen.insert($0.id).inserted }
        .map { player in
            var hs = [HoleScore](repeating: .notEntered, count: holeCount)
            var gp = [Bool](repeating: false, count: holeCount)
            let gc   = player.groupCode ?? ""
            let hc18 = Int(player.handicap.rounded())
            let courseHC = holeCount == 9 ? Int((Double(hc18) / 2.0).rounded()) : hc18
            for hole in 1...holeCount {
                let i = hole - 1
                if let d = scoresByPlayer[player.id]?[hole] {
                    hs[i] = d.pickedUp ? .pickedUp : d.gross > 0 ? .gross(d.gross) : .notEntered
                }
                gp[i] = !gc.isEmpty && (postedByGroup[gc]?.contains(hole) ?? false)
            }
            return FieldSkinsEngine.PlayerInput(
                playerID: player.id,
                courseHandicap: courseHC,
                scores: hs,
                groupPosted: gp)
        }
}

struct AnyCodable: Decodable {
    let value: Any

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let s = try? c.decode(String.self)  { value = s; return }
        if let i = try? c.decode(Int.self)     { value = i; return }
        if let d = try? c.decode(Double.self)  { value = d; return }
        if let b = try? c.decode(Bool.self)    { value = b; return }
        value = ""
    }

    var stringValue: String? { value as? String }
    var intValue:    Int?    { value as? Int }
}
