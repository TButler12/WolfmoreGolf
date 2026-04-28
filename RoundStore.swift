//
//  RoundStore.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 11/6/25.
//
import Foundation

struct RoundSummary: Codable, Identifiable {

    /// Unique per player-row.
    var id: UUID = UUID()

    /// Shared across all player-rows saved from the same game.
    var gameID: UUID = UUID()

    var date: Date

    /// Course this round was played on.
    /// For new rounds, this should be ProfileStore.homeCourseID (UUID string).
    var courseID: String

    var playerName: String
    var totalMoney: Int
    var totalProx: Int
    var totalScore: Int?
    var holesPlayed: Int

    // Per-hole history (up to 18)
    var moneyPerHole: [Int]     // can be negative
    var proxPerHole:  [Bool]
    var scorePerHole: [Int?]    // nil = no score on that hole

    // Wolf stats per hole
    var wolfCalledPerHole:   [Bool]
    var wolfTeamWonPerHole:  [Bool]

    // Umbie per hole
    var umbieWonPerHole: [Bool]

    // NEW
    var gameTypePerHole: [GameType]?
    var fairwayHitPerHole: [Bool?]
    var girPerHole: [Bool?]
    var puttsPerHole: [Int?]

    enum CodingKeys: String, CodingKey {
        case id, gameID, date, courseID, playerName, totalMoney, totalProx, totalScore,
             holesPlayed, moneyPerHole, proxPerHole, scorePerHole,
             wolfCalledPerHole, wolfTeamWonPerHole, umbieWonPerHole,
             gameTypePerHole, fairwayHitPerHole, girPerHole, puttsPerHole
    }

    /// Backwards compatible decode (legacy saves won’t have newer fields).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        gameID = try c.decodeIfPresent(UUID.self, forKey: .gameID) ?? id

        date        = try c.decode(Date.self, forKey: .date)
        courseID    = try c.decodeIfPresent(String.self, forKey: .courseID) ?? ""
        playerName  = try c.decode(String.self, forKey: .playerName)
        totalMoney  = try c.decode(Int.self, forKey: .totalMoney)
        totalProx   = try c.decode(Int.self, forKey: .totalProx)
        totalScore  = try c.decodeIfPresent(Int.self, forKey: .totalScore)
        holesPlayed = try c.decodeIfPresent(Int.self, forKey: .holesPlayed) ?? STANDARD_HOLES

        moneyPerHole = try c.decodeIfPresent([Int].self, forKey: .moneyPerHole)
            ?? Array(repeating: 0, count: STANDARD_HOLES)
        proxPerHole = try c.decodeIfPresent([Bool].self, forKey: .proxPerHole)
            ?? Array(repeating: false, count: STANDARD_HOLES)
        scorePerHole = try c.decodeIfPresent([Int?].self, forKey: .scorePerHole)
            ?? Array(repeating: nil, count: STANDARD_HOLES)

        wolfCalledPerHole = try c.decodeIfPresent([Bool].self, forKey: .wolfCalledPerHole)
            ?? Array(repeating: false, count: STANDARD_HOLES)
        wolfTeamWonPerHole = try c.decodeIfPresent([Bool].self, forKey: .wolfTeamWonPerHole)
            ?? Array(repeating: false, count: STANDARD_HOLES)
        umbieWonPerHole = try c.decodeIfPresent([Bool].self, forKey: .umbieWonPerHole)
            ?? Array(repeating: false, count: STANDARD_HOLES)

        gameTypePerHole = try c.decodeIfPresent([GameType].self, forKey: .gameTypePerHole)

