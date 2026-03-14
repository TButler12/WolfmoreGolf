//
//  NassauEngine.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 3/13/26.
//
//
//  NassauEngine.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 3/13/26.
//

import Foundation

var holeCommitted: [Bool] = Array(repeating: false, count: 18)

enum NassauEngine {

    // MARK: - Handicap Pops

    static func pops(for delta: Int, strokeIndex si: Int) -> Int {
        let d = max(0, delta)
        if d <= 18 { return (si <= d) ? 1 : 0 }
        return 1 + ((si <= (d - 18)) ? 1 : 0)
    }

    // MARK: - State Builders

    static func makeDefaultState(
        playerNames: [String],
        activeFlags: [Bool]
    ) -> NassauState {
        var state = NassauState(
            isEnabled: true,
            defaultStake: 1.0,
            autoPressEnabled: true,
            autoPressTriggerDown: 2,
            oneVsOneMatches: [],
            twoVsTwoMatches: []
        )

        let seats = min(playerNames.count, activeFlags.count)

        let activePlayers = (0..<seats).filter { idx in
            activeFlags[idx] &&
            !playerNames[idx].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        // All 1v1 combinations
        for i in 0..<activePlayers.count {
            for j in (i + 1)..<activePlayers.count {
                let a = activePlayers[i]
                let b = activePlayers[j]

                let aName = playerNames[a].isEmpty ? "P\(a + 1)" : playerNames[a]
                let bName = playerNames[b].isEmpty ? "P\(b + 1)" : playerNames[b]

                state.oneVsOneMatches.append(
                    NassauMatch(
                        title: "\(aName) vs \(bName)",
                        format: .oneVsOne,
                        team1PlayerIndexes: [a],
                        team2PlayerIndexes: [b],
                        scoringMode: .net,
                        stake: state.defaultStake,
                        autoPressEnabled: state.autoPressEnabled,
                        autoPressTriggerDown: state.autoPressTriggerDown
                    )
                )
            }
        }

        // Optional default 2v2 for first four active players
        if activePlayers.count >= 4 {
            let a = activePlayers[0]
            let b = activePlayers[1]
            let c = activePlayers[2]
            let d = activePlayers[3]

            let aName = playerNames[a].isEmpty ? "P\(a + 1)" : playerNames[a]
            let bName = playerNames[b].isEmpty ? "P\(b + 1)" : playerNames[b]
            let cName = playerNames[c].isEmpty ? "P\(c + 1)" : playerNames[c]
            let dName = playerNames[d].isEmpty ? "P\(d + 1)" : playerNames[d]

            state.twoVsTwoMatches.append(
                NassauMatch(
                    title: "\(aName),\(bName) vs \(cName),\(dName)",
                    format: .twoVsTwo,
                    team1PlayerIndexes: [a, b],
                    team2PlayerIndexes: [c, d],
                    scoringMode: .net,
                    stake: state.defaultStake,
                    autoPressEnabled: state.autoPressEnabled,
                    autoPressTriggerDown: state.autoPressTriggerDown
                )
            )
        }

        return state
    }
    
    static func makeAllOneVsOneMatches(
        playerNames: [String],
        activeFlags: [Bool],
        scoringMode: NassauScoringMode = .net,
        stake: Double = 1.0,
        autoPressEnabled: Bool = true,
        autoPressTriggerDown: Int = 2
    ) -> [NassauMatch] {
        let seats = min(playerNames.count, activeFlags.count)

        let activePlayers = (0..<seats).filter { idx in
            activeFlags[idx] &&
            !playerNames[idx].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        var matches: [NassauMatch] = []

        for i in 0..<activePlayers.count {
            for j in (i + 1)..<activePlayers.count {
                let a = activePlayers[i]
                let b = activePlayers[j]

                let aName = playerNames[a].isEmpty ? "P\(a + 1)" : playerNames[a]
                let bName = playerNames[b].isEmpty ? "P\(b + 1)" : playerNames[b]

                matches.append(
                    NassauMatch(
                        title: "\(aName) vs \(bName)",
                        format: .oneVsOne,
                        team1PlayerIndexes: [a],
                        team2PlayerIndexes: [b],
                        scoringMode: scoringMode,
                        stake: stake,
                        autoPressEnabled: autoPressEnabled,
                        autoPressTriggerDown: autoPressTriggerDown
                    )
                )
            }
        }

        return matches
    }

    static func makeDefaultTwoVsTwoMatches(
        playerNames: [String],
        activeFlags: [Bool],
        scoringMode: NassauScoringMode = .net,
        stake: Double = 1.0,
        autoPressEnabled: Bool = true,
        autoPressTriggerDown: Int = 2
    ) -> [NassauMatch] {
        let seats = min(playerNames.count, activeFlags.count)

        let activePlayers = (0..<seats).filter { idx in
            activeFlags[idx] &&
            !playerNames[idx].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        guard activePlayers.count >= 4 else { return [] }

        let a = activePlayers[0]
        let b = activePlayers[1]
        let c = activePlayers[2]
        let d = activePlayers[3]

        let t1a = playerNames[a].isEmpty ? "P\(a + 1)" : playerNames[a]
        let t1b = playerNames[b].isEmpty ? "P\(b + 1)" : playerNames[b]
        let t2a = playerNames[c].isEmpty ? "P\(c + 1)" : playerNames[c]
        let t2b = playerNames[d].isEmpty ? "P\(d + 1)" : playerNames[d]

        return [
            NassauMatch(
                title: "\(t1a),\(t1b) vs \(t2a),\(t2b)",
                format: .twoVsTwo,
                team1PlayerIndexes: [a, b],
                team2PlayerIndexes: [c, d],
                scoringMode: scoringMode,
                stake: stake,
                autoPressEnabled: autoPressEnabled,
                autoPressTriggerDown: autoPressTriggerDown
            )
        ]
    }

    // MARK: - Recalculate State

    static func recalculate(state: inout NassauState, gameData: GameData) {
        state.oneVsOneMatches = state.oneVsOneMatches.map {
            recalculate(match: $0, gameData: gameData)
        }

        state.twoVsTwoMatches = state.twoVsTwoMatches.map {
            recalculate(match: $0, gameData: gameData)
        }
    }

    static func recalculate(match: NassauMatch, gameData: GameData) -> NassauMatch {
        var updated = match

        updated.frontStatusByHole = runningStatus(
            gameData: gameData,
            match: updated,
            startHole: 0,
            endHole: 8
        )

        updated.backStatusByHole = runningStatus(
            gameData: gameData,
            match: updated,
            startHole: 9,
            endHole: 17
        )

        updated.overallStatusByHole = runningStatus(
            gameData: gameData,
            match: updated,
            startHole: 0,
            endHole: 17
        )

        updated.presses = buildAutoPresses(for: updated).map { press in
            var p = press
            p.runningStatus = runningStatusForPress(
                gameData: gameData,
                match: updated,
                startHole: press.startHole,
                endHole: press.endHole
            )
            return p
        }

        return updated
    }

    // MARK: - Segment Status

    static func runningStatus(
        gameData: GameData,
        match: NassauMatch,
        startHole: Int,
        endHole: Int
    ) -> [Int] {
        guard startHole <= endHole else { return [] }

        var results: [Int] = []
        var current = 0

        for hole in startHole...endHole {
            guard hole < holeCommitted.count, holeCommitted[hole] else { continue }

            let winner = winnerForHole(
                gameData: gameData,
                holeIndex: hole,
                match: match
            )

            if winner == 1 {
                current += 1
            } else if winner == -1 {
                current -= 1
            }

            results.append(current)
        }

        return results
    }

    static func runningStatusForPress(
        gameData: GameData,
        match: NassauMatch,
        startHole: Int,
        endHole: Int
    ) -> [Int] {
        guard startHole >= 1, endHole >= startHole else { return [] }

        var results: [Int] = []
        var current = 0

        for hole1Based in startHole...endHole {
            let holeIndex = hole1Based - 1
            guard holeIndex < holeCommitted.count, holeCommitted[holeIndex] else { continue }

            let winner = winnerForHole(
                gameData: gameData,
                holeIndex: holeIndex,
                match: match
            )

            if winner == 1 {
                current += 1
            } else if winner == -1 {
                current -= 1
            }

            results.append(current)
        }

        return results
    }

    // MARK: - Hole Winner

    static func winnerForHole(
        gameData: GameData,
        holeIndex: Int,
        match: NassauMatch
    ) -> Int {
        let team1 = scoreForTeam(
            gameData: gameData,
            holeIndex: holeIndex,
            playerIndexes: match.team1PlayerIndexes,
            match: match
        )

        let team2 = scoreForTeam(
            gameData: gameData,
            holeIndex: holeIndex,
            playerIndexes: match.team2PlayerIndexes,
            match: match
        )

        print("MATCH \(match.title) H\(holeIndex + 1) team1=\(String(describing: team1)) team2=\(String(describing: team2))")

        guard let t1 = team1, let t2 = team2 else { return 0 }
        if t1 < t2 { return 1 }
        if t2 < t1 { return -1 }
        return 0
    }

    // MARK: - Team / Player Scoring

    static func scoreForTeam(
        gameData: GameData,
        holeIndex: Int,
        playerIndexes: [Int],
        match: NassauMatch
    ) -> Int? {
        let scores = playerIndexes.compactMap {
            scoreForPlayer(
                gameData: gameData,
                playerIndex: $0,
                holeIndex: holeIndex,
                scoringMode: match.scoringMode,
                match: match
            )
        }

        switch match.format {
        case .oneVsOne:
            guard scores.count == 1 else { return nil }
            return scores.first

        case .twoVsTwo:
            guard scores.count == playerIndexes.count else { return nil }
            return scores.min()   // best ball
        }
    }

    static func safeScore(
        gameData: GameData,
        playerIndex: Int,
        holeIndex: Int
    ) -> Int? {
        guard playerIndex >= 0,
              playerIndex < gameData.scores.count,
              holeIndex >= 0,
              holeIndex < gameData.scores[playerIndex].count else {
            return nil
        }

        return gameData.scores[playerIndex][holeIndex]
    }

    static func strokesGiven(
        gameData: GameData,
        playerIndex: Int,
        holeIndex: Int,
        match: NassauMatch
    ) -> Int {
        let rawSI = gameData.course.holeHandicaps[safe: holeIndex] ?? 18
        let si = max(1, min(18, rawSI == 0 ? 18 : rawSI))

        let participants = Array(Set(match.team1PlayerIndexes + match.team2PlayerIndexes))
            .filter { idx in
                idx >= 0 &&
                idx < gameData.hcPlayers.count &&
                idx < gameData.playerActivated.count &&
                idx < gameData.playerNames.count &&
                gameData.playerActivated[idx] &&
                !gameData.playerNames[idx].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }

        let baseHC = participants.map { gameData.hcPlayers[$0] }.min() ?? 0
        let delta = max(0, gameData.hcPlayers[playerIndex] - baseHC)

        return pops(for: delta, strokeIndex: si)
    }

    static func scoreForPlayer(
        gameData: GameData,
        playerIndex: Int,
        holeIndex: Int,
        scoringMode: NassauScoringMode,
        match: NassauMatch
    ) -> Int? {
        guard let gross = safeScore(
            gameData: gameData,
            playerIndex: playerIndex,
            holeIndex: holeIndex
        ) else {
            return nil
        }

        switch scoringMode {
        case .gross:
            return gross

        case .net:
            let pops = strokesGiven(
                gameData: gameData,
                playerIndex: playerIndex,
                holeIndex: holeIndex,
                match: match
            )
            let net = gross - pops

            let name = (playerIndex < gameData.playerNames.count)
                ? gameData.playerNames[playerIndex]
                : "P\(playerIndex + 1)"

            print("NASSAU H\(holeIndex + 1) \(name) gross=\(gross) pops=\(pops) net=\(net)")
            return net
        }
    }

    // MARK: - Auto Press

    static func buildAutoPresses(for match: NassauMatch) -> [NassauPress] {
        guard match.autoPressEnabled else { return [] }

        var presses: [NassauPress] = []

        presses.append(
            contentsOf: buildPressesForSegment(
                match: match,
                segment: .front,
                status: match.frontStatusByHole,
                holeOffset: 0,
                trigger: match.autoPressTriggerDown
            )
        )

        presses.append(
            contentsOf: buildPressesForSegment(
                match: match,
                segment: .back,
                status: match.backStatusByHole,
                holeOffset: 9,
                trigger: match.autoPressTriggerDown
            )
        )

        return presses
    }

    static func buildPressesForSegment(
        match: NassauMatch,
        segment: NassauSegment,
        status: [Int],
        holeOffset: Int,
        trigger: Int
    ) -> [NassauPress] {
        var previousAbs = 0

        for (idx, value) in status.enumerated() {
            let currentAbs = abs(value)

            if previousAbs < trigger && currentAbs >= trigger {
                let actualHole = holeOffset + idx
                let startHole = actualHole + 1

                let endHole: Int
                switch segment {
                case .front:
                    endHole = 8
                case .back:
                    endHole = 17
                case .overall:
                    endHole = 17
                }

                if startHole <= endHole {
                    return [
                        NassauPress(
                            segment: segment,
                            startHole: startHole,
                            endHole: endHole,
                            team1PlayerIndexes: match.team1PlayerIndexes,
                            team2PlayerIndexes: match.team2PlayerIndexes,
                            stake: match.stake,
                            runningStatus: []
                        )
                    ]
                }
            }

            previousAbs = currentAbs
        }

        return []
    }
}
