import Foundation

enum StablefordBaseline: String, Codable {
    case par, bogey
}

enum HammerStyle: String, Codable {
    case doubling  // traditional Wolf: ×2, ×4, ×8...
    case additive  // TGL style: stake grows linearly (+base each tap)
}

struct GameData: Codable {
    var holeStatsPromptMuted: Bool = false
    var scorePerHole: [[Int?]] = []
    var umbrellaMode: Bool = false
    var baseGameStake: Int = 2
    var holeCommitted: [Bool] = Array(repeating: false, count: STANDARD_HOLES)

    var nassauState: NassauState?
    var skinsState: SkinsState?

    // Stable UUID for history upsert — generated once per game session, nil on legacy saves
    var historyGameID: UUID? = nil

    // Supabase live match identifier (nil = local/text-based flow)
    var remoteMatchId: String? = nil
    // All remote match IDs created/joined during this game session
    var remoteMatchIds: [String] = []
    // "A" if this player created the match, "B" if they joined — determines remote_nassau_hole_scores side
    var remoteNassauSide: String? = nil
    // Wolf Live session ID and shareable code (nil = not broadcasting)
    var liveSessionId: String? = nil
    var liveSessionCode: String? = nil

    // Tee Game (tournament group) code and group code (nil = not in a tee game)
    var tournamentCode: String? = nil
    var groupCode: String? = nil
    // Stable UUID used as match_id for all tournament hole_score rows in this group session
    var tournamentMatchId: String? = nil
    // Display metadata cached from TournamentRecord at join/create time
    var tournamentName: String? = nil
    var tournamentGameType: String? = nil      // "wolf", "skins", "stableford"
    var tournamentScoringType: String? = nil   // "gross", "net"
    var tournamentDay: Int = 1
    var tournamentIsOrganizer: Bool = false
    var tournamentIsCreator: Bool   = false
    // Tournament pot — separate from skinsState.settings.potAmount (which is the LOCAL pot).
    // Written at join/rejoin time; read by the tournament batch calc in GameViewController.
    var tournamentPotAmount: Double? = nil
    var tournamentCarryTies: Bool?   = nil
    // Optional so old saves (missing these keys) decode safely; use computed wrappers below.
    var stablefordBaselineOpt: StablefordBaseline? = nil
    var stablefordCountingPlayersOpt: Int? = nil
    // When true, Stableford rows are co-submitted alongside the primary money format (hybrid).
    var tournamentStablefordEnabled: Bool? = nil
    // Scramble: the team name this scorer is submitting for (nil = not in a scramble tournament).
    var scrambleTeamName: String? = nil

    // NEW (optional so old saves decode safely)
    var gameTypePerHole: [GameType] = Array(repeating: .sixPointScotch, count: STANDARD_HOLES)

    var gameType: GameType?
    var hammerCountPerHole: [Int]?
    var hammerStyle: HammerStyle = .additive
    var pressStyle: HammerStyle = .doubling
    var wolfStake: Double? = nil
    var wolfPlayerPerHole: [Int?]?
    var wolfWentAlonePerHole: [Bool]?

    // Convenience so your existing code can stay mostly unchanged
    var resolvedGameType: GameType { gameType ?? .sixPointScotch }

    // MARK: - Wolf stats per hole
    var umbieWonPerHole: [Bool] = Array(repeating: false, count: STANDARD_HOLES)
    var wolfCalledPerHole: [Bool] = Array(repeating: false, count: STANDARD_HOLES)
    var wolfTeamWonPerHole: [Bool] = Array(repeating: false, count: STANDARD_HOLES)

    // MARK: - Core game state
    var startHole: Int? = nil
    var course: Course = .default
    var gameName: String = "New Game"
    var popsTable: [[Int]] = []

    var pressedPushedToggleArray: [Bool] = Array(repeating: false, count: STANDARD_HOLES)
    var previousPressedPushedToggleArray: [Bool] = Array(repeating: false, count: STANDARD_HOLES)
    var gameHoleDollarsArray: [Double] = Array(repeating: 2.0, count: STANDARD_HOLES)

    // 5 players × 18 holes; nil = no score entered yet
    var scores: [[Int?]] = Array(
        repeating: Array(repeating: nil, count: STANDARD_HOLES),
        count: MAX_PLAYERS
    )

    // Per-player payout per hole
    var playerMoney: [[Double]] = Array(
        repeating: Array(repeating: 0, count: STANDARD_HOLES),
        count: MAX_PLAYERS
    )

    var rosterNames: [String] = []
    var proxWinnerPerHole: [Int?] = Array(repeating: nil, count: STANDARD_HOLES)

    var pressLevel: [Int] = Array(repeating: 0, count: STANDARD_HOLES)
    var pressInitiatedHole: Int? = nil
    var pressBaseDollars: [Double] = Array(repeating: 0.0, count: STANDARD_HOLES)
    var pressBaseAmount: [Double] = Array(repeating: 0.0, count: STANDARD_HOLES)

    var rollBaseAmount: [Double] = Array(repeating: 0.0, count: STANDARD_HOLES)
    var rollApplied: [Bool] = Array(repeating: false, count: STANDARD_HOLES)

