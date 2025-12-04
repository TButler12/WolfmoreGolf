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

    
    private init() {}

    // Single save slot (no external store, no ids)
    private let currentKey = "currentGame_v1"

    // In-memory model
    var currentGame: GameData?

    // MARK: - Create / Load / Save

    /// Create a brand-new game with defaults, save, and notify once.
    func startNewGame(name: String = "New Game") {
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
        g.scores              = Array(repeating: Array(repeating: nil,  count: 18), count: 9)
        g.playerMoney         = Array(repeating: Array(repeating: 0.0,  count: 18), count: 9)
        g.rollApplied         = Array(repeating: false, count: 18)
        g.rerollApplied       = Array(repeating: false, count: 18)
        g.rerollBaseAmount    = Array(repeating: 0.0,  count: 18)
        g.aloneApplied        = Array(repeating: false, count: 18)
        g.pressMask           = Array(repeating: false, count: 18)
        g.proxWinnerPerHole   = Array(repeating: nil,   count: 18)
        g.wolfButtonStatus    = Array(repeating: Array(repeating: false, count: 18), count: 9)
        g.gameHoleDollarsArray = Array(repeating: defaultBet, count: 18)

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
        g.gameName = name
        g.hole = 0

        // Seats (9)
        g.playerNames     = Array(repeating: "",    count: 9)
        g.hcPlayers       = Array(repeating: 0,     count: 9)   // S-column deltas
        g.playerActivated = Array(repeating: false, count: 9)

        // Course (18)
     // g.courseParToPass = Array(repeating: 4, count: 18)
     // g.courseHCToPass  = Array(1...18)

        // Stakes per hole
        g.gameHoleDollarsArray = Array(repeating: 2.0, count: 18)

        // Wolves (9×18) & Prox (seat 0…4 or nil)
        g.wolfButtonStatus  = Array(repeating: Array(repeating: false, count: 18), count: 9)
        g.proxWinnerPerHole = Array(repeating: nil, count: 18)

        // Scores & per-player payouts (9×18)
        g.scores      = Array(repeating: Array(repeating: nil, count: 18), count: 9)
        g.playerMoney = Array(repeating: Array(repeating: 0,   count: 18), count: 9)

        // Press / previous press flags
        g.pressedPushedToggleArray         = Array(repeating: false, count: 18)
        g.previousPressedPushedToggleArray = Array(repeating: false, count: 18)

        // Roster picker list
        g.rosterNames = []

        return g
    }

    /// Ensure an old save has all fields with correct sizes/defaults.
    private func normalizeShapes(_ g: inout GameData) {
        // Seats
        if g.playerNames.count != 9     { g.playerNames     = pad(g.playerNames,     to: 9,  fill: "") }
        if g.hcPlayers.count != 9       { g.hcPlayers       = pad(g.hcPlayers,       to: 9,  fill: 0) }
        if g.playerActivated.count != 9 { g.playerActivated = pad(g.playerActivated, to: 9,  fill: false) }

        // Course
        if g.courseParToPass.count != 18 { g.courseParToPass = pad(g.courseParToPass, to: 18, fill: 4) }
        if g.courseHCToPass.count  != 18 { g.courseHCToPass  = pad(g.courseHCToPass,  to: 18, fill: 1) }

        // Stakes
        if g.gameHoleDollarsArray.count != 18 {
            g.gameHoleDollarsArray = pad(g.gameHoleDollarsArray, to: 18, fill: 2.0)
        }

        // Wolves & Prox
        if g.wolfButtonStatus.count != 9 || g.wolfButtonStatus.first?.count != 18 {
            g.wolfButtonStatus = Array(repeating: Array(repeating: false, count: 18), count: 9)
        }
        if g.proxWinnerPerHole.count != 18 {
            g.proxWinnerPerHole = Array(repeating: nil, count: 18)
        }

        // Scores & Money
        if g.scores.count != 9 || g.scores.first?.count != 18 {
            g.scores = Array(repeating: Array(repeating: nil, count: 18), count: 9)
        }
        if g.playerMoney.count != 9 || g.playerMoney.first?.count != 18 {
            g.playerMoney = Array(repeating: Array(repeating: 0, count: 18), count: 9)
        }

        // Press
        if g.pressedPushedToggleArray.count != 18 {
            g.pressedPushedToggleArray = Array(repeating: false, count: 18)
        }
        if g.previousPressedPushedToggleArray.count != 18 {
            g.previousPressedPushedToggleArray = Array(repeating: false, count: 18)
        }

        // Roster list ok even if empty
        if g.rosterNames.isEmpty { g.rosterNames = [] }

        // Clamp current hole
        g.hole = max(0, min(17, g.hole))
    }

    private func pad<T>(_ a: [T], to n: Int, fill: T) -> [T] {
        a.count >= n ? Array(a.prefix(n)) : a + Array(repeating: fill, count: n - a.count)
    }
    
    
}

// Put this in GameManager.swift (or its own file) **outside** the GameManager class,
// but in the same target.
extension GameManager {

    /// For the current game, pre-fill every hole for each ACTIVE player with the
    /// course par as their score, but only if that score is currently nil.
    /// (We never overwrite scores that are already set.)
    func seedScoresWithParsForActivePlayers() {
        // Work on a mutable copy of the game
        guard var game = self.currentGame else { return }

        // How many holes? usually 18, but respect the course data
        let holeCount = min(18, game.courseParToPass.count)
        guard holeCount > 0 else { return }

        // Seats visible on the Game screen
        let seatsRange = 0 ..< min(9,
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
