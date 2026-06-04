// GameManager.swift
import Foundation

// MARK: - Notification Names
extension Notification.Name {
    static let reloadUI = Notification.Name("ReloadUI")
}

// MARK: - GameManager

    
final class GameManager {
    static let shared = GameManager()
    // ...
    var canRandomizeTeams = false   // Only true right after a Reset
    var randomizeUnlocked: Bool = false   // locked by default

    // Tracks which wolf team player last received an odd dollar, for fair alternation.
    // Reset each new game; updated by computeHolePayout when a remainder occurs.
    var lastOddDollarRecipient: Int? = nil
    var lastOddDollarHole: Int = -1

    private init() {}
    
    // Single save slot (no external store, no ids)
    private let currentKey = "currentGame_v1"
    
    // In-memory model
    var currentGame: GameData?
    var hasActiveGame: Bool {
        return currentGame != nil
    }
    
    // MARK: - Create / Load / Save
    
    /// Create a brand-new game with defaults, save, and notify once.
    func startNewGame(name: String = "New Game") {
        lastOddDollarRecipient = nil
        lastOddDollarHole = -1
        let g = baselineNewGame(named: name)
        currentGame = g
        saveCurrent()
        requestReload()
    }
    
    
    /// Save current game to UserDefaults (no notify here).
    func saveCurrent() {
        guard var g = currentGame
        else { return }
        do {
            let data = try JSONEncoder().encode(g)
            UserDefaults.standard.set(data, forKey: currentKey)
        } catch {
            print("💾 Save failed:", error)
        }
    }
    
    /// Load the single saved game (if any), normalize, and optionally notify UI.
    @discardableResult
    func loadLastOpened(notify: Bool = true) -> Bool {
        guard let data = UserDefaults.standard.data(forKey: currentKey) else { return false }
        do {
            var g = try JSONDecoder().decode(GameData.self, from: data)
            normalizeShapes(&g)
            currentGame = g
            if notify { requestReload() }
            return true
        } catch {
            print("📦 Load failed:", error)
            return false
        }
    }
    
    // MARK: - Mutations
    
    /// For typing/continuous edits. No save, no notify.
    func updateDuringEditing(_ mutate: (inout GameData) -> Void) {
        guard var g = currentGame else { return }
        mutate(&g)
        currentGame = g
    }
    
    /// Persist immediately (no auto-reload). Call requestReload() yourself if needed.
    func update(_ mutate: (inout GameData) -> Void) {
        guard var g = currentGame else { return }
        mutate(&g)
        currentGame = g
        saveCurrent()
    }
    
    /// Mutate, save, then repaint once.
    func updateAndReload(_ mutate: (inout GameData) -> Void) {
        update(mutate)
        requestReload()
    }
    
    // MARK: - Round Reset (keep course & roster)
    
    /// Start a fresh round but keep: course (pars/HC), roster (names/HC/active), rosterNames.
    func resetForNewRoundPreservingCourseAndRoster() {
        guard let old = currentGame else { return }
        
        let keepCoursePar  = old.courseParToPass
        let keepCourseHC   = old.courseHCToPass
        let keepNames      = old.playerNames
        let keepHCs        = old.hcPlayers
        let keepActives    = old.playerActivated
        let keepRosterList = old.rosterNames
        
        var fresh = baselineNewGame(named: old.gameName)
        fresh.courseParToPass   = keepCoursePar
        fresh.courseHCToPass    = keepCourseHC
        fresh.playerNames       = keepNames
        fresh.hcPlayers         = keepHCs
        fresh.playerActivated   = keepActives
        fresh.rosterNames       = keepRosterList
        // If you want to keep the existing per-hole stakes, uncomment:
        // fresh.gameHoleDollarsArray = old.gameHoleDollarsArray
        
        currentGame = fresh
        saveCurrent()
        requestReload()
    }
    
    // MARK: - Roster helper
    
    /// Add a name to the persisted roster if not already present (case-insensitive).
    func addNameToRoster(_ raw: String) {
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        update { g in
            let exists = g.rosterNames.contains { $0.compare(name, options: .caseInsensitive) == .orderedSame }
            if !exists { g.rosterNames.append(name) }
        }
    }
    