    var rerollApplied: [Bool] = Array(repeating: false, count: STANDARD_HOLES)
    var rerollBaseAmount: [Double] = Array(repeating: 0.0, count: STANDARD_HOLES)

    var aloneApplied: [Bool] = Array(repeating: false, count: STANDARD_HOLES)
    var aloneBaseAmount: [Double] = Array(repeating: 0.0, count: STANDARD_HOLES)

    // Pure stake per hole before any hole-scoped multipliers (roll/reroll/alone/press).
    // Only written by explicit stake adjustments; never by multiplier toggles.
    var holeBaseAmount: [Double] = Array(repeating: 2.0, count: STANDARD_HOLES)

    var wolfButtonStatus: [[Bool]] = Array(
        repeating: Array(repeating: false, count: STANDARD_HOLES),
        count: 9
    )

    // Match Play fixed team assignments (optional so old saves decode safely)
    var matchPlayTeamA: [Int]? = nil
    var matchPlayTeamB: [Int]? = nil
    // Second simultaneous match (dual 1v1 within the foursome)
    var matchPlayTeamA2: [Int]? = nil
    var matchPlayTeamB2: [Int]? = nil
    // Match Play 36-hole round: plays the same 18-hole course twice back-to-back
    var matchPlay36Holes: Bool = false

    var totalHoles: Int { matchPlay36Holes ? 36 : STANDARD_HOLES }

    var isDualMatch: Bool {
        guard resolvedGameType.isMatchPlay,
              let a2 = matchPlayTeamA2, let b2 = matchPlayTeamB2 else { return false }
        return !a2.isEmpty && !b2.isEmpty
    }

    var playerNames: [String] = Array(repeating: "", count: MAX_PLAYERS)
    var hcPlayers: [Int] = Array(repeating: 0, count: MAX_PLAYERS)
    var playerActivated: [Bool] = Array(repeating: false, count: MAX_PLAYERS)
    // Index into course.teeSets; 0 = course default, 1+ = course.teeSets[index-1]
    var playerTeeSetIndex: [Int] = Array(repeating: 0, count: MAX_PLAYERS)

    var hole: Int = 0
    var tournamentStartHole: Int = 0  // 0 = front nine (hole 1), 9 = back nine (hole 10)

    var isUmbrella: Bool = false
    var isPressOn: Bool = false
    var isRollOn: Bool = false
    var isRerollOn: Bool = false
    var isAlone: Bool = false

    var fairwayHit: [[Bool?]] = Array(
        repeating: Array(repeating: nil, count: STANDARD_HOLES),
        count: MAX_PLAYERS
    )

    var girHit: [[Bool?]] = Array(
        repeating: Array(repeating: nil, count: STANDARD_HOLES),
        count: MAX_PLAYERS
    )

    var puttsPerHole: [[Int?]] = Array(
        repeating: Array(repeating: nil, count: STANDARD_HOLES),
        count: MAX_PLAYERS
    )

    // MARK: - Course passthrough
    var courseParToPass: [Int] {
        get { course.pars }
        set { course.pars = Array(newValue.prefix(STANDARD_HOLES)) }
    }

    var courseHCToPass: [Int] {
        get { course.holeHandicaps }
        set {
            let fixed = newValue.prefix(STANDARD_HOLES).map { v in
                let x = (v == 0 ? STANDARD_HOLES : v)
                return max(1, min(STANDARD_HOLES, x))
            }
            course.holeHandicaps = Array(fixed)
        }
    }

    /// Pads (or truncates) every per-hole array to match `totalHoles`.
    /// Call immediately after changing `matchPlay36Holes`.
    mutating func extendToTotalHoles() {
        let target = totalHoles
        func padHole<T>(_ arr: inout [T], fill: T) {
            if arr.count < target { arr += Array(repeating: fill, count: target - arr.count) }
            else if arr.count > target { arr = Array(arr.prefix(target)) }
        }
        let defaultStake = gameHoleDollarsArray.first ?? 2.0
        let defaultBase  = holeBaseAmount.first  ?? 2.0
        padHole(&holeCommitted,                  fill: false)
        padHole(&gameTypePerHole,                fill: GameType.sixPointScotch)
        padHole(&umbieWonPerHole,                fill: false)
        padHole(&wolfCalledPerHole,              fill: false)
        padHole(&wolfTeamWonPerHole,             fill: false)
        padHole(&pressedPushedToggleArray,       fill: false)
        padHole(&previousPressedPushedToggleArray, fill: false)
        padHole(&gameHoleDollarsArray,           fill: defaultStake)
        padHole(&proxWinnerPerHole,              fill: nil)
        padHole(&pressLevel,                     fill: 0)
        padHole(&pressBaseDollars,               fill: 0.0)
        padHole(&pressBaseAmount,                fill: 0.0)
        padHole(&rollBaseAmount,                 fill: 0.0)
        padHole(&rollApplied,                    fill: false)
        padHole(&rerollApplied,                  fill: false)
        padHole(&rerollBaseAmount,               fill: 0.0)
        padHole(&aloneApplied,                   fill: false)
        padHole(&aloneBaseAmount,                fill: 0.0)
        padHole(&holeBaseAmount,                 fill: defaultBase)
        for i in 0..<scores.count      { padHole(&scores[i],      fill: nil as Int?) }
        for i in 0..<playerMoney.count { padHole(&playerMoney[i], fill: 0.0) }
        for i in 0..<fairwayHit.count  { padHole(&fairwayHit[i],  fill: nil as Bool?) }
        for i in 0..<girHit.count      { padHole(&girHit[i],      fill: nil as Bool?) }
        for i in 0..<puttsPerHole.count { padHole(&puttsPerHole[i], fill: nil as Int?) }
        for i in 0..<wolfButtonStatus.count { padHole(&wolfButtonStatus[i], fill: false) }
    }

