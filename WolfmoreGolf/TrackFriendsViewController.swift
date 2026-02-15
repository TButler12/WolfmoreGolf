//
//  TrackFriendsViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 11/14/25.
//
import UIKit

final class TrackFriendsViewController: UITableViewController, UISearchResultsUpdating {

    // MARK: - Constants

    private let limit = 30
    private let cellID = "TrackFriendCell"

    // MARK: - Data

    private var allFriends: [Friend] = []
    private var filteredFriends: [Friend] = []

    // MARK: - UI

    private let searchController = UISearchController(searchResultsController: nil)

    // MARK: - State

    private var canEditTracking = false
    private var hasShownNoRoundAlert = false
    private var hasShownNotHomeAlert = false

    // MARK: - Tracking Course

    /// Course ID used for tracking (home course only).
    /// - If ProfileStore.homeCourseID is set, use that.
    /// - Else, if the default WolfMore course exists, use its UUID.
    /// - Else, fall back to legacy "HOME-COURSE" key.
    private var trackingCourseID: String {
        let stored = ProfileStore.homeCourseID
        if !stored.isEmpty { return stored }
        if let c = CourseLibrary.shared.WolfMore() { return c.id.uuidString }
        return "HOME-COURSE"
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
        configureSearch()

        canEditTracking = isPlayingHomeCourse()
        setEditingEnabled(canEditTracking)

        seedFriendsFromCurrentGameIfNeeded()
        reloadFriends()
        updateHeader()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadFriends()
        updateHeader()
    }

    // MARK: - UI Setup

    private func configureUI() {
        title = "Track Friends"
        view.backgroundColor = .systemBackground
        tableView.backgroundColor = .systemBackground
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        tableView.tableFooterView = UIView()

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped)),
            UIBarButtonItem(title: "Import", style: .plain, target: self, action: #selector(importRoster))
        ]
    }

    private func configureSearch() {
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    private func setEditingEnabled(_ enabled: Bool) {
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = enabled }
    }

    // MARK: - Home-course logic

    /// Returns true if the current game’s course matches the selected home/tracking course.
    private func isPlayingHomeCourse() -> Bool {
        guard let g = GameManager.shared.currentGame else {
            showOnceNoCurrentRoundAlert()
            return false
        }

        guard let uuid = UUID(uuidString: trackingCourseID),
              let homeCourse = CourseLibrary.shared.get(id: uuid) else {
            return false
        }

        let samePars = Array(g.course.pars.prefix(18)) == Array(homeCourse.pars.prefix(18))
        let sameHCs  = Array(g.course.holeHandicaps.prefix(18)) == Array(homeCourse.hcs.prefix(18))
        let isSame = samePars && sameHCs

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
            message: "Tracking by hole is tied to your home course: \(courseName).\nYou can view the list, but changes are disabled for this round.",
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

    private func reloadFriends() {
        allFriends = FriendStore.shared.friends.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        filteredFriends = allFriends
        tableView.reloadData()
    }

    private func updateHeader() {
        let trackedCount = FriendTrackStore.shared.count(courseID: trackingCourseID)

        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.frame.size.height = 36

        label.text = canEditTracking
            ? "Tracking \(trackedCount)/\(limit) for Home Course"
            : "Read-only (not on home course)"

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

            let name = (ac.textFields?[0].text ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let rawPhone = ac.textFields?[1].text ?? ""
            let normalizedPhone = rawPhone.filter(\.isNumber)

            guard !name.isEmpty else { return }

            FriendStore.shared.addOrMergeContact(name: name, phone: normalizedPhone)
            self.reloadFriends()
            self.updateHeader()
        })

        present(ac, animated: true)
    }

    @objc private func importRoster() {
        guard canEditTracking, let g = GameManager.shared.currentGame else { return }
        FriendStore.shared.merge(names: g.playerNames)
        reloadFriends()
        updateHeader()
    }

    // MARK: - TableView

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredFriends.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let friend = filteredFriends[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)

        let tracked = FriendTrackStore.shared.isTracked(friendID: friend.id, courseID: trackingCourseID)

        // Content
        var config = cell.defaultContentConfiguration()
        config.text = friend.name
        config.secondaryText = friend.phone.isEmpty ? nil : friend.phone

        // ✅ GREEN when tracked
        config.textProperties.color = tracked ? .systemGreen : .label
        config.secondaryTextProperties.color = tracked ? .systemGreen : .secondaryLabel

        cell.contentConfiguration = config
        cell.accessoryType = tracked ? .checkmark : .none
        cell.selectionStyle = canEditTracking ? .default : .none

        // ✅ subtle green row tint (and reset when not tracked)
        if #available(iOS 14.0, *) {
            var bg = UIBackgroundConfiguration.listPlainCell()
            bg.backgroundColor = tracked ? UIColor.systemGreen.withAlphaComponent(0.12) : .clear
            cell.backgroundConfiguration = bg
        } else {
            cell.backgroundColor = tracked ? UIColor.systemGreen.withAlphaComponent(0.12) : .clear
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard canEditTracking else { return }

        let friend = filteredFriends[indexPath.row]

        let changed = FriendTrackStore.shared.toggle(
            friendID: friend.id,
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
        let text = (searchController.searchBar.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            filteredFriends = allFriends
            tableView.reloadData()
            return
        }

        filteredFriends = allFriends.filter { $0.name.localizedCaseInsensitiveContains(text) }
        tableView.reloadData()
    }
}

