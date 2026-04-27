//
//  SkinsEngine.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 4/3/26.
//
import Foundation

enum SkinsEngine {

    static func makeDefaultState() -> SkinsState {
        var state = SkinsState()
        state.settings.scoringMode = .net
        state.playerIncluded = Array(repeating: true, count: MAX_PLAYERS)
        return state
    }

    static func recalculate(
        state: inout SkinsState,
        gameData: GameData
    ) {
        state.settings.scoringMode = .net

        normalizeState(&state, gameData: gameData)

        let activeIndexes = activePlayerIndexes(from: gameData, state: state)

        state.resultsByHole = (0..<STANDARD_HOLES).map {
            SkinsHoleResult(
                holeIndex: $0,
                potValue: 1,
                winningPlayerIndexes: [],
                awardedSkinCount: 0,
                carriedToNextHole: false,
                note: nil
            )
        }
        state.skinsWonByPlayer = Array(repeating: 0, count: MAX_PLAYERS)
        state.moneyWonByPlayer = Array(repeating: 0.0, count: MAX_PLAYERS)

        guard activeIndexes.count >= 2 else { return }

        var currentPot = 1

        for hole in 0..<STANDARD_HOLES {
            var result = SkinsHoleResult(
                holeIndex: hole,
                potValue: currentPot,
                winningPlayerIndexes: [],
                awardedSkinCount: 0,
                carriedToNextHole: false,
                note: nil
            )

            guard hole < gameData.holeCommitted.count,
                  gameData.holeCommitted[hole] else {
                state.resultsByHole[hole] = result
                continue
            }

            switch state.settings.mode {
            case .automatic:
                result = autoResolveHole(
                    hole: hole,
                    pot: currentPot,
                    activeIndexes: activeIndexes,
                    carryoversEnabled: state.settings.carryoversEnabled,
                    gameData: gameData,
                    state: state
                )

            case .manual:
                result = manualResolveHole(
                    hole: hole,
                    pot: currentPot,
                    overrideDecision: state.manualOverridesByHole[safe: hole] ?? nil,
                    carryoversEnabled: state.settings.carryoversEnabled
                )
            }

            state.resultsByHole[hole] = result

            if let winner = result.winningPlayerIndexes.first,
               result.awardedSkinCount > 0 {
                state.skinsWonByPlayer[winner] += result.awardedSkinCount
                currentPot = 1
            } else {
                currentPot = result.carriedToNextHole ? (currentPot + 1) : 1
            }
        }

        applyMoney(state: &state, gameData: gameData)
    }

    private static func autoResolveHole(
        hole: Int,
        pot: Int,
        activeIndexes: [Int],
        carryoversEnabled: Bool,
        gameData: GameData,
        state: SkinsState
    ) -> SkinsHoleResult {
        var scored: [(playerIndex: Int, value: Int)] = []

        for idx in activeIndexes {
            guard let value = skinScore(
                for: idx,
                hole: hole,
                gameData: gameData,
                state: state
            ) else {
                return SkinsHoleResult(
                    holeIndex: hole,
                    potValue: pot,
                    winningPlayerIndexes: [],
                    awardedSkinCount: 0,
                    carriedToNextHole: false,
                    note: "Incomplete scores"
                )
            }
            scored.append((idx, value))
        }

        guard let low = scored.map(\.value).min() else {
            return SkinsHoleResult(
                holeIndex: hole,
                potValue: pot,
                winningPlayerIndexes: [],
                awardedSkinCount: 0,
                carriedToNextHole: false,
                note: "No scores"
            )
        }

        let winners = scored.filter { $0.value == low }.map(\.playerIndex)

        if winners.count == 1 {
            return SkinsHoleResult(
                holeIndex: hole,
                potValue: pot,
                winningPlayerIndexes: winners,
                awardedSkinCount: pot,
                carriedToNextHole: false,
                note: nil
            )
        } else {
            return SkinsHoleResult(
                holeIndex: hole,
                potValue: pot,
                winningPlayerIndexes: [],
                awardedSkinCount: 0,
                carriedToNextHole: carryoversEnabled,
                note: carryoversEnabled ? "Tie - carryover" : "Tie - no skin"
            )
        }
    }

