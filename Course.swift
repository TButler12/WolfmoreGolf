//
//  Course.swift
//  Wolfmore-7Man
//
//  Created by Tom BUTLER on 9/29/25.
//

// Course.swift
import Foundation

struct TeeSet: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var pars: [Int]
    var hcs: [Int]
}

struct Course: Codable {
    var id: UUID = UUID()
    var name: String = "Course"
    var pars: [Int]
    var holeHandicaps: [Int]
    var teeSets: [TeeSet] = []

    // CodingKeys in struct body so synthesized encode(to:) encodes all properties.
    private enum CodingKeys: String, CodingKey {
        case id, name, pars, holeHandicaps, teeSets
    }

    static let `default` = Course(
        name: "WolfMore",
        pars: Array(repeating: 4, count: STANDARD_HOLES),
        holeHandicaps: Array(1...STANDARD_HOLES)
    )
}

extension Course {
    // Custom decoder so `teeSets` defaults to [] when the key is absent in old saves.
    // Defined in extension to preserve the synthesized memberwise init.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id            = (try? c.decodeIfPresent(UUID.self,   forKey: .id))            ?? UUID()
        name          = (try? c.decodeIfPresent(String.self, forKey: .name))          ?? "Course"
        pars          = try c.decode([Int].self, forKey: .pars)
        holeHandicaps = try c.decode([Int].self, forKey: .holeHandicaps)
        teeSets       = (try? c.decodeIfPresent([TeeSet].self, forKey: .teeSets))     ?? []
    }
}
