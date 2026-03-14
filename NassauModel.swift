//
//  NassauModel.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 3/13/26.
//

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

struct NassauPress: Codable, Equatable {
    var id: UUID = UUID()
    var segment: NassauSegment
    var startHole: Int
    var endHole: Int
    var team1PlayerIndexes: [Int]
    var team2PlayerIndexes: [Int]
    var stake: Double = 1.0
    var runningStatus: [Int] = []   // + = team1 up, - = team2 up, 0 = AS
}

struct NassauMatch: Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var format: NassauFormat
    var team1PlayerIndexes: [Int]
    var team2PlayerIndexes: [Int]
    var scoringMode: NassauScoringMode = .gross
    var stake: Double = 1.0
    var autoPressEnabled: Bool = true
    var autoPressTriggerDown: Int = 2

    var frontStatusByHole: [Int] = []
    var backStatusByHole: [Int] = []
    var overallStatusByHole: [Int] = []

    var presses: [NassauPress] = []
}

struct NassauState: Codable, Equatable {
    var isEnabled: Bool = false
    var defaultStake: Double = 1.0
    var autoPressEnabled: Bool = true
    var autoPressTriggerDown: Int = 2

    var oneVsOneMatches: [NassauMatch] = []
    var twoVsTwoMatches: [NassauMatch] = []
}
