//
//  RoundStore.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 11/6/25.
//
import Foundation

// MARK: - Model

struct RoundSummary: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date

    /// Course this round was played on.
    /// For new rounds, this should be ProfileStore.homeCourseID (or the course UUID string).
    var courseID: String

    var playerName: String
    var totalMoney: Int
    var totalProx: Int
    var totalScore: Int?
    var holesPlayed: Int

    // Per-hole history for “Hole Stats”
    var moneyPerHole: [Int]   // 18 ints (can be negative)
    var proxPerHole:  [Bool]  // 18 flags

    // Per-hole gross scores for this player (nil = no score on that hole)
    var scorePerHole: [Int?]

    // Wolf stats per hole (for Wolf% by hole)
    var wolfCalledPerHole:   [Bool]   // true if Wolf was called on that hole
    var wolfTeamWonPerHole:  [Bool]   // true if Wolf side won that hole

    // Umbrella (Umbie) per hole – true if any team got all 6 points
    var umbieWonPerHole: [Bool]

    enum CodingKeys: String, CodingKey {
        case id, date, courseID, playerName, totalMoney, totalProx, totalScore,
             holesPlayed, moneyPerHole, proxPerHole,
             scorePerHole,
             wolfCalledPerHole, wolfTeamWonPerHole,
             umbieWonPerHole
    }

    // Backwards compatible with old saves (no courseID / per-hole arrays)
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decodeIfPresent(UUID.self,   forKey: .id) ?? UUID()
        date        = try c.decode(Date.self,            forKey: .date)

        // Old saves didn’t have courseID – treat as “unknown”
        courseID    = try c.decodeIfPresent(String.self, forKey: .courseID) ?? ""

        playerName  = try c.decode(String.self,          forKey: .playerName)
        totalMoney  = try c.decode(Int.self,             forKey: .totalMoney)
        totalProx   = try c.decode(Int.self,             forKey: .totalProx)
        totalScore  = try c.decodeIfPresent(Int.self,    forKey: .totalScore)
        holesPlayed = try c.decodeIfPresent(Int.self,    forKey: .holesPlayed) ?? 18

        moneyPerHole = try c.decodeIfPresent([Int].self,  forKey: .moneyPerHole)
            ?? Array(repeating: 0, count: 18)
        proxPerHole  = try c.decodeIfPresent([Bool].self, forKey: .proxPerHole)
            ?? Array(repeating: false, count: 18)

        // Per-hole scores – default to 18 nils for old rounds
        scorePerHole = try c.decodeIfPresent([Int?].self, forKey: .scorePerHole)
            ?? Array(repeating: nil, count: 18)

        // Wolf flags – default to all false for old rounds
        wolfCalledPerHole = try c.decodeIfPresent([Bool].self, forKey: .wolfCalledPerHole)
            ?? Array(repeating: false, count: 18)
        wolfTeamWonPerHole = try c.decodeIfPresent([Bool].self, forKey: .wolfTeamWonPerHole)
            ?? Array(repeating: false, count: 18)

        // Umbie flags – default to all false for old rounds
        umbieWonPerHole = try c.decodeIfPresent([Bool].self, forKey: .umbieWonPerHole)
            ?? Array(repeating: false, count: 18)
    }

    init(
        id: UUID = UUID(),
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
        umbieWonPerHole: [Bool]
    ) {
        self.id = id
        self.date = date
        self.courseID = courseID
        self.playerName = playerName
        self.totalMoney = totalMoney
        self.totalProx = totalProx
        self.totalScore = totalScore
        self.holesPlayed = holesPlayed
        self.moneyPerHole        = Array(moneyPerHole.prefix(18))
        self.proxPerHole         = Array(proxPerHole.prefix(18))
        self.scorePerHole        = Array(scorePerHole.prefix(18))
        self.wolfCalledPerHole   = Array(wolfCalledPerHole.prefix(18))
        self.wolfTeamWonPerHole  = Array(wolfTeamWonPerHole.prefix(18))
        self.umbieWonPerHole     = Array(umbieWonPerHole.prefix(18))
    }
}


// MARK: - Aggregate stats model

struct MyStats {
    let rounds: Int
    let totalMoney: Int
    let avgMoneyPerRound: Double   // “per 18 holes”
    let totalProx: Int
    let avgProxPerRound: Double    // “per 18 holes”
}

// Use the current home/tracking course when building global tracked stats
private var trackingCourseID: String {
    let stored = ProfileStore.homeCourseID
    return stored.isEmpty ? "HOME-COURSE" : stored
}

private var trackedFriendStats: [(friend: Friend, stats: MyStats)] {
    let trackedFriends = FriendStore.shared.friends.filter {
        FriendTrackStore.shared.isTracked($0.id, on: trackingCourseID)
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

    // MARK: Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        rounds = (try? JSONDecoder().decode([RoundSummary].self, from: data)) ?? []
    }

    private func save() {
        let data = (try? JSONEncoder().encode(rounds)) ?? Data()
        UserDefaults.standard.set(data, forKey: key)
    }
}


// MARK: - Capture from current game

extension RoundStore {

