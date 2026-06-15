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
    private var isBuildingGroup = false
    private var selectedGroupMemberIDs = Set<UUID>()

    // MARK: - Data
    private var friends: [Friend] { FriendStore.shared.friends }

    private var courseID: String {
        let stored = ProfileStore.homeCourseID
        return stored.isEmpty ? "HOME-COURSE" : stored
    }
    
    var editingGroup: TextGroup?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.keyboardDismissMode = .onDrag
        tableView.tableFooterView = UIView()
        tableView.cellLayoutMarginsFollowReadableWidth = false

        navigationItem.leftItemsSupplementBackButton = true
        navigationItem.leftBarButtonItem =
            UIBarButtonItem(title: "Import",
                            style: .plain,
                            target: self,
                            action: #selector(importTapped))
        if let group = editingGroup {
            title = "Edit Group"
            isBuildingGroup = true
            selectedGroupMemberIDs = Set(group.memberIDs)

            navigationItem.leftBarButtonItems = [
                UIBarButtonItem(title: "Delete",
                                style: .plain,
                                target: self,
                                action: #selector(deleteEditingGroupTapped)),
                UIBarButtonItem(title: "Import",
                                style: .plain,
                                target: self,
                                action: #selector(importTapped))
            ]

            navigationItem.rightBarButtonItems = [
                UIBarButtonItem(title: "Save",
                                style: .done,
                                target: self,
                                action: #selector(newGroupTapped)),
                UIBarButtonItem(title: "Cancel",
                                style: .plain,
                                target: self,
                                action: #selector(cancelNewGroupTapped))
            ]
        }
        if let group = editingGroup {
            title = "Edit Group"
            isBuildingGroup = true
            selectedGroupMemberIDs = Set(group.memberIDs)

            navigationItem.rightBarButtonItems = [
                UIBarButtonItem(title: "Save",
                                style: .done,
                                target: self,
                                action: #selector(newGroupTapped)),
                UIBarButtonItem(title: "Cancel",
                                style: .plain,
                                target: self,
                                action: #selector(cancelNewGroupTapped))
            ]
        } else {
            title = "Contacts"

            navigationItem.rightBarButtonItems = [
                UIBarButtonItem(title: "Create Group",
                                style: .plain,
                                target: self,
                                action: #selector(newGroupTapped)),
                UIBarButtonItem(barButtonSystemItem: .add,
                                target: self,
                                action: #selector(addTapped))
            ]
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        tableView.reloadData()
    }

    // MARK: - Table

    override func numberOfSections(in tableView: UITableView) -> Int {
        isBuildingGroup ? 1 : 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !isBuildingGroup && section == 0 { return 1 }
        return friends.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if !isBuildingGroup && section == 0 { return "You" }
        return nil
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if !isBuildingGroup && indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "YouCell")
                ?? UITableViewCell(style: .subtitle, reuseIdentifier: "YouCell")
            configureYouCell(cell)
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: Const.cellID)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: Const.cellID)

        let friend = friends[indexPath.row]
        configure(cell, with: friend)
        return cell
    }

    private func configureYouCell(_ cell: UITableViewCell) {
        let name = (ProfileStore.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        cell.textLabel?.text = (name.isEmpty || name == "Player 1") ? "Set your scoring name" : name
        cell.detailTextLabel?.text = "Your scoring name — tap to edit"
        cell.textLabel?.textColor = .label
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.25)
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
    }
    @objc private func deleteEditingGroupTapped() {
        guard let group = editingGroup else { return }

        let ac = UIAlertController(
            title: "Delete Group",
            message: "Delete \"\(group.name)\"?",
            preferredStyle: .alert
        )

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        ac.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            TextGroupStore.shared.delete(id: group.id)
            self?.navigationController?.popViewController(animated: true)
        })

        present(ac, animated: true)
    }
    private func configure(_ cell: UITableViewCell, with friend: Friend) {
        cell.textLabel?.text = friend.name

        let phone = friend.phone.trimmingCharacters(in: .whitespacesAndNewlines)
        cell.detailTextLabel?.text = phone.isEmpty ? "No mobile" : formattedPhone(phone)

        let isTracked = FriendTrackStore.shared.isTracked(friend.id, on: courseID)
        let isSelectedForGroup = selectedGroupMemberIDs.contains(friend.id)

        if isBuildingGroup {
            cell.accessoryType = isSelectedForGroup ? .checkmark : .none
            cell.tintColor = .systemBlue
            cell.accessoryView = nil
            cell.textLabel?.textColor = .label
            cell.detailTextLabel?.textColor = .secondaryLabel
        } else {
            cell.accessoryType = isTracked ? .checkmark : .none
            cell.tintColor = isTracked ? .systemGreen : .systemGray
            cell.textLabel?.textColor = isTracked ? .systemGreen : .label
            cell.detailTextLabel?.textColor = isTracked ? .systemGreen : .secondaryLabel
            cell.accessoryView = makeFavoriteButton(isFavorite: friend.isFavorite, friendID: friend.id)
        }

        cell.selectionStyle = .default
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if !isBuildingGroup && indexPath.section == 0 {
            presentEditScoringName()
            return
        }

        let friend = friends[indexPath.row]

        if isBuildingGroup {
            if selectedGroupMemberIDs.contains(friend.id) {
                selectedGroupMemberIDs.remove(friend.id)
            } else {
                selectedGroupMemberIDs.insert(friend.id)
            }
            tableView.reloadRows(at: [indexPath], with: .automatic)
            return
        }

        presentEdit(for: friend)
    }

    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        if isBuildingGroup { return nil }
        guard indexPath.section == 1 else { return nil }
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
    private func importSelectedContact(name: String, phone: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = phone.filter(\.isNumber)

        guard !trimmedName.isEmpty else { return }

        let existingHC = FriendStore.shared.friends.first(where: {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .caseInsensitiveCompare(trimmedName) == .orderedSame
        })?.defaultHC

        showImportHCPrompt(name: trimmedName, phone: digits, prefillHC: existingHC)
    }

    private func showImportHCPrompt(name: String, phone: String, prefillHC: Int?) {
        let ac = UIAlertController(
            title: "Handicap",
            message: "Enter HC for \(name)",
            preferredStyle: .alert
        )

        ac.addTextField { tf in
            tf.placeholder = "HC (optional)"
            tf.keyboardType = .numberPad
            if let prefillHC, prefillHC > 0 {
                tf.text = "\(prefillHC)"
            }
        }

        ac.addAction(UIAlertAction(title: "Skip", style: .cancel) { [weak self] _ in
            self?.upsertImportedFriend(name: name, phone: phone, hc: nil)
        })

        ac.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            let raw = (ac.textFields?.first?.text ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let hc = Int(raw)
            self?.upsertImportedFriend(name: name, phone: phone, hc: hc)
        })

        present(ac, animated: true)
    }

    private func upsertImportedFriend(name: String, phone: String, hc: Int?) {
        if var existing = FriendStore.shared.friends.first(where: {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .caseInsensitiveCompare(name) == .orderedSame
        }) {
            if let hc {
                existing.defaultHC = max(0, hc)
            }
            if !phone.isEmpty {
                existing.phone = phone
            }
            FriendStore.shared.upsert(existing)
        } else {
            let friend = Friend(
                name: name,
                defaultHC: max(0, hc ?? 0),
                phone: phone
            )
            FriendStore.shared.upsert(friend)
        }
        tableView.reloadData()
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
    @objc private func newGroupTapped() {
        if isBuildingGroup {
            promptToSaveCustomGroup()
        } else {
            isBuildingGroup = true
            selectedGroupMemberIDs.removeAll()

            navigationItem.rightBarButtonItems = [
                UIBarButtonItem(title: "Save Group",
                                style: .done,
                                target: self,
                                action: #selector(newGroupTapped)),
                UIBarButtonItem(title: "Cancel",
                                style: .plain,
                                target: self,
                                action: #selector(cancelNewGroupTapped))
            ]

            title = "Select Friends"
            tableView.reloadData()
        }
    }

    @objc private func cancelNewGroupTapped() {
        isBuildingGroup = false
        selectedGroupMemberIDs.removeAll()

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Add Group",
                            style: .plain,
                            target: self,
                            action: #selector(newGroupTapped)),
            UIBarButtonItem(barButtonSystemItem: .add,
                            target: self,
                            action: #selector(addTapped))
        ]

        title = "Contacts"
        tableView.reloadData()
    }

    private func promptToSaveCustomGroup() {
        guard !selectedGroupMemberIDs.isEmpty else {
            let ac = UIAlertController(
                title: "No Contacts Selected",
                message: "Select at least one contact for this custom group.",
                preferredStyle: .alert
            )
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            return
        }

        let isEditing = (editingGroup != nil)

        let ac = UIAlertController(
            title: isEditing ? "Edit Group" : "New Custom Group",
            message: isEditing ? "Update group name" : "Enter a group name.",
            preferredStyle: .alert
        )

        ac.addTextField { [weak self] tf in
            tf.placeholder = "Group name"
            tf.text = self?.editingGroup?.name   // 👈 prefill
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        ac.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self else { return }

            let finalName = (ac.textFields?.first?.text ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !finalName.isEmpty else { return }

            let ids = Array(self.selectedGroupMemberIDs)

            if var group = self.editingGroup {
                // 🔥 EDIT EXISTING
                group.name = finalName
                group.memberIDs = ids
                TextGroupStore.shared.upsert(group)
            } else {
                // 🔥 CREATE NEW
                TextGroupStore.shared.upsert(TextGroup(name: finalName, memberIDs: ids))
            }

            // RESET STATE
            self.isBuildingGroup = false
            self.editingGroup = nil
            self.selectedGroupMemberIDs.removeAll()

            self.navigationItem.rightBarButtonItems = [
                UIBarButtonItem(title: "Add Group",
                                style: .plain,
                                target: self,
                                action: #selector(self.newGroupTapped)),
                UIBarButtonItem(barButtonSystemItem: .add,
                                target: self,
                                action: #selector(self.addTapped))
            ]

            self.title = "Contacts"
            self.tableView.reloadData()
            self.navigationController?.popViewController(animated: true)
        })

        present(ac, animated: true)
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
            self.importSelectedContact(name: name, phone: phone)
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

    private func presentEditScoringName() {
        let ac = UIAlertController(
            title: "Your Scoring Name",
            message: "This name appears on every scorecard you play.",
            preferredStyle: .alert
        )

        ac.addTextField { tf in
            let stored = ProfileStore.name ?? ""
            tf.text = (stored == "Player 1" || stored.isEmpty) ? "" : stored
            tf.placeholder = "e.g. McTommy, Bucky"
            tf.autocapitalizationType = .words
            tf.clearButtonMode = .whileEditing
            tf.returnKeyType = .done
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        ac.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            let raw = (ac.textFields?.first?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !raw.isEmpty else { return }
            ProfileStore.name = raw
            self?.tableView.reloadData()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
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

        picker.dismiss(animated: true) { [weak self] in
            self?.importSelectedContact(name: name, phone: raw)
        }
    }
}
