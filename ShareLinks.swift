import Foundation

enum ShareLinks {

    static let appStoreURL = "https://apps.apple.com/us/app/wolfmore-golf/id6755116882"

    static func joinClubEvent(code: String) -> String {
        "wolfmore://join?code=\(code.uppercased())"
    }

    static func watchLive(code: String) -> String {
        "wolfmore://watch?code=\(code.uppercased())"
    }

    // Human-readable text only — pass the deep-link URL as a separate activityItem alongside this.
    static func clubEventShareText(eventName: String, courseName: String?, code: String) -> String {
        let courseStr = courseName.map { " at \($0)" } ?? ""
        return "⛳ Join \"\(eventName)\"\(courseStr) on WolfMore Golf. Code: \(code.uppercased())\nDon't have WolfMore Golf? \(appStoreURL)"
    }
}
