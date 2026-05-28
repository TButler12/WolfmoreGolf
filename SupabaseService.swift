// SupabaseService.swift
import Foundation
import Supabase

final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

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
                "player_included":  AnyJSON.array(playerIncluded.map { .bool($0) })
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

        GameManager.shared.update { g in
            var state = g.nassauState ?? NassauState()
            if let stake = match.stake {
                state.settings.baseStake = stake
            }
            if let pm = match.pressMode, let mode = NassauPressMode(rawValue: pm) {
                state.settings.pressMode = mode
            }
            if let trigger = match.trigger {
                state.settings.autoPressTriggerDown = trigger
            }
            if let included = match.playerIncluded {
                state.playerIncluded = included
            }
            g.nassauState = state
        }

        return match
    }

    // MARK: - Fetch active matches
    func fetchActiveMatches() async throws -> [MatchRecord] {
        let response: PostgrestResponse<[MatchRecord]> = try await client
            .from("matches")
            .select()
            .eq("status", value: "active")
            .execute()
        return response.value
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
    func submitHoleScore(
        matchId: String,
        playerSlot: Int,
        hole: Int,
        grossScore: Int
    ) async throws {
        try await client.from("hole_scores").insert([
            "match_id":    matchId,
            "player_slot": String(playerSlot),
            "hole":        String(hole),
            "gross_score": String(grossScore)
        ]).execute()
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
