import Foundation
import Supabase

enum AnalyticsService {

    static func track(_ event: String, properties: [String: Any] = [:]) {
        #if DEBUG
        let propString = properties.isEmpty ? "" : " \(properties)"
        print("[Analytics] \(event)\(propString)")
        #endif

        let appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "unknown"

        Task {
            do {
                try await SupabaseService.shared.client
                    .from("analytics_events")
                    .insert([
                        "event_name":  AnyJSON.string(event),
                        "user_id":     AnyJSON.string(DeviceID.id),
                        "properties":  AnyJSON.object(properties.mapValues { toAnyJSON($0) }),
                        "app_version": AnyJSON.string(appVersion),
                    ] as [String: AnyJSON])
                    .execute()
            } catch {
                #if DEBUG
                print("[Analytics] insert failed: \(error)")
                #endif
            }
        }
    }

    private static func toAnyJSON(_ value: Any) -> AnyJSON {
        switch value {
        case let b as Bool:             return .bool(b)
        case let i as Int:              return .integer(i)
        case let d as Double:           return .double(d)
        case let s as String:           return .string(s)
        case let arr as [Any]:          return .array(arr.map { toAnyJSON($0) })
        case let dict as [String: Any]: return .object(dict.mapValues { toAnyJSON($0) })
        default:                        return .string("\(value)")
        }
    }
}
