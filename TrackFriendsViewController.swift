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
    private let searchController = UISearchController(searchResultsController: nil)

    /// One consistent key everywhere.
    /// If Home Course isn’t set yet, we still allow tracking under a legacy bucket.
    private var trackingCourseID: String {
        let id = ProfileStore.homeCourseID.trimmingCharacters(in: .whitespacesAndNewlines)
        return id.isEmpty ? "HOME-COURSE" : id
    }

    /// We’ll DISABLE editing only when we KNOW we’re on a different course.
    /// If we can’t verify (no game / no home course UUID), we allow editing so the feature still works.
    private var canEditTracking = true

    private var hasShownNoRoundAlert = false
    private var hasShownNotHomeAlert = false

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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        definesPresentationContext = true

        seedFriendsFromCurrentGameIfNeeded()

        // Decide editability (soft rules that don’t break the feature)
        canEditTracking = computeCanEditTracking()
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = canEditTracking }

        reloadData()
        updateHeader()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Recompute in case user started a round or changed home course
        canEditTracking = computeCanEditTracking()
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = canEditTracking }

        reloadData()
        updateHeader()
    }

    // MARK: - Course matching (soft)

    /// We only block edits if we can prove the current round is NOT on the home course.
    /// Otherwise we allow edits to keep tracking usable.
    private func computeCanEditTracking() -> Bool {

        // If no current game, allow edits (otherwise the screen feels broken)
        guard let g = GameManager.shared.currentGame else {
            // Optional one-time heads up, but don’t block
            showOnceNoCurrentRoundAlert()
            return true
        }

        // If home course isn’t a UUID yet, allow edits under HOME-COURSE bucket
        guard let homeUUID = UUID(uuidString: trackingCourseID),
              let homeCourse = CourseLibrary.shared.get(id: homeUUID) else {
            return true
        }

        let currentPars = Array(g.course.pars.prefix(STANDARD_HOLES))
        let currentHCs  = Array(g.course.holeHandicaps.prefix(STANDARD_HOLES))
        let homePars    = Array(homeCourse.pars.prefix(STANDARD_HOLES))
        let homeHCs     = Array(homeCourse.hcs.prefix(STANDARD_HOLES))

        let isSame = (currentPars == homePars && currentHCs == homeHCs)

        if !isSame {
            showOnceNotHomeCourseAlert(courseName: homeCourse.name)
        }

        return isSame
    }

    private func showOnceNoCurrentRoundAlert() {
        guard !hasShownNoRoundAlert else { return }
        hasShownNoRoundAlert = true

        let ac = UIAlertController(
            title: "No Current Round",
            message: "You can still manage tracked friends now. If you start a round on your Home Course, tracking will line up with hole stats.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    private func showOnceNotHomeCourseAlert(courseName: String) {
        guard !hasShownNotHomeAlert else { return }
        hasShownNotHomeAlert = true

        let ac = UIAlertController(
            title: "Not Home Course",
            message: "Tracking is tied to your Home Course: \(courseName). You can view the list here, but changes are disabled while playing a different course.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    // MARK: - Data helpers

    private func seedFriendsFromCurrentGameIfNeeded() {
        guard FriendStore.shared.friends.isEmpty,
              let g = GameManager.shared.currentGame else { return }

        let names = g.playerNames
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !names.isEmpty else { return }
        FriendStore.shared.merge(names: names)
    }

    private func reloadData() {
        allFriends = FriendStore.shared.friends.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        filtered = allFriends
        tableView.reloadData()
    }

    private func updateHeader() {
        let n = FriendTrackStore.shared.count(for: trackingCourseID)

        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.frame.size.height = 36

        if canEditTracking {
            label.text = "Tracking \(n)/\(limit)"
        } else {
            label.text = "Read-only (not on home course)"
        }

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
        ac.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self else { return }

            let name = (ac.textFields?[0].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let phone = (ac.textFields?[1].text ?? "").filter(\.isNumber)

            guard !name.isEmpty else { return }

            let friend = Friend(name: name, phone: phone)
            FriendStore.shared.upsert(friend)

            self.reloadData()
            self.updateHeader()
        })

        present(ac, animated: true)
    }

    @objc private func importRoster() {
        guard canEditTracking, let g = GameManager.shared.currentGame else { return }
        FriendStore.shared.merge(names: g.playerNames)
        reloadData()
        updateHeader()
    }

    // MARK: - TableView

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filtered.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let friend = filtered[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        var config = cell.defaultContentConfiguration()
        config.text = friend.name
        config.secondaryText = friend.phone.isEmpty ? "" : friend.phone
        cell.contentConfiguration = config

        let tracked = FriendTrackStore.shared.isTracked(friend.id, on: trackingCourseID)
        cell.accessoryType = tracked ? .checkmark : .none

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard canEditTracking else { return }

        let friend = filtered[indexPath.row]
        let changed = FriendTrackStore.shared.toggle(friend.id, courseID: trackingCourseID, limit: limit)

        if !changed {
            let ac = UIAlertController(
                title: "Limit Reached",
                message: "You can track up to \(limit) friends.",
                preferredStyle: .alert
            )
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            return
        }

        tableView.reloadRows(at: [indexPath], with: .automatic)
        updateHeader()
    }

    // MARK: - Search

    func updateSearchResults(for searchController: UISearchController) {
        let text = (searchController.searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        if text.isEmpty {
            filtered = allFriends
        } else {
            filtered = allFriends.filter { $0.name.localizedCaseInsensitiveContains(text) }
        }
        tableView.reloadData()
    }
}

