//
//  FriendStore.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 11/14/25.
//
// Stores/FriendStore.swift
import Foundation

final class FriendStore {
    static let shared = FriendStore()
    private let k = "friends.v1"

    private(set) var friends: [Friend] = []

    private init() {
        load()
    }

    private func load() {
        if let d = UserDefaults.standard.data(forKey: k),
           let f = try? JSONDecoder().decode([Friend].self, from: d) {
            friends = f
        } else {
            friends = []
        }
    }

    private func save() {
        if let d = try? JSONEncoder().encode(friends) {
            UserDefaults.standard.set(d, forKey: k)
        }
    }

    func add(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let key = trimmed.lowercased()
        if friends.contains(where: { $0.name.lowercased() == key }) { return }

        friends.append(Friend(id: UUID(), name: trimmed))
        friends.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        save()
    }

    func merge(names: [String]) {
        var changed = false

        for n in names {
            let trimmed = n.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let key = trimmed.lowercased()

            if !friends.contains(where: { $0.name.lowercased() == key }) {
                friends.append(Friend(id: UUID(), name: trimmed))
                changed = true
            }
        }

        if changed {
            friends.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            save()
        }
    }
}
