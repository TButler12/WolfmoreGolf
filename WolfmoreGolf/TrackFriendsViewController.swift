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

    private let limit = 10

    // TODO: later we’ll hook this to a real home-course ID.
    // For now just use a stable string so tracking works.
    private var courseID: String { "HOME-COURSE" }


    private let searchController = UISearchController(searchResultsController: nil)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Track Friends"

        // Table cell registration (since we use a plain UITableViewCell)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

        // Navigation buttons: Add + Import Roster
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add,
                            target: self,
                            action: #selector(addTapped)),
            UIBarButtonItem(title: "Import Roster",
                            style: .plain,
                            target: self,
                            action: #selector(importRoster))
        ]

        // Search setup
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        definesPresentationContext = true

        reloadData()
        updateHeader()
    }

    // MARK: - Data helpers

    private func reloadData() {
        allFriends = FriendStore.shared.friends.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        filtered = allFriends
        tableView.reloadData()
    }

    private func updateHeader() {
        let n = FriendTrackStore.shared.count(for: courseID)
        let label = UILabel()
        label.textAlignment = .center
        label.text = "Tracking \(n)/\(limit) for Home Course"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.frame.size.height = 36
        tableView.tableHeaderView = label
    }

    // MARK: - Actions

    @objc private func addTapped() {
        let ac = UIAlertController(title: "Add Friend",
                                   message: nil,
                                   preferredStyle: .alert)
        ac.addTextField { tf in
            tf.placeholder = "Name"
            tf.autocapitalizationType = .words
            tf.clearButtonMode = .whileEditing
            tf.returnKeyType = .done
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Add", style: .default) { _ in
            let name = ac.textFields?.first?.text ?? ""
            FriendStore.shared.add(name)
            self.reloadData()
        })
        present(ac, animated: true)
    }

    /// Pull names from the current roster / card and merge into FriendStore
    @objc private func importRoster() {
        if let g = GameManager.shared.currentGame {
            let names = g.playerNames  // or g.rosterNames if you have that
            FriendStore.shared.merge(names: names)
            reloadData()
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
        cell.contentConfiguration = config

        let tracked = FriendTrackStore.shared.isTracked(friend.id, on: courseID)
        cell.accessoryType = tracked ? .checkmark : .none

        return cell
    }

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let friend = filtered[indexPath.row]
        let changed = FriendTrackStore.shared.toggle(friend.id,
                                                     courseID: courseID,
                                                     limit: limit)

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