        fairwayHitPerHole = try c.decodeIfPresent([Bool?].self, forKey: .fairwayHitPerHole)
            ?? Array(repeating: nil, count: STANDARD_HOLES)
        girPerHole = try c.decodeIfPresent([Bool?].self, forKey: .girPerHole)
            ?? Array(repeating: nil, count: STANDARD_HOLES)
        puttsPerHole = try c.decodeIfPresent([Int?].self, forKey: .puttsPerHole)
            ?? Array(repeating: nil, count: STANDARD_HOLES)
    }

    init(
        id: UUID = UUID(),
        gameID: UUID = UUID(),
        date: Date,
        courseID: String,
        playerName: String,
        totalMoney: Int,
        totalProx: Int,
        totalScore: Int?,
        holesPlayed: Int,
        moneyPerHole: [Int],
        proxPerHole: [Bool],
        scorePerHole: [Int?],
        wolfCalledPerHole: [Bool],
        wolfTeamWonPerHole: [Bool],
        umbieWonPerHole: [Bool],
        gameTypePerHole: [GameType]? = nil,
        fairwayHitPerHole: [Bool?] = Array(repeating: nil, count: STANDARD_HOLES),
        girPerHole: [Bool?] = Array(repeating: nil, count: STANDARD_HOLES),
        puttsPerHole: [Int?] = Array(repeating: nil, count: STANDARD_HOLES)
    ) {
        self.id = id
        self.gameID = gameID
        self.date = date
        self.courseID = courseID
        self.playerName = playerName
        self.totalMoney = totalMoney
        self.totalProx = totalProx
        self.totalScore = totalScore
        self.holesPlayed = holesPlayed

        self.moneyPerHole       = Array(moneyPerHole.prefix(STANDARD_HOLES))
        self.proxPerHole        = Array(proxPerHole.prefix(STANDARD_HOLES))
        self.scorePerHole       = Array(scorePerHole.prefix(STANDARD_HOLES))
        self.wolfCalledPerHole  = Array(wolfCalledPerHole.prefix(STANDARD_HOLES))
        self.wolfTeamWonPerHole = Array(wolfTeamWonPerHole.prefix(STANDARD_HOLES))
        self.umbieWonPerHole    = Array(umbieWonPerHole.prefix(STANDARD_HOLES))

        self.gameTypePerHole = gameTypePerHole.map { Array($0.prefix(STANDARD_HOLES)) }
        self.fairwayHitPerHole = Array(fairwayHitPerHole.prefix(STANDARD_HOLES))
        self.girPerHole = Array(girPerHole.prefix(STANDARD_HOLES))
        self.puttsPerHole = Array(puttsPerHole.prefix(STANDARD_HOLES))
    }
}

// MARK: - Aggregate stats model

struct MyStats {
    let rounds: Int
    let totalMoney: Int
    let avgMoneyPerRound: Double   // normalized to “per 18 holes”
    let totalProx: Int
    let avgProxPerRound: Double    // normalized to “per 18 holes”
    var fairwaysHit: Int = 0
    var fairwaysPossible: Int = 0

    var girHit: Int = 0
    var girPossible: Int = 0

    var totalPutts: Int = 0
    var holesWithPutts: Int = 0
    var fairwayPct: Double {
        fairwaysPossible > 0 ? (Double(fairwaysHit) / Double(fairwaysPossible)) * 100 : 0
    }

    var girPct: Double {
        girPossible > 0 ? (Double(girHit) / Double(girPossible)) * 100 : 0
    }

    var avgPutts: Double {
        holesWithPutts > 0 ? Double(totalPutts) / Double(holesWithPutts) : 0
    }
}


// MARK: - Tracking helpers

/// Uses the user’s current home course for “tracked friends” filtering.
/// If no home course exists yet, return a stable placeholder.
private var trackingCourseID: String {
    let stored = ProfileStore.homeCourseID
    return stored.isEmpty ? "HOME-COURSE" : stored
}

private var trackedFriendStats: [(friend: Friend, stats: MyStats)] {
    let trackedFriends = FriendStore.shared.friends.filter { friend in
        FriendTrackStore.shared.isTracked(friend.id, on: trackingCourseID)
    }

    return trackedFriends.compactMap { friend in
        guard let s = RoundStore.shared.stats(forPlayerNamed: friend.name) else { return nil }
        return (friend, s)
    }
}


// MARK: - Store

final class RoundStore {

    static let shared = RoundStore()

    private let key = "round.store.v1"
    private let freeRoundLimit = 10

    private(set) var rounds: [RoundSummary] = []

    private init() { load() }

    func add(_ r: RoundSummary) {
        rounds.insert(r, at: 0)
        save()
        NotificationCenter.default.post(name: .reloadUI, object: nil)
    }

