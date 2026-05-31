// SupabaseService.swift
import Foundation
import Supabase

final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient
    private var holeScoreChannels: [String: RealtimeChannelV2] = [:]

    private init() {
        client = SupabaseClient(
            supabaseURL: SUPABASE_URL,
            supabaseKey: SUPABASE_ANON_KEY
        )
    }

    // MARK: - Match creation
    // Chain .select().single() after .insert() and annotate the response
    // type so the compiler picks execute<T: Decodable> over execute<Void>.
    func createMatch(
        courseA: String,
        courseB: String,
        stake: Double,
        games: [String]
    ) async throws -> MatchRecord {
        let code = generateCode()
        let nassau = GameManager.shared.currentGame?.nassauState
        let pressMode      = nassau?.settings.pressMode.rawValue ?? NassauPressMode.auto.rawValue
        let trigger        = nassau?.settings.autoPressTriggerDown ?? 2
        let playerIncluded = nassau?.playerIncluded ?? Array(repeating: true, count: MAX_PLAYERS)

        let response: PostgrestResponse<MatchRecord> = try await client
            .from("matches")
            .insert([
                "code":             AnyJSON.string(code),
                "course_a":         AnyJSON.string(courseA),
                "course_b":         AnyJSON.string(courseB),
                "stake":            AnyJSON.double(stake),
                "games":            AnyJSON.array(games.map { .string($0) }),
                "status":           AnyJSON.string("active"),
                "press_mode":       AnyJSON.string(pressMode),
                "trigger":          AnyJSON.integer(trigger),
                "player_included":  AnyJSON.array(playerIncluded.map { .bool($0) }),
                "host_name":        AnyJSON.string(ProfileStore.name ?? "")
            ] as [String: AnyJSON])
            .select()
            .single()
            .execute()
        return response.value
    }

    // MARK: - Join match (applies host's Nassau settings to local state)
    func joinMatch(code: String) async throws -> MatchRecord {
        let response: PostgrestResponse<MatchRecord> = try await client
            .from("matches")
            .select()
            .eq("code", value: code.uppercased())
            .single()
            .execute()
        let match = response.value

        let currentOpponents = match.opponentNames ?? []
        if currentOpponents.count >= 5 {
            throw NSError(domain: "WolfmoreGolf", code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "Match is full (maximum 5 opponents)"])
        }

        let myName = ProfileStore.name ?? ""
        let playerSlot = currentOpponents.count + 1   // host=0, first joiner=1, etc.
        let newOpponents = currentOpponents + [myName]
        print("DEBUG joinMatch: assigning playerSlot=\(playerSlot) name=\(myName)")

        // Append joiner to opponent_names; keep legacy opponent_name for old clients
        try await client
            .from("matches")
            .update([
                "opponent_name":  AnyJSON.string(myName),
                "opponent_names": AnyJSON.array(newOpponents.map { .string($0) })
            ] as [String: AnyJSON])
            .eq("id", value: match.id)
            .execute()

        GameManager.shared.update { g in
            var state = g.nassauState ?? NassauState()
            if let stake   = match.stake                                         { state.settings.baseStake = stake }
            if let pm      = match.pressMode, let mode = NassauPressMode(rawValue: pm) { state.settings.pressMode = mode }
            if let trigger = match.trigger                                        { state.settings.autoPressTriggerDown = trigger }
            if let included = match.playerIncluded                               { state.playerIncluded = included }
            g.nassauState = state
        }

        return match
    }

    // MARK: - Fetch single match by UUID
    func fetchMatch(id: String) async throws -> MatchRecord {
        let response: PostgrestResponse<MatchRecord> = try await client
            .from("matches")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
        return response.value
    }

    // MARK: - Fetch active matches (last 24 hours only)
    func fetchActiveMatches() async throws -> [MatchRecord] {
        let cutoff = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400))
        print("DEBUG fetchActiveMatches: querying status=active, cutoff=\(cutoff)")
        let response: PostgrestResponse<[MatchRecord]> = try await client
            .from("matches")
            .select()
            .eq("status", value: "active")
            .gte("created_at", value: cutoff)
            .execute()
        print("DEBUG fetchActiveMatches: \(response.value.count) active matches returned")
        return response.value
    }

    // MARK: - Archive match (hides it from fetchActiveMatches without hard-deleting)
    func archiveMatch(id: String) async throws {
        print("DEBUG archiveMatch query: id=\(id)")
        let response: PostgrestResponse<[MatchRecord]> = try await client
            .from("matches")
            .update(["status": "archived"])
            .eq("id", value: id)
            .select()
            .execute()
        print("DEBUG archiveMatch: \(id) — rows updated: \(response.value.count)")
        if response.value.isEmpty {
            print("WARNING archiveMatch: 0 rows updated — RLS policy may be blocking UPDATE on matches table")
            throw NSError(domain: "WolfmoreGolf", code: 403,
                          userInfo: [NSLocalizedDescriptionKey: "Could not delete match — check Supabase RLS policy on matches table"])
        }
    }

    // MARK: - Add player to match
    func addPlayer(
        matchId: String,
        name: String,
        handicap: Int,
        slot: Int
    ) async throws {
        try await client.from("players").insert([
            "match_id":  matchId,
            "name":      name,
            "handicap":  String(handicap),
            "slot":      String(slot)
        ]).execute()
    }

    // MARK: - Submit hole score
    // playerName defaults to the device owner; pass an explicit name when submitting other players' scores.
    func submitHoleScore(
        matchId: String,
        playerSlot: Int,
        hole: Int,
        grossScore: Int,
        playerName: String? = nil,
        holeHc: Int? = nil
    ) async throws {
        let name = playerName ?? ProfileStore.name ?? ""
        print("DEBUG submitHoleScore: matchId=\(matchId) hole=\(hole) score=\(grossScore) playerName=\(name) hc=\(holeHc.map(String.init) ?? "nil")")
        var payload: [String: String] = [
            "match_id":    matchId,
            "player_slot": String(playerSlot),
            "hole":        String(hole),
            "gross_score": String(grossScore),
            "player_name": name
        ]
        if let hc = holeHc { payload["hole_hc"] = String(hc) }
        try await client.from("hole_scores").upsert(payload, onConflict: "match_id,player_slot,hole").execute()
    }

    // MARK: - Fetch raw hole scores
    func fetchHoleScores(matchId: String) async throws -> [HoleScoreRecord] {
        let response: PostgrestResponse<[HoleScoreRecord]> = try await client
            .from("hole_scores")
            .select()
            .eq("match_id", value: matchId)
            .execute()
        return response.value
    }

    // MARK: - Subscribe to hole scores (live opponent updates)
    // Channel stored internally so the VC can call unsubscribeFromHoleScores on dismiss.
    func subscribeToHoleScores(
        matchId: String,
        onScore: @escaping (HoleScoreRecord) -> Void
    ) {
        let channel = client.channel("scores-\(matchId)")
        holeScoreChannels[matchId] = channel

        channel.onPostgresChange(
            InsertAction.self,
            schema: "public",
            table: "hole_scores",
            filter: "match_id=eq.\(matchId)"
        ) { action in
            if let record = try? action.decodeRecord(
                as: HoleScoreRecord.self,
                decoder: JSONDecoder()
            ) {
                print("DEBUG incomingScore: \(record)")
                DispatchQueue.main.async { onScore(record) }
            }
        }

        Task {
            await channel.subscribe()
            print("DEBUG subscribeToHoleScores: subscribed to matchId=\(matchId)")
        }
    }

    func unsubscribeFromHoleScores(matchId: String) {
        guard let channel = holeScoreChannels.removeValue(forKey: matchId) else { return }
        Task { await channel.unsubscribe() }
    }

    // MARK: - Fetch resolved hole results
    func fetchResults(matchId: String) async throws -> [HoleResultRecord] {
        let response: PostgrestResponse<[HoleResultRecord]> = try await client
            .from("hole_results")
            .select()
            .eq("match_id", value: matchId)
            .execute()
        return response.value
    }

    // MARK: - Subscribe to hole results (live updates)
    // onPostgresChange is synchronous and returns RealtimeSubscription.
    // Only subscribe() is async — wrap it in Task {}.
    // decodeRecord requires an explicit decoder argument.
    @discardableResult
    func subscribeToResults(
        matchId: String,
        onResult: @escaping (HoleResultRecord) -> Void
    ) -> RealtimeSubscription {
        let channel = client.channel("match-\(matchId)")

        let subscription = channel.onPostgresChange(
            InsertAction.self,
            schema: "public",
            table: "hole_results",
            filter: "match_id=eq.\(matchId)"
        ) { action in
            if let record = try? action.decodeRecord(
                as: HoleResultRecord.self,
                decoder: JSONDecoder()
            ) {
                DispatchQueue.main.async { onResult(record) }
            }
        }

        Task { await channel.subscribe() }

        return subscription
    }

    // MARK: - Helpers
    private func generateCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}
