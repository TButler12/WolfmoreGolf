import Foundation

final class ResetSnapshotStore {
    static let shared = ResetSnapshotStore()

    private let key = "resetGameSnapshot_v1"
    private let expirySeconds: TimeInterval = 86_400 // 24 hours

    private init() {}

    struct Entry: Codable {
        let gameData: GameData
        let savedAt: Date
    }

    func save(_ gameData: GameData) {
        let entry = Entry(gameData: gameData, savedAt: Date())
        guard let data = try? JSONEncoder().encode(entry) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    func load() -> Entry? {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let entry = try? JSONDecoder().decode(Entry.self, from: data)
        else { return nil }
        if Date().timeIntervalSince(entry.savedAt) > expirySeconds {
            discard()
            return nil
        }
        return entry
    }

    func discard() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    func restore() {
        guard let entry = load() else { return }
        GameManager.shared.currentGame = entry.gameData
        GameManager.shared.saveCurrent()
        discard()
    }
}