    func replaceAll(_ rs: [RoundSummary]) {
        rounds = rs
        save()
    }

    func clearAll() {
        rounds.removeAll()
        save()
    }

    func deleteLast() {
        guard !rounds.isEmpty else { return }
        rounds.removeFirst()
        save()
    }
    struct HoleAverage {
        let hole: Int
        let fairwayPct: Double?
        let girPct: Double?
        let avgPutts: Double?
    }
    func lastRound(forPlayer name: String) -> RoundSummary? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let rows = visibleRows(isPro: true)
            .filter { $0.playerName.caseInsensitiveCompare(trimmed) == .orderedSame }

        return rows.sorted { $0.date > $1.date }.first
    }
    // MARK: - Prox rate (grouped by game)

    private func proxRateForHoleGroupedByGame(
        _ holeIndex: Int,
        rows: [RoundSummary]
    ) -> (pct: Double, hits: Int, rounds: Int) {

        let byGame = Dictionary(grouping: rows, by: \.gameID)

        var roundsThatPlayedHole = 0
        var gamesWithProx = 0

        for (_, gameRows) in byGame {
            // Only count this game if at least one saved row shows the hole was played.
            guard gameRows.contains(where: { $0.holesPlayed > holeIndex }) else { continue }
            roundsThatPlayedHole += 1

            // Prox is "true for the game" if ANY player-row had prox=true on that hole.
            let proxAwardedThisGame = gameRows.contains { r in
                holeIndex < r.proxPerHole.count && r.proxPerHole[holeIndex]
            }
            if proxAwardedThisGame { gamesWithProx += 1 }
        }

        let pct = roundsThatPlayedHole == 0 ? 0.0 :
            (Double(gamesWithProx) / Double(roundsThatPlayedHole)) * 100.0

        return (pct, gamesWithProx, roundsThatPlayedHole)
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        rounds = (try? JSONDecoder().decode([RoundSummary].self, from: data)) ?? []
    }

    private func save() {
        let data = (try? JSONEncoder().encode(rounds)) ?? Data()
        UserDefaults.standard.set(data, forKey: key)
    }

    // MARK: - Limits / Visibility

    private var savedRoundCount: Int {
        Set(rounds.map(\.gameID)).count
    }

    private var canSaveAnotherRound: Bool { true }

    /// GameIDs sorted newest -> oldest (based on the newest row date in each game).
    private var gameIDsNewestFirst: [UUID] {
        let grouped = Dictionary(grouping: rounds, by: \.gameID)

        let gamesWithDate: [(UUID, Date)] = grouped.map { (gameID, rows) in
            let newestDate = rows.map(\.date).max() ?? .distantPast
            return (gameID, newestDate)
        }

        return gamesWithDate
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }

    func visibleGameIDs(isPro: Bool) -> Set<UUID> {
        Set(rounds.map(\.gameID))
    }

    func visibleRows(isPro: Bool) -> [RoundSummary] { rounds }

    func lockedRoundCount(isPro: Bool) -> Int {
        if isPro { return 0 }
        let totalGames = Set(rounds.map(\.gameID)).count
        return max(0, totalGames - freeRoundLimit)
    }
}


// MARK: - Capture from current game

extension RoundStore {

