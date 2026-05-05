//
//  UpdateChecker.swift
//  WolfmoreGolf
//

import UIKit

final class UpdateChecker {

    static let shared = UpdateChecker()
    private init() {}

    // MARK: - Constants

    private let appStoreID = "6755116882"
    private let throttleInterval: TimeInterval = 60 * 60 * 24   // 24 hours

    private enum Key {
        static let lastCheck    = "lastUpdateCheck"
        static let skippedVersion = "skippedUpdateVersion"
    }

    // MARK: - Public API

    /// Automatic check — respects 24-hour throttle and skip preference.
    func check(from vc: UIViewController) {
        guard shouldRunThrottledCheck() else { return }
        UserDefaults.standard.set(Date(), forKey: Key.lastCheck)

        fetchAppStoreInfo { [weak vc] info in
            guard let vc, let info else { return }
            guard Self.isNewer(info.version, than: Self.localVersion()) else { return }
            let skipped = UserDefaults.standard.string(forKey: Key.skippedVersion)
            guard skipped != info.version else { return }
            DispatchQueue.main.async {
                self.presentUpdateAlert(version: info.version, from: vc, isManual: false)
            }
        }
    }

    /// Manual check — ignores throttle and skip, always shows a result.
    func checkManually(from vc: UIViewController) {
        fetchAppStoreInfo { [weak vc] info in
            guard let vc else { return }
            DispatchQueue.main.async {
                guard let info else {
                    self.presentNoConnectionAlert(from: vc)
                    return
                }
                if Self.isNewer(info.version, than: Self.localVersion()) {
                    self.presentUpdateAlert(version: info.version, from: vc, isManual: true)
                } else {
                    self.presentUpToDateAlert(from: vc)
                }
            }
        }
    }

    /// Fetches only the releaseNotes field from the App Store. Returns nil on
    /// failure. Used by the "What's New" flow without duplicating the API call.
    func latestAppStoreReleaseNotes(completion: @escaping (String?) -> Void) {
        fetchAppStoreInfo { info in
            completion(info?.releaseNotes)
        }
    }

    // MARK: - Throttle

    private func shouldRunThrottledCheck() -> Bool {
        guard let last = UserDefaults.standard.object(forKey: Key.lastCheck) as? Date else {
            return true
        }
        return Date().timeIntervalSince(last) >= throttleInterval
    }

    // MARK: - Network

    private struct AppStoreInfo {
        let version: String
        let releaseNotes: String?
    }

    private func fetchAppStoreInfo(completion: @escaping (AppStoreInfo?) -> Void) {
        guard let bundleID = Bundle.main.bundleIdentifier,
              let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleID)") else {
            completion(nil)
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]],
                  let first = results.first,
                  let version = first["version"] as? String else {
                completion(nil)
                return
            }
            let notes = first["releaseNotes"] as? String
            completion(AppStoreInfo(version: version, releaseNotes: notes))
        }
        task.resume()
    }

    // MARK: - Version comparison

    private static func localVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    /// Returns true if `candidate` is strictly greater than `current`.
    private static func isNewer(_ candidate: String, than current: String) -> Bool {
        let a = candidate.split(separator: ".").compactMap { Int($0) }
        let b = current.split(separator: ".").compactMap { Int($0) }
        let len = max(a.count, b.count)
        for i in 0..<len {
            let av = i < a.count ? a[i] : 0
            let bv = i < b.count ? b[i] : 0
            if av != bv { return av > bv }
        }
        return false
    }

    // MARK: - Alerts

    private func presentUpdateAlert(version: String, from vc: UIViewController, isManual: Bool) {
        let alert = UIAlertController(
            title: "Update Available",
            message: "A new version of Wolfmore (\(version)) is available with improvements and fixes. Update now?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Update", style: .default) { [weak self] _ in
            self?.openAppStore()
        })

        // Manual checks override skip — don't offer "Skip This Version"
        if !isManual {
            alert.addAction(UIAlertAction(title: "Skip This Version", style: .default) { _ in
                UserDefaults.standard.set(version, forKey: Key.skippedVersion)
            })
        }

        alert.addAction(UIAlertAction(title: "Later", style: .cancel))

        vc.present(alert, animated: true)
    }

    private func presentUpToDateAlert(from vc: UIViewController) {
        let alert = UIAlertController(
            title: "You're Up to Date",
            message: "Wolfmore \(Self.localVersion()) is the latest version.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        vc.present(alert, animated: true)
    }

    private func presentNoConnectionAlert(from vc: UIViewController) {
        let alert = UIAlertController(
            title: "Couldn't Check for Updates",
            message: "Make sure you're connected to the internet and try again.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        vc.present(alert, animated: true)
    }

    private func openAppStore() {
        guard let url = URL(string: "itms-apps://apps.apple.com/app/id\(appStoreID)") else { return }
        UIApplication.shared.open(url)
    }
}
