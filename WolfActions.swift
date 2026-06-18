import UIKit

enum WolfActions {

    // MARK: - Remote Nassau

    static func presentRemoteNassau(from presenter: UIViewController) {
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
                        g.remoteMatchId    = match.id
                        g.remoteNassauSide = "A"
                        if !g.remoteMatchIds.contains(match.id) { g.remoteMatchIds.append(match.id) }
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
                        g.remoteMatchId    = match.id
                        g.remoteNassauSide = "B"
                        if !g.remoteMatchIds.contains(match.id) { g.remoteMatchIds.append(match.id) }
                    }
                    NotificationCenter.default.post(name: NSNotification.Name("RemoteMatchDidStart"), object: nil)
                    SupabaseService.shared.subscribeToResults(matchId: match.id) { _ in }
                    await MainActor.run {
                        let alert = UIAlertController(
                            title: "Joined Match",
                            message: "Connected to live match \(match.code). Scores will sync as they come in.",
                            preferredStyle: .alert
                        )
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
        let msg = code.map { "Could not find match with code \($0)." } ?? error.localizedDescription
        let alert = UIAlertController(title: "Live Match Error", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        presenter.present(alert, animated: true)
    }

    // MARK: - Go Live

    static func presentGoLive(from presenter: UIViewController) {
        guard let g = GameManager.shared.currentGame else { return }

        if let sessionId = g.liveSessionId {
            let code = g.liveSessionCode ?? ""
            let alert = UIAlertController(
                title: "Live Session Active",
                message: code.isEmpty ? nil : "Code: \(code)",
                preferredStyle: .alert
            )
            if !code.isEmpty {
                alert.addAction(UIAlertAction(title: "Share Code", style: .default) { [weak presenter] _ in
                    guard let presenter else { return }
                    showGoLiveCreatedAlert(code: code, from: presenter)
                })
            }
            alert.addAction(UIAlertAction(title: "Stop Live", style: .destructive) { [weak presenter] _ in
                guard let presenter else { return }
                stopLiveSession(id: sessionId, from: presenter)
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            presenter.present(alert, animated: true)
        } else {
            let names = (0..<MAX_PLAYERS).compactMap { s -> String? in
                guard g.playerActivated[safe: s] == true else { return nil }
                return g.playerNames[safe: s] ?? ""
            }
            let course = g.course.name.isEmpty ? "Custom Course" : g.course.name
            Task {
                do {
                    let session = try await SupabaseService.shared.createWolfSession(
                        playerNames: names,
                        courseName: course
                    )
                    GameManager.shared.update { g in
                        g.liveSessionId = session.id
                        g.liveSessionCode = session.code
                    }
                    GameManager.shared.saveCurrent()
                    await MainActor.run {
                        NotificationCenter.default.post(name: .reloadUI, object: nil)
                        showGoLiveCreatedAlert(code: session.code, from: presenter)
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
    }

    private static func stopLiveSession(id: String, from presenter: UIViewController) {
        Task {
            do {
                try await SupabaseService.shared.archiveWolfSession(id: id)
            } catch {
                print("ERROR archiveWolfSession: \(error)")
            }
            GameManager.shared.update { g in
                g.liveSessionId = nil
                g.liveSessionCode = nil
            }
            GameManager.shared.saveCurrent()
            await MainActor.run {
                NotificationCenter.default.post(name: .reloadUI, object: nil)
            }
        }
    }

    private static func showGoLiveCreatedAlert(code: String, from presenter: UIViewController) {
        let link = "wolfmore://watch?code=\(code)"
        let alert = UIAlertController(
            title: "Live Session Created",
            message: "Share this link with spectators:\n\(link)",
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
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        presenter.present(alert, animated: true)
    }
}
