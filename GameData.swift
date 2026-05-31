import Foundation

struct GameData: Codable {
    var holeStatsPromptMuted: Bool = false
    var scorePerHole: [[Int?]] = []
    var umbrellaMode: Bool = false
    var baseGameStake: Int = 2
    var holeCommitted: [Bool] = Array(repeating: false, count: STANDARD_HOLES)

    var nassauState: NassauState?
    var skinsState: SkinsState?

    // Supabase live match identifier (nil = local/text-based flow)
    var remoteMatchId: String? = nil
    // All remote match IDs created/joined during this game session
    var remoteMatchIds: [String] = []

    // NEW (optional so old saves decode safely)
    var gameTypePerHole: [GameType] = Array(repeating: .sixPointScotch, count: STANDARD_HOLES)

    var gameType: GameType?
    var hammerCountPerHole: [Int]?
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

    var pressMask: [Bool] = Array(repeating: false, count: STANDARD_HOLES)
    var pressBaseDollars: [Double] = Array(repeating: 0.0, count: STANDARD_HOLES)
    var pressBaseAmount: [Double] = Array(repeating: 0.0, count: STANDARD_HOLES)

    var rollBaseAmount: [Double] = Array(repeating: 0.0, count: STANDARD_HOLES)
    var rollApplied: [Bool] = Array(repeating: false, count: STANDARD_HOLES)

    var rerollApplied: [Bool] = Array(repeating: false, count: STANDARD_HOLES)
    var rerollBaseAmount: [Double] = Array(repeating: 0.0, count: STANDARD_HOLES)

    var aloneApplied: [Bool] = Array(repeating: false, count: STANDARD_HOLES)
    var aloneBaseAmount: [Double] = Array(repeating: 0.0, count: STANDARD_HOLES)

    var wolfButtonStatus: [[Bool]] = Array(
        repeating: Array(repeating: false, count: STANDARD_HOLES),
        count: 9
    )

    var playerNames: [String] = Array(repeating: "", count: MAX_PLAYERS)
    var hcPlayers: [Int] = Array(repeating: 0, count: MAX_PLAYERS)
    var playerActivated: [Bool] = Array(repeating: false, count: MAX_PLAYERS)

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
    func hammerMultiplier(for hole: Int) -> Double {
        let c = hammerCountPerHole?[safe: hole] ?? 0
        return Double(1 << max(0, c))
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
