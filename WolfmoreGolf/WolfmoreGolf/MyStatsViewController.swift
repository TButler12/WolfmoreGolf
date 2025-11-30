import UIKit

final class MyStatsViewController: UIViewController {

    // For now: just use ALL friends in FriendStore.
    // No course ID, no tracking filter.
    private var allFriends: [Friend] {
        return FriendStore.shared.friends
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // For now just log results; later you’ll reload a table
        debugPrintMoneyAverages()
    }

    // MARK: - Stats helpers

    /// Returns an array of (friend, stats) for all friends that have stats.
    private func computeMoneyAverages() -> [(friend: Friend, stats: MyStats)] {
        return allFriends.compactMap { friend in
            guard let stats = RoundStore.shared.stats(forPlayerNamed: friend.name) else {
                print("MyStats: no stats for \(friend.name)")
                return nil
            }
            return (friend, stats)
        }
    }

    /// Temporary: print to console so you can verify it works.
    private func debugPrintMoneyAverages() {
        let rows = computeMoneyAverages()
        if rows.isEmpty {
            print("MyStats: no stats found for any friends")
        }
        for row in rows {
            let f = row.friend
            let s = row.stats
            print("\(f.name): \(s.rounds) rounds, total $\(s.totalMoney), avg $\(s.avgMoneyPerRound), prox avg \(s.avgProxPerRound)")
        }
    }
}