    /// Creates & saves a RoundSummary from the current GameManager state.
    /// - If gameID is nil, this call creates a new one (single-player save).
    /// - recordAllPlayersFromCurrentGame() passes the SAME gameID for everyone.
    @discardableResult
    func recordFromCurrentGame(
        playerNameOverride: String? = nil,
        gameID: UUID? = nil,
        date: Date = Date()
    ) -> RoundSummary? {

        guard let g = GameManager.shared.currentGame else { return nil }

        // ---------- Resolve player name ----------
        let who = (playerNameOverride ?? ProfileStore.name)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !who.isEmpty else { return nil }

        // ---------- Find ACTIVE seat that matches name ----------
        let seatsRange = 0..<min(MAX_PLAYERS, min(g.playerNames.count, g.playerActivated.count))
        guard let seat = seatsRange.first(where: { i in
            g.playerActivated[i] &&
            g.playerNames[i]
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .caseInsensitiveCompare(who) == .orderedSame
        }) else {
            return nil
        }

        // One shared game id for all player-rows saved in the same "Save Round" action.
        let sharedGameID = gameID ?? UUID()

        // Helpers to force 18-length arrays
        func pad<T>(_ arr: [T], to count: Int, with value: T) -> [T] {
            if arr.count >= count { return Array(arr.prefix(count)) }
            return arr + Array(repeating: value, count: count - arr.count)
        }

        // ---------- MONEY (18 ints) ----------
        let moneyRowD: [Double] = (seat < g.playerMoney.count) ? g.playerMoney[seat] : []
        let moneyPerHoleIntRaw: [Int] = moneyRowD.map { Int($0.rounded()) }
        let moneyPerHoleInt: [Int] = pad(moneyPerHoleIntRaw, to: STANDARD_HOLES, with: 0)
        let totalMoney: Int = moneyPerHoleInt.reduce(0, +)

        // ---------- PROX (18 bools) ----------
        let winners: [Int] = g.proxWinnerPerHole.map { $0 ?? -1 }
        let proxFlagsRaw: [Bool] = winners.map { $0 == seat }
        let proxFlags: [Bool] = pad(proxFlagsRaw, to: STANDARD_HOLES, with: false)
        let totalProx: Int = proxFlags.filter { $0 }.count

        // ---------- WOLF / UMBIE (18 bools) ----------
        let wolfCalled: [Bool]  = pad(Array(g.wolfCalledPerHole),   to: STANDARD_HOLES, with: false)
        let wolfTeamWon: [Bool] = pad(Array(g.wolfTeamWonPerHole),  to: STANDARD_HOLES, with: false)
        let umbieWon: [Bool]    = pad(Array(g.umbieWonPerHole),     to: STANDARD_HOLES, with: false)
        // ---------- GAME TYPE / FIR / GIR / PUTTS ----------
        let gameTypes: [GameType]? = {
            guard !g.gameTypePerHole.isEmpty else { return nil }
            return Array(g.gameTypePerHole.prefix(STANDARD_HOLES))
        }()

        let firForSeat: [Bool?] = {
            guard seat < g.fairwayHit.count else { return Array(repeating: nil, count: STANDARD_HOLES) }
            return pad(g.fairwayHit[seat], to: STANDARD_HOLES, with: nil)
        }()

        let girForSeat: [Bool?] = {
            guard seat < g.girHit.count else { return Array(repeating: nil, count: STANDARD_HOLES) }
            return pad(g.girHit[seat], to: STANDARD_HOLES, with: nil)
        }()

        let puttsForSeat: [Int?] = {
            guard seat < g.puttsPerHole.count else { return Array(repeating: nil, count: STANDARD_HOLES) }
            return pad(g.puttsPerHole[seat], to: STANDARD_HOLES, with: nil)
        }()

        // ---------- SCORES (18 optional ints) ----------
        var scoresForSeat = [Int?](repeating: nil, count: STANDARD_HOLES)

        if seat < g.scores.count,
           let first = g.scores.first,
           first.count == STANDARD_HOLES {
            // [player][hole]
            for h in 0..<min(STANDARD_HOLES, g.scores[seat].count) {
                scoresForSeat[h] = g.scores[seat][h]
            }
        } else if g.scores.count == STANDARD_HOLES {
            // [hole][player]
            for h in 0..<STANDARD_HOLES {
                let row = g.scores[h]
                if seat < row.count {
                    scoresForSeat[h] = row[seat]
                }
            }
        }

        // ---------- HOLES PLAYED ----------
        // Last hole index that has any evidence it was played.
        var holesPlayed = 0
        for h in 0..<STANDARD_HOLES {
            let hasScore = (scoresForSeat[h] != nil)
            let hasMoney = (moneyPerHoleInt[h] != 0)
            let hasProx  = proxFlags[h]
            let hasFlag  = wolfCalled[h] || umbieWon[h] || wolfTeamWon[h]

            if hasScore || hasMoney || hasProx || hasFlag {
                holesPlayed = h + 1
            }
        }

        // ---------- TOTAL SCORE ----------
        var sum = 0
        var haveAnyScore = false
        for h in 0..<STANDARD_HOLES {
            if let v = scoresForSeat[h] {
                sum += v
                haveAnyScore = true
            }
        }
        let totalScore: Int? = haveAnyScore ? sum : nil

        // ---------- Final display name ----------
        let finalName: String = {
            if !who.isEmpty { return who }
            if seat < g.playerNames.count {
                let n = g.playerNames[seat].trimmingCharacters(in: .whitespacesAndNewlines)
                if !n.isEmpty { return n }
            }
            return "Me"
        }()

        // ---------- CourseID ----------
        let courseIDForRound: String = {
            guard
                let homeUUID = UUID(uuidString: ProfileStore.homeCourseID),
                let homeCourse = CourseLibrary.shared.get(id: homeUUID)
            else { return "" }

            let currentPars = Array(g.course.pars.prefix(STANDARD_HOLES))
            let currentHCs  = Array(g.course.holeHandicaps.prefix(STANDARD_HOLES))
            let homePars    = Array(homeCourse.pars.prefix(STANDARD_HOLES))
            let homeHCs     = Array(homeCourse.hcs.prefix(STANDARD_HOLES))

            return (currentPars == homePars && currentHCs == homeHCs)
                ? homeCourse.id.uuidString
                : ""
        }()

        let summary = RoundSummary(
            id: UUID(),
            gameID: sharedGameID,
            date: date,
            courseID: courseIDForRound,
            playerName: finalName,
            totalMoney: totalMoney,
            totalProx: totalProx,
            totalScore: totalScore,
            holesPlayed: holesPlayed,
            moneyPerHole: moneyPerHoleInt,
            proxPerHole: proxFlags,
            scorePerHole: scoresForSeat,
            wolfCalledPerHole: wolfCalled,
            wolfTeamWonPerHole: wolfTeamWon,
            umbieWonPerHole: umbieWon,
            gameTypePerHole: gameTypes,
            fairwayHitPerHole: firForSeat,
            girPerHole: girForSeat,
            puttsPerHole: puttsForSeat
        )

        add(summary)
        return summary
    }
}


