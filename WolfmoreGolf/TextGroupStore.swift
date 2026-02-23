//
//  TextGroupStore.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 2/23/26.
//

import Foundation

struct TextGroup: Codable, Equatable, Identifiable {
    let id: UUID
    var name: String
    var memberIDs: [UUID]   // Friend.id list
    var updatedAt: Date

    init(id: UUID = UUID(), name: String, memberIDs: [UUID]) {
        self.id = id
        self.name = name
        self.memberIDs = memberIDs
        self.updatedAt = Date()
    }
}

final class TextGroupStore {
    static let shared = TextGroupStore()
    private init() { load() }

    private let key = "text.groups.v1"
    private(set) var groups: [TextGroup] = []

    func allSorted() -> [TextGroup] {
        groups.sorted { $0.updatedAt > $1.updatedAt }
    }

    func get(id: UUID) -> TextGroup? {
        groups.first { $0.id == id }
    }

    func upsert(_ g: TextGroup) {
        var g = g
        g.updatedAt = Date()

        if let i = groups.firstIndex(where: { $0.id == g.id }) {
            groups[i] = g
        } else if let j = groups.firstIndex(where: { $0.name.caseInsensitiveCompare(g.name) == .orderedSame }) {
            // preserve existing ID if overwriting by name
            groups[j] = TextGroup(id: groups[j].id, name: g.name, memberIDs: g.memberIDs)
        } else {
            groups.append(g)
        }
        save()
    }

    func delete(id: UUID) {
        groups.removeAll { $0.id == id }
        save()
    }

    // MARK: - Persistence
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        groups = (try? JSONDecoder().decode([TextGroup].self, from: data)) ?? []
    }

    private func save() {
        let data = (try? JSONEncoder().encode(groups)) ?? Data()
        UserDefaults.standard.set(data, forKey: key)
    }
}
