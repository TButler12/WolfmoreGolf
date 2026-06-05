//
//  SharedRoundBuilder.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 4/10/26.
//
import Foundation

enum SharedRoundBuilder {

    private static func resolvedCourseName(from g: GameData) -> String {
        let stored = g.course.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return (stored.isEmpty || stored == "WolfMore") ? "Custom Course" : stored
    }

    static func make(from g: GameData, playerIndex: Int) -> SharedRound {
        let scores: [Int?] = (0..<STANDARD_HOLES).map { hole in
            guard playerIndex < g.scores.count,
                  hole < g.scores[playerIndex].count else { return nil }
            return g.scores[playerIndex][hole]
        }

        let fairways: [Bool?] = (0..<STANDARD_HOLES).map { hole in
            guard playerIndex < g.fairwayHit.count,
                  hole < g.fairwayHit[playerIndex].count else { return nil }
            return g.fairwayHit[playerIndex][hole]
        }

        let girs: [Bool?] = (0..<STANDARD_HOLES).map { hole in
            guard playerIndex < g.girHit.count,
                  hole < g.girHit[playerIndex].count else { return nil }
            return g.girHit[playerIndex][hole]
        }

        let putts: [Int?] = (0..<STANDARD_HOLES).map { hole in
            guard playerIndex < g.puttsPerHole.count,
                  hole < g.puttsPerHole[playerIndex].count else { return nil }
            return g.puttsPerHole[playerIndex][hole]
        }

        return SharedRound(
            playerName: playerIndex < g.playerNames.count ? g.playerNames[playerIndex] : "Player",
            courseName: resolvedCourseName(from: g),
            pars: Array(g.course.pars.prefix(STANDARD_HOLES)),
            hcs: Array(g.course.holeHandicaps.prefix(STANDARD_HOLES)),
            scores: scores,
            fairways: fairways,
            girs: girs,
            putts: putts,
            courseHandicap: playerIndex < g.hcPlayers.count ? g.hcPlayers[playerIndex] : 0
        )
    }

    // Identity-only round: preserves name/course/HC but no scores.
    // Used when accepting a challenge before playing your round.
    static func makeIdentity(from g: GameData, playerIndex: Int) -> SharedRound {
        SharedRound(
            playerName: playerIndex < g.playerNames.count ? g.playerNames[playerIndex] : "Player",
            courseName: resolvedCourseName(from: g),
            pars: Array(g.course.pars.prefix(STANDARD_HOLES)),
            hcs: Array(g.course.holeHandicaps.prefix(STANDARD_HOLES)),
            scores: [],
            fairways: [],
            girs: [],
            putts: [],
            courseHandicap: playerIndex < g.hcPlayers.count ? g.hcPlayers[playerIndex] : 0
        )
    }
}