// MARK: - Per-friend stats (per 18 holes, across all courses)

extension RoundStore {

    func stats(forPlayerNamed name: String) -> MyStats? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let isPro = true
        let visible = visibleRows(isPro: isPro)

        let rowsForPlayer = visible.filter {
            $0.playerName.caseInsensitiveCompare(trimmed) == .orderedSame
        }
        guard !rowsForPlayer.isEmpty else { return nil }

        let roundCount = Set(rowsForPlayer.map(\.gameID)).count

        let totalMoney = rowsForPlayer.reduce(0) { $0 + $1.totalMoney }
        let totalProx  = rowsForPlayer.reduce(0) { $0 + $1.totalProx }

        let totalHoles = rowsForPlayer.reduce(0) { acc, round in
            acc + max(round.holesPlayed, 1)
        }

        let moneyPer18: Double = totalHoles > 0
            ? Double(totalMoney) / Double(totalHoles) * Double(STANDARD_HOLES)
            : 0

        let proxPer18: Double = totalHoles > 0
            ? Double(totalProx) / Double(totalHoles) * Double(STANDARD_HOLES)
            : 0

        // ✅ NEW STATS
        var fairwaysHit = 0
        var fairwaysPossible = 0

        var girHit = 0
        var girPossible = 0

        var totalPutts = 0
        var holesWithPutts = 0

        for r in rowsForPlayer {
            for h in 0..<min(STANDARD_HOLES, r.holesPlayed) {

                // FIR (count only when value exists)
                if let fw = r.fairwayHitPerHole[h] {
                    fairwaysPossible += 1
                    if fw { fairwaysHit += 1 }
                }

                // GIR
                if let gir = r.girPerHole[h] {
                    girPossible += 1
                    if gir { girHit += 1 }
                }

                // PUTTS
                if let p = r.puttsPerHole[h] {
                    totalPutts += p
                    holesWithPutts += 1
                }
            }
        }

        return MyStats(
            rounds: roundCount,
            totalMoney: totalMoney,
            avgMoneyPerRound: moneyPer18,
            totalProx: totalProx,
            avgProxPerRound: proxPer18,
            fairwaysHit: fairwaysHit,
            fairwaysPossible: fairwaysPossible,
            girHit: girHit,
            girPossible: girPossible,
            totalPutts: totalPutts,
            holesWithPutts: holesWithPutts
        )
    }
}


