//
//  TextGroupStore.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 3/25/26.
//

import Foundation

final class TextGroupStore {

    static let shared = TextGroupStore()

    private let key = "wolfmore.textgroups.v1"

   
    private init() {
        load()
    }
    private(set) var groups: [TextGroup] = []
   

    func allSorted() -> [TextGroup] {
        groups.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    func upsert(_ group: TextGroup) {
        if let idx = groups.firstIndex(where: { $0.id == group.id }) {
            groups[idx] = group
        } else {
            groups.append(group)
        }
        save()
    }

    func delete(id: UUID) {
        groups.removeAll { $0.id == id }
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            groups = []
            return
        }

        do {
            groups = try JSONDecoder().decode([TextGroup].self, from: data)
        } catch {
            print("Failed to load TextGroups:", error)
            groups = []
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(groups)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Failed to save TextGroups:", error)
        }
    }
}
