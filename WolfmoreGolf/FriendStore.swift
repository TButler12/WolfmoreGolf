import Foundation

final class FriendStore {

    var isTracked: Bool
  
    private init() {
        self.isTracked = false
        load()
    }

    func setTracked(friendID: UUID, isTracked: Bool) {
        guard let idx = friends.firstIndex(where: { $0.id == friendID }) else { return }
        friends[idx].isTracked = isTracked
        resort()
    }

    static let shared = FriendStore()
    private let defaultsKey = "friends.v1"

    // Anyone can read, only FriendStore can change.
    private(set) var friends: [Friend] = [] {
        didSet { save() }
    }
    

    var preselectedCount: Int {
        friends.filter { $0.preselectForRound }.count
    }
   
    

    // MARK: - CRUD (Core)

    func upsert(_ friend: Friend) {
        if let idx = friends.firstIndex(where: { $0.id == friend.id }) {
            friends[idx] = friend
        } else {
            friends.append(friend)
        }
        resort()
    }

    func remove(friendID: UUID) {
        friends.removeAll { $0.id == friendID }
        // didSet -> save()
    }

    // MARK: - Add

    /// Old call sites that used `add(_ name: String)` still work.
    func add(_ name: String) {
        add(name: name)
    }

    func add(name: String) {
        add(name: name, phone: "")
    }

    /// Manual add (Contacts screen or typing).
    /// De-dupes by *name* (case-insensitive) to preserve old behavior.
    func add(name: String, phone: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let key = trimmed.lowercased()
        if friends.contains(where: { $0.name.lowercased() == key }) { return }

        let cleanPhone = normalizePhone(phone)
        let newFriend = Friend(name: trimmed, phone: cleanPhone)
        friends.append(newFriend)
        resort()
    }

    /// Add a bunch of names (e.g. from current game card).
    func merge(names: [String]) {
        for n in names { add(name: n) }
    }

    // MARK: - Add / Import (Phone Contacts)

    /// For importing iPhone contacts. De-dupes by phone first, then name.
    func addOrMergeContact(name: String, phone: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let cleanPhone = normalizePhone(phone)

        // 1) Phone match → update name/phone (preferred)
        if !cleanPhone.isEmpty,
           let idx = friends.firstIndex(where: { normalizePhone($0.phone) == cleanPhone }) {

            friends[idx].phone = cleanPhone

            // Only update name if incoming looks better / not empty
            let current = friends[idx].name.trimmingCharacters(in: .whitespacesAndNewlines)
            if current.isEmpty {
                friends[idx].name = trimmedName
            }
            resort()
            return
        }

        // 2) Name match → fill phone if missing
        let key = trimmedName.lowercased()
        if let idx = friends.firstIndex(where: { $0.name.lowercased() == key }) {
            if friends[idx].phone.isEmpty, !cleanPhone.isEmpty {
                friends[idx].phone = cleanPhone
                resort()
            }
            return
        }

        // 3) Brand new
        let newFriend = Friend(name: trimmedName, phone: cleanPhone)
        friends.append(newFriend)
        resort()
    }

    // MARK: - Update (Manage Players)

    func update(friendID: UUID,
                defaultHC: Int? = nil,
                preselectForRound: Bool? = nil) {
        guard let idx = friends.firstIndex(where: { $0.id == friendID }) else { return }

        if let hc = defaultHC { friends[idx].defaultHC = hc }
        if let pre = preselectForRound { friends[idx].preselectForRound = pre }

        resort()
    }

    // MARK: - Update (Contacts)

    func updateContact(friendID: UUID,
                       name: String? = nil,
                       phone: String? = nil) {
        guard let idx = friends.firstIndex(where: { $0.id == friendID }) else { return }

        if let name {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { friends[idx].name = trimmed }
        }

        if let phone {
            friends[idx].phone = normalizePhone(phone)
        }

        resort()
    }

    func setFavorite(friendID: UUID, isFavorite: Bool) {
        guard let idx = friends.firstIndex(where: { $0.id == friendID }) else { return }
        friends[idx].isFavorite = isFavorite
        resort()
    }

    // MARK: - Persistence

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: defaultsKey),
            let decoded = try? JSONDecoder().decode([Friend].self, from: data)
        else {
            friends = []
            return
        }

        friends = decoded
        resort()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(friends) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    // MARK: - Sorting

    private func resort() {
        friends.sort {
            if $0.isFavorite != $1.isFavorite { return $0.isFavorite && !$1.isFavorite }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        // didSet -> save()
    }

    // MARK: - Phone Normalize (US-friendly)

    private func normalizePhone(_ s: String) -> String {
        let digits = s.filter(\.isNumber)
        if digits.count == 11, digits.first == "1" {
            return String(digits.dropFirst())
        }
        return digits
    }
}
