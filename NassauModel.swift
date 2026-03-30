import Foundation

enum NassauFormat: String, Codable {
    case oneVsOne
    case twoVsTwo
}

enum NassauSegment: String, Codable {
    case front
    case back
    case overall
}

enum NassauScoringMode: String, Codable {
    case gross
    case net
}

enum NassauPressMode: String, Codable {
    case off
    case auto
    case manual
}

enum NassauPressStartRule: String, Codable {
    case nextHole
    case currentHole
}

enum NassauPressAmountMode: String, Codable {
    case sameAsBase
    case custom
}

struct NassauSettings: Codable, Equatable {
    var isEnabled: Bool = true

    var baseStake: Double = 1.0

    var pressMode: NassauPressMode = .auto
    var autoPressTriggerDown: Int = 2
    var pressStartRule: NassauPressStartRule = .nextHole
    var pressAmountMode: NassauPressAmountMode = .sameAsBase
    var customPressStake: Double = 1.0
    var maxPressesPerSegment: Int = 3

    var allowOverallPresses: Bool = false

    func resolvedPressStake() -> Double {
        switch pressAmountMode {
        case .sameAsBase:
            return baseStake
        case .custom:
            return customPressStake
        }
    }
}

struct NassauPress: Codable, Equatable {
    var id: UUID = UUID()
    var segment: NassauSegment
    var startHole: Int                  // 1-based
    var endHole: Int                    // 1-based
    var team1PlayerIndexes: [Int]
    var team2PlayerIndexes: [Int]
    var stake: Double = 1.0
    var runningStatus: [Int] = []       // + = team1 up, - = team2 up, 0 = AS
    var createdManually: Bool = false
}

struct NassauMatch: Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var format: NassauFormat
    var team1PlayerIndexes: [Int]
    var team2PlayerIndexes: [Int]
    var scoringMode: NassauScoringMode = .gross

    // Main segment wager
    var stake: Double = 1.0

    // Per-match overrides
    var pressMode: NassauPressMode? = nil
    var autoPressTriggerDown: Int? = nil
    var pressStartRule: NassauPressStartRule? = nil
    var pressAmountMode: NassauPressAmountMode? = nil
    var customPressStake: Double? = nil
    var maxPressesPerSegment: Int? = nil
    var allowOverallPresses: Bool? = nil

    var frontStatusByHole: [Int] = []
    var backStatusByHole: [Int] = []
    var overallStatusByHole: [Int] = []

    var presses: [NassauPress] = []

    func resolvedPressMode(using state: NassauState) -> NassauPressMode {
        pressMode ?? state.settings.pressMode
    }

    func resolvedTrigger(using state: NassauState) -> Int {
        autoPressTriggerDown ?? state.settings.autoPressTriggerDown
    }

    func resolvedPressStartRule(using state: NassauState) -> NassauPressStartRule {
        pressStartRule ?? state.settings.pressStartRule
    }

    func resolvedPressAmountMode(using state: NassauState) -> NassauPressAmountMode {
        pressAmountMode ?? state.settings.pressAmountMode
    }

    func resolvedCustomPressStake(using state: NassauState) -> Double {
        customPressStake ?? state.settings.customPressStake
    }

    func resolvedMaxPressesPerSegment(using state: NassauState) -> Int {
        maxPressesPerSegment ?? state.settings.maxPressesPerSegment
    }

    func resolvedAllowOverallPresses(using state: NassauState) -> Bool {
        allowOverallPresses ?? state.settings.allowOverallPresses
    }

    func resolvedPressStake(using state: NassauState) -> Double {
        switch resolvedPressAmountMode(using: state) {
        case .sameAsBase:
            return stake
        case .custom:
            return resolvedCustomPressStake(using: state)
        }
    }
}

struct NassauState: Codable, Equatable {
    var settings: NassauSettings = NassauSettings()
    var oneVsOneMatches: [NassauMatch] = []
    var twoVsTwoMatches: [NassauMatch] = []

    var isEnabled: Bool {
        get { settings.isEnabled }
        set { settings.isEnabled = newValue }
    }

    var defaultStake: Double {
        get { settings.baseStake }
        set { settings.baseStake = newValue }
    }

    var autoPressEnabled: Bool {
        get { settings.pressMode == .auto }
        set { settings.pressMode = newValue ? .auto : .off }
    }

    var autoPressTriggerDown: Int {
        get { settings.autoPressTriggerDown }
        set { settings.autoPressTriggerDown = newValue }
    }
}

// MARK: - Final Summary Models

struct NassauSegmentSummary {
    let title: String
    let team1Display: String
    let team2Display: String
    let holesWonTeam1: Int
    let holesWonTeam2: Int
    let ties: Int
    let resultText: String
    let moneyDelta: Double
}

struct NassauPressSummary {
    let title: String
    let resultText: String
    let moneyDelta: Double
}

struct NassauMatchFinalSummary {
    let matchTitle: String
    let team1Display: String
    let team2Display: String
    let front9: NassauSegmentSummary?
    let back9: NassauSegmentSummary?
    let overall18: NassauSegmentSummary?
    let presses: [NassauPressSummary]
    let totalMoneyDelta: Double
    let totalMoneyText: String
}
