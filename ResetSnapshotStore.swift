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

    /// Set after a successful save so the home screen can animate the banner in on next appearance.
    var needsAttentionOnNextAppearance = false

    /// Saves a snapshot using the best available source of current game data.
    /// Call this from any confirmation handler before wiping the game.
    func saveFromCurrentGame() {
        // 1. In-memory game — fastest path
        if let g = GameManager.shared.currentGame {
            save(g); needsAttentionOnNextAppearance = true; return
        }
        // 2. Not in memory — try loading from disk first
        if GameManager.shared.loadLastOpened(notify: false),
           let g = GameManager.shared.currentGame {
            save(g); needsAttentionOnNextAppearance = true; return
        }
        // 3. Final fallback: deserialize currentGame_v1 directly
        if let data = UserDefaults.standard.data(forKey: "currentGame_v1"),
           let g = try? JSONDecoder().decode(GameData.self, from: data) {
            save(g); needsAttentionOnNextAppearance = true
        }
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
