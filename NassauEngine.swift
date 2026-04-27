
//  NassauEngine.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 3/13/26.
//

import Foundation

enum NassauEngine {

    // MARK: - Final Summary

    static func finalSummaries(
        state: NassauState,
        playerNames: [String],
        gameData: GameData
    ) -> [NassauMatchFinalSummary] {
        let oneVsOne = state.oneVsOneMatches.map {
            finalSummary(for: $0, playerNames: playerNames, gameData: gameData)
        }

        let twoVsTwo = state.twoVsTwoMatches.map {
            finalSummary(for: $0, playerNames: playerNames, gameData: gameData)
        }

        return oneVsOne + twoVsTwo
    }

    static func finalSummary(
        for match: NassauMatch,
        playerNames: [String],
        gameData: GameData
    ) -> NassauMatchFinalSummary {

        let team1Display = displayNames(
            for: match.team1PlayerIndexes,
            playerNames: playerNames
        )

        let team2Display = displayNames(
            for: match.team2PlayerIndexes,
            playerNames: playerNames
        )

        let front9 = summarizeSegment(
            title: "Front 9",
            status: match.frontStatusByHole,
            team1Display: team1Display,
            team2Display: team2Display,
            stake: match.stake,
            segmentIsComplete: isFrontComplete(gameData: gameData)
        )

        let back9 = summarizeSegment(
            title: "Back 9",
            status: match.backStatusByHole,
            team1Display: team1Display,
            team2Display: team2Display,
            stake: match.stake,
            segmentIsComplete: isBackComplete(gameData: gameData)
        )

        let overall18 = summarizeSegment(
            title: "18 Hole",
            status: match.overallStatusByHole,
            team1Display: team1Display,
            team2Display: team2Display,
            stake: match.stake,
            segmentIsComplete: isOverallComplete(gameData: gameData)
        )

        let presses: [NassauPressSummary] = match.presses.enumerated().map { index, press in
            summarizePress(
                press: press,
                index: index,
                team1Display: team1Display,
                team2Display: team2Display,
                isComplete: isPressComplete(press, gameData: gameData)
            )
        }

        let totalMoney =
            (front9?.moneyDelta ?? 0) +
            (back9?.moneyDelta ?? 0) +
            (overall18?.moneyDelta ?? 0) +
            presses.reduce(0) { $0 + $1.moneyDelta }

        return NassauMatchFinalSummary(
            matchTitle: match.title,
            team1Display: team1Display,
            team2Display: team2Display,
            front9: front9,
            back9: back9,
            overall18: overall18,
            presses: presses,
            totalMoneyDelta: totalMoney,
            totalMoneyText: moneyText(
                delta: totalMoney,
                team1: team1Display,
                team2: team2Display
            )
        )
    }

    private static func summarizeSegment(
        title: String,
        status: [Int],
        team1Display: String,
        team2Display: String,
        stake: Double,
        segmentIsComplete: Bool
    ) -> NassauSegmentSummary? {
        guard !status.isEmpty else { return nil }

        var team1Wins = 0
        var team2Wins = 0
        var ties = 0
        var previous = 0

        for value in status {
            let delta = value - previous

            if delta > 0 {
                team1Wins += delta
            } else if delta < 0 {
                team2Wins += abs(delta)
            } else {
                ties += 1
            }

            previous = value
        }

        let final = status.last ?? 0
        let resultText: String
        let moneyDelta: Double

        if segmentIsComplete {
            if final > 0 {
                resultText = "\(team1Display) won \(final) up"
                moneyDelta = stake
            } else if final < 0 {
                resultText = "\(team2Display) won \(abs(final)) up"
                moneyDelta = -stake
            } else {
                resultText = "Halved"
                moneyDelta = 0
            }
        } else {
            if final > 0 {
                resultText = "\(team1Display) \(final) up"
            } else if final < 0 {
                resultText = "\(team2Display) \(abs(final)) up"
            } else {
                resultText = "All Square"
            }
            moneyDelta = 0
        }

        return NassauSegmentSummary(
            title: title,
            team1Display: team1Display,
            team2Display: team2Display,
            holesWonTeam1: team1Wins,
            holesWonTeam2: team2Wins,
            ties: ties,
            resultText: resultText,
            moneyDelta: moneyDelta
        )
    }

