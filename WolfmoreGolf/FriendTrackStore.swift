//
//  FriendTrackStore.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 11/14/25.
//

import Foundation

/// Stores which friends are "tracked" per course.
/// Key = courseID (String), Value = set of Friend IDs (UUIDs).
final class FriendTrackStore {
    static let shared = FriendTrackStore()

    private let key = "friend.track.v1"

    // courseID → set of friend IDs
    private var tracked: [String: Set<UUID>] = [:]

    private init() {
        load()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }

        if let decoded = try? JSONDecoder().decode([String: [UUID]].self, from: data) {
            // convert [UUID] → Set<UUID>
            tracked = decoded.reduce(into: [:]) { partial, pair in
                partial[pair.key] = Set(pair.value)
            }
        }
    }

    private func save() {
        // convert Set<UUID> → [UUID] for encoding
        let encodable = tracked.mapValues { Array($0) }
        if let data = try? JSONEncoder().encode(encodable) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    // MARK: - Query

    /// Is this friend tracked on this course?
    func isTracked(_ friendID: UUID, on courseID: String) -> Bool {
        tracked[courseID]?.contains(friendID) ?? false
    }

    /// How many friends are tracked on this specific course?
    func count(for courseID: String) -> Int {
        tracked[courseID]?.count ?? 0
    }

    /// Total tracked entries across all courses (optional, if you want it).
    var totalTrackedCount: Int {
        tracked.values.reduce(0) { $0 + $1.count }
    }

    // MARK: - Mutation

    /// Toggle tracked/untracked for a friend on a course.
    /// Respects `limit`: if already at limit and trying to add, returns false.
    @discardableResult
    func toggle(_ friendID: UUID, courseID: String, limit: Int) -> Bool {
        var set = tracked[courseID] ?? []

        if set.contains(friendID) {
            // Turning OFF
            set.remove(friendID)
            tracked[courseID] = set
            save()
            return true
        } else {
            // Turning ON – enforce per-course limit
            if set.count >= limit {
                return false
            }
            set.insert(friendID)
            tracked[courseID] = set
            save()
            return true
        }
    }

    /// Clear all tracking (if you ever need a reset).
    func clearAll() {
        tracked.removeAll()
        save()
    }
}

