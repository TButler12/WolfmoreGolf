import Foundation

struct PermanentRosterPlayer: Codable {
    var id: UUID
    var name: String
    var handicap: Int
}

final class PermanentRosterStore {
    static let shared = PermanentRosterStore()
    private let key = "wolfmore_permanentRoster"

    var players: [PermanentRosterPlayer] {
        get {
            guard let data = UserDefaults.standard.data(forKey: key),
                  let list = try? JSONDecoder().decode([PermanentRosterPlayer].self, from: data)
            else { return [] }
            return list
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: key)
            }
        }
    }

    // Inserts or updates by name (case-insensitive). Always re-sorts alphabetically.
    func upsert(name: String, handicap: Int) {
        var current = players
        if let idx = current.firstIndex(where: { $0.name.lowercased() == name.lowercased() }) {
            current[idx].handicap = handicap
        } else {
            current.append(PermanentRosterPlayer(id: UUID(), name: name, handicap: handicap))
        }
        players = current.sorted { $0.name < $1.name }
    }

    func remove(id: UUID) {
        players = players.filter { $0.id != id }
    }
}
