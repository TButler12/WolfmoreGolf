//
//  RemoteMatchStore.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 4/13/26.
//
import Foundation

final class RemoteMatchStore {
    static let shared = RemoteMatchStore()

    private let key = "remote_matches_v1"
    private(set) var matches: [RemoteMatch] = []

    private init() {
        load()
    }

    func load() {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode([RemoteMatch].self, from: data)
        else {
            matches = []
            return
            
        }
        matches = decoded
        sortMatches()

    }

    func save() {
        guard let data = try? JSONEncoder().encode(matches) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    func add(_ match: RemoteMatch) {
       
        matches.append(match)
        sortMatches()
        save()
    }

    func update(_ match: RemoteMatch) {
        guard let index = matches.firstIndex(where: { $0.id == match.id }) else { return }
        matches[index] = match
        sortMatches()
        save()
       
    }
    func all() -> [RemoteMatch] {
        matches
    }
    func remove(matchID: UUID) {
        matches.removeAll { $0.id == matchID }
        save()
    }
    func attachOpponentRound(_ round: SharedRound, to matchID: UUID) {
        guard var match = match(with: matchID) else { return }
        match.opponentRound = round
        update(match)
    }
    func match(with id: UUID) -> RemoteMatch? {
        matches.first { $0.id == id }
    }
    private func sortMatches() {
        matches.sort { $0.createdAt > $1.createdAt }
    }
}
