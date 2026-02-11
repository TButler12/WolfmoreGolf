//
//  ContactsViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 2/7/26.
//
import UIKit
import ContactsUI

final class ContactsViewController: UITableViewController {

    // MARK: - Constants
    private enum Const {
        static let cellID = "ContactCell"
        static let starSize = CGSize(width: 28, height: 28)
        static let trackLimit = 30
    }

    // MARK: - Data
    private var friends: [Friend] { FriendStore.shared.friends }

    private var courseID: String {
        let stored = ProfileStore.homeCourseID
        return stored.isEmpty ? "HOME-COURSE" : stored
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Contacts"
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.keyboardDismissMode = .onDrag
        tableView.tableFooterView = UIView()

        navigationItem.rightBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: .add,
                            target: self,
                            action: #selector(addTapped))

        navigationItem.leftItemsSupplementBackButton = true
        navigationItem.leftBarButtonItem =
            UIBarButtonItem(title: "Import",
                            style: .plain,
                            target: self,
                            action: #selector(importTapped))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        tableView.reloadData()
    }

    // MARK: - Table
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        friends.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: Const.cellID)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: Const.cellID)

        let friend = friends[indexPath.row]
        configure(cell, with: friend)
        return cell
    }

    private func configure(_ cell: UITableViewCell, with friend: Friend) {
        cell.textLabel?.text = friend.name

        let phone = friend.phone.trimmingCharacters(in: .whitespacesAndNewlines)
        cell.detailTextLabel?.text = phone.isEmpty ? "No mobile" : formattedPhone(phone)

        let isTracked = FriendTrackStore.shared.isTracked(friend.id, on: courseID)

        cell.accessoryType = isTracked ? .checkmark : .none
        cell.tintColor = isTracked ? .systemGreen : .systemGray

        // Optional: make tracked friends visually different
        cell.textLabel?.textColor = isTracked ? .systemGreen : .label
        cell.detailTextLabel?.textColor = isTracked ? .systemGreen : .secondaryLabel

        cell.accessoryView = makeFavoriteButton(isFavorite: friend.isFavorite, friendID: friend.id)
        cell.selectionStyle = .default
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        presentEdit(for: friends[indexPath.row])
    }

    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {

        let friend = friends[indexPath.row]
        let isTracked = FriendTrackStore.shared.isTracked(friend.id, on: courseID)

        let trackTitle = isTracked ? "Untrack" : "Track"
        let track = UIContextualAction(style: .normal, title: trackTitle) { [weak self] _, _, done in
            guard let self else { done(true); return }

            // ✅ uses your setTracked(desired, id, courseID, limit) helper
            let desiredOn = !isTracked
            let ok = FriendTrackStore.shared.setTracked(
                desiredOn,
                friend.id,
                courseID: self.courseID,
                limit: Const.trackLimit
            )

            if ok {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            } else {
                self.showTrackLimitAlert()
            }
            done(true)
        }
        track.backgroundColor = .systemGreen

        let delete = UIContextualAction(style: .destructive, title: "Delete") { _, _, done in
            FriendStore.shared.remove(friendID: friend.id)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            done(true)
        }

        let cfg = UISwipeActionsConfiguration(actions: [delete, track])
        cfg.performsFirstActionWithFullSwipe = false
        return cfg
    }

    // MARK: - Favorites
    private func makeFavoriteButton(isFavorite: Bool, friendID: UUID) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: isFavorite ? "star.fill" : "star"), for: .normal)
        button.tintColor = .systemYellow
        button.frame = CGRect(origin: .zero, size: Const.starSize)

        // safer than tag
        button.accessibilityIdentifier = friendID.uuidString
        button.addTarget(self, action: #selector(favoriteTapped(_:)), for: .touchUpInside)
        return button
    }

    @objc private func favoriteTapped(_ sender: UIButton) {
        guard
            let idString = sender.accessibilityIdentifier,
            let id = UUID(uuidString: idString),
            let friend = FriendStore.shared.friends.first(where: { $0.id == id })
        else { return }

        FriendStore.shared.setFavorite(friendID: friend.id, isFavorite: !friend.isFavorite)
        tableView.reloadData()
    }

    // MARK: - Add / Edit
    @objc private func addTapped() {
        let ac = UIAlertController(title: "New Contact", message: nil, preferredStyle: .alert)

        ac.addTextField {
            $0.placeholder = "Name"
            $0.autocapitalizationType = .words
        }
        ac.addTextField {
            $0.placeholder = "Mobile"
            $0.keyboardType = .phonePad
            $0.clearButtonMode = .whileEditing
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        ac.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self else { return }
            let name = ac.textFields?[0].text ?? ""
            let phone = ac.textFields?[1].text ?? ""
            self.handleNewOrImportedFriend(named: name, phone: phone)
        })

        present(ac, animated: true)
    }

    private func presentEdit(for friend: Friend) {
        let ac = UIAlertController(title: "Edit Contact", message: nil, preferredStyle: .alert)

        ac.addTextField { tf in
            tf.placeholder = "Name"
            tf.text = friend.name
            tf.autocapitalizationType = .words
        }
        ac.addTextField { tf in
            tf.placeholder = "Mobile"
            tf.keyboardType = .phonePad
            tf.text = friend.phone
        }

        let favTitle = friend.isFavorite ? "Remove Favorite ⭐️" : "Add to Favorites ⭐️"
        ac.addAction(UIAlertAction(title: favTitle, style: .default) { [weak self] _ in
            guard let self else { return }
            FriendStore.shared.setFavorite(friendID: friend.id, isFavorite: !friend.isFavorite)
            self.tableView.reloadData()
        })

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        ac.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self else { return }

            let name = (ac.textFields?[0].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let phone = (ac.textFields?[1].text ?? "")

            FriendStore.shared.updateContact(friendID: friend.id, name: name, phone: phone)
            self.tableView.reloadData()
        })

        ac.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self else { return }
            FriendStore.shared.remove(friendID: friend.id)
            self.tableView.reloadData()
        })

        present(ac, animated: true)
    }

    // MARK: - Centralized add/import (includes tracking prompt)
    private func handleNewOrImportedFriend(named name: String, phone: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = phone.filter(\.isNumber)

        guard !trimmed.isEmpty else { return }

        // Upsert
        if var existing = FriendStore.shared.friends.first(where: {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .caseInsensitiveCompare(trimmed) == .orderedSame
        }) {
            if !digits.isEmpty { existing.phone = digits }
            FriendStore.shared.upsert(existing)
        } else {
            FriendStore.shared.upsert(Friend(name: trimmed, phone: digits))
        }

        tableView.reloadData()

        // Prompt to track if not already tracked
        guard let saved = FriendStore.shared.friends.first(where: {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .caseInsensitiveCompare(trimmed) == .orderedSame
        }) else { return }

        guard !FriendTrackStore.shared.isTracked(saved.id, on: courseID) else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.promptTrackNewFriend(saved)
        }
    }

    private func promptTrackNewFriend(_ friend: Friend) {
        let ac = UIAlertController(
            title: "Track this player?",
            message: "Track \(friend.name) for ⭐ Home Course stats?",
            preferredStyle: .alert
        )

        ac.addAction(UIAlertAction(title: "Not now", style: .cancel))

        ac.addAction(UIAlertAction(title: "Track", style: .default) { [weak self] _ in
            guard let self else { return }

            let ok = FriendTrackStore.shared.setTracked(
                true,
                friend.id,
                courseID: self.courseID,
                limit: Const.trackLimit
            )

            if ok {
                self.tableView.reloadData()
            } else {
                self.showTrackLimitAlert()
            }
        })

        present(ac, animated: true)
    }

    private func showTrackLimitAlert() {
        let ac = UIAlertController(
            title: "Limit Reached",
            message: "You can track up to \(Const.trackLimit) friends for this course.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    // MARK: - Phone formatting
    private func formattedPhone(_ input: String) -> String {
        let d = input.filter(\.isNumber)
        guard d.count == 10 else { return input }
        let a = d.prefix(3)
        let b = d.dropFirst(3).prefix(3)
        let c = d.suffix(4)
        return "(\(a)) \(b)-\(c)"
    }
}

// MARK: - Import from iPhone Contacts (Picker)
extension ContactsViewController: CNContactPickerDelegate {

    @objc private func importTapped() {
        let picker = CNContactPickerViewController()
        picker.delegate = self

        // ✅ show only phone numbers; user taps a specific number (keeps search + avoids multi-select)
        picker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
        picker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
        picker.predicateForSelectionOfContact = NSPredicate(value: false)
        picker.predicateForSelectionOfProperty =
            NSPredicate(format: "key == %@", CNContactPhoneNumbersKey)

        present(picker, animated: true)
    }

    func contactPicker(_ picker: CNContactPickerViewController,
                       didSelect contactProperty: CNContactProperty) {
        guard let phone = contactProperty.value as? CNPhoneNumber else { return }

        let name = CNContactFormatter.string(from: contactProperty.contact, style: .fullName)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let raw = phone.stringValue
        handleNewOrImportedFriend(named: name, phone: raw)
    }
}
