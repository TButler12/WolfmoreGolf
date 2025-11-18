//
//  OwnerSeat.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 11/9/25.

import Foundation

// Normalize names so " TJ  BUTLER " == "tj butler"
private extension String {
    var normalizedPlayerName: String {
        self.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}

extension GameManager {
    /// Returns the seat index (0…8) of the current device's owner if found **and active**; else nil.
    func ownerSeatIndex() -> Int? {
        guard let g = currentGame,
              let whoRaw = ProfileStore.name, !whoRaw.isEmpty else { return nil }

        let who = whoRaw.normalizedPlayerName
        let seats = min(9, min(g.playerNames.count, g.playerActivated.count))

        for i in 0..<seats {
            let name = g.playerNames[i].normalizedPlayerName
            if g.playerActivated[i], !name.isEmpty, name == who {
                return i
            }
        }
        return nil
    }

    /// Convenience flag
    var isOwnerActive: Bool { ownerSeatIndex() != nil }
}
