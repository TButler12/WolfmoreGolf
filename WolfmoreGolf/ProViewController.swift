//
//  ProViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 1/29/26.
//

import UIKit

final class ProViewController: UITableViewController {

    private enum Section: Int, CaseIterable { case unlock, plan }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "WolfMore Pro"
        tableView = UITableView(frame: .zero, style: .insetGrouped)

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
    }

    @objc private func closeTapped() { dismiss(animated: true) }

    override func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        (Section(rawValue: section) == .unlock) ? 3 : 1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        (Section(rawValue: section) == .unlock) ? "Unlock with Pro" : "Yearly Plan"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)

        if Section(rawValue: indexPath.section) == .unlock {
            cell.selectionStyle = .none
            cell.textLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
            cell.textLabel?.text = [
                "Unlimited round history",
                "Year-long summaries",
                "Advanced player & course stats"
            ][indexPath.row]
        } else {
            cell.textLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
            cell.textLabel?.text = "Upgrade to Pro (Yearly) — —"
            cell.accessoryType = .disclosureIndicator
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard Section(rawValue: indexPath.section) == .plan else { return }

        let ac = UIAlertController(
            title: "Coming Soon",
            message: "Purchases will be enabled after App Store Connect products are set up.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}

