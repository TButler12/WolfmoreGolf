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
    // Returns MatchRecord so caller has both the 6-char code and the UUID.
    func createMatch(
        courseA: String,
        courseB: String,
        stake: Double,
        games: [String]
    ) async throws -> MatchRecord {
        let code = generateCode()
        try await client.from("matches").insert([
            "code":     code,
            "course_a": courseA,
            "course_b": courseB,
            "stake":    String(stake),
            "games":    games.joined(separator: ","),
            "status":   "active"
        ]).execute()
        return try await joinMatch(code: code)
    }

    // MARK: - Join match
    func joinMatch(code: String) async throws -> MatchRecord {
        let response = try await client.from("matches")
            .select()
            .eq("code", value: code.uppercased())
            .single()
            .execute()
        return try response.value
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
        let response = try await client.from("hole_results")
            .select()
            .eq("match_id", value: matchId)
            .execute()
        return try response.value
    }

    // MARK: - Subscribe to hole results (live updates)
    func subscribeToResults(
        matchId: String,
        onResult: @escaping (HoleResultRecord) -> Void
    ) {
        let channel = client.realtimeV2.channel("match-\(matchId)")
        channel.on(
            .insert,
            table: "hole_results",
            filter: "match_id=eq.\(matchId)"
        ) { message in
            if let record = try? message.decodeRecord(as: HoleResultRecord.self) {
                DispatchQueue.main.async { onResult(record) }
            }
        }
        channel.subscribe()
    }

    // MARK: - Helpers
    private func generateCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}
