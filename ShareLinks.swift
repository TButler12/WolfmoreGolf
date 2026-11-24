import Foundation

enum ShareLinks {

    static let appStoreURL = "https://apps.apple.com/app/wolfmore-golf/id6451419388"

    static func joinClubEvent(code: String) -> String {
        "wolfmore://join?code=\(code.uppercased())"
    }

    static func watchLive(code: String) -> String {
        "wolfmore://watch?code=\(code.uppercased())"
    }

    static func clubEventShareText(eventName: String, courseName: String?, code: String) -> String {
        let courseStr = courseName.map { " at \($0)" } ?? ""
        return """
⛳ Join "\(eventName)"\(courseStr) on WolfMore Golf
Tap to join: \(joinClubEvent(code: code))
Or open WolfMore → Club Event → Join → enter \(code.uppercased())
Don't have WolfMore? \(appStoreURL)
"""
    }

    static func goLiveShareText(eventCode: String) -> String {
        """
Watching live on WolfMore Golf
Tap to watch: \(watchLive(code: eventCode))
Or open WolfMore → Watch Live → enter \(eventCode.uppercased())
Don't have WolfMore? \(appStoreURL)
"""
    }

    static func goLiveAndJoinShareText(eventCode: String, joinCode: String) -> String {
        """
Watch or score live on WolfMore Golf
Scorers tap: \(joinClubEvent(code: joinCode))
Viewers tap: \(watchLive(code: eventCode))
Don't have WolfMore? \(appStoreURL)
"""
    }
}
