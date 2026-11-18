import Foundation

final class ResetSnapshotStore {
    static let shared = ResetSnapshotStore()

    private let key = "resetGameSnapshots_v2"
    private let maxEntries = 5

    private init() {}

    struct Entry: Codable, Identifiable {
        let id: UUID
        let gameData: GameData
        let savedAt: Date
    }

    /// Set after a successful save so the home screen can animate the banner in on next appearance.
    var needsAttentionOnNextAppearance = false

    // MARK: - Persistence

    private func loadAll() -> [Entry] {
        guard let raw = UserDefaults.standard.data(forKey: key) else { return [] }

        // Fast path: data already contains all required fields (saves from 3.2.1+).
        if let entries = try? JSONDecoder().decode([Entry].self, from: raw) { return entries }

        // Slow path: patch GameData within each entry for pre-3.2.1 saves.
        // GameData.migrate() injects default values for fields added after 3.1.5.
        guard var arr = (try? JSONSerialization.jsonObject(with: raw)) as? [[String: Any]] else {
            rescueSnapshot(raw)
            return []
        }
        arr = arr.map { entry in
            var e = entry
            if var gd = e["gameData"] as? [String: Any] {
                if gd["holeReversed"] == nil {
                    gd["holeReversed"] = Array(repeating: false, count: STANDARD_HOLES)
                    e["gameData"] = gd
                }
            }
            return e
        }
        guard let patched = try? JSONSerialization.data(withJSONObject: arr),
              let entries = try? JSONDecoder().decode([Entry].self, from: patched) else {
            rescueSnapshot(raw)
            return []
        }
        return entries
    }

    private func rescueSnapshot(_ raw: Data) {
        let rescueKey = key + "_rescue"
        if UserDefaults.standard.data(forKey: rescueKey) == nil {
            UserDefaults.standard.set(raw, forKey: rescueKey)
            print("📦 Snapshot store decode failed; raw bytes rescued to \(rescueKey)")
        }
    }

    private func saveAll(_ entries: [Entry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    // MARK: - Public API

    var hasSnapshots: Bool { !loadAll().isEmpty }

    func allEntries() -> [Entry] { loadAll() }

    func save(_ gameData: GameData) {
        let entry = Entry(id: UUID(), gameData: gameData, savedAt: Date())
        var entries = loadAll()
        entries.insert(entry, at: 0)
        if entries.count > maxEntries { entries = Array(entries.prefix(maxEntries)) }
        saveAll(entries)
    }

    /// Saves a snapshot using the best available source of current game data.
    /// Call this from any confirmation handler before wiping the game.
    func saveFromCurrentGame() {
        if let g = GameManager.shared.currentGame {
            save(g); notifySnapshot(); return
        }
        if GameManager.shared.loadLastOpened(notify: false),
           let g = GameManager.shared.currentGame {
            save(g); notifySnapshot(); return
        }
        if let data = UserDefaults.standard.data(forKey: "currentGame_v1"),
           let g = try? JSONDecoder().decode(GameData.self, from: data) {
            save(g); notifySnapshot()
        }
    }

    private func notifySnapshot() {
        needsAttentionOnNextAppearance = true
        NotificationCenter.default.post(name: .snapshotSaved, object: nil)
    }

    /// Returns the most recent entry; used by the existing banner restore flow.
    func load() -> Entry? { loadAll().first }

    func remove(_ entry: Entry) {
        var entries = loadAll()
        entries.removeAll { $0.id == entry.id }
        saveAll(entries)
    }

    /// Removes the most recent entry; preserves existing banner/discard semantics.
    func discard() {
        var entries = loadAll()
        if !entries.isEmpty { entries.removeFirst() }
        saveAll(entries)
    }

    /// Restores the most recent snapshot; preserves existing banner restore flow.
    func restore() {
        guard let entry = load() else { return }
        restore(entry: entry)
    }

    func restore(entry: Entry) {
        GameManager.shared.currentGame = entry.gameData
        GameManager.shared.saveCurrent()
        remove(entry)
    }
}
