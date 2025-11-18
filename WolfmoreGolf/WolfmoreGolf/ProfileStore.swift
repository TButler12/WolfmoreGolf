import Foundation

enum ProfileStore {
    private static let key = "profile.myName"

    static var name: String? {
        get { getName() }
        set { set(name: newValue) }
    }

    static func set(name: String?) {
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmed.isEmpty {
            UserDefaults.standard.removeObject(forKey: key)
        } else {
            UserDefaults.standard.set(trimmed, forKey: key)
        }
    }

    static func getName() -> String? {
        let v = UserDefaults.standard.string(forKey: key)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (v?.isEmpty == false) ? v : nil
    }
}