    /// Create & save a RoundSummary from the current GameManager state.
    /// Only records if the profile name matches an **active** seat.
    @discardableResult
    func recordFromCurrentGame(playerNameOverride: String? = nil) -> RoundSummary? {
        // Just read the game; do NOT mutate it here.
        guard let g = GameManager.shared.currentGame else { return nil }

        // Resolve the owner name
        let who = (playerNameOverride ?? ProfileStore.name)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !who.isEmpty else { return nil }

        // Find ACTIVE seat that matches the owner name (case-insensitive)
        let seatsRange = 0..<min(9, min(g.playerNames.count, g.playerActivated.count))
        guard let seat = seatsRange.first(where: { i in
            g.playerActivated[i] &&
            g.playerNames[i]
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .caseInsensitiveCompare(who) == .orderedSame
        }) else {
            // Owner not active => do not record
            return nil
        }

        // --- MONEY PER HOLE + TOTAL ---
        let moneyRowD: [Double] = (seat < g.playerMoney.count) ? g.playerMoney[seat] : []
        let moneyPerHoleInt: [Int] = moneyRowD.prefix(18).map { Int($0.rounded()) }
        let totalMoney: Int = moneyPerHoleInt.reduce(0) { acc, value in
            acc + value
        }

        // --- PROX PER HOLE + TOTAL ---
        let winners: [Int] = g.proxWinnerPerHole.map { $0 ?? -1 }
        let proxFlags: [Bool] = winners.prefix(18).map { $0 == seat }
        let totalProx: Int = proxFlags.filter { $0 }.count

        // --- WOLF / UMBIE PER HOLE (for stats) ---
        let wolfCalled: [Bool]  = Array(g.wolfCalledPerHole.prefix(18))
        let wolfTeamWon: [Bool] = Array(g.wolfTeamWonPerHole.prefix(18))
        let umbieWon: [Bool]    = Array(g.umbieWonPerHole.prefix(18))

        // --- SCORES + HOLES PLAYED ---
        var scoresForSeat = [Int?](repeating: nil, count: 18)

        if seat < g.scores.count,
           let first = g.scores.first,
           first.count == 18 {
            // [player][hole]
            for h in 0..<min(18, g.scores[seat].count) {
                scoresForSeat[h] = g.scores[seat][h]
            }
        } else if g.scores.count == 18 {
            // [hole][player]
            for h in 0..<18 {
                let row = g.scores[h]
                if seat < row.count {
                    scoresForSeat[h] = row[seat]
                }
            }
        }

        var sum = 0
        var haveAnyScore = false
        var holesPlayed = 0

        for h in 0..<18 {
            if let v = scoresForSeat[h] {
                sum += v
                haveAnyScore = true
                holesPlayed = h + 1  // last hole with a score
            }
        }

        // If we had no scores, estimate from money (any non-zero money means that hole was played)
        if !haveAnyScore {
            for h in 0..<min(18, moneyRowD.count) where moneyRowD[h] != 0 {
                holesPlayed = h + 1
            }
        }

        if holesPlayed == 0 {
            holesPlayed = 18 // fallback so we never divide by 0
        }

        let totalScore: Int? = haveAnyScore ? sum : nil

        // Final display name (stick with profile name if available)
        let finalName: String = {
            if !who.isEmpty { return who }
            if seat < g.playerNames.count {
                let n = g.playerNames[seat].trimmingCharacters(in: .whitespacesAndNewlines)
                if !n.isEmpty { return n }
            }
            return "Me"
        }()

        // Decide if this round should be tagged as "home/tracking course"
        let courseIDForRound: String = {
            guard
                let homeUUID = UUID(uuidString: ProfileStore.homeCourseID),
                let homeCourse = CourseLibrary.shared.get(id: homeUUID)
            else {
                return ""   // unknown / non-tracked course
            }

            let currentPars = Array(g.course.pars.prefix(18))
            let currentHCs  = Array(g.course.holeHandicaps.prefix(18))

            let homePars = Array(homeCourse.pars.prefix(18))
            let homeHCs  = Array(homeCourse.hcs.prefix(18))

            if currentPars == homePars && currentHCs == homeHCs {
                print("RoundStore: tagging round as home course \(homeCourse.name)")
                return homeCourse.id.uuidString
            } else {
                print("RoundStore: round NOT on home course (home = \(homeCourse.name))")
                return ""
            }
        }()

        let summary = RoundSummary(
            date: Date(),
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
            umbieWonPerHole: umbieWon
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

        // NOTE: this intentionally aggregates across ALL courses.
        let roundsForPlayer = rounds.filter {
            $0.playerName.caseInsensitiveCompare(trimmed) == .orderedSame
        }
        guard !roundsForPlayer.isEmpty else { return nil }

        let count = roundsForPlayer.count

        let totalMoney = roundsForPlayer.reduce(0) { acc, round in
            acc + round.totalMoney
        }

        let totalProx = roundsForPlayer.reduce(0) { acc, round in
            acc + round.totalProx
        }

        let totalHoles = roundsForPlayer.reduce(0) { acc, round in
            acc + max(round.holesPlayed, 1)
        }

        let moneyPer18: Double = totalHoles > 0
            ? Double(totalMoney) / Double(totalHoles) * 18.0
            : 0

        let proxPer18: Double = totalHoles > 0
            ? Double(totalProx) / Double(totalHoles) * 18.0
            : 0

        return MyStats(
            rounds: count,
            totalMoney: totalMoney,
            avgMoneyPerRound: moneyPer18,
            totalProx: totalProx,
            avgProxPerRound: proxPer18
        )
    }
}


// MARK: - Capture ALL players from current game

extension RoundStore {
    func recordAllPlayersFromCurrentGame() {
        guard let g = GameManager.shared.currentGame else { return }

        let seats = 0..<min(9, min(g.playerNames.count, g.playerActivated.count))

        for seat in seats where g.playerActivated[seat] {
            let name = g.playerNames[seat]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }

            _ = recordFromCurrentGame(playerNameOverride: name)
        }
    }
}
