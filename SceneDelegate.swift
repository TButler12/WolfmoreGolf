//
//  SceneDelegate.swift
//  Wolfmore-5Man
//
//  Created by Tom BUTLER on 9/24/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // ONE copy only
    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        // Boot your persisted game (or create a fresh one)
        if !GameManager.shared.loadLastOpened() {
            GameManager.shared.startNewGame()
        }

        // If you're using storyboards, keep this guard and you're done
        guard let windowScene = (scene as? UIWindowScene) else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            ReviewPrompter.maybeRequest(in: windowScene)
        }

        // Handle deep links on cold launch — storyboard isn't wired until next run loop turn
        if let url = connectionOptions.urlContexts.first?.url {
            DispatchQueue.main.async { [weak self] in
                self?.handleURL(url)
            }
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        handleURL(url)
    }

    // MARK: - URL routing

    private func handleURL(_ url: URL) {
        guard url.scheme?.lowercased() == "wolfmore",
              let host = url.host?.lowercased(),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        else { return }

        guard let root = window?.rootViewController else { return }
        let nav = (root as? UINavigationController) ?? root.navigationController

        if host == "watch" {
            let vc = WolfSpectatorViewController()
            vc.sessionCode = code
            nav?.pushViewController(vc, animated: true)

        } else if host == "nassau" {
            let confirm = UIAlertController(
                title: "Join Live Nassau?",
                message: "Join the remote Nassau match with code \(code.uppercased())?",
                preferredStyle: .alert
            )
            confirm.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            confirm.addAction(UIAlertAction(title: "Join", style: .default) { _ in
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
                        SupabaseService.shared.subscribeToResults(matchId: match.id) { _ in }
                        await MainActor.run {
                            // Post immediately (GameVC observer already registered) then pop —
                            // matches WolfActions.joinLiveMatch which also posts before any navigation.
                            NotificationCenter.default.post(name: .remoteMatchDidStart, object: nil)
                            nav?.popToRootViewController(animated: true)
                        }
                    } catch {
                        await MainActor.run {
                            let err = UIAlertController(title: "Couldn't Join", message: error.localizedDescription, preferredStyle: .alert)
                            err.addAction(UIAlertAction(title: "OK", style: .default))
                            root.present(err, animated: true)
                        }
                    }
                }
            })
            root.present(confirm, animated: true)
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        GameManager.shared.saveCurrent()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        GameManager.shared.saveCurrent()
    }

    // (Other lifecycle methods optional)
}