// MARK: - Capture ALL players from current game (shared gameID)

extension RoundStore {

    func recordAllPlayersFromCurrentGame() {
        guard let g = GameManager.shared.currentGame else { return }

        let sharedGameID = UUID()
        let now = Date()

        let seats = 0..<min(MAX_PLAYERS, min(g.playerNames.count, g.playerActivated.count))

        for seat in seats where g.playerActivated[seat] {
            let name = g.playerNames[seat]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }

            _ = recordFromCurrentGame(
                playerNameOverride: name,
                gameID: sharedGameID,
                date: now
            )
        }
    }
}


// MARK: - Course filtered visibility helpers

extension RoundStore {

    func visibleRowsForCourse(_ courseID: String) -> [RoundSummary] {
        visibleRows(isPro: true).filter { $0.courseID == courseID }
    }

    func visibleGameIDsForCourse(_ courseID: String) -> Set<UUID> {
        Set(visibleRowsForCourse(courseID).map(\.gameID))
    }

    func visibleGamesForCourse(_ courseID: String) -> [[RoundSummary]] {
        let rows = visibleRowsForCourse(courseID)
        guard !rows.isEmpty else { return [] }

        let byGameID = Dictionary(grouping: rows, by: \.gameID)
        if byGameID.values.contains(where: { $0.count > 1 }) {
            return byGameID.values.map { Array($0) }
        }

        // Fallback bucket for legacy “bad grouping”
        let byBucket = Dictionary(grouping: rows) { r -> String in
            let bucket = Int(r.date.timeIntervalSince1970 / 30.0)
            return "\(r.courseID)|\(bucket)"
        }
        return byBucket.values.map { Array($0) }
    }
}
extension RoundStore {

    /// Phones for the players in these saved rows (skips blanks, removes duplicates)
    func recipientPhones(for gameRows: [RoundSummary]) -> [String] {
        let friends = FriendStore.shared.friends

        let phones: [String] = gameRows.compactMap { row -> String? in
            let rowName = row.playerName
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            guard let friend = friends.first(where: {
                $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == rowName
            }) else {
                return nil
            }

            let phone = friend.phone.trimmingCharacters(in: .whitespacesAndNewlines)
            return phone.isEmpty ? nil : phone
        }

        // unique, stable-ish order (or remove sorted() if you want original order)
        return Array(Set(phones)).sorted()
    }
}
extension RoundStore {

    func averagesByHole(forPlayer name: String) -> [HoleAverage] {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let rows = visibleRows(isPro: true)
            .filter { $0.playerName.caseInsensitiveCompare(trimmed) == .orderedSame }

        guard !rows.isEmpty else { return [] }

        var results: [HoleAverage] = []

        for h in 0..<STANDARD_HOLES {
            var fwHit = 0
            var fwTotal = 0
            var girHit = 0
            var girTotal = 0
            var puttSum = 0
            var puttTotal = 0

            for r in rows {
                guard h < min(STANDARD_HOLES, r.holesPlayed) else { continue }

                if h < r.fairwayHitPerHole.count, let fw = r.fairwayHitPerHole[h] {
                    fwTotal += 1
                    if fw { fwHit += 1 }
                }

                if h < r.girPerHole.count, let gir = r.girPerHole[h] {
                    girTotal += 1
                    if gir { girHit += 1 }
                }

                if h < r.puttsPerHole.count, let p = r.puttsPerHole[h] {
                    puttSum += p
                    puttTotal += 1
                }
            }

            let fairwayPct = fwTotal > 0 ? (Double(fwHit) / Double(fwTotal)) * 100.0 : nil
            let girPct = girTotal > 0 ? (Double(girHit) / Double(girTotal)) * 100.0 : nil
            let avgPutts = puttTotal > 0 ? Double(puttSum) / Double(puttTotal) : nil

            results.append(HoleAverage(
                hole: h + 1,
                fairwayPct: fairwayPct,
                girPct: girPct,
                avgPutts: avgPutts
            ))
        }

        return results
    }
}
