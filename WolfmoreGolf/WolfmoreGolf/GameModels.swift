//
//  GameModels.swift
//  Wolfmore-7Man
//
//  Created by Tom BUTLER on 9/30/25.
// GameModels.swift
import Foundation

public struct Player: Codable, Equatable {
    public var name: String
    public var handicap: Int?          // nil if unknown
    public var isActive: Bool
}

public struct CourseData: Codable, Equatable {
    public var name: String
    public var pars: [Int]             // usually 18
    public var holeHandicaps: [Int]    // 1 = hardest ... 18 = easiest

    public static let `default` = CourseData(
        name: "Default",
        pars: Array(repeating: 4, count: 18),
        holeHandicaps: Array(1...18)
    )
}

public struct Game: Codable {
    public var players: [Player]
    public var course: CourseData
    public var holeIndex: Int
    public var dollars: Double
    public var umbrellaOn: Bool
    public var scores: [[Int?]]        // [player][hole]
    public var popsTable: [[Int]]
    // [hole][player]
}
