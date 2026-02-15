//
//  ContactsViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 2/7/26.
//
import UIKit
import ContactsUI

final class ContactsViewController: UITableViewController {

    private enum CellID { static let contact = "ContactCell" }

    // MARK: - Data

    private var allFriends: [Friend] { FriendStore.shared.friends }

    private enum Filter: Int { case all, tracked, favorites }
    private var filter: Filter = .all { didSet { applySnapshot() } }

    private var searchText: String = "" { didSet { applySnapshot() } }

    // This is what the table actually displays after filter + search
    private var visibleFriends: [Friend] = []

    // MARK: - UI

    private lazy var searchController: UISearchController = {
        let sc = UISearchController(searchResultsController: nil)
        sc.obscuresBackgroundDuringPresentation = false
        sc.searchResultsUpdater = self
        sc.searchBar.placeholder = "Search contacts"
        return sc
    }()

    private lazy var filterControl: UISegmentedControl = {
        let c = UISegmentedControl(items: ["All", "Tracked", "⭐️"])
        c.selectedSegmentIndex = 0
        c.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
        return c
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Contacts"
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: CellID.contact)

        // Search
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        // Top filter
        tableView.tableHeaderView = makeHeader()

        // LEFT = Import
        navigationItem.leftBarButtonItem =
            UIBarButtonItem(title: "Import", style: .plain, target: self, action: #selector(importTapped))

        // RIGHT = Add + Close
        let add = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
        let close = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeTapped))
        navigationItem.rightBarButtonItems = [add, close]

        applySnapshot()
    }

    @objc private func closeTapped() {
        if presentingViewController != nil {
            dismiss(animated: true)                 // presented modally
        } else {
            navigationController?.popViewController(animated: true) // pushed
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        applySnapshot()
    }

    private func makeHeader() -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
        filterControl.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(filterControl)

        NSLayoutConstraint.activate([
            filterControl.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            filterControl.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            filterControl.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }

    @objc private func filterChanged() {
        filter = Filter(rawValue: filterControl.selectedSegmentIndex) ?? .all
    }

    // MARK: - Filtering

    private func applySnapshot() {
        var base = allFriends

        // Filter first
        switch filter {
        case .all:
            break
        case .tracked:
            base = base.filter { $0.isTracked }
        case .favorites:
            base = base.filter { $0.isFavorite }
        }

        // Search next
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            let lower = q.lowercased()
            base = base.filter {
                $0.name.lowercased().contains(lower) ||
                formattedPhone($0.phone).lowercased().contains(lower) ||
                $0.phone.lowercased().contains(lower)
            }
        }

        visibleFriends = base
        tableView.reloadData()
    }

    // MARK: - Table

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        visibleFriends.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: CellID.contact, for: indexPath)
        let f = visibleFriends[indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = f.name
        config.secondaryText = formattedPhone(f.phone)
        cell.contentConfiguration = config

        // Accessory: star (favorite) as a simple visual
        // If you’d rather not show it here, remove this.
        cell.accessoryView = favoriteStarView(isFavorite: f.isFavorite)

        // Show tracked state subtly using accessoryType
        cell.accessoryType = f.isTracked ? .checkmark : .none

        return cell
    }

    private func favoriteStarView(isFavorite: Bool) -> UIImageView {
        let iv = UIImageView(image: UIImage(systemName: isFavorite ? "star.fill" : "star"))
        iv.tintColor = .systemYellow
        iv.contentMode = .scaleAspectFit
        iv.frame = CGRect(x: 0, y: 0, width: 26, height: 26)
        return iv
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        presentEdit(for: visibleFriends[indexPath.row])
    }

    // MARK: - Swipe actions (Track / Favorite / Delete)

    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {

        let f = visibleFriends[indexPath.row]

        let delete = UIContextualAction(style: .destructive, title: "Delete") { _, _, done in
            FriendStore.shared.remove(friendID: f.id)
            self.applySnapshot()
            done(true)
        }

        let favoriteTitle = f.isFavorite ? "Unstar" : "Star"
        let favorite = UIContextualAction(style: .normal, title: favoriteTitle) { _, _, done in
            FriendStore.shared.setFavorite(friendID: f.id, isFavorite: !f.isFavorite)
            self.applySnapshot()
            done(true)
        }
        favorite.backgroundColor = .systemYellow

        let trackTitle = f.isTracked ? "Untrack" : "Track"
        let track = UIContextualAction(style: .normal, title: trackTitle) { _, _, done in
            FriendStore.shared.setTracked(friendID: f.id, isTracked: !f.isTracked)
            self.applySnapshot()
            done(true)
        }
        track.backgroundColor = .systemGreen

        return UISwipeActionsConfiguration(actions: [delete, favorite, track])
    }

    // Optional: swipe from left for “Track” (super Apple-feel)
    override func tableView(_ tableView: UITableView,
                            leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {

        let f = visibleFriends[indexPath.row]
        let trackTitle = f.isTracked ? "Untrack" : "Track"
        let track = UIContextualAction(style: .normal, title: trackTitle) { _, _, done in
            FriendStore.shared.setTracked(friendID: f.id, isTracked: !f.isTracked)
            self.applySnapshot()
            done(true)
        }
        track.backgroundColor = .systemGreen
        return UISwipeActionsConfiguration(actions: [track])
    }

    // MARK: - Add / Edit

    @objc private func addTapped() {
        let ac = UIAlertController(title: "New Contact", message: nil, preferredStyle: .alert)

        ac.addTextField { $0.placeholder = "Name" }
        ac.addTextField {
            $0.placeholder = "Mobile"
            $0.keyboardType = .phonePad
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        ac.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            let name = (ac.textFields?[0].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let phone = (ac.textFields?[1].text ?? "")
            guard !name.isEmpty else { return }

            FriendStore.shared.addOrMergeContact(name: name, phone: phone)
            self.applySnapshot()
        })

        present(ac, animated: true)
    }

    private func presentEdit(for friend: Friend) {
        let ac = UIAlertController(title: "Edit Contact", message: nil, preferredStyle: .actionSheet)

        let favTitle = friend.isFavorite ? "Remove Favorite ⭐️" : "Add to Favorites ⭐️"
        ac.addAction(UIAlertAction(title: favTitle, style: .default) { _ in
            FriendStore.shared.setFavorite(friendID: friend.id, isFavorite: !friend.isFavorite)
            self.applySnapshot()
        })

        let trackTitle = friend.isTracked ? "Untrack" : "Track"
        ac.addAction(UIAlertAction(title: trackTitle, style: .default) { _ in
            FriendStore.shared.setTracked(friendID: friend.id, isTracked: !friend.isTracked)
            self.applySnapshot()
        })

        ac.addAction(UIAlertAction(title: "Edit Name/Phone", style: .default) { _ in
            self.presentEditFields(for: friend)
        })

        ac.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            FriendStore.shared.remove(friendID: friend.id)
            self.applySnapshot()
        })

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // iPad safety
        if let pop = ac.popoverPresentationController,
           let idx = visibleFriends.firstIndex(where: { $0.id == friend.id }) {
            pop.sourceView = tableView
            pop.sourceRect = tableView.rectForRow(at: IndexPath(row: idx, section: 0))
        }

        present(ac, animated: true)
    }

    private func presentEditFields(for friend: Friend) {
        let ac = UIAlertController(title: "Edit", message: nil, preferredStyle: .alert)

        ac.addTextField { tf in
            tf.placeholder = "Name"
            tf.text = friend.name
        }

        ac.addTextField { tf in
            tf.placeholder = "Mobile"
            tf.keyboardType = .phonePad
            tf.text = friend.phone
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        ac.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            let name = ac.textFields?[0].text ?? ""
            let phone = ac.textFields?[1].text ?? ""
            FriendStore.shared.updateContact(friendID: friend.id, name: name, phone: phone)
            self.applySnapshot()
        })

        present(ac, animated: true)
    }

    // MARK: - Phone formatting

    private func formattedPhone(_ input: String) -> String {
        let d = input.filter(\.isNumber)
        guard d.count == 10 else { return d }
        let a = d.prefix(3)
        let b = d.dropFirst(3).prefix(3)
        let c = d.suffix(4)
        return "(\(a)) \(b)-\(c)"
    }
}

