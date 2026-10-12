import UIKit

// MARK: - Match Board history (persisted in UserDefaults)

struct SavedMatchBoard: Codable {
    let code: String
    let name: String
    let createdAt: TimeInterval
}

enum MatchBoardStore {
    static let key = "createdMatchBoards"

    static func all() -> [SavedMatchBoard] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let boards = try? JSONDecoder().decode([SavedMatchBoard].self, from: data)
        else { return [] }
        return boards
    }

    static func save(code: String, name: String) {
        var current = all()
        current.removeAll { $0.code == code }
        current.insert(SavedMatchBoard(code: code, name: name, createdAt: Date().timeIntervalSince1970), at: 0)
        if let data = try? JSONEncoder().encode(Array(current.prefix(10))) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func todaysBoard() -> SavedMatchBoard? {
        all().first { Calendar.current.isDateInToday(Date(timeIntervalSince1970: $0.createdAt)) }
    }
}

enum WolfActions {

    // MARK: - Remote Nassau

    static func presentRemoteNassau(from presenter: UIViewController) {
        let pm = PremiumManager.shared
        guard pm.canUse(.remoteNassau) else {
            presenter.present(PaywallViewController(feature: .remoteNassau), animated: true)
            return
        }
        pm.recordUse(.remoteNassau)
        pm.nudgeIfNeeded(for: .remoteNassau, from: presenter)
        let ac = UIAlertController(title: "Remote Nassau", message: nil, preferredStyle: .actionSheet)

        ac.addAction(UIAlertAction(title: "▶ Start Live Match", style: .default) { [weak presenter] _ in
            guard let presenter else { return }
            startLiveMatch(from: presenter)
        })
        ac.addAction(UIAlertAction(title: "↩ Join Live Match", style: .default) { [weak presenter] _ in
            guard let presenter else { return }
            joinLiveMatch(from: presenter)
        })
        ac.addAction(UIAlertAction(title: "View Matches", style: .default) { [weak presenter] _ in
            guard let presenter else { return }
            let vc = RemoteMatchesViewController()
            presenter.navigationController?.pushViewController(vc, animated: true)
        })
        let hasMatch = GameManager.shared.currentGame?.remoteMatchId != nil
        let shareTitle = hasMatch ? "Share Match Code" : "Share Match Code (no active match)"
        let shareAction = UIAlertAction(title: shareTitle, style: .default) { [weak presenter] _ in
            guard let presenter else { return }
            shareMatchCode(from: presenter)
        }
        shareAction.isEnabled = hasMatch
        ac.addAction(shareAction)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.sourceView = presenter.view
            pop.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY,
                                    width: 0, height: 0)
            pop.permittedArrowDirections = []
        }
        presenter.present(ac, animated: true)
    }

    static func startLiveMatch(from presenter: UIViewController) {
        guard let g = GameManager.shared.currentGame else { return }
        let nassau     = g.nassauState
        let stake      = nassau?.settings.baseStake ?? Double(g.baseGameStake)
        let courseName = g.course.name

        let stakeText: String = stake == floor(stake)
            ? "$\(Int(stake))"
            : String(format: "$%.2f", stake)

        let pressModeText: String
        switch nassau?.settings.pressMode ?? .auto {
        case .auto:   pressModeText = "Auto"
        case .manual: pressModeText = "Manual"
        case .off:    pressModeText = "Off"
        }

        let trigger = nassau?.settings.autoPressTriggerDown ?? 2

        let included: [String] = (0..<MAX_PLAYERS).compactMap { idx in
            guard idx < g.playerActivated.count, g.playerActivated[idx],
                  idx < g.playerNames.count else { return nil }
            let name = g.playerNames[idx].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            let isIncluded = nassau.map { idx < $0.playerIncluded.count && $0.playerIncluded[idx] } ?? true
            return isIncluded ? name : nil
        }

        let playersText = included.isEmpty ? "None" : included.joined(separator: ", ")

        let message = """
            Stake: \(stakeText)
            Press Mode: \(pressModeText)
            Trigger: \(trigger) down
            Players: \(playersText)
            """

        let confirm = UIAlertController(
            title: "Start Live Match",
            message: message,
            preferredStyle: .alert
        )
        confirm.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        confirm.addAction(UIAlertAction(title: "Confirm", style: .default) { [weak presenter] _ in
            guard let presenter else { return }
            Task {
                do {
                    let match = try await SupabaseService.shared.createMatch(
                        courseA: courseName,
                        courseB: "",
                        stake: stake,
                        games: ["nassau"]
                    )
                    GameManager.shared.update { g in
                        if g.remoteNassauSideMap == nil {
                            var seeded: [String: String] = [:]
                            if let existingSide = g.remoteNassauSide {
                                for id in g.remoteMatchIds { seeded[id] = existingSide }
                                if let single = g.remoteMatchId, !g.remoteMatchIds.contains(single) {
                                    seeded[single] = existingSide
                                }
                            }
                            g.remoteNassauSideMap = seeded
                        }
                        g.remoteMatchId    = match.id
                        g.remoteNassauSide = "A"
                        if !g.remoteMatchIds.contains(match.id) { g.remoteMatchIds.append(match.id) }
                        var sideMap = g.remoteNassauSideMap ?? [:]
                        sideMap[match.id] = "A"
                        g.remoteNassauSideMap = sideMap
                    }
                    NotificationCenter.default.post(name: NSNotification.Name("RemoteMatchDidStart"), object: nil)
                    await MainActor.run {
                        let link = "wolfmore://nassau?code=\(match.code)"
                        let alert = UIAlertController(
                            title: "Live Match Created",
                            message: "Share this link with your opponent:\n\(link)",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "Copy Code", style: .default) { _ in
                            UIPasteboard.general.string = match.code
                        })
                        alert.addAction(UIAlertAction(title: "Share", style: .default) { [weak presenter] _ in
                            guard let presenter else { return }
                            let avc = UIActivityViewController(activityItems: [link], applicationActivities: nil)
                            if let pop = avc.popoverPresentationController {
                                pop.sourceView = presenter.view
                                pop.sourceRect = CGRect(x: presenter.view.bounds.midX,
                                                        y: presenter.view.bounds.midY,
                                                        width: 0, height: 0)
                                pop.permittedArrowDirections = []
                            }
                            presenter.present(avc, animated: true)
                        })
                        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                        presenter.present(alert, animated: true)
                    }
                } catch {
                    await MainActor.run { showLiveMatchError(error, from: presenter) }
                }
            }
        })
        presenter.present(confirm, animated: true)
    }

    static func joinLiveMatch(from presenter: UIViewController) {
        let prompt = UIAlertController(
            title: "Join Live Match",
            message: "Enter the 6-character match code",
            preferredStyle: .alert
        )
        prompt.addTextField { tf in
            tf.placeholder            = "WOLF42"
            tf.autocapitalizationType = .allCharacters
        }
        prompt.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        prompt.addAction(UIAlertAction(title: "Join", style: .default) { [weak presenter] _ in
            guard let presenter,
                  let code = prompt.textFields?.first?.text?
                      .trimmingCharacters(in: .whitespacesAndNewlines),
                  !code.isEmpty else { return }
            Task {
                do {
                    let joinerCourse = GameManager.shared.currentGame?.course.name
                        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let match = try await SupabaseService.shared.joinMatch(code: code, courseB: joinerCourse)
                    GameManager.shared.update { g in
                        if g.remoteNassauSideMap == nil {
                            var seeded: [String: String] = [:]
                            if let existingSide = g.remoteNassauSide {
                                for id in g.remoteMatchIds { seeded[id] = existingSide }
                                if let single = g.remoteMatchId, !g.remoteMatchIds.contains(single) {
                                    seeded[single] = existingSide
                                }
                            }
                            g.remoteNassauSideMap = seeded
                        }
                        g.remoteMatchId    = match.id
                        g.remoteNassauSide = "B"
                        if !g.remoteMatchIds.contains(match.id) { g.remoteMatchIds.append(match.id) }
                        var sideMap = g.remoteNassauSideMap ?? [:]
                        sideMap[match.id] = "B"
                        g.remoteNassauSideMap = sideMap
                    }
                    NotificationCenter.default.post(name: NSNotification.Name("RemoteMatchDidStart"), object: nil)
                    SupabaseService.shared.subscribeToResults(matchId: match.id) { _ in }
                    await MainActor.run {
                        var msg = "Connected to live match \(match.code)."
                        if let s = match.stake {
                            let by = match.hostName.map { ", set by \($0)" } ?? ""
                            msg += "\nStake: $\(Int(s)) per bet\(by)."
                        }
                        msg += "\nScores will sync as they come in."
                        let alert = UIAlertController(title: "Joined Match", message: msg, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                        presenter.present(alert, animated: true)
                    }
                } catch {
                    await MainActor.run { showLiveMatchError(error, code: code, from: presenter) }
                }
            }
        })
        presenter.present(prompt, animated: true)
    }

    private static func shareMatchCode(from presenter: UIViewController) {
        guard let matchId = GameManager.shared.currentGame?.remoteMatchId else { return }
        Task {
            do {
                let match = try await SupabaseService.shared.fetchMatch(id: matchId)
                await MainActor.run {
                    let link = "wolfmore://nassau?code=\(match.code)"
                    let avc = UIActivityViewController(activityItems: [link], applicationActivities: nil)
                    if let pop = avc.popoverPresentationController {
                        pop.sourceView = presenter.view
                        pop.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY,
                                                width: 0, height: 0)
                        pop.permittedArrowDirections = []
                    }
                    presenter.present(avc, animated: true)
                }
            } catch {
                await MainActor.run {
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription,
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                    presenter.present(alert, animated: true)
                }
            }
        }
    }

    private static func showLiveMatchError(_ error: Error, code: String? = nil, from presenter: UIViewController) {
        let ns = error as NSError
        let underlying = ns.userInfo[NSUnderlyingErrorKey] as? NSError
        print("[LiveMatchError] type=\(type(of: error)) domain=\(ns.domain) code=\(ns.code) underlying=\(underlying.map { "\($0.domain)/\($0.code)" } ?? "nil") desc=\(ns.localizedDescription)")

        func isNetwork(_ e: NSError) -> Bool { e.domain == NSURLErrorDomain }
        let isOurError     = ns.domain == "WolfmoreGolf"
        let isNetworkError = isNetwork(ns) || underlying.map(isNetwork) == true
        let msg: String
        if isOurError      { msg = error.localizedDescription }
        else if isNetworkError { msg = "Couldn't connect. Check your signal and try again." }
        else               { msg = code.map { "Could not find match with code \($0)." } ?? error.localizedDescription }
        let alert = UIAlertController(title: "Live Match Error", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        presenter.present(alert, animated: true)
    }

    // MARK: - Match play gate helpers

    private static func presentMatchPlayWarning(gameTypeName: String, hasHolesScored: Bool,
                                                from presenter: UIViewController,
                                                switchAction: @escaping () -> Void) {
        var msg = "This match board is for match play. Your round is set to \(gameTypeName).\n\nSwitch to match play to set up teams, then you'll be linked to the board."
        if hasHolesScored {
            msg += "\n\nNote: switching game type applies to remaining holes only."
        }
        let alert = UIAlertController(title: "Match Play Required", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Switch to Match Play", style: .default) { _ in switchAction() })
        presenter.present(alert, animated: true)
    }

    private static func openMatchPlaySettings(from presenter: UIViewController, completion: @escaping () -> Void) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "GameSettingsViewController") as? GameSettingsViewController else { return }
        vc.gameData = GameManager.shared.currentGame
        vc.onPop = {
            guard GameManager.shared.currentGame?.resolvedGameType.isMatchPlay == true else { return }
            completion()
        }
        presenter.navigationController?.pushViewController(vc, animated: true)
    }

    private static func executeGoLiveTask(names: [String], course: String, handicaps: [Int],
                                          nineHole: Bool, nineHoleStart: Int,
                                          groupName: String?, eventCode: String?,
                                          from presenter: UIViewController) {
        Task {
            do {
                let (sessionId, code, token) = try await SupabaseService.shared.createWolfSession(
                    playerNames: names,
                    courseName: course,
                    groupName: groupName,
                    playerHandicaps: handicaps,
                    nineHoleMatch: nineHole,
                    nineHoleStartingHole: nineHoleStart
                )
                GameManager.shared.update { g in
                    g.liveSessionId        = sessionId
                    g.liveSessionCode      = code
                    g.liveCreatorToken     = token
                    g.liveSessionGroupName = groupName
                }
                if let evCode = eventCode {
                    do {
                        try await SupabaseService.shared.linkSessionToEvent(
                            sessionId: sessionId,
                            creatorToken: token,
                            eventCode: evCode
                        )
                        GameManager.shared.update { g in g.liveLinkedEventCode = evCode }
                        if GameManager.shared.currentGame?.resolvedGameType.isMatchPlay == false {
                            try? await SupabaseService.shared.publishMatchStatus(
                                sessionId: sessionId, creatorToken: token,
                                matchStatus: "Not playing match play", holesPlayed: 0)
                        }
                    } catch {
                        print("WARN linkSessionToEvent at launch: \(error)")
                    }
                }
                GameManager.shared.saveCurrent()
                await MainActor.run {
                    NotificationCenter.default.post(name: .reloadUI, object: nil)
                    showGoLiveCreatedAlert(code: code, from: presenter)
                }
            } catch {
                await MainActor.run {
                    let a = UIAlertController(title: "Go Live Failed",
                                              message: error.localizedDescription,
                                              preferredStyle: .alert)
                    a.addAction(UIAlertAction(title: "OK", style: .default))
                    presenter.present(a, animated: true)
                }
            }
        }
    }

    private static func executeLinkTask(sessionId: String, token: String, evCode: String,
                                        from presenter: UIViewController) {
        Task {
            do {
                try await SupabaseService.shared.linkSessionToEvent(
                    sessionId: sessionId, creatorToken: token, eventCode: evCode)
                GameManager.shared.update { g in g.liveLinkedEventCode = evCode }
                if GameManager.shared.currentGame?.resolvedGameType.isMatchPlay == false {
                    try? await SupabaseService.shared.publishMatchStatus(
                        sessionId: sessionId, creatorToken: token,
                        matchStatus: "Not playing match play", holesPlayed: 0)
                }
                GameManager.shared.saveCurrent()
                await MainActor.run {
                    let a = UIAlertController(title: "Linked",
                                              message: "Session linked to leaderboard \(evCode).",
                                              preferredStyle: .alert)
                    a.addAction(UIAlertAction(title: "OK", style: .default))
                    presenter.present(a, animated: true)
                }
            } catch {
                await MainActor.run {
                    let a = UIAlertController(title: "Link Failed",
                                              message: error.localizedDescription,
                                              preferredStyle: .alert)
                    a.addAction(UIAlertAction(title: "OK", style: .default))
                    presenter.present(a, animated: true)
                }
            }
        }
    }

    // MARK: - Go Live

    static func presentGoLive(from presenter: UIViewController) {
        guard let g = GameManager.shared.currentGame else { return }

        // Gate only when starting a new session; managing an existing one is always allowed
        if g.liveSessionId == nil {
            let pm = PremiumManager.shared
            guard pm.canUse(.liveWolf) else {
                presenter.present(PaywallViewController(feature: .liveWolf), animated: true)
                return
            }
            pm.recordUse(.liveWolf)
            pm.nudgeIfNeeded(for: .liveWolf, from: presenter)
        }

        if let sessionId = g.liveSessionId {
            let code      = g.liveSessionCode ?? ""
            let groupName = g.liveSessionGroupName
            let boardStatus = g.liveLinkedEventCode.map { "Leaderboard: \($0)" } ?? "Not on a leaderboard"
            let msgParts = [groupName, code.isEmpty ? nil : "Code: \(code)", boardStatus].compactMap { $0 }
            let menu = UIAlertController(
                title: "Live Wolf",
                message: msgParts.joined(separator: "\n"),
                preferredStyle: .actionSheet
            )
            if !code.isEmpty {
                menu.addAction(UIAlertAction(title: "Share Code", style: .default) { [weak presenter] _ in
                    guard let presenter else { return }
                    let link = "wolfmore://watch?code=\(code)"
                    let av = UIActivityViewController(activityItems: [link], applicationActivities: nil)
                    presenter.present(av, animated: true)
                })
                menu.addAction(UIAlertAction(title: "Copy Code", style: .default) { _ in
                    UIPasteboard.general.string = code
                })
            }
            if g.liveLinkedEventCode == nil {
                menu.addAction(UIAlertAction(title: "Link to Leaderboard…", style: .default) { [weak presenter] _ in
                    guard let presenter else { return }
                    linkToMatchBoardAction(sessionId: sessionId, creatorToken: g.liveCreatorToken, from: presenter)
                })
            } else {
                let evCode = g.liveLinkedEventCode!
                menu.addAction(UIAlertAction(title: "Unlink from Leaderboard (\(evCode))", style: .default) { [weak presenter] _ in
                    guard let presenter else { return }
                    unlinkFromMatchBoardAction(sessionId: sessionId, creatorToken: g.liveCreatorToken, from: presenter)
                })
            }
            menu.addAction(UIAlertAction(title: "Create Leaderboard…", style: .default) { [weak presenter] _ in
                guard let presenter else { return }
                createMatchBoardAction(from: presenter)
            })
            menu.addAction(UIAlertAction(title: "Stop Live", style: .destructive) { [weak presenter] _ in
                guard let presenter else { return }
                stopLiveSession(id: sessionId, from: presenter)
            })
            menu.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            if let pop = menu.popoverPresentationController {
                pop.sourceView = presenter.view
                pop.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY,
                                        width: 0, height: 0)
                pop.permittedArrowDirections = []
            }
            presenter.present(menu, animated: true)
        } else {
            let names = (0..<g.activePlayerLimit).compactMap { s -> String? in
                guard g.playerActivated[safe: s] == true else { return nil }
                return g.playerNames[safe: s] ?? ""
            }
            let handicaps = (0..<g.activePlayerLimit).compactMap { s -> Int? in
                guard g.playerActivated[safe: s] == true else { return nil }
                return g.hcPlayers[safe: s] ?? 0
            }
            let course       = g.course.name.isEmpty ? "Custom Course" : g.course.name
            let nineHole     = g.isNineHoleMatch
            let nineHoleStart = g.nineHoleStartingHole

            let prefillBoardCode = MatchBoardStore.todaysBoard()?.code ?? ""
            let namePrompt = UIAlertController(
                title: "Go Live",
                message: "Group name (optional) · Leaderboard code (leave blank if none)\n\nGot a code from the organizer? Enter it below to appear on their leaderboard.",
                preferredStyle: .alert
            )
            namePrompt.addTextField { tf in
                tf.placeholder        = "Group name, e.g. \(course)"
                tf.returnKeyType      = .next
                tf.clearButtonMode    = .whileEditing
                NotificationCenter.default.addObserver(
                    forName: UITextField.textDidChangeNotification,
                    object: tf,
                    queue: .main
                ) { _ in
                    if let t = tf.text, t.count > 20 { tf.text = String(t.prefix(20)) }
                }
            }
            namePrompt.addTextField { tf in
                tf.placeholder            = "Leaderboard code, e.g. EABC123"
                tf.text                   = prefillBoardCode
                tf.autocapitalizationType = .allCharacters
                tf.autocorrectionType     = .no
                tf.returnKeyType          = .done
                NotificationCenter.default.addObserver(
                    forName: UITextField.textDidChangeNotification,
                    object: tf,
                    queue: .main
                ) { _ in
                    if let t = tf.text { tf.text = String(t.prefix(7)).uppercased() }
                }
            }
            namePrompt.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            namePrompt.addAction(UIAlertAction(title: "Go Live", style: .default) { [weak presenter] _ in
                guard let presenter else { return }
                var raw = namePrompt.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if raw.count > 20 { raw = String(raw.prefix(20)) }
                let groupName: String? = raw.isEmpty ? nil : raw
                let eventCodeRaw = (namePrompt.textFields?[1].text ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                let eventCodeEntry: String? = eventCodeRaw.isEmpty ? nil : eventCodeRaw

                // If a board code was entered and game isn't match play (or 6-Point, which can broadcast freely), warn first
                if let evCode = eventCodeEntry,
                   let g = GameManager.shared.currentGame,
                   !g.resolvedGameType.isMatchPlay,
                   g.resolvedGameType != .sixPointScotch {
                    let hasHoles = g.holeCommitted.contains(true)
                    presentMatchPlayWarning(gameTypeName: g.resolvedGameType.displayName,
                                           hasHolesScored: hasHoles, from: presenter) {
                        openMatchPlaySettings(from: presenter) {
                            executeGoLiveTask(names: names, course: course, handicaps: handicaps,
                                              nineHole: nineHole, nineHoleStart: nineHoleStart,
                                              groupName: groupName, eventCode: evCode, from: presenter)
                        }
                    }
                    return
                }

                executeGoLiveTask(names: names, course: course, handicaps: handicaps,
                                  nineHole: nineHole, nineHoleStart: nineHoleStart,
                                  groupName: groupName, eventCode: eventCodeEntry, from: presenter)
            })
            presenter.present(namePrompt, animated: true)
        }
    }

    private static func stopLiveSession(id: String, from presenter: UIViewController) {
        Task {
            do {
                try await SupabaseService.shared.archiveWolfSession(id: id)
            } catch {
                print("ERROR archiveWolfSession: \(error)")
            }
            GameManager.shared.update { g in
                g.liveSessionId        = nil
                g.liveSessionCode      = nil
                g.liveCreatorToken     = nil
                g.liveSessionGroupName = nil
                g.liveLinkedEventCode  = nil
            }
            GameManager.shared.saveCurrent()
            await MainActor.run {
                NotificationCenter.default.post(name: .reloadUI, object: nil)
            }
        }
    }

    static func createMatchBoardAction(from presenter: UIViewController) {
        let prompt = UIAlertController(
            title: "Create Live Leaderboard",
            message: "Give the leaderboard a name. You'll get a code to share with scorers and viewers.",
            preferredStyle: .alert
        )
        prompt.addTextField { tf in
            tf.placeholder     = "e.g. Saturday Match Play"
            tf.returnKeyType   = .done
            tf.clearButtonMode = .whileEditing
        }
        prompt.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        prompt.addAction(UIAlertAction(title: "Create", style: .default) { [weak presenter] _ in
            guard let presenter else { return }
            let name = (prompt.textFields?.first?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return }
            let code = SupabaseService.shared.generateEventCodePublic()
            Task {
                do {
                    let result = try await SupabaseService.shared.createLiveEvent(name: name, code: code)
                    MatchBoardStore.save(code: result.eventCode, name: name)
                    GameManager.shared.update { g in
                        g.liveEventId             = result.eventId
                        g.liveEventCode           = result.eventCode
                        g.liveEventOrganizerToken = result.organizerToken
                    }
                    GameManager.shared.saveCurrent()
                    await MainActor.run {
                        showMatchBoardCreatedAlert(code: result.eventCode, name: name, from: presenter)
                    }
                } catch {
                    await MainActor.run {
                        let a = UIAlertController(title: "Create Leaderboard Failed",
                                                  message: error.localizedDescription,
                                                  preferredStyle: .alert)
                        a.addAction(UIAlertAction(title: "OK", style: .default))
                        presenter.present(a, animated: true)
                    }
                }
            }
        })
        presenter.present(prompt, animated: true)
    }

    private static func linkToMatchBoardAction(sessionId: String, creatorToken: String?,
                                               from presenter: UIViewController) {
        guard let token = creatorToken else { return }
        let prompt = UIAlertController(
            title: "Link to Leaderboard",
            message: "Enter the 7-character leaderboard code",
            preferredStyle: .alert
        )
        prompt.addTextField { tf in
            tf.placeholder            = "e.g. EABC123"
            tf.autocapitalizationType = .allCharacters
            tf.autocorrectionType     = .no
            tf.returnKeyType          = .done
            NotificationCenter.default.addObserver(
                forName: UITextField.textDidChangeNotification,
                object: tf,
                queue: .main
            ) { _ in
                if let t = tf.text { tf.text = String(t.prefix(7)).uppercased() }
            }
        }
        prompt.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        prompt.addAction(UIAlertAction(title: "Link", style: .default) { [weak presenter] _ in
            guard let presenter else { return }
            let evCode = (prompt.textFields?.first?.text ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            guard !evCode.isEmpty else { return }

            if let g = GameManager.shared.currentGame,
               !g.resolvedGameType.isMatchPlay,
               g.resolvedGameType != .sixPointScotch {
                let hasHoles = g.holeCommitted.contains(true)
                presentMatchPlayWarning(gameTypeName: g.resolvedGameType.displayName,
                                       hasHolesScored: hasHoles, from: presenter) {
                    openMatchPlaySettings(from: presenter) {
                        executeLinkTask(sessionId: sessionId, token: token, evCode: evCode, from: presenter)
                    }
                }
                return
            }

            executeLinkTask(sessionId: sessionId, token: token, evCode: evCode, from: presenter)
        })
        presenter.present(prompt, animated: true)
    }

    private static func unlinkFromMatchBoardAction(sessionId: String, creatorToken: String?,
                                                    from presenter: UIViewController) {
        guard let token = creatorToken else { return }
        let evCode = GameManager.shared.currentGame?.liveLinkedEventCode ?? ""
        let confirm = UIAlertController(
            title: "Unlink from Match Board",
            message: evCode.isEmpty ? "Remove this session from the match board?" :
                     "Remove this session from match board \(evCode)?",
            preferredStyle: .alert
        )
        confirm.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        confirm.addAction(UIAlertAction(title: "Unlink", style: .destructive) { [weak presenter] _ in
            guard let presenter else { return }
            Task {
                do {
                    try await SupabaseService.shared.unlinkSessionFromEvent(
                        sessionId: sessionId,
                        creatorToken: token
                    )
                    GameManager.shared.update { g in g.liveLinkedEventCode = nil }
                    GameManager.shared.saveCurrent()
                } catch {
                    print("ERROR unlinkSessionFromEvent: \(error)")
                }
                await MainActor.run {
                    NotificationCenter.default.post(name: .reloadUI, object: nil)
                }
            }
        })
        presenter.present(confirm, animated: true)
    }

    static func showMatchBoardCreatedAlert(code: String, name: String, from presenter: UIViewController) {
        let link = "wolfmore://watch?code=\(code)"
        let alert = UIAlertController(
            title: "Leaderboard Created",
            message: "Send this code to each group's scorer and your viewers.\n\n\(code)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Copy Code", style: .default) { _ in
            UIPasteboard.general.string = code
        })
        alert.addAction(UIAlertAction(title: "Share", style: .default) { [weak presenter] _ in
            guard let presenter else { return }
            let av = UIActivityViewController(activityItems: [link], applicationActivities: nil)
            presenter.present(av, animated: true)
        })
        alert.addAction(UIAlertAction(title: "View Board", style: .default) { [weak presenter] _ in
            guard let presenter else { return }
            let vc = LiveEventViewController(eventCode: code)
            if let nav = presenter.navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .pageSheet
                presenter.present(nav, animated: true)
            }
        })
        alert.addAction(UIAlertAction(title: "Done", style: .cancel))
        presenter.present(alert, animated: true)
    }

    private static func showGoLiveCreatedAlert(code: String, from presenter: UIViewController) {
        let alert = UIAlertController(
            title: "Live Session Created",
            message: "Share this code with spectators: \(code)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Copy Code", style: .default) { _ in
            UIPasteboard.general.string = code
        })
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        presenter.present(alert, animated: true)
    }

    // MARK: - Join with Code

    static func presentJoinWithCode(
        from presenter: UIViewController,
        handleTournament: ((TournamentRecord, UIViewController) -> Void)? = nil
    ) {
        let alert = UIAlertController(
            title: "Join with Code",
            message: "Enter a tournament, leaderboard, or Live Wolf code",
            preferredStyle: .alert
        )
        alert.addTextField { tf in
            tf.placeholder            = "e.g. ABC123 or EABC123"
            tf.autocapitalizationType = .allCharacters
            tf.autocorrectionType     = .no
            tf.returnKeyType          = .go
            NotificationCenter.default.addObserver(
                forName: UITextField.textDidChangeNotification,
                object: tf,
                queue: .main
            ) { _ in
                if let t = tf.text { tf.text = String(t.prefix(7)).uppercased() }
            }
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Join", style: .default) { [weak presenter] _ in
            guard let presenter else { return }
            let raw = (alert.textFields?.first?.text ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
            guard !raw.isEmpty else { return }
            resolveJoinCode(raw, from: presenter, handleTournament: handleTournament)
        })
        presenter.present(alert, animated: true)
    }

    private static func resolveJoinCode(
        _ code: String,
        from presenter: UIViewController,
        handleTournament: ((TournamentRecord, UIViewController) -> Void)?
    ) {
        if code.count == 7 && code.hasPrefix("E") {
            joinLeaderboard(code: code, from: presenter)
            return
        }

        let spinner = UIAlertController(title: nil, message: "Looking up code…", preferredStyle: .alert)
        presenter.present(spinner, animated: true)

        Task {
            async let tourneyFetch = SupabaseService.shared.fetchTournament(code: code)
            async let wolfFetch    = SupabaseService.shared.fetchWolfSessionByCode(code: code)
            let tourney: TournamentRecord?  = try? await tourneyFetch
            let wolfSession: WolfSession?   = try? await wolfFetch

            await MainActor.run {
                spinner.dismiss(animated: false) {
                    switch (tourney, wolfSession) {
                    case (let t?, let w?):
                        let ac = UIAlertController(
                            title: "Which did you mean?",
                            message: "Tournament \"\(t.name)\" or Live Wolf group \"\(w.groupName ?? w.code)\"?",
                            preferredStyle: .alert
                        )
                        ac.addAction(UIAlertAction(title: "Tournament", style: .default) { _ in
                            dispatchTournament(t, from: presenter, handleTournament: handleTournament)
                        })
                        ac.addAction(UIAlertAction(title: "Live Wolf", style: .default) { _ in
                            openSessionSpectator(wolfSession: w, from: presenter)
                        })
                        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                        presenter.present(ac, animated: true)
                    case (let t?, nil):
                        dispatchTournament(t, from: presenter, handleTournament: handleTournament)
                    case (nil, let w?):
                        openSessionSpectator(wolfSession: w, from: presenter)
                    case (nil, nil):
                        checkNassauCode(code, from: presenter)
                    }
                }
            }
        }
    }

    private static func joinLeaderboard(code: String, from presenter: UIViewController) {
        let g = GameManager.shared.currentGame

        guard let game = g else {
            let vc = LiveEventViewController(eventCode: code)
            if let nav = presenter.navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .pageSheet
                presenter.present(nav, animated: true)
            }
            return
        }

        if game.liveLinkedEventCode?.uppercased() == code {
            let vc = LiveEventViewController(eventCode: code)
            presenter.navigationController?.pushViewController(vc, animated: true)
            return
        }

        if let sessionId = game.liveSessionId, let token = game.liveCreatorToken {
            executeLinkTask(sessionId: sessionId, token: token, evCode: code, from: presenter)
            return
        }

        guard PremiumManager.shared.canUse(.liveWolf) else {
            presenter.present(PaywallViewController(feature: .liveWolf), animated: true)
            return
        }
        PremiumManager.shared.recordUse(.liveWolf)
        PremiumManager.shared.nudgeIfNeeded(for: .liveWolf, from: presenter)

        let fullName  = ProfileStore.name ?? ""
        let firstName = fullName.components(separatedBy: " ").first ?? fullName
        let groupName = firstName.isEmpty ? "My Group" : "\(firstName)'s group"

        let names = (0..<game.activePlayerLimit).compactMap { s -> String? in
            guard game.playerActivated[safe: s] == true else { return nil }
            return game.playerNames[safe: s] ?? ""
        }
        let handicaps = (0..<game.activePlayerLimit).compactMap { s -> Int? in
            guard game.playerActivated[safe: s] == true else { return nil }
            return game.hcPlayers[safe: s] ?? 0
        }
        let course        = game.course.name.isEmpty ? "Custom Course" : game.course.name
        let nineHole      = game.isNineHoleMatch
        let nineHoleStart = game.nineHoleStartingHole

        executeGoLiveTask(names: names, course: course, handicaps: handicaps,
                          nineHole: nineHole, nineHoleStart: nineHoleStart,
                          groupName: groupName, eventCode: code, from: presenter)
    }

    private static func openSessionSpectator(wolfSession: WolfSession, from presenter: UIViewController) {
        let vc = WolfSpectatorViewController()
        vc.sessionCode = wolfSession.code
        if let nav = presenter.navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .pageSheet
            presenter.present(nav, animated: true)
        }
    }

    private static func dispatchTournament(
        _ record: TournamentRecord,
        from presenter: UIViewController,
        handleTournament: ((TournamentRecord, UIViewController) -> Void)?
    ) {
        if let handler = handleTournament {
            handler(record, presenter)
        } else {
            linkTournamentToRound(record: record, from: presenter)
        }
    }

    private static func linkTournamentToRound(record: TournamentRecord, from presenter: UIViewController) {
        let typeName: String
        switch record.gameType {
        case "wolf":       typeName = "Wolf"
        case "stableford": typeName = "Stableford"
        case "skins":      typeName = "Skins"
        case "scramble":   typeName = "Scramble"
        default:           typeName = record.gameType.capitalized
        }
        let ac = UIAlertController(
            title: "Join \"\(record.name)\"?",
            message: "\(typeName) tournament.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Watch", style: .default) { [weak presenter] _ in
            guard let presenter else { return }
            let vc = TournamentLeaderboardViewController(code: record.code)
            if let nav = presenter.navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .pageSheet
                presenter.present(nav, animated: true)
            }
        })
        ac.addAction(UIAlertAction(title: "Join as Scorer", style: .default) { _ in
            GameManager.applyTournamentJoin(record: record)
            NotificationCenter.default.post(name: .reloadUI, object: nil)
        })
        presenter.present(ac, animated: true)
    }

    private static func checkNassauCode(_ code: String, from presenter: UIViewController) {
        Task {
            let isNassau = (try? await SupabaseService.shared.fetchMatchByCode(code: code)) != nil
            await MainActor.run {
                if isNassau {
                    let ac = UIAlertController(
                        title: "Remote Nassau Code",
                        message: "That's a Remote Nassau code. Use Remote Nassau to join a live match.",
                        preferredStyle: .alert
                    )
                    ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                    ac.addAction(UIAlertAction(title: "Open Remote Nassau", style: .default) { [weak presenter] _ in
                        guard let presenter else { return }
                        joinLiveMatch(from: presenter)
                    })
                    presenter.present(ac, animated: true)
                } else {
                    let ac = UIAlertController(
                        title: "Code Not Found",
                        message: "No tournament, leaderboard, or Live Wolf group found for that code. Check the code and try again.",
                        preferredStyle: .alert
                    )
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    presenter.present(ac, animated: true)
                }
            }
        }
    }
}
