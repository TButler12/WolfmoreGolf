//
//  FriendTrackStore.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 11/14/25.
//

import Foundation

/// Stores which friends are "tracked" per course.
/// - Key: courseID (String)
/// - Value: Set of Friend IDs (UUID strings)
final class FriendTrackStore {

    static let shared = FriendTrackStore()
    private init() { load() }

    private let defaultsKey = "friend.track.v1"

    // courseID -> Set(friendUUIDString)
    private var trackedByCourse: [String: Set<String>] = [:] {
        didSet { save() }
    }

    // MARK: - Read

    func isTracked(friendID: UUID, courseID: String) -> Bool {
        trackedByCourse[courseID]?.contains(friendID.uuidString) ?? false
    }

    func trackedIDs(courseID: String) -> Set<String> {
        trackedByCourse[courseID] ?? []
    }

    func count(courseID: String) -> Int {
        trackedByCourse[courseID]?.count ?? 0
    }

    /// Convenience for older call sites (e.g. `count(for:)`).
    func count(for courseID: String) -> Int {
        count(courseID: courseID)
    }

    // MARK: - Write

    func setTracked(friendID: UUID, courseID: String, isTracked: Bool) {
        var set = trackedByCourse[courseID] ?? Set<String>()
        let id = friendID.uuidString

        if isTracked {
            set.insert(id)
        } else {
            set.remove(id)
        }

        trackedByCourse[courseID] = set
    }

    /// Toggle tracking for a friend on a course.
    /// - Returns: `true` if the toggle succeeded. `false` only when trying to add but the limit is reached.
    @discardableResult
    func toggle(friendID: UUID, courseID: String, limit: Int) -> Bool {
        var set = trackedByCourse[courseID] ?? Set<String>()
        let id = friendID.uuidString

        if set.contains(id) {
            set.remove(id)
            trackedByCourse[courseID] = set
            return true
        }

        guard set.count < limit else { return false }

        set.insert(id)
        trackedByCourse[courseID] = set
        return true
    }

    // MARK: - Persistence

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: defaultsKey),
            let decoded = try? JSONDecoder().decode([String: Set<String>].self, from: data)
        else { return }

        trackedByCourse = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(trackedByCourse) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
