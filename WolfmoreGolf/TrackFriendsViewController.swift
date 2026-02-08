//
//  ViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 11/14/25.
//
import UIKit

final class TrackFriendsViewController: UITableViewController, UISearchResultsUpdating {

    // MARK: - Data

    private var allFriends: [Friend] = []
    private var filtered: [Friend] = []

    private let limit = 30

    /// Course ID used for tracking (home course only).
    /// - If ProfileStore.homeCourseID is set, use that.
    /// - Else, if Biltmore exists, use its UUID.
    /// - Else, fall back to legacy "HOME-COURSE" key.
    private var trackingCourseID: String {
        let stored = ProfileStore.homeCourseID
        if !stored.isEmpty { return stored }

        if let b = CourseLibrary.shared.WolfMore() {
            return b.id.uuidString
        }

        return "HOME-COURSE"
    }

    private let searchController = UISearchController(searchResultsController: nil)

    /// Whether the user is currently playing the home / tracking course.
    private var canEditTracking = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Track Friends"
    

           navigationItem.rightBarButtonItems = [
               UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped)),
               UIBarButtonItem(title: "Import", style: .plain, target: self, action: #selector(importRoster))
           ]
        view.backgroundColor = .systemBackground
        tableView.backgroundColor = .systemBackground

        print("TrackFriendsViewController viewDidLoad, trackingCourseID = \(trackingCourseID)")

        // Table cell registration (plain UITableViewCell)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

        // Navigation buttons: Add + Import Roster
        

        // Search setup
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        definesPresentationContext = true

        // Only allow tracking edits if we’re on the home course
        canEditTracking = isPlayingHomeCourse()
        if !canEditTracking {
            navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = false }
        }

        // If FriendStore is empty, seed it from the current game once
        seedFriendsFromCurrentGameIfNeeded()

        reloadData()
        updateHeader()
    }

    // MARK: - Home-course logic

    /// Returns true if the current game’s course matches the selected home/tracking course.
    private func isPlayingHomeCourse() -> Bool {
        guard let g = GameManager.shared.currentGame else {
            print("TrackFriends: no current game – tracking edits disabled")
            showOnceNoCurrentRoundAlert()
            return false
        }

        guard let uuid = UUID(uuidString: trackingCourseID),
              let homeCourse = CourseLibrary.shared.get(id: uuid) else {
            print("TrackFriends: no matching CourseProfile for trackingCourseID \(trackingCourseID)")
            return false
        }

        let currentPars = g.course.pars
        let currentHCs  = g.course.holeHandicaps

        let isSame =
            Array(currentPars.prefix(18)) == Array(homeCourse.pars.prefix(18)) &&
            Array(currentHCs.prefix(18))  == Array(homeCourse.hcs.prefix(18))

        if isSame {
            print("TrackFriends: playing home/tracking course \(homeCourse.name)")
        } else {
            print("TrackFriends: NOT playing home course. Current pars/HCs differ from \(homeCourse.name)")
            showOnceNotHomeCourseAlert(courseName: homeCourse.name)
        }

        return isSame
    }

    private var hasShownNoRoundAlert = false
    private var hasShownNotHomeAlert = false

    private func showOnceNoCurrentRoundAlert() {
        guard !hasShownNoRoundAlert else { return }
        hasShownNoRoundAlert = true

        let ac = UIAlertController(
            title: "No Current Round",
            message: "Start a round on your home course to choose which friends to track by hole.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    private func showOnceNotHomeCourseAlert(courseName: String) {
        guard !hasShownNotHomeAlert else { return }
        hasShownNotHomeAlert = true

        let ac = UIAlertController(
            title: "Home Course Only",
            message: "Tracking by hole is tied to your home course: \(courseName).\nYou can still view the list, but changes are disabled for this round.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    // MARK: - Data helpers

    private func seedFriendsFromCurrentGameIfNeeded() {
        if FriendStore.shared.friends.isEmpty,
           let g = GameManager.shared.currentGame {

            let names = g.playerNames
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            if !names.isEmpty {
                print("TrackFriends: seeding \(names.count) names from current game")
                FriendStore.shared.merge(names: names)
            } else {
                print("TrackFriends: current game has no usable names")
            }
        } else {
            print("TrackFriends: FriendStore already has \(FriendStore.shared.friends.count) friends")
        }
    }

    private func reloadData() {
        allFriends = FriendStore.shared.friends.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        filtered = allFriends
        print("TrackFriends: reloadData → \(filtered.count) rows")
        tableView.reloadData()
    }

    private func updateHeader() {
        let n = FriendTrackStore.shared.count(for: trackingCourseID)
        let label = UILabel()
        label.textAlignment = .center

        if canEditTracking {
            label.text = "Tracking \(n)/\(limit) for Home Course"
        } else {
            label.text = "Read-only (not on home course)"
        }

        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.frame.size.height = 36
        tableView.tableHeaderView = label
    }

    // MARK: - Actions

    @objc private func addTapped() {
        guard canEditTracking else { return }

        let ac = UIAlertController(title: "Add Friend", message: nil, preferredStyle: .alert)

        ac.addTextField { tf in
            tf.placeholder = "Name"
            tf.autocapitalizationType = .words
            tf.clearButtonMode = .whileEditing
        }

        ac.addTextField { tf in
            tf.placeholder = "Mobile (optional)"
            tf.keyboardType = .phonePad
            tf.clearButtonMode = .whileEditing
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Add", style: .default) { _ in
            let name = (ac.textFields?[0].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let rawPhone = ac.textFields?[1].text ?? ""
            let normalized = rawPhone.filter { $0.isNumber }

            guard !name.isEmpty else { return }

            // Create & save the friend with phone
            let friend = Friend(name: name, phone: normalized)
            FriendStore.shared.upsert(friend)   // we’ll add upsert if you don’t have it

            self.reloadData()
        })

        present(ac, animated: true)
    }

    /// Pull names from the current roster / card and merge into FriendStore
    @objc private func importRoster() {
        guard canEditTracking else { return }

        if let g = GameManager.shared.currentGame {
            let names = g.playerNames
            print("TrackFriends: importing roster names \(names)")
            FriendStore.shared.merge(names: names)
            reloadData()
        } else {
            print("TrackFriends: no current game to import from")
        }
    }

    // MARK: - TableView

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        filtered.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let friend = filtered[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell",
                                                 for: indexPath)

        var config = cell.defaultContentConfiguration()
        config.text = friend.name
        config.secondaryText = friend.phone.isEmpty ? "" : friend.phone

        let tracked = FriendTrackStore.shared.isTracked(friend.id, on: trackingCourseID)
        cell.accessoryType = tracked ? .checkmark : .none

        return cell
    }

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard canEditTracking else { return }

        let friend = filtered[indexPath.row]
        let changed = FriendTrackStore.shared.toggle(
            friend.id,
            courseID: trackingCourseID,
            limit: limit
        )

        if !changed {
            let ac = UIAlertController(
                title: "Limit Reached",
                message: "You can track up to \(limit) friends for this course.",
                preferredStyle: .alert
            )
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }

        tableView.reloadRows(at: [indexPath], with: .automatic)
        updateHeader()
    }

    // MARK: - Search

    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text,
              !text.isEmpty else {
            filtered = allFriends
            tableView.reloadData()
            return
        }
        filtered = allFriends.filter {
            $0.name.localizedCaseInsensitiveContains(text)
        }
        tableView.reloadData()
    }
}