    private static func summarizePress(
        press: NassauPress,
        index: Int,
        team1Display: String,
        team2Display: String,
        isComplete: Bool
    ) -> NassauPressSummary {
        let final = press.runningStatus.last ?? 0
        let title = pressTitle(for: press, index: index)

        let resultText: String
        let moneyDelta: Double

        if isComplete {
            if final > 0 {
                resultText = "\(team1Display) won \(final) up"
                moneyDelta = press.stake
            } else if final < 0 {
                resultText = "\(team2Display) won \(abs(final)) up"
                moneyDelta = -press.stake
            } else {
                resultText = "Halved"
                moneyDelta = 0
            }
        } else {
            if final > 0 {
                resultText = "\(team1Display) \(final) up"
            } else if final < 0 {
                resultText = "\(team2Display) \(abs(final)) up"
            } else {
                resultText = "All Square"
            }
            moneyDelta = 0
        }

        return NassauPressSummary(
            title: title,
            resultText: resultText,
            moneyDelta: moneyDelta
        )
    }

    private static func pressTitle(
        for press: NassauPress,
        index: Int
    ) -> String {
        let number = index + 1

        switch press.segment {
        case .front:
            return "Front Press \(number)"
        case .back:
            return "Back Press \(number)"
        case .overall:
            return "Overall Press \(number)"
        }
    }

    // MARK: - Handicap Pops

    static func pops(for delta: Int, strokeIndex si: Int) -> Int {
        let d = max(0, delta)

        if d <= STANDARD_HOLES {
            return (si <= d) ? 1 : 0
        }

        return 1 + ((si <= (d - STANDARD_HOLES)) ? 1 : 0)
    }
   
    // MARK: - State Builders

