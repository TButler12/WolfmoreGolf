//
//  GameData.swift
//  Wolfmore-7Man
//
//  Created by Tom BUTLER on 9/29/25.
//
// GameData.swift
import Foundation

struct GameData: Codable {
    
    
    var startHole: Int? = nil      // shotgun start hole (0…17); nil until set

    var course: Course = .default
    var gameName: String = "New Game"
    var popsTable: [[Int]] = []
    var pressedPushedToggleArray: [Bool] = Array(repeating: false, count: 18)
    var previousPressedPushedToggleArray: [Bool] = Array(repeating: false, count: 18)
    var gameHoleDollarsArray: [Double] = Array(repeating: 2.0, count: 18)
    
    // 9 players × 18 holes; nil = no score entered yet
    var scores: [[Int?]] = Array(repeating: Array(repeating: nil, count: 18), count: 9)
    
    // Per-player payout per hole (what you show on the game screen)
    var playerMoney: [[Double]] = Array(repeating: Array(repeating: 0, count: 18), count: 9)
    
    var rosterNames: [String] = []
    var proxWinnerPerHole: [Int?] = Array(repeating: nil, count: 18)
    var pressMask:        [Bool]   = Array(repeating: false, count: 18)
    var pressBaseDollars: [Double] = Array(repeating: 0.0,  count: 18)
    var pressBaseAmount: [Double] = Array(repeating: 0.0,  count: 18)
    var rollBaseAmount: [Double] = Array(repeating: 0.0, count: 18)
    var rollApplied: [Bool] = Array(repeating: false, count: 18)
    // Re-roll state per hole (depends on Roll)
    var rerollApplied:   [Bool]   = Array(repeating: false, count: 18)
    var rerollBaseAmount:[Double] = Array(repeating: 0.0,    count: 18)
    var aloneApplied:    [Bool]   = Array(repeating: false, count: 18)
    var aloneBaseAmount: [Double] = Array(repeating: 0.0,  count: 18)
    
    var wolfButtonStatus: [[Bool]] = Array(
        repeating: Array(repeating: false, count: 18),
        count: 9  // ← exactly 9 buttons/players
    )
    var playerNames: [String]      = Array(repeating: "",     count: 9)
    var hcPlayers:   [Int]         = Array(repeating: 0,      count: 9)
    var playerActivated: [Bool]    = Array(repeating: false,  count: 9)
    
    //var courseParToPass: [Int] = Array(repeating: 4, count: 18)   // Par per hole
    //var courseHCToPass:  [Int] = Array(1...18)                    // Stroke index per hole (1..18)
    
    // Dollars per hole (seed with your default)
    
    var hole: Int = 0
    
   
    var isUmbrella: Bool = false   // true = MUTE the double for the whole game

    var isPressOn: Bool = false
    var isRollOn: Bool = false
    var isRerollOn: Bool = false
    var isAlone: Bool = false
    // In GameData
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

    
}

extension Collection {
    subscript(safe index: Index) -> Element? { indices.contains(index) ? self[index] : nil }
}
