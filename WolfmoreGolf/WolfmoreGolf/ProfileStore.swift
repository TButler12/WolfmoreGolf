
import Foundation

enum ProfileStore {
    // MARK: - Name

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

    // MARK: - Home Course Tracking

    private static let homeCourseKey = "profile.homeCourseID"

    /// The course ID (UUID string) of the user's chosen "home / tracking" course.
    /// If nothing is set yet, we fall back to a default string.
    static var homeCourseID: String {
        get {
            UserDefaults.standard.string(forKey: homeCourseKey) ?? "HOME-COURSE"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: homeCourseKey)
        }
    }
}