    mutating func normalize(holes: Int = STANDARD_HOLES) {
        if gameType == nil { gameType = .sixPointScotch }
        if hammerCountPerHole == nil { hammerCountPerHole = Array(repeating: 0, count: holes) }
        if wolfPlayerPerHole == nil { wolfPlayerPerHole = Array(repeating: nil, count: holes) }
        if wolfWentAlonePerHole == nil { wolfWentAlonePerHole = Array(repeating: false, count: holes) }

        func pad<T>(_ arr: inout [T], with value: T) {
            if arr.count < holes { arr += Array(repeating: value, count: holes - arr.count) }
            if arr.count > holes { arr = Array(arr.prefix(holes)) }
        }

        pad(&hammerCountPerHole!, with: 0)
        pad(&wolfPlayerPerHole!, with: nil as Int?)
        pad(&wolfWentAlonePerHole!, with: false)

        if skinsState == nil {
            skinsState = SkinsEngine.makeDefaultState()
        }
    }
}

extension GameData {
    /// Recomputes `gameHoleDollarsArray[h]` from the pure base × press multiplier × active hole-scoped flags.
    /// Call this after toggling rollApplied, rerollApplied, or aloneApplied on or off.
    mutating func recomputeHoleAmount(hole h: Int) {
        guard h >= 0, h < STANDARD_HOLES else { return }
        if holeBaseAmount.count != STANDARD_HOLES { holeBaseAmount = Array(repeating: 2.0, count: STANDARD_HOLES) }
        if gameHoleDollarsArray.count != STANDARD_HOLES { gameHoleDollarsArray = Array(repeating: 2.0, count: STANDARD_HOLES) }

        var amount = holeBaseAmount[h] <= 0 ? 2.0 : holeBaseAmount[h]

        let pl = pressLevel[safe: h] ?? 0
        if pl > 0 {
            amount *= pressStyle == .additive ? Double(pl + 1) : Double(1 << pl)
        }

        if rollApplied[safe: h]   ?? false { amount *= 2.0 }
        if rerollApplied[safe: h] ?? false { amount *= 2.0 }
        if aloneApplied[safe: h]  ?? false { amount *= 2.0 }

        gameHoleDollarsArray[h] = max(1.0, (amount * 2.0).rounded() / 2.0)
    }

    func hammerMultiplier(for hole: Int) -> Double {
        let c = max(0, hammerCountPerHole?[safe: hole] ?? 0)
        switch hammerStyle {
        case .doubling: return Double(1 << c)   // 1×, 2×, 4×, 8×…
        case .additive: return Double(c + 1)    // 1×, 2×, 3×, 4×… (linear)
        }
    }
}

extension GameData {
    var stablefordBaseline: StablefordBaseline {
        get { stablefordBaselineOpt ?? .par }
        mutating set { stablefordBaselineOpt = newValue }
    }
    var stablefordCountingPlayers: Int {
        get { stablefordCountingPlayersOpt ?? 3 }
        mutating set { stablefordCountingPlayersOpt = newValue }
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension GameData {
    // Par for a hole considering the player's assigned tee set (0 = course default).
    func parForHole(_ hole: Int, player: Int) -> Int {
        let idx = playerTeeSetIndex[safe: player] ?? 0
        if idx > 0, let ts = course.teeSets[safe: idx - 1], hole < ts.pars.count {
            return ts.pars[hole]
        }
        return courseParToPass[safe: hole] ?? 4
    }

    // Stroke index for a hole considering the player's assigned tee set.
    // Always returns a value in 1...STANDARD_HOLES.
    func hcForHole(_ hole: Int, player: Int) -> Int {
        let idx = playerTeeSetIndex[safe: player] ?? 0
        if idx > 0, let ts = course.teeSets[safe: idx - 1], hole < ts.hcs.count {
            let raw = ts.hcs[hole]
            return max(1, min(STANDARD_HOLES, raw == 0 ? STANDARD_HOLES : raw))
        }
        let raw = courseHCToPass[safe: hole] ?? STANDARD_HOLES
        return max(1, min(STANDARD_HOLES, raw == 0 ? STANDARD_HOLES : raw))
    }

    // True when the player is using a non-default tee set.
    func isUsingAltTee(player: Int) -> Bool {
        (playerTeeSetIndex[safe: player] ?? 0) > 0
    }
}
