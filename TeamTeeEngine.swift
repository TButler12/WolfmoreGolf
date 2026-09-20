import Foundation

enum TeamTeeEngine {

    static func recalculate(gameData: GameData) -> TeamTeeResult? {
        guard let settings = gameData.teamTeeSettings, settings.isEnabled else { return nil }

        let totalHoles = gameData.totalHoles
        let activeSeats = (0..<MAX_PLAYERS).filter {
            ($0 < gameData.playerActivated.count && gameData.playerActivated[$0]) &&
            ($0 < gameData.playerNames.count &&
             !gameData.playerNames[$0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        guard !activeSeats.isEmpty else { return nil }

        let baseHC = activeSeats.compactMap {
            $0 < gameData.hcPlayers.count ? gameData.hcPlayers[$0] : nil
        }.min() ?? 0

        var holeResults: [TeamTeeHoleResult?] = Array(repeating: nil, count: totalHoles)

        for mp in 0..<totalHoles {
            guard gameData.holeCommitted[safe: mp] == true else { continue }
            let courseH = gameData.courseHoleIndex(for: mp)
            let par = gameData.courseParToPass[safe: courseH] ?? 4
            let countN = settings.count(forPar: par)

            var netsByPlayer: [Int: Int] = [:]
            var allScored = true

            for seat in activeSeats {
                guard seat < gameData.scores.count,
                      mp < gameData.scores[seat].count,
                      let gross = gameData.scores[seat][mp] else {
                    allScored = false; break
                }
                let si    = gameData.hcForHole(courseH, player: seat)
                let hc    = seat < gameData.hcPlayers.count ? gameData.hcPlayers[seat] : 0
                let delta = max(0, hc - baseHC)
                let pops: Int = {
                    if delta <= STANDARD_HOLES { return si <= delta ? 1 : 0 }
                    return 1 + (si <= (delta - STANDARD_HOLES) ? 1 : 0)
                }()
                netsByPlayer[seat] = gross - pops
            }

            guard allScored, !netsByPlayer.isEmpty else { continue }

            let sorted  = netsByPlayer.sorted { $0.value < $1.value }
            let take    = min(countN, sorted.count)
            let counted = sorted.prefix(take)
            let teamScore = counted.map(\.value).reduce(0, +)

            holeResults[mp] = TeamTeeHoleResult(
                holeIndex:    mp,
                netScore:     teamScore,
                countedSeats: Set(counted.map(\.key)),
                netsByPlayer: netsByPlayer
            )
        }

        return TeamTeeResult(seats: activeSeats, holeResults: holeResults)
    }
}
