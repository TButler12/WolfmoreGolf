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

        // If you create the window manually, do it here instead of the guard:
        // let windowScene = scene as! UIWindowScene
        // let window = UIWindow(windowScene: windowScene)
        // window.rootViewController = ... // your initial VC
        // self.window = window
        // window.makeKeyAndVisible()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        GameManager.shared.saveCurrent()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        GameManager.shared.saveCurrent()
    }

    // (Other lifecycle methods optional)
}
