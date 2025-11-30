//
//  HoleStatsViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 11/18/25.
//
import UIKit


final class HoleStatsViewController: UITableViewController {

    /// 0-based (0 = Hole 1)
    var holeIndex: Int = 0

    private struct Row {
        let name: String
        let avgMoney: Double
        let proxPct: Double   // 0–100
        let rounds: Int       // how many rounds contributed
    }

    private var rows: [Row] = []

    /// Use the same “home / tracking course” ID logic as TrackFriends.
    /// If ProfileStore.homeCourseID is empty, fall back to Biltmore’s UUID,
    /// then finally a legacy "HOME-COURSE" string.
    private var trackingCourseID: String {
        let stored = ProfileStore.homeCourseID
        if !stored.isEmpty { return stored }

        if let b = CourseLibrary.shared.biltmore() {
            return b.id.uuidString
        }

        return "HOME-COURSE"
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Hole \(holeIndex + 1) Stats"
        view.backgroundColor = .systemBackground
        tableView.backgroundColor = .systemBackground

        buildRows()
        updateEmptyBackgroundIfNeeded()
    }
    
    var trackToggled: ((Bool) -> Void)?

    // MARK: - Build data

    private func buildRows() {
        let courseID = trackingCourseID
        print("HoleStats: building rows for holeIndex \(holeIndex), courseID \(courseID)")

        // 1️⃣ Only friends tracked for the home / tracking course
        let trackedFriends = FriendStore.shared.friends.filter {
            FriendTrackStore.shared.isTracked($0.id, on: courseID)
        }
        print("HoleStats: trackedFriends = \(trackedFriends.count)")

        var built: [Row] = []

        // 2️⃣ For each tracked friend, only include rounds:
        //    - whose courseID == trackingCourseID
        //    - whose playerName matches
        //    - that actually have data for this hole
        for friend in trackedFriends {
            let rds = RoundStore.shared.rounds.filter { r in
                r.courseID == courseID &&                           // 👈 HOME COURSE ONLY
                r.playerName.caseInsensitiveCompare(friend.name) == .orderedSame &&
                r.moneyPerHole.indices.contains(holeIndex) &&
                r.proxPerHole.indices.contains(holeIndex)
            }

            guard !rds.isEmpty else { continue }

            let totalRounds = rds.count
            let totalMoney  = rds.reduce(0) { partial, r in
                partial + r.moneyPerHole[holeIndex]
            }
            let avgMoney = Double(totalMoney) / Double(totalRounds)

            let proxWins = rds.filter { $0.proxPerHole[holeIndex] }.count
            let proxPct  = totalRounds > 0
                ? Double(proxWins) / Double(totalRounds) * 100.0
                : 0.0

            built.append(Row(
                name: friend.name,
                avgMoney: avgMoney,
                proxPct: proxPct,
                rounds: totalRounds
            ))
        }

        print("HoleStats: built \(built.count) rows")

        rows = built.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }

        tableView.reloadData()
    }

    private func updateEmptyBackgroundIfNeeded() {
        if rows.isEmpty {
            let label = UILabel()
            label.textAlignment = .center
            label.numberOfLines = 0
            label.textColor = .secondaryLabel
            label.text = """
            No hole stats for your home course yet.

            • Make sure a Home / Tracking Course is set in Course Setup.
            • Use Track Friends (on your home course) to choose who to track.
            • Play and save rounds on that course to build stats.
            """
            tableView.backgroundView = label
        } else {
            tableView.backgroundView = nil
        }
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // In Interface Builder, make this cell style "Subtitle" with ID "HoleStatsCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: "HoleStatsCell",
                                                 for: indexPath)
        let r = rows[indexPath.row]

        let roundsText = r.rounds == 1 ? "1 round" : "\(r.rounds) rounds"
        cell.textLabel?.text = r.name
        cell.detailTextLabel?.text = String(
            format: "Avg $%.1f • Prox %.0f%% • %@",
            r.avgMoney,
            r.proxPct,
            roundsText
        )
        return cell
    }

    @IBAction private func closeTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction private func trackButtonTapped(_ sender: UIButton) {
        sender.isSelected.toggle()
        trackToggled?(sender.isSelected)
    }
}
