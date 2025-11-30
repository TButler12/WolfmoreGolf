//
//  Friend.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 11/14/25.
//

import Foundation

struct Friend: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var defaultHC: Int          // default handicap for this player
    var preselectForRound: Bool // should be pre-activated for next round?

    init(id: UUID = UUID(),
         name: String,
         defaultHC: Int = 0,
         preselectForRound: Bool = false) {
        self.id = id
        self.name = name
        self.defaultHC = defaultHC
        self.preselectForRound = preselectForRound
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, defaultHC, preselectForRound
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Player"
        defaultHC = try c.decodeIfPresent(Int.self, forKey: .defaultHC) ?? 0
        preselectForRound = try c.decodeIfPresent(Bool.self,
                                                  forKey: .preselectForRound) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(defaultHC, forKey: .defaultHC)
        try c.encode(preselectForRound, forKey: .preselectForRound)
    }
}
