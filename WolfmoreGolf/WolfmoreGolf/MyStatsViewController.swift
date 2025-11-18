import UIKit

final class MyStatsViewController: UIViewController {

    private let courseID = "HOME-COURSE"   // later you can use ProfileStore.homeCourseID

    // Friends the user chose to track on this course
    private var trackedFriends: [Friend] {
        FriendStore.shared.friends.filter {
            FriendTrackStore.shared.isTracked($0.id, on: courseID)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // For now just log results; later you’ll reload a table
        debugPrintMoneyAverages()
    }

    // MARK: - Stats helpers

    /// Returns an array of (friend, stats) for all tracked friends.
    private func computeMoneyAverages() -> [(friend: Friend, stats: MyStats)] {
        return trackedFriends.compactMap { friend in
            guard let stats = RoundStore.shared.stats(forPlayerNamed: friend.name) else {
                return nil
            }
            return (friend, stats)
        }
    }

    /// Temporary: print to console so you can verify it works.
    private func debugPrintMoneyAverages() {
        let rows = computeMoneyAverages()
        for row in rows {
            let f = row.friend
            let s = row.stats
            print("\(f.name): \(s.rounds) rounds, total $\(s.totalMoney), avg $\(s.avgMoneyPerRound), prox avg \(s.avgProxPerRound)")
        }
    }
}
