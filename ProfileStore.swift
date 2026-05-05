
import Foundation

enum ProfileStore {

    // MARK: - Name
    private static let nameKey = "profile.myName"

    static var name: String? {
        get {
            let v = (UserDefaults.standard.string(forKey: nameKey) ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return v.isEmpty ? nil : v
        }
        set {
            let trimmed = (newValue ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                UserDefaults.standard.removeObject(forKey: nameKey)
            } else {
                UserDefaults.standard.set(trimmed, forKey: nameKey)
            }
        }
    }

    // MARK: - My HC / Preselect
    private static let myHCKey = "profile.myHC"
    static var myHC: Int {
        get { UserDefaults.standard.integer(forKey: myHCKey) }
        set { UserDefaults.standard.set(newValue, forKey: myHCKey) }
    }

    private static let myPreselectKey = "profile.myPreselect"
    static var myPreselectForRound: Bool {
        get { UserDefaults.standard.bool(forKey: myPreselectKey) }
        set { UserDefaults.standard.set(newValue, forKey: myPreselectKey) }
    }

    // MARK: - Home Course
    private static let homeCourseKey = "profile.homeCourseID"

    /// Empty string = not set yet.
    static var homeCourseID: String {
        get { UserDefaults.standard.string(forKey: homeCourseKey) ?? "" }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                UserDefaults.standard.removeObject(forKey: homeCourseKey)
            } else {
                UserDefaults.standard.set(trimmed, forKey: homeCourseKey)
            }
        }
    }

    static var hasHomeCourse: Bool {
        UUID(uuidString: homeCourseID) != nil
    }

    // MARK: - One-time prompt flag
    private static let didPromptHomeCourseKey = "profile.didPromptHomeCourse_v1"

    static var didPromptHomeCourse: Bool {
        get { UserDefaults.standard.bool(forKey: didPromptHomeCourseKey) }
        set { UserDefaults.standard.set(newValue, forKey: didPromptHomeCourseKey) }
    }
}