    // MARK: - Notify
    
    /// Explicitly tell the UI to repaint (main thread).
    func requestReload() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .reloadUI, object: nil)
        }
    }
    
    // MARK: - Bootstrap helpers
    
    /// If `currentGame` exists, normalize shapes and save.
    func normalizeCurrentIfNeeded() {
        guard var g = currentGame else { return }
        normalizeShapes(&g)
        currentGame = g
        saveCurrent()
    }
    
    
    func resetCurrentGame(keepCourse: Bool = true, defaultBet: Double = 2.0) {
        guard var g = currentGame else { return }
        
        // Preserve course-related values
        let savedCourse = g.course
        let savedPars   = g.courseParToPass
        let savedHCs    = g.courseHCToPass
        
        // Round-only reset
        g.hole = 0
        g.scores               = Array(repeating: Array(repeating: nil, count: STANDARD_HOLES), count: MAX_PLAYERS)
        g.playerMoney          = Array(repeating: Array(repeating: 0.0, count: STANDARD_HOLES), count: MAX_PLAYERS)
        g.rollApplied          = Array(repeating: false, count: STANDARD_HOLES)
        g.rerollApplied        = Array(repeating: false, count: STANDARD_HOLES)
        g.rerollBaseAmount     = Array(repeating: 0.0, count: STANDARD_HOLES)
        g.aloneApplied         = Array(repeating: false, count: STANDARD_HOLES)
        g.pressLevel           = Array(repeating: 0, count: STANDARD_HOLES)
        g.pressInitiatedHole   = nil
        g.proxWinnerPerHole    = Array(repeating: nil, count: STANDARD_HOLES)
        g.wolfButtonStatus     = Array(repeating: Array(repeating: false, count: STANDARD_HOLES), count: MAX_PLAYERS)
        g.gameHoleDollarsArray = Array(repeating: defaultBet, count: STANDARD_HOLES)
        
        // ✅ NEW: Wolf/Hammer state reset (safe defaults)
        g.hammerCountPerHole   = Array(repeating: 0, count: STANDARD_HOLES)
        g.wolfPlayerPerHole    = Array(repeating: nil, count: STANDARD_HOLES)
        g.wolfWentAlonePerHole = Array(repeating: false, count: STANDARD_HOLES)
        
        if keepCourse {
            g.course          = savedCourse
            g.courseParToPass = savedPars
            g.courseHCToPass  = savedHCs
        }
        
        currentGame = g
        saveCurrent()
        NotificationCenter.default.post(name: .reloadUI, object: nil)
    }
    
    
    // MARK: - Private builders / normalizers
    
    /// Build a fresh game with all arrays sized and defaults filled.
    private func baselineNewGame(named name: String) -> GameData {
        var g = GameData()
        
        // Game type default (keeps  current behavior)
        g.gameType = .sixPointScotch
        
        // Hammer/Wolf storage
        g.hammerCountPerHole   = Array(repeating: 0,   count: STANDARD_HOLES)
        g.wolfPlayerPerHole    = Array(repeating: nil, count: STANDARD_HOLES)
        g.wolfWentAlonePerHole = Array(repeating: false, count: STANDARD_HOLES)
        
        g.gameName = name
        g.hole = 0
        
        // Seats (9)
        g.playerNames     = Array(repeating: "",    count: MAX_PLAYERS)
        g.hcPlayers       = Array(repeating: 0,     count: MAX_PLAYERS)   // S-column deltas
        g.playerActivated = Array(repeating: false, count: MAX_PLAYERS)
        
        // Course (18)
        // g.courseParToPass = Array(repeating: 4, count: STANDARD_HOLES)
        // g.courseHCToPass  = Array(1...STANDARD_HOLES)
        
        // Stakes per hole
        g.gameHoleDollarsArray = Array(repeating: 2.0, count: STANDARD_HOLES)
        
        // Wolves (5×18) & Prox (seat 0…4 or nil)
        g.wolfButtonStatus  = Array(repeating: Array(repeating: false, count: STANDARD_HOLES), count: MAX_PLAYERS)
        g.proxWinnerPerHole = Array(repeating: nil, count: STANDARD_HOLES)
        
        // Scores & per-player payouts (9×18)
        g.scores      = Array(repeating: Array(repeating: nil, count: STANDARD_HOLES), count: MAX_PLAYERS)
        g.playerMoney = Array(repeating: Array(repeating: 0,   count: STANDARD_HOLES), count: MAX_PLAYERS)
        
        // Press / previous press flags
        g.pressedPushedToggleArray         = Array(repeating: false, count: STANDARD_HOLES)
        g.previousPressedPushedToggleArray = Array(repeating: false, count: STANDARD_HOLES)
        
        // Roster picker list
        g.rosterNames = []
        
        // Nassau defaults
        g.nassauState = NassauEngine.makeDefaultState(
            playerNames: g.playerNames,
            activeFlags: g.playerActivated
        )
        
        return g
    }
    
    /// Ensure an old save has all fields with correct sizes/defaults.
    private func normalizeShapes(_ g: inout GameData) {
        g.normalize()   // ✅ handles gameType + hammer/wolf arrays
        
        // Seats
        if g.playerNames.count != MAX_PLAYERS     { g.playerNames     = pad(g.playerNames,     to: MAX_PLAYERS,  fill: "") }
        if g.hcPlayers.count != MAX_PLAYERS       { g.hcPlayers       = pad(g.hcPlayers,       to: MAX_PLAYERS,  fill: 0) }
        if g.playerActivated.count != MAX_PLAYERS { g.playerActivated = pad(g.playerActivated, to: MAX_PLAYERS,  fill: false) }
        
        // Course
        if g.courseParToPass.count != STANDARD_HOLES { g.courseParToPass = pad(g.courseParToPass, to: STANDARD_HOLES, fill: 4) }
        if g.courseHCToPass.count  != STANDARD_HOLES { g.courseHCToPass  = pad(g.courseHCToPass,  to: STANDARD_HOLES, fill: 1) }
        
        // Stakes
        if g.gameHoleDollarsArray.count != STANDARD_HOLES {
            g.gameHoleDollarsArray = pad(g.gameHoleDollarsArray, to: STANDARD_HOLES, fill: 2.0)
        }
        
        // Wolves & Prox
        if g.wolfButtonStatus.count != MAX_PLAYERS || g.wolfButtonStatus.first?.count != STANDARD_HOLES {
            g.wolfButtonStatus = Array(repeating: Array(repeating: false, count: STANDARD_HOLES), count: MAX_PLAYERS)
        }
        if g.proxWinnerPerHole.count != STANDARD_HOLES {
            g.proxWinnerPerHole = Array(repeating: nil, count: STANDARD_HOLES)
        }
        
        // Scores & Money
        if g.scores.count != MAX_PLAYERS || g.scores.first?.count != STANDARD_HOLES {
            g.scores = Array(repeating: Array(repeating: nil, count: STANDARD_HOLES), count: MAX_PLAYERS)
        }
        if g.playerMoney.count != MAX_PLAYERS || g.playerMoney.first?.count != STANDARD_HOLES {
            g.playerMoney = Array(repeating: Array(repeating: 0, count: STANDARD_HOLES), count: MAX_PLAYERS)
        }
        
        // Press
        if g.pressedPushedToggleArray.count != STANDARD_HOLES {
            g.pressedPushedToggleArray = Array(repeating: false, count: STANDARD_HOLES)
        }
        if g.previousPressedPushedToggleArray.count != STANDARD_HOLES {
            g.previousPressedPushedToggleArray = Array(repeating: false, count: STANDARD_HOLES)
        }
        
        // Roster list ok even if empty
        if g.rosterNames.isEmpty { g.rosterNames = [] }
        
        // Clamp current hole
        g.hole = max(0, min(17, g.hole))
    }
    
    
    private func pad<T>(_ a: [T], to n: Int, fill: T) -> [T] {
        a.count >= n ? Array(a.prefix(n)) : a + Array(repeating: fill, count: n - a.count)
    }
    
    
    
    func saveCurrentRoundAsLastRound() {
        guard let g = currentGame else { return }
        
        let profileName = (ProfileStore.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let playerName = profileName.isEmpty ? (g.playerNames.first ?? "Player") : profileName
        
        let myIndex = g.playerNames.firstIndex {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedCaseInsensitiveCompare(playerName) == .orderedSame
        } ?? 0
        
        let scores: [Int?] = myIndex < g.scores.count
        ? Array(g.scores[myIndex].prefix(STANDARD_HOLES))
        : Array(repeating: nil, count: STANDARD_HOLES)
        
        let pars = Array(g.course.pars.prefix(STANDARD_HOLES))
        
        let fairways: [Bool?] = myIndex < g.fairwayHit.count
        ? Array(g.fairwayHit[myIndex].prefix(STANDARD_HOLES))
        : Array(repeating: nil, count: STANDARD_HOLES)
        
        let girs: [Bool?] = myIndex < g.girHit.count
        ? Array(g.girHit[myIndex].prefix(STANDARD_HOLES))
        : Array(repeating: nil, count: STANDARD_HOLES)
        
        let putts: [Int?] = myIndex < g.puttsPerHole.count
        ? Array(g.puttsPerHole[myIndex].prefix(STANDARD_HOLES))
        : Array(repeating: nil, count: STANDARD_HOLES)
        
        let totalScore = scores.compactMap { $0 }.reduce(0, +)
        let totalPutts = putts.compactMap { $0 }.reduce(0, +)
        let fairwaysHitCount = fairways.compactMap { $0 }.filter { $0 }.count
        let girCount = girs.compactMap { $0 }.filter { $0 }.count
        
        let completed = CompletedRound(
            date: Date(),
            courseName: g.course.name,
            playerName: playerName,
            holeScores: scores,
            pars: pars,
            fairwaysHit: fairways,
            girs: girs,
            putts: putts,
            totalScore: totalScore,
            totalPutts: totalPutts,
            fairwaysHitCount: fairwaysHitCount,
            girCount: girCount
        )
        
        RoundHistoryStore.shared.saveLastRound(completed)
    }
}


