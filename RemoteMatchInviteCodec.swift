//
//  RemoteMatchInviteCodec.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 4/13/26.
//

import Foundation

enum RemoteMatchInviteCodec {

    static func encode(_ invite: RemoteMatchInvite) -> String? {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(invite) else { return nil }
        return "WOLFMORE_REMOTE_INVITE:" + data.base64EncodedString()
    }

    static func decode(_ string: String) -> RemoteMatchInvite? {
        let cleaned = string
            .replacingOccurrences(of: "WOLFMORE_REMOTE_INVITE:", with: "")
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()

        guard let data = Data(base64Encoded: cleaned) else { return nil }
        return try? JSONDecoder().decode(RemoteMatchInvite.self, from: data)
    }
}
