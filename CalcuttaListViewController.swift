import UIKit

final class CalcuttaListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var events: [CalcuttaEvent] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Calcutta Pools"
        view.backgroundColor = .systemGroupedBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add, target: self, action: #selector(newTapped))

        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        CalcuttaStore.shared.seedTonightsEventIfNeeded()
        events = CalcuttaStore.shared.events
        tableView.reloadData()
    }

    // MARK: - Actions

    @objc private func doneTapped() {
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func newTapped() {
        let ac = UIAlertController(title: "New Calcutta Pool", message: "Enter a name for this event.", preferredStyle: .alert)
        ac.addTextField { tf in
            tf.placeholder = "e.g., Club Championship 2026"
            tf.autocapitalizationType = .words
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Create", style: .default) { [weak self, weak ac] _ in
            let name = (ac?.textFields?.first?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return }
            let event = CalcuttaEvent(name: name)
            CalcuttaStore.shared.save(event)
            let vc = CalcuttaManagerViewController(event: event)
            self?.navigationController?.pushViewController(vc, animated: true)
        })
        present(ac, animated: true)
    }
}

// MARK: - UITableViewDataSource / Delegate

extension CalcuttaListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        events.isEmpty ? 1 : events.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if events.isEmpty {
            let cell = UITableViewCell()
            cell.textLabel?.text = "No Calcutta pools yet — tap ＋ to create one"
            cell.textLabel?.textColor = .secondaryLabel
            cell.textLabel?.numberOfLines = 0
            cell.selectionStyle = .none
            return cell
        }

        let event = events[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = event.name
        let pot = event.totalPot
        let teamCount = event.teams.count
        cell.detailTextLabel?.text = "\(teamCount) team\(teamCount == 1 ? "" : "s")  ·  Pot: \(calcuttaFormatMoney(pot))"
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !events.isEmpty else { return }
        let vc = CalcuttaManagerViewController(event: events[indexPath.row])
        navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete, !events.isEmpty else { return }
        let event = events[indexPath.row]
        let ac = UIAlertController(
            title: "Delete \"\(event.name)\"?",
            message: "This cannot be undone.",
            preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            CalcuttaStore.shared.delete(event)
            self?.events = CalcuttaStore.shared.events
            self?.tableView.reloadData()
        })
        present(ac, animated: true)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { !events.isEmpty }
}

// MARK: - Shared formatting helper (file-private, accessible within module via internal)

func calcuttaFormatMoney(_ value: Double) -> String {
    let fmt = NumberFormatter()
    fmt.numberStyle = .currency
    fmt.maximumFractionDigits = 0
    fmt.minimumFractionDigits = 0
    return fmt.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
}
