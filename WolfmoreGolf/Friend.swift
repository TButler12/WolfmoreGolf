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
}


/// friendID -> set of courseIDs the user chose to track
final class FriendTrackStore {
    static let shared = FriendTrackStore()
    private let k = "friendTrack.v1"

    private(set) var tracked: [UUID: Set<String>] = [:]

    private init() { load() }

    private func load() {
        if let d = UserDefaults.standard.data(forKey: k),
           let obj = try? JSONDecoder().decode([UUID: Set<String>].self, from: d) {
            tracked = obj
        }
    }
    private func save() {
        if let d = try? JSONEncoder().encode(tracked) {
            UserDefaults.standard.setValue(d, forKey: k)
        }
    }

    func isTracked(_ fid: UUID, on courseID: String) -> Bool {
        tracked[fid]?.contains(courseID) ?? false
    }

    /// Toggle tracking for (friend, course). Enforces `limit` per course.
    /// Returns true if state changed; false if blocked by limit.
    @discardableResult
    func toggle(_ fid: UUID, courseID: String, limit: Int = 10) -> Bool {
        var set = tracked[fid, default: []]
        if set.contains(courseID) {
            set.remove(courseID)
            tracked[fid] = set.isEmpty ? nil : set
            save()
            return true
        } else {
            // enforce per-course limit
            let currentlyTrackedCount = tracked.values.filter { $0.contains(courseID) }.count
            guard currentlyTrackedCount < limit else { return false }
            set.insert(courseID)
            tracked[fid] = set
            save()
            return true
        }
    }

    /// Count how many friends are tracked for a specific course.
    func count(for courseID: String) -> Int {
        tracked.values.filter { $0.contains(courseID) }.count
    }
}
