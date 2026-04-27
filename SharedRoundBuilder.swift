//
//  SharedRoundBuilder.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 4/10/26.
//
import Foundation

enum SharedRoundBuilder {

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
            courseName: g.course.name,
            pars: Array(g.course.pars.prefix(STANDARD_HOLES)),
            hcs: Array(g.course.holeHandicaps.prefix(STANDARD_HOLES)),
            scores: scores as! [Int],
            fairways: fairways,
            girs: girs,
            putts: putts,
            courseHandicap: playerIndex < g.hcPlayers.count ? g.hcPlayers[playerIndex] : 0

        )
    }
}
