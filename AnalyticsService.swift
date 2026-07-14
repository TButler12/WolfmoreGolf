import Foundation

/// Lightweight analytics stub. All calls are no-ops in production until a real
/// backend (PostHog, Amplitude, etc.) is wired in — swap the implementation here.
enum AnalyticsService {

    static func track(_ event: String, properties: [String: Any] = [:]) {
        #if DEBUG
        let propString = properties.isEmpty ? "" : " \(properties)"
        print("[Analytics] \(event)\(propString)")
        #endif
        // TODO: forward to real analytics backend
    }
}