    private static func manualResolveHole(
        hole: Int,
        pot: Int,
        overrideDecision: ManualSkinsHoleDecision?,
        carryoversEnabled: Bool
    ) -> SkinsHoleResult {
        guard let decision = overrideDecision else {
            return SkinsHoleResult(
                holeIndex: hole,
                potValue: pot,
                winningPlayerIndexes: [],
                awardedSkinCount: 0,
                carriedToNextHole: false,
                note: "No manual result"
            )
        }

        if let winner = decision.winnerIndexes.first {
            let award = max(1, decision.awardedSkinCount ?? pot)
            return SkinsHoleResult(
                holeIndex: hole,
                potValue: pot,
                winningPlayerIndexes: [winner],
                awardedSkinCount: award,
                carriedToNextHole: false,
                note: "Manual"
            )
        }

        return SkinsHoleResult(
            holeIndex: hole,
            potValue: pot,
            winningPlayerIndexes: [],
            awardedSkinCount: 0,
            carriedToNextHole: decision.shouldCarryOver && carryoversEnabled,
            note: decision.shouldCarryOver && carryoversEnabled
                ? "Manual carryover"
                : "Manual no skin"
        )
    }

    private static func skinScore(
        for playerIndex: Int,
        hole: Int,
        gameData: GameData,
        state: SkinsState
    ) -> Int? {
        guard playerIndex < gameData.scores.count,
              hole < gameData.scores[playerIndex].count,
              let gross = gameData.scores[playerIndex][hole] else {
            return nil
        }

        let pops = popsForPlayer(
            playerIndex,
            hole: hole,
            gameData: gameData,
            state: state
        )

        return gross - pops
    }

    private static func activePlayerIndexes(
        from gameData: GameData,
        state: SkinsState
    ) -> [Int] {
        let activated = gameData.playerActivated
        let included = state.playerIncluded
        let count = min(MAX_PLAYERS, min(activated.count, included.count))

        return (0..<count).compactMap { idx in
            (activated[idx] && included[idx]) ? idx : nil
        }
    }

    private static func popsForPlayer(
        _ playerIndex: Int,
        hole: Int,
        gameData: GameData,
        state: SkinsState
    ) -> Int {
        guard playerIndex < gameData.hcPlayers.count,
              hole < gameData.courseHCToPass.count else { return 0 }

        let activeIndexes = activePlayerIndexes(from: gameData, state: state)

        let activeCaps = activeIndexes.compactMap { idx -> Int? in
            guard idx < gameData.hcPlayers.count else { return nil }
            return gameData.hcPlayers[idx]
        }

        guard let lowCap = activeCaps.min() else { return 0 }

        let playerCap = gameData.hcPlayers[playerIndex]
        let delta = max(0, playerCap - lowCap)

        let siRaw = gameData.courseHCToPass[hole]
        let si = max(1, min(STANDARD_HOLES, siRaw == 0 ? STANDARD_HOLES : siRaw))

        return pops(for: delta, strokeIndex: si)
    }

    private static func pops(for delta: Int, strokeIndex si: Int) -> Int {
        let d = max(0, delta)
        if d <= STANDARD_HOLES { return si <= d ? 1 : 0 }
        return 1 + (si <= (d - STANDARD_HOLES) ? 1 : 0)
    }

    private static func applyMoney(
        state: inout SkinsState,
        gameData: GameData
    ) {
        let activeIndexes = activePlayerIndexes(from: gameData, state: state)
        let activeCount = activeIndexes.count

        guard activeCount >= 2 else {
            state.moneyWonByPlayer = Array(repeating: 0.0, count: MAX_PLAYERS)
            return
        }

        let skinValue = state.settings.skinValue
        state.moneyWonByPlayer = Array(repeating: 0.0, count: MAX_PLAYERS)

        for winner in activeIndexes {
            let won = state.skinsWonByPlayer[winner]
            guard won > 0 else { continue }

            let gainPerSkin = Double(activeCount - 1) * skinValue
            state.moneyWonByPlayer[winner] += Double(won) * gainPerSkin
        }

        for loser in activeIndexes {
            let skinsWonByOthers = activeIndexes
                .filter { $0 != loser }
                .reduce(0) { $0 + state.skinsWonByPlayer[$1] }

            state.moneyWonByPlayer[loser] -= Double(skinsWonByOthers) * skinValue
        }
    }

