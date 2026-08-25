import Foundation

struct TournamentHistoryEntry: Codable {
    let code: String
    let name: String
    let gameType: String
    var lastDay: Int
    var lastJoined: Date
    var isOrganizer: Bool
    var groupCode: String?         // scorer's claim identity — nil for old entries or organizers
    var tournamentMatchId: String? // score submission ID — nil for old entries or organizers
}

final class TournamentHistoryStore {
    static let shared = TournamentHistoryStore()
    private let key = "tournamentHistory_v1"
    private let maxEntries = 5
    private init() {}

    func record(code: String, name: String, gameType: String, day: Int, isOrganizer: Bool,
                groupCode: String? = nil, tournamentMatchId: String? = nil) {
        var entries = all()
        entries.removeAll { $0.code == code }
        entries.insert(TournamentHistoryEntry(
            code: code, name: name, gameType: gameType,
            lastDay: day, lastJoined: Date(), isOrganizer: isOrganizer,
            groupCode: groupCode, tournamentMatchId: tournamentMatchId
        ), at: 0)
        save(Array(entries.prefix(maxEntries)))
    }

    func all() -> [TournamentHistoryEntry] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let entries = try? JSONDecoder().decode([TournamentHistoryEntry].self, from: data)
        else { return [] }
        return entries
    }

    func remove(code: String) {
        var entries = all()
        entries.removeAll { $0.code == code }
        save(entries)
    }

    private func save(_ entries: [TournamentHistoryEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
