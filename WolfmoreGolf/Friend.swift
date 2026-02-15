//
//  Friend.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 11/14/25.
import Foundation

struct Friend: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var defaultHC: Int
    var preselectForRound: Bool
    var phone: String
    var isFavorite: Bool
    var isTracked: Bool   // ✅ NEW

    init(id: UUID = UUID(),
         name: String,
         defaultHC: Int = 0,
         preselectForRound: Bool = false,
         phone: String = "",
         isFavorite: Bool = false,
         isTracked: Bool = false) {   // ✅ NEW
        self.id = id
        self.name = name
        self.defaultHC = defaultHC
        self.preselectForRound = preselectForRound
        self.phone = phone
        self.isFavorite = isFavorite
        self.isTracked = isTracked
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, defaultHC, preselectForRound, phone, isFavorite, isTracked
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Player"
        defaultHC = try c.decodeIfPresent(Int.self, forKey: .defaultHC) ?? 0
        preselectForRound = try c.decodeIfPresent(Bool.self, forKey: .preselectForRound) ?? false
        phone = try c.decodeIfPresent(String.self, forKey: .phone) ?? ""
        isFavorite = try c.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        isTracked = try c.decodeIfPresent(Bool.self, forKey: .isTracked) ?? false   // ✅ NEW
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(defaultHC, forKey: .defaultHC)
        try c.encode(preselectForRound, forKey: .preselectForRound)
        try c.encode(phone, forKey: .phone)
        try c.encode(isFavorite, forKey: .isFavorite)
        try c.encode(isTracked, forKey: .isTracked)   // ✅ NEW
    }
}


