//
//  GameData.swift
//  Wolfmore-7Man
//
//  Created by Tom BUTLER on 9/29/25.
//
// GameData.swift
import Foundation

struct GameData: Codable {

    // NEW (optional so old saves decode safely)
    var gameType: GameType?
    var hammerCountPerHole: [Int]?
    var wolfPlayerPerHole: [Int?]?
    var wolfWentAlonePerHole: [Bool]?
    
    // Convenience so your existing code can stay mostly unchanged
    var resolvedGameType: GameType { gameType ?? .sixPointScotch }

    // MARK: - Wolf stats per hole (for Hole Stats / Wolf% views)
    // In GameData.swift
    var umbieWonPerHole: [Bool] = Array(repeating: false, count: 18)

    /// true if any Wolf was called on that hole
    var wolfCalledPerHole: [Bool] = Array(repeating: false, count: 18)

    /// true if the Wolf team actually won that hole (given a Wolf was called)
    var wolfTeamWonPerHole: [Bool] = Array(repeating: false, count: 18)


    // MARK: - Core game state

    var startHole: Int? = nil      // shotgun start hole (0…17); nil until set

    var course: Course = .default
    var gameName: String = "New Game"
    var popsTable: [[Int]] = []

    var pressedPushedToggleArray: [Bool] = Array(repeating: false, count: 18)
    var previousPressedPushedToggleArray: [Bool] = Array(repeating: false, count: 18)
    var gameHoleDollarsArray: [Double] = Array(repeating: 2.0, count: 18)

    // 9 players × 18 holes; nil = no score entered yet
    var scores: [[Int?]] = Array(
        repeating: Array(repeating: nil, count: 18),
        count: 5
    )

    // Per-player payout per hole (what you show on the game screen)
    var playerMoney: [[Double]] = Array(
        repeating: Array(repeating: 0, count: 18),
        count: 5
    )

    var rosterNames: [String] = []
    var proxWinnerPerHole: [Int?] = Array(repeating: nil, count: 18)

    var pressMask:        [Bool]   = Array(repeating: false, count: 18)
    var pressBaseDollars: [Double] = Array(repeating: 0.0,  count: 18)
    var pressBaseAmount:  [Double] = Array(repeating: 0.0,  count: 18)

    var rollBaseAmount: [Double] = Array(repeating: 0.0, count: 18)
    var rollApplied:    [Bool]   = Array(repeating: false, count: 18)

    // Re-roll state per hole (depends on Roll)
    var rerollApplied:    [Bool]   = Array(repeating: false, count: 18)
    var rerollBaseAmount: [Double] = Array(repeating: 0.0,    count: 18)

    var aloneApplied:    [Bool]   = Array(repeating: false, count: 18)
    var aloneBaseAmount: [Double] = Array(repeating: 0.0,  count: 18)

    var wolfButtonStatus: [[Bool]] = Array(
        repeating: Array(repeating: false, count: 18),
        count: 9  // exactly 9 buttons/players
    )

    var playerNames:   [String] = Array(repeating: "",    count: 5)
    var hcPlayers:     [Int]    = Array(repeating: 0,     count: 5)
    var playerActivated: [Bool] = Array(repeating: false, count: 5)

    var hole: Int = 0

    var isUmbrella: Bool = false   // true = MUTE the double for the whole game

    var isPressOn:  Bool = false
    var isRollOn:   Bool = false
    var isRerollOn: Bool = false
    var isAlone:    Bool = false


    // MARK: - Course passthrough

    var courseParToPass: [Int] {
        get { course.pars }
        set { course.pars = Array(newValue.prefix(18)) }
    }

    var courseHCToPass: [Int] {
        get { course.holeHandicaps }
        set {
            let fixed = newValue.prefix(18).map { v in
                let x = (v == 0 ? 18 : v)
                return max(1, min(18, x))
            }
            course.holeHandicaps = Array(fixed)
        }
    }
    mutating func normalize(holes: Int = 18) {
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
    }
    

}
extension GameData {
    func hammerMultiplier(for hole: Int) -> Double {
        let c = hammerCountPerHole?[safe: hole] ?? 0
        return Double(1 << max(0, c))   // 1,2,4,8...
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
