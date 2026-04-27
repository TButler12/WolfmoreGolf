//
//  GameModels.swift
//  Wolfmore-7Man
//
//  Created by Tom BUTLER on 9/30/25.
// GameModels.swift
import Foundation

public struct Player: Codable, Equatable {
    public var name: String
    public var handicap: Int?
    public var isActive: Bool
}

public struct CourseData: Codable, Equatable {
    public var name: String
    public var pars: [Int]
    public var holeHandicaps: [Int]

    public static let `default` = CourseData(
        name: "Default",
        pars: Array(repeating: 4, count: STANDARD_HOLES),
        holeHandicaps: Array(1...STANDARD_HOLES)
    )
}

public struct Game: Codable {
    public var players: [Player]
    public var course: CourseData
    public var holeIndex: Int
    public var dollars: Double
    public var umbrellaOn: Bool
    public var scores: [[Int?]]
    public var popsTable: [[Int]]
}

// MARK: - Course / Location Promo Models

public enum PromoType: String, Codable {
    case deal
    case event
    case featured
}

public enum VenueType: String, Codable {
    case golfCourse
    case resort
    case indoorGolf
}

public struct LocationPromo: Codable, Equatable {
    public var type: PromoType
    public var title: String
    public var subtitle: String?
    public var isActive: Bool

    public init(
        type: PromoType,
        title: String,
        subtitle: String? = nil,
        isActive: Bool = true
    ) {
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.isActive = isActive
    }
}
