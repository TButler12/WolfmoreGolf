import UIKit

final class MyStatsViewController: UIViewController {

    // For now: just use ALL friends in FriendStore.
    private var allFriends: [Friend] {
        FriendStore.shared.friends
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showFriendStatsAlert()
    }

    // MARK: - Stats helpers

    /// Returns an array of (friend, stats) for all friends that have stats.
    private func computeMoneyAverages() -> [(friend: Friend, stats: MyStats)] {
        return allFriends.compactMap { friend in
            guard let stats = RoundStore.shared.stats(forPlayerNamed: friend.name) else {
                return nil
            }
            return (friend, stats)
        }
    }

    // MARK: - UI

    private func showFriendStatsAlert() {
        let rows = computeMoneyAverages()

        // No stats at all
        guard !rows.isEmpty else {
            let ac = UIAlertController(
                title: "Friend Stats",
                message: "No rounds saved yet.",
                preferredStyle: .alert
            )
            ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                self.dismiss(animated: true)
            })
            present(ac, animated: true)
            return
        }

        // Sort by name (optional)
        let sorted = rows.sorted {
            $0.friend.name.localizedCaseInsensitiveCompare($1.friend.name) == .orderedAscending
        }

        var blocks: [String] = []

        for row in sorted {
            let f = row.friend
            let s = row.stats

            // Adjust these to whatever “per 18” values you already use
            let moneyPer18 = s.avgMoneyPerRound      // or s.avgMoneyPer18 if you have it
            let proxPer18  = s.avgProxPerRound       // or s.avgProxPer18

            let block = String(
                format:
                """
                • %@:
                  %d rds, avg $%.1f per 18
                  prox %.1f per 18
                """,
                f.name,
                s.rounds,
                moneyPer18,
                proxPer18
            )

            blocks.append(block)
        }

        // 👇 blank line between friends → much more breathing room
        let message = blocks.joined(separator: "\n\n")

        let ac = UIAlertController(
            title: "Friend Stats (all-time)",
            message: message,
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.dismiss(animated: true)
        })

        // iPad safety
        if let pop = ac.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX,
                                    y: view.bounds.midY,
                                    width: 1, height: 1)
        }

        present(ac, animated: true)
    }
}
