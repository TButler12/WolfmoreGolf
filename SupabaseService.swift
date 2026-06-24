// SupabaseService.swift
import Foundation
import Supabase

final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient
    private var holeScoreChannels: [String: RealtimeChannelV2] = [:]
    private var wolfSessionChannels: [String: RealtimeChannelV2] = [:]

    private init() {
        client = SupabaseClient(
            supabaseURL: SUPABASE_URL,
            supabaseKey: SUPABASE_ANON_KEY
        )
        print("DEBUG supabase URL: \(SUPABASE_URL)")
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
    func joinMatch(code: String, courseB: String = "") async throws -> MatchRecord {
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

        // Append joiner to opponent_names; record joiner's course for same-course detection
        var updateFields: [String: AnyJSON] = [
            "opponent_name":  AnyJSON.string(myName),
            "opponent_names": AnyJSON.array(newOpponents.map { .string($0) })
        ]
        if !courseB.isEmpty { updateFields["course_b"] = AnyJSON.string(courseB) }
        try await client
            .from("matches")
            .update(updateFields)
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
        let response: PostgrestResponse<[MatchRecord]> = try await client
            .from("matches")
            .select()
            .eq("status", value: "active")
            .gte("created_at", value: cutoff)
            .execute()
        return response.value
    }

    // MARK: - Archive match (hides it from fetchActiveMatches without hard-deleting)
    func archiveMatch(id: String) async throws {
        let response: PostgrestResponse<[MatchRecord]> = try await client
            .from("matches")
            .update(["status": "archived"])
            .eq("id", value: id)
            .select()
            .execute()
        if response.value.isEmpty {
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
        holeHc: Int? = nil,
        playerHc: Int? = nil
    ) async throws {
        let name = playerName ?? ProfileStore.name ?? ""
        let g = GameManager.shared.currentGame
        var payload: [String: AnyJSON] = [
            "match_id":        .string(matchId),
            "player_slot":     .string(String(playerSlot)),
            "hole":            .string(String(hole)),
            "gross_score":     .string(String(grossScore)),
            "player_name":     .string(name),
            "tournament_code": g?.tournamentCode.map { .string($0) } ?? .null,
            "group_code":      g?.groupCode.map { .string($0) } ?? .null
        ]
        if let hc = holeHc   { payload["hole_hc"]   = .string(String(hc)) }
        if let hc = playerHc { payload["player_hc"] = .string(String(hc)) }
        try await client.from("hole_scores").upsert(payload, onConflict: "match_id,player_slot,hole").execute()
    }

    // MARK: - Tournament per-hole scores
    // Writes one row per player per hole into hole_scores.
    // Conflict key: (match_id, tournament_code, player_name, hole) — fires regardless of Live Wolf status.
    func submitTournamentHoleScore(
        playerSlot: Int,
        playerName: String,
        hole: Int,
        grossScore: Int,
        netScore: Int,
        holeMoney: Double,
        totalMoney: Double,
        holeHc: Int? = nil,
        playerHc: Int? = nil,
        tournamentCode: String,
        groupCode: String,
        day: Int = 1,
        game_type: String = "wolf",
        skins_won: Int = 0
    ) async throws {
        let g = GameManager.shared.currentGame
        guard let matchId = g?.tournamentMatchId else {
            print("❌ submitTournamentHoleScore skipped — tournamentMatchId is nil (game not in a tournament)")
            return
        }
        let storedHole = hole + 1   // caller passes 0-based index; store as 1-based
        print("🏆 submitTournamentHoleScore matchId=\(matchId) player=\(playerName) hole=\(storedHole) gross=\(grossScore) net=\(netScore) holeMoney=\(holeMoney) totalMoney=\(totalMoney) game_type=\(game_type)")
        var payload: [String: AnyJSON] = [
            "match_id":        .string(matchId),
            "player_slot":     .string(String(playerSlot)),
            "player_name":     .string(playerName),
            "hole":            .string(String(storedHole)),
            "gross_score":     .string(String(grossScore)),
            "net_score":       .string(String(netScore)),
            "hole_money":      .double(holeMoney),
            "total_money":     .double(totalMoney),
            "tournament_code": .string(tournamentCode),
            "group_code":      .string(groupCode),
            "day":             .string(String(day)),
            "game_type":       .string(game_type),
            "skins_won":       .string(String(skins_won)),
        ]
        if let hc = holeHc   { payload["hole_hc"]   = .string(String(hc)) }
        if let hc = playerHc { payload["player_hc"] = .string(String(hc)) }
        try await client.from("hole_scores")
            .upsert(payload, onConflict: "match_id,tournament_code,player_name,hole,day,game_type")
            .execute()
    }

    // MARK: - Remote Nassau per-hole scores (remote_nassau_hole_scores table)
    // Upserts one hole at a time; conflict key is (match_id, side, hole).
    func submitRemoteNassauHole(
        matchId:    String,
        side:       String,   // "A" = host, "B" = opponent
        hole:       Int,      // 1-based
        grossScore: Int,
        handicap:   Int,      // hole HC difficulty rank
        playerHc:   Int? = nil,
        playerName: String? = nil
    ) async throws {
        var payload: [String: String] = [
            "match_id":    matchId,
            "side":        side,
            "hole":        String(hole),
            "gross_score": String(grossScore),
            "handicap":    String(handicap)
        ]
        if let ph = playerHc   { payload["player_hc"]   = String(ph) }
        if let pn = playerName { payload["player_name"] = pn }
        try await client
            .from("remote_nassau_hole_scores")
            .upsert(payload, onConflict: "match_id,side,hole")
            .execute()
    }

    func fetchRemoteNassauHoles(matchId: String) async throws -> [RemoteNassauHoleScore] {
        let response: PostgrestResponse<[RemoteNassauHoleScore]> = try await client
            .from("remote_nassau_hole_scores")
            .select()
            .eq("match_id", value: matchId)
            .order("hole")
            .execute()
        let rows = response.value
        print("DEBUG fetch returned \(rows.count) rows")
        for r in rows { print("DEBUG row: side=\(r.side) hole=\(r.hole) score=\(r.grossScore)") }
        return rows
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
        let channel = client.channel("scores-\(matchId)-\(UUID().uuidString)")
        holeScoreChannels["ins-\(matchId)"] = channel

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
                DispatchQueue.main.async { onScore(record) }
            }
        }

        Task {
            do {
                try await channel.subscribeWithError()
            } catch {
                print("ERROR hole_scores INSERT subscribe failed: \(error)")
            }
        }
    }

    // Score corrections come through as UPDATE events — separate channel required by SDK.
    func subscribeToHoleScoreUpdates(
        matchId: String,
        onScore: @escaping (HoleScoreRecord) -> Void
    ) {
        let channel = client.channel("scores-upd-\(matchId)-\(UUID().uuidString)")
        holeScoreChannels["upd-\(matchId)"] = channel

        channel.onPostgresChange(
            UpdateAction.self,
            schema: "public",
            table: "hole_scores",
            filter: "match_id=eq.\(matchId)"
        ) { action in
            if let record = try? action.decodeRecord(
                as: HoleScoreRecord.self,
                decoder: JSONDecoder()
            ) {
                DispatchQueue.main.async { onScore(record) }
            }
        }

        Task {
            do {
                try await channel.subscribeWithError()
            } catch {
                print("ERROR hole_scores UPDATE subscribe failed: \(error)")
            }
        }
    }

    func unsubscribeFromHoleScores(matchId: String) {
        for key in ["ins-\(matchId)", "upd-\(matchId)"] {
            if let ch = holeScoreChannels.removeValue(forKey: key) {
                Task { await ch.unsubscribe() }
            }
        }
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

    // MARK: - Wolf Live session

    func createWolfSession(playerNames: [String], courseName: String) async throws -> WolfSession {
        let code = generateCode()
        let hostName = ProfileStore.name ?? ""
        let response: PostgrestResponse<WolfSession> = try await client
            .from("wolf_sessions")
            .insert([
                "code":         AnyJSON.string(code),
                "host_name":    AnyJSON.string(hostName),
                "player_names": AnyJSON.array(playerNames.map { .string($0) }),
                "course_name":  AnyJSON.string(courseName),
                "status":       AnyJSON.string("active")
            ] as [String: AnyJSON])
            .select()
            .single()
            .execute()
        return response.value
    }

    func submitWolfHole(
        sessionId: String,
        hole: Int,
        scores: [Int],
        wolfSlot: Int?,
        partnerSlot: Int?,
        wentAlone: Bool,
        teamWon: Bool,
        payouts: [Double],
        decision: String? = nil,
        hammerMultiplier: Int = 1,
        pressed: Int = 0
    ) async throws {
        let g = GameManager.shared.currentGame
        struct Payload: Encodable {
            var session_id: String
            var hole: Int
            var scores: [Int]
            var went_alone: Bool
            var team_won: Bool
            var money_deltas: [Double]
            var wolf_slot: Int?
            var partner_slot: Int?
            var decision: String?
            var hammer_multiplier: Int
            var wolf_player: Int  // repurposed: press active (1) / inactive (0); column is integer in DB
            var tournament_code: String?
            var group_code: String?
        }
        let payload = Payload(
            session_id: sessionId,
            hole: hole,
            scores: scores,
            went_alone: wentAlone,
            team_won: teamWon,
            money_deltas: payouts,
            wolf_slot: wolfSlot,
            partner_slot: partnerSlot,
            decision: decision,
            hammer_multiplier: hammerMultiplier,
            wolf_player: pressed,
            tournament_code: g?.tournamentCode,
            group_code: g?.groupCode
        )
        print("🏆 submitWolfHole tournament_code=\(g?.tournamentCode ?? "nil") group_code=\(g?.groupCode ?? "nil")")
        print("DEBUG upsert payload: session=\(sessionId) hole=\(hole) scores=\(scores) wolfSlot=\(String(describing: wolfSlot)) partnerSlot=\(String(describing: partnerSlot)) wentAlone=\(wentAlone) teamWon=\(teamWon) moneyDeltas=\(payouts)")
        try await client.from("wolf_hole_results")
            .upsert(payload, onConflict: "session_id,hole")
            .execute()
    }

    func archiveWolfSession(id: String) async throws {
        try await client
            .from("wolf_sessions")
            .update(["status": AnyJSON.string("archived")] as [String: AnyJSON])
            .eq("id", value: id)
            .execute()
    }

    func fetchWolfSession(id: String) async throws -> WolfSession {
        let response: PostgrestResponse<WolfSession> = try await client
            .from("wolf_sessions")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
        return response.value
    }

    func fetchWolfSessionByCode(code: String) async throws -> WolfSession {
        let response: PostgrestResponse<WolfSession> = try await client
            .from("wolf_sessions")
            .select()
            .eq("code", value: code.uppercased())
            .single()
            .execute()
        return response.value
    }

    func fetchWolfHoleResults(sessionId: String) async throws -> [WolfHoleResult] {
        let response: PostgrestResponse<[WolfHoleResult]> = try await client
            .from("wolf_hole_results")
            .select()
            .eq("session_id", value: sessionId)
            .order("hole")
            .execute()
        return response.value
    }

    // One onPostgresChange registration per channel before subscribe() — SDK requirement.
    func subscribeToWolfHoles(
        sessionId: String,
        onResult: @escaping (WolfHoleResult) -> Void
    ) {
        let channel = client.channel("wolf-holes-\(sessionId)-\(UUID().uuidString)")
        wolfSessionChannels["holes-\(sessionId)"] = channel

        channel.onPostgresChange(
            InsertAction.self,
            schema: "public",
            table: "wolf_hole_results",
            filter: "session_id=eq.\(sessionId)"
        ) { action in
            do {
                let record = try action.decodeRecord(as: WolfHoleResult.self, decoder: JSONDecoder())
                DispatchQueue.main.async { onResult(record) }
            } catch {
                print("ERROR wolf INSERT decodeRecord failed: \(error)")
            }
        }

        Task {
            do {
                try await channel.subscribeWithError()
                print("DEBUG wolf INSERT channel subscribed for session \(sessionId)")
            } catch {
                print("DEBUG wolf INSERT channel error: \(error)")
            }
        }
    }

    // Score corrections (UPDATE) get their own channel to avoid multi-registration.
    func subscribeToWolfHoleUpdates(
        sessionId: String,
        onResult: @escaping (WolfHoleResult) -> Void
    ) {
        let channel = client.channel("wolf-holes-upd-\(sessionId)-\(UUID().uuidString)")
        wolfSessionChannels["holes-upd-\(sessionId)"] = channel

        channel.onPostgresChange(
            UpdateAction.self,
            schema: "public",
            table: "wolf_hole_results",
            filter: "session_id=eq.\(sessionId)"
        ) { action in
            print("DEBUG wolf UPDATE event received raw")
            do {
                let record = try action.decodeRecord(as: WolfHoleResult.self, decoder: JSONDecoder())
                DispatchQueue.main.async { onResult(record) }
            } catch {
                print("ERROR wolf UPDATE decodeRecord failed: \(error)")
            }
        }

        Task {
            do {
                try await channel.subscribeWithError()
                print("DEBUG wolf UPDATE channel subscribed for session \(sessionId)")
            } catch {
                print("DEBUG wolf UPDATE channel error: \(error)")
            }
        }
    }

    func subscribeToWolfSession(
        sessionId: String,
        onUpdate: @escaping (WolfSession) -> Void
    ) {
        let channel = client.channel("wolf-session-\(sessionId)")
        wolfSessionChannels["session-\(sessionId)"] = channel

        channel.onPostgresChange(
            UpdateAction.self,
            schema: "public",
            table: "wolf_sessions",
            filter: "id=eq.\(sessionId)"
        ) { action in
            if let record = try? action.decodeRecord(as: WolfSession.self, decoder: JSONDecoder()) {
                DispatchQueue.main.async { onUpdate(record) }
            }
        }

        Task { await channel.subscribe() }
    }

    func unsubscribeFromWolfSession(sessionId: String) async {
        for key in ["holes-\(sessionId)", "holes-upd-\(sessionId)", "session-\(sessionId)"] {
            if let ch = wolfSessionChannels.removeValue(forKey: key) {
                await ch.unsubscribe()
            }
        }
    }

    // MARK: - Tee Games (tournaments table)

    func createTournament(
        name: String,
        gameType: String,
        scoringType: String,
        stake: Double?,
        potAmount: Double?,
        carryTies: Bool?,
        courseName: String
    ) async throws -> TournamentRecord {
        let code = generateCode()
        var payload: [String: AnyJSON] = [
            "code":        AnyJSON.string(code),
            "name":        AnyJSON.string(name),
            "game_type":   AnyJSON.string(gameType),
            "scoring":     AnyJSON.string(scoringType),
            "created_by":  AnyJSON.string(DeviceID.id),
            "course_name": AnyJSON.string(courseName)
        ]
        if let s = stake { payload["stake"] = AnyJSON.double(s) }
        if let p = potAmount { payload["pot_amount"] = AnyJSON.double(p) }
        if let c = carryTies { payload["carry_ties"] = AnyJSON.bool(c) }

        let response: PostgrestResponse<TournamentRecord> = try await client
            .from("tournaments")
            .insert(payload)
            .select()
            .single()
            .execute()
        return response.value
    }

    func advanceTournamentDay(code: String) async throws {
        let records: [TournamentRecord] = try await client
            .from("tournaments")
            .select()
            .eq("code", value: code)
            .execute()
            .value
        guard let current = records.first?.currentDay else { return }
        try await client
            .from("tournaments")
            .update(["current_day": current + 1])
            .eq("code", value: code)
            .execute()
    }

    func fetchTournament(code: String) async throws -> TournamentRecord {
        let response: PostgrestResponse<TournamentRecord> = try await client
            .from("tournaments")
            .select()
            .eq("code", value: code.uppercased())
            .single()
            .execute()
        return response.value
    }

    func fetchTournamentHoleScores(code: String) async throws -> [TournamentHoleScoreRow] {
        let response: PostgrestResponse<[TournamentHoleScoreRow]> = try await client
            .from("hole_scores")
            .select("match_id, player_name, hole, gross_score, net_score, hole_money, total_money, day, game_type, skins_won")
            .eq("tournament_code", value: code.uppercased())
            .execute()
        return response.value
    }

    func fetchPlayerOffsets(code: String, day: Int) async throws -> [String: Double] {
        let rows: [PlayerOffsetRow] = try await client
            .from("player_offsets")
            .select()
            .eq("tournament_code", value: code)
            .eq("day", value: day)
            .execute()
            .value
        return Dictionary(uniqueKeysWithValues: rows.map { ($0.playerName, $0.offsetAmount) })
    }

    func upsertPlayerOffset(code: String, day: Int, playerName: String, amount: Double) async throws {
        print("🟡 upsertPlayerOffset called: code=\(code) day=\(day) player=\(playerName) amount=\(amount)")
        struct PlayerOffsetInsert: Encodable {
            let tournament_code: String
            let day: Int
            let player_name: String
            let offset_amount: Double
        }
        try await client
            .from("player_offsets")
            .upsert(PlayerOffsetInsert(
                tournament_code: code,
                day: day,
                player_name: playerName,
                offset_amount: amount
            ))
            .execute()
    }

    // MARK: - Helpers
    private func generateCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}