// MARK: - Search

extension ContactsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        searchText = searchController.searchBar.text ?? ""
    }
}

// MARK: - Apple Contact Picker (Import)

extension ContactsViewController: CNContactPickerDelegate {

    @objc private func importTapped() {
        let picker = CNContactPickerViewController()
        picker.delegate = self
        picker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
        present(picker, animated: true)
    }

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
        var added = 0

        for c in contacts {
            let name = ([c.givenName, c.familyName].joined(separator: " "))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }

            let phone = bestPhone(from: c)
            if phone.filter(\.isNumber).isEmpty { continue }

            FriendStore.shared.addOrMergeContact(name: name, phone: phone)
            added += 1
        }

        applySnapshot()

        if added == 0 {
            let a = UIAlertController(
                title: "No numbers found",
                message: "Those contacts didn’t have mobile numbers.",
                preferredStyle: .alert
            )
            a.addAction(UIAlertAction(title: "OK", style: .default))
            present(a, animated: true)
        }
    }

    private func bestPhone(from c: CNContact) -> String {
        if let mobile = c.phoneNumbers.first(where: { isMobileLabel($0.label) })?.value.stringValue {
            return mobile
        }
        return c.phoneNumbers.first?.value.stringValue ?? ""
    }

    private func isMobileLabel(_ label: String?) -> Bool {
        guard let label else { return false }
        return label.contains("Mobile") || label.contains("_$!<Mobile>!$_")
    }
}