extension GameManager {

    /// For the current game, pre-fill every hole for each ACTIVE player with the
    /// course par as their score, but only if that score is currently nil.
    /// (We never overwrite scores that are already set.)
    func seedScoresWithParsForActivePlayers() {
        // Work on a mutable copy of the game
        guard var game = self.currentGame else { return }

        // How many holes? usually 18, but respect the course data
        let holeCount = min(STANDARD_HOLES, game.courseParToPass.count)
        guard holeCount > 0 else { return }

        // Seats visible on the Game screen
        let seatsRange = 0 ..< min(MAX_PLAYERS,
                                   min(game.playerNames.count,
                                       game.playerActivated.count))

        // Ensure scores is shaped as [player][hole] and has a row per seat
        if game.scores.count < seatsRange.endIndex {
            for _ in game.scores.count ..< seatsRange.endIndex {
                game.scores.append(Array(repeating: nil, count: holeCount))
            }
        }

        // Fill nil scores with par for every active player, every hole
        for seat in seatsRange where game.playerActivated[seat] {

            // Make sure this player’s row has a slot for each hole
            if game.scores[seat].count < holeCount {
                game.scores[seat] += Array(
                    repeating: nil,
                    count: holeCount - game.scores[seat].count
                )
            }

            for hole in 0..<holeCount {
                if game.scores[seat][hole] == nil {
                    game.scores[seat][hole] = game.courseParToPass[hole]
                }
            }
        }

        // Write back to the singleton
        self.currentGame = game
    }
}
extension GameManager {

    /// True if there is a saved/continue-able game on this device
    var hasSavedGame: Bool {
        // If it's already loaded in memory, yes
        if currentGame != nil { return true }

        // Otherwise check the actual save slot
        return UserDefaults.standard.data(forKey: "currentGame_v1") != nil
    }
}
