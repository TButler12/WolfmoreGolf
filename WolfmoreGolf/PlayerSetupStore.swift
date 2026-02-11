//
//  PlayerSetupStore.swift
//  Wolfmore-5Man
//
//  Created by Tom BUTLER on 9/30/25.
//
//  PlayerSetupStore.swift
//  Wolfmore-5Man
import Foundation

struct PlayerSetupRow: Codable {
    var name: String
    var handicap: Int
    var isActive: Bool
    var strokes: Int
}

enum PlayerSetupStore {
    private static let key = "playerSetup.v1"
    static func save(_ rows: [PlayerSetupRow]) {
        if let d = try? JSONEncoder().encode(rows) {
            UserDefaults.standard.set(d, forKey: key)
        }
    }
    static func load() -> [PlayerSetupRow] {
        guard let d = UserDefaults.standard.data(forKey: key),
              let rows = try? JSONDecoder().decode([PlayerSetupRow].self, from: d) else { return [] }
        return rows
    }
}
