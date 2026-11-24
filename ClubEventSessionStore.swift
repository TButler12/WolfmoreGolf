import Foundation

// MARK: - Organizer Store

/// A locally-persisted record of a club event the user has created as organizer on this device.
struct ClubEventOrganizerEntry: Codable {
    let id: UUID
    let code: String
    let name: String
    let courseName: String?
    let createdAt: Date
}

/// Persists the last few club events created by this device so the organizer
/// can re-open them from the Live & Tournaments screen.
final class ClubEventOrganizerStore {
    static let shared = ClubEventOrganizerStore()

    private let key = "clubEventOrganizerEntries"
    private let maxEntries = 10

    private init() {}

    var all: [ClubEventOrganizerEntry] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([ClubEventOrganizerEntry].self, from: data)
        else { return [] }
        return list
    }

    func save(_ entry: ClubEventOrganizerEntry) {
        var list = all.filter { $0.id != entry.id }
        list.insert(entry, at: 0)
        if list.count > maxEntries { list = Array(list.prefix(maxEntries)) }
        write(list)
    }

    func remove(id: UUID) {
        let list = all.filter { $0.id != id }
        write(list)
    }

    private func write(_ list: [ClubEventOrganizerEntry]) {
        guard let data = try? JSONEncoder().encode(list) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

// MARK: - Session Store

/// A locally-persisted record of an active scoring session — captures enough to
/// resume per-hole scoring for a group after the app relaunches.
struct ClubEventSession: Codable {
    let eventId: UUID
    let eventCode: String
    let eventName: String
    let courseName: String?
    let groupCode: String
    let startingHole: Int
    let playerIds: [UUID]
}

final class ClubEventSessionStore {
    static let shared = ClubEventSessionStore()

    private let key = "activeClubEventSession"

    private init() {}

    var current: ClubEventSession? {
        get {
            guard let data = UserDefaults.standard.data(forKey: key),
                  let s = try? JSONDecoder().decode(ClubEventSession.self, from: data)
            else { return nil }
            return s
        }
        set {
            if let s = newValue {
                save(s)
            } else {
                clear()
            }
        }
    }

    func save(_ session: ClubEventSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
