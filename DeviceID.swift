import Foundation
import Security

// Keychain-backed persistent device UUID.
// Survives app reinstalls; used as created_by for tournament organizer gating.
enum DeviceID {

    static var id: String { read() ?? create() }

    private static let service = "com.wolfmore.golf"
    private static let account = "device.uuid"

    private static func read() -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrService:      service,
            kSecAttrAccount:      account,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let uuid = String(data: data, encoding: .utf8) else { return nil }
        return uuid
    }

    @discardableResult
    private static func create() -> String {
        let uuid = UUID().uuidString
        let data = Data(uuid.utf8)
        let attrs: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData:   data,
            // accessible after first unlock so background tasks can read it
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        SecItemAdd(attrs as CFDictionary, nil)
        return uuid
    }
}
