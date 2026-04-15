//
//  RemoteRoundCodec.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 4/9/26.
//

import Foundation

enum RemoteRoundCodec {

    static func encode(_ round: SharedRound) -> String? {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(round) else { return nil }
        return "WOLFMORE_REMOTE_NASSAU:" + data.base64EncodedString()
    }

    static func decode(_ string: String) -> SharedRound? {
        let cleaned = string
            .replacingOccurrences(of: "WOLFMORE_REMOTE_NASSAU:", with: "")
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()

        guard let data = Data(base64Encoded: cleaned) else { return nil }
        return try? JSONDecoder().decode(SharedRound.self, from: data)
    }
}
