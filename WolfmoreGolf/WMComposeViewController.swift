//
//  WMComposeViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 2/23/26.
//
import UIKit

/// Pre-compose preview that shows recipient NAMES before we hand off to Apple Messages.
final class WMComposeViewController: UIViewController {

    // MARK: - Public
    var onSend: ((String) -> Void)?

    // MARK: - State
    private let recipients: [RecipientPreview]
    private let initialText: String

    // MARK: - UI
    private let toLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.textColor = .secondaryLabel
        return l
    }()

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private let textView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 18)
        tv.layer.borderWidth = 1
        tv.layer.borderColor = UIColor.systemGray4.cgColor
        tv.layer.cornerRadius = 12
        return tv
    }()

    // MARK: - Init (✅ must match what TextViewController calls)
    init(titleText: String, recipients: [RecipientPreview], initialText: String) {
        self.recipients = recipients
        self.initialText = initialText
        super.init(nibName: nil, bundle: nil)
        self.title = titleText
    }

    required init?(coder: NSCoder) {
        fatalError("WMComposeViewController must be created programmatically.")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Send",
            style: .done,
            target: self,
            action: #selector(sendTapped)
        )

        toLabel.text = "To: \(recipients.count) recipient\(recipients.count == 1 ? "" : "s")"

        tableView.dataSource = self
        tableView.isScrollEnabled = true                 // ✅ allow scrolling to see all recipients
        tableView.keyboardDismissMode = .interactive      // ✅ nice feel when dragging
        tableView.alwaysBounceVertical = recipients.count > 4

        textView.text = initialText

        layout()
        DispatchQueue.main.async { [weak self] in self?.textView.becomeFirstResponder() }
    }

    private func layout() {
        toLabel.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(toLabel)
        view.addSubview(tableView)
        view.addSubview(textView)

        // ✅ Allow the table to grow, but cap it so the message box stays usable
        let minTableHeight: CGFloat = 120
        let maxTableHeight: CGFloat = 280

        NSLayoutConstraint.activate([
            toLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            toLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            toLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            tableView.topAnchor.constraint(equalTo: toLabel.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.heightAnchor.constraint(greaterThanOrEqualToConstant: minTableHeight),
            tableView.heightAnchor.constraint(lessThanOrEqualToConstant: maxTableHeight),

            textView.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 12),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -16),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 160)
        ])
    }

    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func sendTapped() {
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        dismiss(animated: true) { [weak self] in
            self?.onSend?(text)
        }
    }

    // MARK: - Helpers
    private func last4(_ phone: String) -> String {
        let d = phone.filter(\.isNumber)
        guard d.count >= 4 else { return d }
        return "••• \(d.suffix(4))"
    }
}

// MARK: - UITableViewDataSource
extension WMComposeViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        recipients.count   // ✅ show all recipients (scroll handles overflow)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let r = recipients[indexPath.row]
        cell.textLabel?.text = r.name
        cell.detailTextLabel?.text = last4(r.phone)
        cell.selectionStyle = .none
        return cell
    }
}
