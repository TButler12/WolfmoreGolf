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
    var playerName: String         // from ProfileStore.name at save time
    var totalMoney: Int            // whole dollars (rounded if money is Double)
    var totalProx: Int
    var totalScore: Int?           // optional
    var holesPlayed: Int           // NEW: how many holes actually counted for this player

    enum CodingKeys: String, CodingKey {
        case id, date, playerName, totalMoney, totalProx, totalScore, holesPlayed
    }

    // Decode old saved data (that didn't have holesPlayed) as 18 holes
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date        = try c.decode(Date.self, forKey: .date)
        playerName  = try c.decode(String.self, forKey: .playerName)
        totalMoney  = try c.decode(Int.self, forKey: .totalMoney)
        totalProx   = try c.decode(Int.self, forKey: .totalProx)
        totalScore  = try c.decodeIfPresent(Int.self, forKey: .totalScore)
        holesPlayed = try c.decodeIfPresent(Int.self, forKey: .holesPlayed) ?? 18
    }

    // Default init you already get from Swift, but we restate for clarity
    init(
        id: UUID = UUID(),
        date: Date,
        playerName: String,
        totalMoney: Int,
        totalProx: Int,
        totalScore: Int?,
        holesPlayed: Int
    ) {
        self.id = id
        self.date = date
        self.playerName = playerName
        self.totalMoney = totalMoney
        self.totalProx = totalProx
        self.totalScore = totalScore
        self.holesPlayed = holesPlayed
    }
}

// Optional summary type you can use in UI
struct MyStats {
    let rounds: Int
    let totalMoney: Int
    let avgMoneyPerRound: Double
    let totalProx: Int
    let avgProxPerRound: Double
}

private let courseID = "HOME-COURSE"   // same string you used in TrackFriendsVC
private var trackedFriendStats: [(friend: Friend, stats: MyStats)] {
    let trackedFriends = FriendStore.shared.friends.filter {
        FriendTrackStore.shared.isTracked($0.id, on: courseID)
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

    // Save a new round at the top
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

    /// Delete the most recently saved round (top of list)
    func deleteLast() {
        guard !rounds.isEmpty else { return }
        rounds.removeFirst()
        save()
    }

    // MARK: Persistance

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
// MARK: - Capture from current game

extension RoundStore {

    /// Create & save a RoundSummary from the current GameManager state.
    /// Only records if the profile name matches an **active** seat.
    @discardableResult
    func recordFromCurrentGame(playerNameOverride: String? = nil) -> RoundSummary? {
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

        // --- MONEY TOTALS ---
        let moneyRowD: [Double] = (seat < g.playerMoney.count) ? g.playerMoney[seat] : []
        let totalMoney: Int = Int(moneyRowD.prefix(18).reduce(0.0, +).rounded())

        // --- PROX WINS ---
        let winners: [Int] = g.proxWinnerPerHole.map { $0 ?? -1 }
        let totalProx = winners.prefix(18).filter { $0 == seat }.count

        // --- SCORES + HOLES PLAYED ---
        var scoresForSeat = [Int?](repeating: nil, count: 18)

        if seat < g.scores.count, let first = g.scores.first, first.count == 18 {
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
                holesPlayed = h + 1      // last hole with a score
            }
        }

        // If we had no scores, estimate from money (any non-zero money means that hole was played)
        if !haveAnyScore {
            for h in 0..<min(18, moneyRowD.count) where moneyRowD[h] != 0 {
                holesPlayed = h + 1
            }
        }

        if holesPlayed == 0 {
            // total fallback so we never divide by 0 in stats
            holesPlayed = 18
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

        let summary = RoundSummary(
            date: Date(),
            playerName: finalName,
            totalMoney: totalMoney,
            totalProx: totalProx,
            totalScore: totalScore,
            holesPlayed: holesPlayed
        )

        add(summary)
        return summary
    }
}

// MARK: - Per-friend stats

extension RoundStore {
    /// Aggregate stats for a given player name (case-insensitive).
    func stats(forPlayerNamed name: String) -> MyStats? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // All rounds saved for this name
        let roundsForPlayer = rounds.filter {
            $0.playerName.caseInsensitiveCompare(trimmed) == .orderedSame
        }
        guard !roundsForPlayer.isEmpty else { return nil }

        let count      = roundsForPlayer.count
        let totalMoney = roundsForPlayer.reduce(0) { $0 + $1.totalMoney }
        let totalProx  = roundsForPlayer.reduce(0) { $0 + $1.totalProx }

        // Normalize by total holes, then scale to 18
        let totalHoles = roundsForPlayer.reduce(0) { $0 + max($1.holesPlayed, 1) }

        let moneyPer18: Double = totalHoles > 0
            ? Double(totalMoney) / Double(totalHoles) * 18.0
            : 0

        let proxPer18: Double = totalHoles > 0
            ? Double(totalProx) / Double(totalHoles) * 18.0
            : 0

        return MyStats(
            rounds: count,
            totalMoney: totalMoney,
            avgMoneyPerRound: moneyPer18,   // now "per 18 holes"
            totalProx: totalProx,
            avgProxPerRound: proxPer18      // now "per 18 holes"
        )
    }
}

// MARK: - Capture ALL players from current game

extension RoundStore {

    /// Helper if you ever want to save EVERY active player on the card.
    /// (Uses the same logic as `recordFromCurrentGame`.)
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
