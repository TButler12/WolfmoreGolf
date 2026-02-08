//
//  ContactsViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 2/7/26.
//

import UIKit
import ContactsUI

final class ContactsViewController: UITableViewController {

    private enum Const {
        static let cellID = "ContactCell"
        static let starSize = CGSize(width: 32, height: 32)
    }

    private var friends: [Friend] { FriendStore.shared.friends }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("Contacts nav:", navigationController as Any, "presenting:", presentingViewController as Any)

        title = "Contacts"
        tableView = UITableView(frame: .zero, style: .insetGrouped)

        navigationItem.rightBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
        navigationItem.leftItemsSupplementBackButton = true

        navigationItem.leftBarButtonItem =
            UIBarButtonItem(title: "Import", style: .plain, target: self, action: #selector(importTapped))

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
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
        cell.detailTextLabel?.text = formattedPhone(friend.phone)
        cell.selectionStyle = .default
        cell.accessoryView = makeFavoriteButton(isFavorite: friend.isFavorite, friendID: friend.id)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        presentEdit(for: friends[indexPath.row])
    }

    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {

        let friend = friends[indexPath.row]

        let delete = UIContextualAction(style: .destructive, title: "Delete") { _, _, done in
            FriendStore.shared.remove(friendID: friend.id)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            done(true)
        }

        return UISwipeActionsConfiguration(actions: [delete])
    }

    // MARK: - Favorites

    private func makeFavoriteButton(isFavorite: Bool, friendID: UUID) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: isFavorite ? "star.fill" : "star"), for: .normal)
        button.tintColor = .systemYellow
        button.frame = CGRect(origin: .zero, size: Const.starSize)
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill

        // Store identity (safe even when list resorts)
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

        // Resort changes row order → reload whole table
        tableView.reloadData()
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
            let name = (ac.textFields?[0].text ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let phone = (ac.textFields?[1].text ?? "")

            guard !name.isEmpty else { return }

            FriendStore.shared.addOrMergeContact(name: name, phone: phone)
            self.tableView.reloadData()
        })

        present(ac, animated: true)
    }

    private func presentEdit(for friend: Friend) {
        let ac = UIAlertController(title: "Edit Contact", message: nil, preferredStyle: .alert)

        ac.addTextField { tf in
            tf.placeholder = "Name"
            tf.text = friend.name
        }

        ac.addTextField { tf in
            tf.placeholder = "Mobile"
            tf.keyboardType = .phonePad
            tf.text = friend.phone
        }

        let favTitle = friend.isFavorite ? "Remove Favorite ⭐️" : "Add to Favorites ⭐️"
        ac.addAction(UIAlertAction(title: favTitle, style: .default) { _ in
            FriendStore.shared.setFavorite(friendID: friend.id, isFavorite: !friend.isFavorite)
            self.tableView.reloadData()
        })

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        ac.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            let name = (ac.textFields?[0].text ?? "")
            let phone = (ac.textFields?[1].text ?? "")
            FriendStore.shared.updateContact(friendID: friend.id, name: name, phone: phone)
            self.tableView.reloadData()
        })

        ac.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            FriendStore.shared.remove(friendID: friend.id)
            self.tableView.reloadData()
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

            // Skip contacts that don’t have a real number
            if phone.filter(\.isNumber).isEmpty { continue }

            FriendStore.shared.addOrMergeContact(name: name, phone: phone)
            added += 1
        }

        tableView.reloadData()

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
        // Prefer mobile if present, otherwise first number
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
