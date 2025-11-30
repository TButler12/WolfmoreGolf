import Foundation

final class FriendStore {
    static let shared = FriendStore()
    private let defaultsKey = "friends.v1"

    // Anyone can read, only FriendStore can change.
    private(set) var friends: [Friend] = [] {
        didSet { save() }
    }
    var preselectedCount: Int {
           friends.filter { $0.preselectForRound }.count
       }

    private init() {
        load()
    }

    // MARK: - Persistence

    private func load() {
        if let d = UserDefaults.standard.data(forKey: defaultsKey),
           let f = try? JSONDecoder().decode([Friend].self, from: d) {
            friends = f.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        } else {
            friends = []
        }
    }

    private func save() {
        if let d = try? JSONEncoder().encode(friends) {
            UserDefaults.standard.set(d, forKey: defaultsKey)
        }
    }

    // MARK: - Add

    /// Old call sites that used `add(_ name: String)` still work.
    func add(_ name: String) {
        add(name: name)
    }

    /// Main add that trims, avoids duplicates, and sorts.
    func add(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let key = trimmed.lowercased()
        if friends.contains(where: { $0.name.lowercased() == key }) { return }

        let newFriend = Friend(name: trimmed)   // defaultHC = 0, preselectForRound = false
        friends.append(newFriend)
        friends.sort {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        // didSet on friends calls save()
    }

    /// Add a bunch of names (e.g. from current game card).
    func merge(names: [String]) {
        for n in names {
            add(name: n)
        }
    }

    // MARK: - Remove

    func remove(friendID: UUID) {
        friends.removeAll { $0.id == friendID }
        // didSet -> save()
    }

    // MARK: - Update

    /// Update one friend’s fields (used by ManagePlayersVC).
    func update(friendID: UUID,
                defaultHC: Int? = nil,
                preselectForRound: Bool? = nil) {
        guard let idx = friends.firstIndex(where: { $0.id == friendID }) else { return }

        if let hc = defaultHC {
            friends[idx].defaultHC = hc
        }
        if let pre = preselectForRound {
            friends[idx].preselectForRound = pre
        }
        // Changing an element of `friends` also triggers didSet -> save()
    }
}