    static func summaryText(
        state: SkinsState,
        gameData: GameData
    ) -> String {
        let activeIndexes = activePlayerIndexes(from: gameData, state: state)
        var lines: [String] = []

        lines.append("SKINS")
        lines.append("Mode: \(state.settings.mode == .automatic ? "Automatic" : "Manual")")
        lines.append("Scoring: Net")
        lines.append("Carryovers: \(state.settings.carryoversEnabled ? "On" : "Off")")
        lines.append("Skin Value: \(formatMoney(state.settings.skinValue))")

        let names = activeIndexes.map { displayName(for: $0, gameData: gameData) }
        if !names.isEmpty {
            lines.append("Players In: \(names.joined(separator: ", "))")
        }

        lines.append("")
        lines.append("TOTALS")

        for idx in activeIndexes {
            let name = displayName(for: idx, gameData: gameData)
            let skins = state.skinsWonByPlayer[idx]
            let money = state.moneyWonByPlayer[idx]
            lines.append("\(name): \(skins) skins (\(formatSignedMoney(money)))")
        }

        lines.append("")
        lines.append("BY HOLE")

        for hole in 0..<STANDARD_HOLES {
            let result = state.resultsByHole[hole]
            let holeNumber = hole + 1

            if let winner = result.winningPlayerIndexes.first {
                let name = displayName(for: winner, gameData: gameData)
                lines.append("Hole \(holeNumber): \(name) won \(result.awardedSkinCount)")
            } else if result.carriedToNextHole {
                lines.append("Hole \(holeNumber): Tie - carryover")
            } else if gameData.holeCommitted[safe: hole] == true {
                lines.append("Hole \(holeNumber): No skin")
            } else {
                lines.append("Hole \(holeNumber): Not completed")
            }
        }

        return lines.joined(separator: "\n")
    }

    private static func normalizeState(
        _ state: inout SkinsState,
        gameData: GameData
    ) {
        if state.playerIncluded.count < MAX_PLAYERS {
            state.playerIncluded += Array(repeating: true, count: MAX_PLAYERS - state.playerIncluded.count)
        }
        if state.playerIncluded.count > MAX_PLAYERS {
            state.playerIncluded = Array(state.playerIncluded.prefix(MAX_PLAYERS))
        }

        if state.manualOverridesByHole.count < STANDARD_HOLES {
            state.manualOverridesByHole += Array(
                repeating: nil,
                count: STANDARD_HOLES - state.manualOverridesByHole.count
            )
        }
        if state.manualOverridesByHole.count > STANDARD_HOLES {
            state.manualOverridesByHole = Array(state.manualOverridesByHole.prefix(STANDARD_HOLES))
        }

        if state.resultsByHole.count < STANDARD_HOLES {
            state.resultsByHole += (state.resultsByHole.count..<STANDARD_HOLES).map {
                SkinsHoleResult(holeIndex: $0)
            }
        }
        if state.resultsByHole.count > STANDARD_HOLES {
            state.resultsByHole = Array(state.resultsByHole.prefix(STANDARD_HOLES))
        }

        if state.skinsWonByPlayer.count < MAX_PLAYERS {
            state.skinsWonByPlayer += Array(repeating: 0, count: MAX_PLAYERS - state.skinsWonByPlayer.count)
        }
        if state.skinsWonByPlayer.count > MAX_PLAYERS {
            state.skinsWonByPlayer = Array(state.skinsWonByPlayer.prefix(MAX_PLAYERS))
        }

        if state.moneyWonByPlayer.count < MAX_PLAYERS {
            state.moneyWonByPlayer += Array(repeating: 0.0, count: MAX_PLAYERS - state.moneyWonByPlayer.count)
        }
        if state.moneyWonByPlayer.count > MAX_PLAYERS {
            state.moneyWonByPlayer = Array(state.moneyWonByPlayer.prefix(MAX_PLAYERS))
        }

        let activeCount = min(MAX_PLAYERS, gameData.playerActivated.count)
        if state.playerIncluded.allSatisfy({ $0 }) && activeCount > 0 {
            for i in 0..<activeCount where !gameData.playerActivated[i] {
                state.playerIncluded[i] = false
            }
        }
    }

    private static func displayName(
        for index: Int,
        gameData: GameData
    ) -> String {
        guard index < gameData.playerNames.count else { return "Player \(index + 1)" }
        let trimmed = gameData.playerNames[index].trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Player \(index + 1)" : trimmed
    }

    private static func formatMoney(_ value: Double) -> String {
        if value == floor(value) {
            return "$\(Int(value))"
        } else {
            return String(format: "$%.2f", value)
        }
    }

    private static func formatSignedMoney(_ value: Double) -> String {
        if value >= 0 {
            return "+" + formatMoney(value)
        } else {
            return "-" + formatMoney(abs(value))
        }
    }
}
