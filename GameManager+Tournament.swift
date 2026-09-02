//
//  GameManager+Tournament.swift
//  WolfmoreGolf
//

import Foundation

extension GameManager {

    // MARK: - Tournament join

    /// Single shared join path for all entry points (scoring-page button, Live & Tournaments,
    /// LiveConnectedViewController). Handles same-day ID reuse, all game-state writes, course
    /// update from the organizer's courseName, and history recording.
    @discardableResult
    static func applyTournamentJoin(record: TournamentRecord) -> (groupCode: String, matchId: String) {
        if shared.currentGame == nil { _ = shared.loadLastOpened(notify: false) }
        if shared.currentGame == nil { shared.startNewGame() }

        let liveDay = record.currentDay ?? 1
        let existing = TournamentHistoryStore.shared.all().first { $0.code == record.code }
        let isSameDay = existing?.lastDay == liveDay
        let groupCode: String
        let matchId: String
        if isSameDay, let sg = existing?.groupCode, let sm = existing?.tournamentMatchId {
            groupCode = sg; matchId = sm
        } else {
            groupCode = UUID().uuidString; matchId = UUID().uuidString
        }

        shared.update { g in
            // Wipe scores and hole state from any previous round so stale data from a
            // different course never appears in the newly joined session.
            let holes = g.totalHoles
            g.scores        = Array(repeating: Array(repeating: nil, count: holes), count: MAX_PLAYERS)
            g.holeCommitted = Array(repeating: false, count: holes)
            g.hole          = 0

            g.tournamentCode        = record.code
            g.groupCode             = groupCode
            g.tournamentMatchId     = matchId
            g.tournamentName        = record.name
            g.tournamentGameType    = record.gameType
            g.tournamentScoringType = record.scoring
            g.tournamentDay         = liveDay
            g.tournamentIsCreator   = (record.createdBy == DeviceID.id)
            g.tournamentIsOrganizer = g.tournamentIsCreator
                || (record.coOrganizerDevices?.contains(DeviceID.id) == true)
            g.tournamentPotAmount   = record.potAmount
            g.tournamentCarryTies   = record.carryTies
            if record.gameType == "skins", let stake = record.stake {
                var skins = g.skinsState ?? SkinsEngine.makeDefaultState()
                skins.settings.skinValue = stake
                g.skinsState = skins
            } else if record.gameType == "wolf", let wolfStake = record.wolfStake {
                g.wolfStake = wolfStake
                g.gameHoleDollarsArray = Array(repeating: wolfStake, count: STANDARD_HOLES)
            }
            g.stablefordBaseline        = StablefordBaseline(rawValue: record.stablefordBaseline ?? "par") ?? .par
            g.stablefordCountingPlayers = record.stablefordTeamCount ?? 3
            g.tournamentStablefordEnabled = record.stablefordEnabled
            g.gameType = nil
            switch record.gameType {
            case "stableford": g.gameType = .tournament
            case "wolf":
                switch record.wolfVariant {
                case "2pt":       g.gameType = .wolf
                case "lowball":   g.gameType = .wolfLowBall
                case "matchplay": g.gameType = .matchPlay
                default:          g.gameType = .sixPointScotch
                }
                if let ps = record.pressStyle  { g.pressStyle  = ps == "additive" ? .additive : .doubling }
                if let hs = record.hammerStyle { g.hammerStyle = hs == "additive" ? .additive : .doubling }
            default: break
            }
            // Update course for all game types when the organizer specified one.
            if let courseName = record.courseName,
               let profile = CourseLibrary.shared.courses.first(where: {
                   $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                       .caseInsensitiveCompare(courseName.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame
               }) {
                g.course = Course(id: profile.id, name: profile.name,
                                  pars: Array(profile.pars.prefix(STANDARD_HOLES)),
                                  holeHandicaps: Array(profile.hcs.prefix(STANDARD_HOLES)),
                                  teeSets: profile.teeSets ?? [])
                // Reset any tee-set indices that are out of bounds for the new course.
                let setCount = g.course.teeSets.count
                for i in g.playerTeeSetIndex.indices where g.playerTeeSetIndex[i] > setCount {
                    g.playerTeeSetIndex[i] = 0
                }
            }
        }

        UserDefaults.standard.set(liveDay, forKey: "lastTournamentDay_\(record.code)")
        shared.saveCurrent()
        let isOrg = shared.currentGame?.tournamentIsOrganizer == true
        TournamentHistoryStore.shared.record(
            code: record.code, name: record.name,
            gameType: record.gameType, day: liveDay, isOrganizer: isOrg,
            groupCode: groupCode, tournamentMatchId: matchId)
        NotificationCenter.default.post(name: .reloadUI, object: nil)
        return (groupCode, matchId)
    }

    // MARK: - Stableford helpers

    /// Returns handicap strokes received on a hole for Stableford.
    /// Uses the player's absolute handicap (not delta vs. field).
    func absoluteStrokesGiven(playerHC: Int, strokeIndex: Int) -> Int {
        let hc = max(0, playerHC)
        if hc <= 18 { return (strokeIndex <= hc) ? 1 : 0 }
        return 1 + ((strokeIndex <= (hc - 18)) ? 1 : 0)
    }

    /// Returns Stableford points for one player on one hole.
    /// Returns nil if gross score is nil (hole not yet played).
    /// Par mode: eagle=3, birdie=2, par=1, bogey+=0.
    /// Bogey mode: birdie+=3, par=2, bogey=1, double+=0. Both modes cap at 3.
    func stablefordPoints(
        grossScore: Int?,
        par: Int,
        playerHC: Int,
        strokeIndex: Int,
        baseline: StablefordBaseline = .par
    ) -> Int? {
        guard let gross = grossScore else { return nil }
        let strokes = absoluteStrokesGiven(playerHC: playerHC, strokeIndex: strokeIndex)
        let net = gross - strokes
        let offset = baseline == .bogey ? 1 : 0
        return min(3, max(0, 1 + offset - (net - par)))
    }

    /// Returns total Stableford points for a player across all played holes.
    /// Unplayed holes (nil score) are excluded.
    func totalStablefordPoints(playerIndex: Int, game: GameData, upThrough: Int? = nil) -> Int {
        let holesToSum = committedHoles(game: game, upThrough: upThrough)
        var total = 0
        for hole in holesToSum {
            let par   = game.parForHole(hole, player: playerIndex)
            let si    = game.hcForHole(hole, player: playerIndex)
            let hc    = game.hcPlayers[safe: playerIndex] ?? 0
            let gross = (playerIndex < game.scores.count) ? game.scores[playerIndex][hole] : nil
            if let pts = stablefordPoints(grossScore: gross, par: par, playerHC: hc,
                                          strokeIndex: si, baseline: game.stablefordBaseline) {
                total += pts
            }
        }
        return total
    }

    /// Holes that have been committed (Update Scores pressed), from startHole through upThrough,
    /// wrapping for back-9 starts. Only committed holes count toward Stableford totals.
    private func committedHoles(game: GameData, upThrough: Int?) -> [Int] {
        let end   = max(0, min(17, upThrough ?? (STANDARD_HOLES - 1)))
        let start = max(0, min(17, game.startHole ?? end))
        let range = start <= end
            ? Array(start...end)
            : Array(start..<STANDARD_HOLES) + Array(0...end)
        return range.filter { game.holeCommitted[safe: $0] == true }
    }

    /// Best-N Stableford points for one hole across all active players.
    /// N is set by game.stablefordCountingPlayers (2, 3, or 4).
    func teamHoleScore(hole: Int, game: GameData) -> Int {
        let capacity = min(game.playerNames.count, game.playerActivated.count)
        let activeSeats = (0..<capacity).filter {
            game.playerActivated[$0] &&
            !game.playerNames[$0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        let pts: [Int] = activeSeats.compactMap { seat in
            let par   = game.parForHole(hole, player: seat)
            let si    = game.hcForHole(hole, player: seat)
            let hc    = game.hcPlayers[safe: seat] ?? 0
            let gross = (seat < game.scores.count) ? game.scores[seat][hole] : nil
            return stablefordPoints(grossScore: gross, par: par, playerHC: hc, strokeIndex: si,
                                    baseline: game.stablefordBaseline)
        }
        let n = max(1, min(game.stablefordCountingPlayers, pts.count))
        return pts.sorted(by: >).prefix(n).reduce(0, +)
    }

    /// Sum of teamHoleScore across committed holes (start through upThrough, or all holes if nil).
    func runningTeamStablefordTotal(game: GameData, upThrough: Int? = nil) -> Int {
        committedHoles(game: game, upThrough: upThrough).reduce(0) { $0 + teamHoleScore(hole: $1, game: game) }
    }
}