    static func makeDefaultState(
        playerNames: [String],
        activeFlags: [Bool]
    ) -> NassauState {
        var state = NassauState(
            settings: NassauSettings(
                isEnabled: true,
                baseStake: 1.0,
                pressMode: .auto,
                autoPressTriggerDown: 2,
                pressStartRule: .nextHole,
                pressAmountMode: .sameAsBase,
                customPressStake: 1.0,
                maxPressesPerSegment: 3,
                allowOverallPresses: false
            ),
            oneVsOneMatches: [],
            twoVsTwoMatches: []
        )

        let seats = min(playerNames.count, activeFlags.count)

        let activePlayers = (0..<seats).filter { idx in
            activeFlags[idx] &&
            !playerNames[idx].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

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
                        stake: state.settings.baseStake
                    )
                )
            }
        }

        state.twoVsTwoMatches = makeDefaultTwoVsTwoMatches(
            playerNames: playerNames,
            activeFlags: activeFlags,
            scoringMode: .net,
            stake: state.settings.baseStake
        )

        return state
    }

    static func makeAllOneVsOneMatches(
        playerNames: [String],
        activeFlags: [Bool],
        scoringMode: NassauScoringMode = .net,
        stake: Double = 1.0
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
                        stake: stake
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
        stake: Double = 1.0
    ) -> [NassauMatch] {
        let seats = min(playerNames.count, activeFlags.count)

        let activePlayers = (0..<seats).filter { idx in
            activeFlags[idx] &&
            !playerNames[idx].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        guard activePlayers.count >= 4 else { return [] }

        let firstFour = Array(activePlayers.prefix(4))

        let a = firstFour[0]
        let b = firstFour[1]
        let c = firstFour[2]
        let d = firstFour[3]

        let aName = playerNames[a].isEmpty ? "P\(a + 1)" : playerNames[a]
        let bName = playerNames[b].isEmpty ? "P\(b + 1)" : playerNames[b]
        let cName = playerNames[c].isEmpty ? "P\(c + 1)" : playerNames[c]
        let dName = playerNames[d].isEmpty ? "P\(d + 1)" : playerNames[d]

        return [
            NassauMatch(
                title: "\(aName) & \(bName) vs \(cName) & \(dName)",
                format: .twoVsTwo,
                team1PlayerIndexes: [a, b],
                team2PlayerIndexes: [c, d],
                scoringMode: scoringMode,
                stake: stake
            ),
            NassauMatch(
                title: "\(aName) & \(cName) vs \(bName) & \(dName)",
                format: .twoVsTwo,
                team1PlayerIndexes: [a, c],
                team2PlayerIndexes: [b, d],
                scoringMode: scoringMode,
                stake: stake
            ),
            NassauMatch(
                title: "\(aName) & \(dName) vs \(bName) & \(cName)",
                format: .twoVsTwo,
                team1PlayerIndexes: [a, d],
                team2PlayerIndexes: [b, c],
                scoringMode: scoringMode,
                stake: stake
            )
        ]
    }

    // MARK: - Recalculate State

    static func recalculate(
        state: inout NassauState,
        gameData: GameData
    ) {
        state.oneVsOneMatches = state.oneVsOneMatches.map {
            recalculate(match: $0, state: state, gameData: gameData)
        }

        state.twoVsTwoMatches = state.twoVsTwoMatches.map {
            recalculate(match: $0, state: state, gameData: gameData)
        }
    }

    static func recalculate(
        match: NassauMatch,
        state: NassauState,
        gameData: GameData
    ) -> NassauMatch {
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

        switch updated.resolvedPressMode(using: state) {
        case .off:
            updated.presses = []

        case .auto:
            let manualPresses = updated.presses.filter { $0.createdManually }
            let autoPresses = buildAutoPresses(for: updated, state: state)
            updated.presses = manualPresses + autoPresses

        case .manual:
            updated.presses = updated.presses.filter { $0.createdManually }
        }

        updated.presses = updated.presses.map { press in
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
    static func canAddManualPress(
        match: NassauMatch,
        state: NassauState,
        segment: NassauSegment,
        currentHole1Based: Int
    ) -> Bool {
        guard match.resolvedPressMode(using: state) == .manual else { return false }

        let startRule = match.resolvedPressStartRule(using: state)
        let maxPresses = max(0, match.resolvedMaxPressesPerSegment(using: state))

        if maxPresses == 0 { return false }

        let existingCount = match.presses.filter { $0.segment == segment }.count
        if existingCount >= maxPresses { return false }

        let segmentEnd: Int
        switch segment {
        case .front: segmentEnd = 9
        case .back: segmentEnd = STANDARD_HOLES
        case .overall: segmentEnd = STANDARD_HOLES
        }

        let proposedStart: Int
        switch startRule {
        case .nextHole:
            proposedStart = currentHole1Based + 1
        case .currentHole:
            proposedStart = currentHole1Based
        }

        return proposedStart <= segmentEnd
    }

    static func addManualPress(
        to match: inout NassauMatch,
        state: NassauState,
        segment: NassauSegment,
        currentHole1Based: Int
    ) {
        guard canAddManualPress(
            match: match,
            state: state,
            segment: segment,
            currentHole1Based: currentHole1Based
        ) else { return }

        let startRule = match.resolvedPressStartRule(using: state)
        let pressStake = match.resolvedPressStake(using: state)

        let startHole: Int
        switch startRule {
        case .nextHole:
            startHole = currentHole1Based + 1
        case .currentHole:
            startHole = currentHole1Based
        }

        let endHole: Int
        switch segment {
        case .front:
            endHole = 9
        case .back:
            endHole = STANDARD_HOLES
        case .overall:
            endHole = STANDARD_HOLES
        }

        guard startHole <= endHole else { return }

        match.presses.append(
            NassauPress(
                segment: segment,
                startHole: startHole,
                endHole: endHole,
                team1PlayerIndexes: match.team1PlayerIndexes,
                team2PlayerIndexes: match.team2PlayerIndexes,
                stake: pressStake,
                runningStatus: [],
                createdManually: true
            )
        )
    }
    // MARK: - Commitment Helpers
    static func isHoleCommitted(
        gameData: GameData,
        holeIndex: Int
    ) -> Bool {
        guard holeIndex >= 0 else { return false }
        guard holeIndex < gameData.holeCommitted.count else { return false }
        return gameData.holeCommitted[holeIndex]
    }
  
    static func committedHoleCount(
        gameData: GameData,
        in range: ClosedRange<Int>
    ) -> Int {
        range.filter { isHoleCommitted(gameData: gameData, holeIndex: $0) }.count
    }

    static func isFrontComplete(gameData: GameData) -> Bool {
        committedHoleCount(gameData: gameData, in: 0...8) == 9
    }

    static func isBackComplete(gameData: GameData) -> Bool {
        committedHoleCount(gameData: gameData, in: 9...17) == 9
    }

    static func isOverallComplete(gameData: GameData) -> Bool {
        committedHoleCount(gameData: gameData, in: 0...(STANDARD_HOLES-1)) == STANDARD_HOLES
    }

    static func lastCommittedHoleNumber(gameData: GameData) -> Int? {
        for i in stride(from: 17, through: 0, by: -1) {
            if isHoleCommitted(gameData: gameData, holeIndex: i) {
                return i + 1
            }
        }
        return nil
    }

    static func isPressComplete(
        _ press: NassauPress,
        gameData: GameData
    ) -> Bool {
        let endIndex = press.endHole - 1
        return isHoleCommitted(gameData: gameData, holeIndex: endIndex)
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
            guard isHoleCommitted(gameData: gameData, holeIndex: hole) else { continue }

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

            guard isHoleCommitted(gameData: gameData, holeIndex: holeIndex) else { continue }

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
            return scores.min()
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
        let rawSI = gameData.course.holeHandicaps[safe: holeIndex] ?? STANDARD_HOLES
        let si = max(1, min(STANDARD_HOLES, rawSI == 0 ? STANDARD_HOLES : rawSI))

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
            return gross - pops
        }
    }

    // MARK: - Auto Press

    static func buildAutoPresses(
        for match: NassauMatch,
        state: NassauState
    ) -> [NassauPress] {
        guard match.resolvedPressMode(using: state) == .auto else { return [] }

        var presses: [NassauPress] = []

        presses.append(
            contentsOf: buildPressesForSegment(
                match: match,
                state: state,
                segment: .front,
                status: match.frontStatusByHole,
                holeOffset: 0
            )
        )

        presses.append(
            contentsOf: buildPressesForSegment(
                match: match,
                state: state,
                segment: .back,
                status: match.backStatusByHole,
                holeOffset: 9
            )
        )

        if match.resolvedAllowOverallPresses(using: state) {
            presses.append(
                contentsOf: buildPressesForSegment(
                    match: match,
                    state: state,
                    segment: .overall,
                    status: match.overallStatusByHole,
                    holeOffset: 0
                )
            )
        }

        return presses
    }

    static func buildPressesForSegment(
        match: NassauMatch,
        state: NassauState,
        segment: NassauSegment,
        status: [Int],
        holeOffset: Int
    ) -> [NassauPress] {
        let trigger = match.resolvedTrigger(using: state)
        let maxPresses = max(0, match.resolvedMaxPressesPerSegment(using: state))
        let pressStake = match.resolvedPressStake(using: state)
        let startRule = match.resolvedPressStartRule(using: state)

        guard trigger > 0, maxPresses != 0 else { return [] }

        var presses: [NassauPress] = []
        var previousAbs = 0

        for (idx, value) in status.enumerated() {
            let currentAbs = abs(value)

            let crossedTrigger = previousAbs < trigger && currentAbs >= trigger
            guard crossedTrigger else {
                previousAbs = currentAbs
                continue
            }

            if presses.count >= maxPresses {
                break
            }

            let actualHoleIndex = holeOffset + idx
            let triggerHoleNumber = actualHoleIndex + 1

            let startHole: Int
            switch startRule {
            case .nextHole:
                startHole = triggerHoleNumber + 1
            case .currentHole:
                startHole = triggerHoleNumber
            }

            let endHole: Int
            switch segment {
            case .front:
                endHole = 9
            case .back:
                endHole = STANDARD_HOLES
            case .overall:
                endHole = STANDARD_HOLES
            }

            if startHole <= endHole {
                presses.append(
                    NassauPress(
                        segment: segment,
                        startHole: startHole,
                        endHole: endHole,
                        team1PlayerIndexes: match.team1PlayerIndexes,
                        team2PlayerIndexes: match.team2PlayerIndexes,
                        stake: pressStake,
                        runningStatus: [],
                        createdManually: false
                    )
                )
            }

            previousAbs = currentAbs
        }

        return presses
    }

    static func buildPressesForSegment(
        match: NassauMatch,
        segment: NassauSegment,
        status: [Int],
        holeOffset: Int,
        trigger: Int
    ) -> [NassauPress] {
        var presses: [NassauPress] = []
        var previousAbs = 0

        for (idx, value) in status.enumerated() {
            let currentAbs = abs(value)

            if previousAbs < trigger && currentAbs >= trigger {
                let actualHoleIndex = holeOffset + idx
                let triggerHoleNumber = actualHoleIndex + 1
                let startHole = triggerHoleNumber + 1

                let endHole: Int
                switch segment {
                case .front:
                    endHole = 9
                case .back:
                    endHole = STANDARD_HOLES
                case .overall:
                    endHole = STANDARD_HOLES
                }

                if startHole <= endHole {
                    presses.append(
                        NassauPress(
                            segment: segment,
                            startHole: startHole,
                            endHole: endHole,
                            team1PlayerIndexes: match.team1PlayerIndexes,
                            team2PlayerIndexes: match.team2PlayerIndexes,
                            stake: match.stake,
                            runningStatus: []
                        )
                    )
                }
            }

            previousAbs = currentAbs
        }

        return presses
    }

    // MARK: - Display Result Helpers

    static func settledResultText(
        for status: [Int],
        segmentIsComplete: Bool,
        team1Display: String,
        team2Display: String
    ) -> String {
        guard segmentIsComplete else { return "In Progress" }

        let final = status.last ?? 0

        if final > 0 {
            return "\(team1Display) won \(final) up"
        } else if final < 0 {
            return "\(team2Display) won \(abs(final)) up"
        } else {
            return "Halved"
        }
    }

    static func frontResultText(
        for match: NassauMatch,
        playerNames: [String],
        gameData: GameData
    ) -> String {
        let team1 = displayNames(for: match.team1PlayerIndexes, playerNames: playerNames)
        let team2 = displayNames(for: match.team2PlayerIndexes, playerNames: playerNames)

        return settledResultText(
            for: match.frontStatusByHole,
            segmentIsComplete: isFrontComplete(gameData: gameData),
            team1Display: team1,
            team2Display: team2
        )
    }

    static func backResultText(
        for match: NassauMatch,
        playerNames: [String],
        gameData: GameData
    ) -> String {
        let team1 = displayNames(for: match.team1PlayerIndexes, playerNames: playerNames)
        let team2 = displayNames(for: match.team2PlayerIndexes, playerNames: playerNames)

        return settledResultText(
            for: match.backStatusByHole,
            segmentIsComplete: isBackComplete(gameData: gameData),
            team1Display: team1,
            team2Display: team2
        )
    }

    static func overallResultText(
        for match: NassauMatch,
        playerNames: [String],
        gameData: GameData
    ) -> String {
        let team1 = displayNames(for: match.team1PlayerIndexes, playerNames: playerNames)
        let team2 = displayNames(for: match.team2PlayerIndexes, playerNames: playerNames)

        return settledResultText(
            for: match.overallStatusByHole,
            segmentIsComplete: isOverallComplete(gameData: gameData),
            team1Display: team1,
            team2Display: team2
        )
    }

    static func netNassauMoneyText(
        for match: NassauMatch,
        playerNames: [String],
        gameData: GameData
    ) -> String {
        let team1 = displayNames(for: match.team1PlayerIndexes, playerNames: playerNames)
        let team2 = displayNames(for: match.team2PlayerIndexes, playerNames: playerNames)

        var delta: Double = 0

        if isFrontComplete(gameData: gameData), let final = match.frontStatusByHole.last {
            if final > 0 {
                delta += match.stake
            } else if final < 0 {
                delta -= match.stake
            }
        }

        if isBackComplete(gameData: gameData), let final = match.backStatusByHole.last {
            if final > 0 {
                delta += match.stake
            } else if final < 0 {
                delta -= match.stake
            }
        }

        if isOverallComplete(gameData: gameData), let final = match.overallStatusByHole.last {
            if final > 0 {
                delta += match.stake
            } else if final < 0 {
                delta -= match.stake
            }
        }

        for press in match.presses {
            guard isPressComplete(press, gameData: gameData) else { continue }
            guard let final = press.runningStatus.last else { continue }

            if final > 0 {
                delta += press.stake
            } else if final < 0 {
                delta -= press.stake
            }
        }

        return moneyText(delta: delta, team1: team1, team2: team2)
    }

    static func runningStatusText(_ status: [Int]) -> String {
        guard let final = status.last else { return "AS" }

        if final > 0 { return "\(final) Up" }
        if final < 0 { return "\(abs(final)) Down" }
        return "All Square"
    }

    // MARK: - Display Helpers

    private static func displayNames(
        for indexes: [Int],
        playerNames: [String]
    ) -> String {
        let names = indexes.compactMap { idx -> String? in
            guard idx >= 0, idx < playerNames.count else { return nil }

            let trimmed = playerNames[idx].trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "P\(idx + 1)" : trimmed
        }

        return names.isEmpty ? "Unknown" : names.joined(separator: " / ")
    }

    private static func moneyText(
        delta: Double,
        team1: String,
        team2: String
    ) -> String {
        if delta > 0 {
            return "\(team1) +$\(formatMoney(delta))"
        } else if delta < 0 {
            return "\(team2) +$\(formatMoney(abs(delta)))"
        } else {
            return "Even"
        }
    }

    private static func formatMoney(
        _ value: Double
    ) -> String {
        if value == floor(value) {
            return String(Int(value))
        } else {
            return String(format: "%.2f", value)
        }
    }
}
