//
//  CustomGroupsViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 2/23/26.
//
import UIKit

final class CustomGroupsViewController: UITableViewController {

    var onPick: ((TextGroup) -> Void)?

    private var groups: [TextGroup] { TextGroupStore.shared.allSorted() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Custom Groups"
        tableView = UITableView(frame: .zero, style: .insetGrouped)

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeTapped))
    }

    @objc private func closeTapped() { dismiss(animated: true) }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        groups.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let g = groups[indexPath.row]
        cell.textLabel?.text = g.name
        cell.detailTextLabel?.text = "\(g.memberIDs.count) people"
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let g = groups[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        dismiss(animated: true) { [weak self] in
            self?.onPick?(g)
        }
    }

    // Swipe actions: Rename / Delete
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        let g = groups[indexPath.row]

        let delete = UIContextualAction(style: .destructive, title: "Delete") { _,_,done in
            TextGroupStore.shared.delete(id: g.id)
            tableView.reloadData()
            done(true)
        }

        let rename = UIContextualAction(style: .normal, title: "Rename") { [weak self] _,_,done in
            self?.promptRename(group: g)
            done(true)
        }
        rename.backgroundColor = .systemBlue

        return UISwipeActionsConfiguration(actions: [delete, rename])
    }

    private func promptRename(group: TextGroup) {
        let ac = UIAlertController(title: "Rename Group", message: nil, preferredStyle: .alert)
        ac.addTextField { tf in
            tf.text = group.name
            tf.clearButtonMode = .whileEditing
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            let name = (ac.textFields?.first?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return }
            var updated = group
            updated.name = name
            TextGroupStore.shared.upsert(updated)
            self.tableView.reloadData()
        })
        present(ac, animated: true)
    }
}
