//
//  CustomGroupsViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 2/23/26.
//
import UIKit

final class CustomGroupsViewController: UITableViewController {

    var onPick: ((TextGroup) -> Void)?
    private var groups: [TextGroup] {
        TextGroupStore.shared.groups
    }
    
    var editingGroup: TextGroup?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Custom Groups"
        tableView = UITableView(frame: .zero, style: .insetGrouped)

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

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
        tableView.deselectRow(at: indexPath, animated: true)

        let group = groups[indexPath.row]

        // PICK MODE (used by TextViewController)
        if let onPick {
            dismiss(animated: true) {
                onPick(group)
            }
            return
        }

        // EDIT MODE (used when navigating from your normal flow)
        guard let vc = storyboard?.instantiateViewController(
            withIdentifier: "ContactsViewController"
        ) as? ContactsViewController else {
            return
        }

        vc.editingGroup = group
        navigationController?.pushViewController(vc, animated: true)
    }
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {

        let g = groups[indexPath.row]

        // 🔥 EDIT MEMBERS (THIS is what you need)
        let edit = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, done in
            guard let self else {
                done(false)
                return
            }

            let sb = UIStoryboard(name: "Main", bundle: nil)
            guard let vc = sb.instantiateViewController(
                withIdentifier: "ContactsViewController"
            ) as? ContactsViewController else {
                done(false)
                return
            }

            vc.editingGroup = g
            self.navigationController?.pushViewController(vc, animated: true)
            done(true)
        }
        edit.backgroundColor = .systemOrange

        let rename = UIContextualAction(style: .normal, title: "Rename") { [weak self] _, _, done in
            self?.promptRename(group: g)
            done(true)
        }
        rename.backgroundColor = .systemBlue

        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            TextGroupStore.shared.delete(id: g.id)
            self?.tableView.reloadData()
            done(true)
        }

        let cfg = UISwipeActionsConfiguration(actions: [delete, rename, edit])
        cfg.performsFirstActionWithFullSwipe = false
        return cfg
    }

    private func promptRename(group: TextGroup) {
        let ac = UIAlertController(title: "Rename Group", message: nil, preferredStyle: .alert)
        ac.addTextField { tf in
            tf.text = group.name
            tf.clearButtonMode = .whileEditing
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            let name = (ac.textFields?.first?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return }
            var updated = group
            updated.name = name
            TextGroupStore.shared.upsert(updated)
            self?.tableView.reloadData()
        })
        self.present(ac, animated: true)
    }
}
