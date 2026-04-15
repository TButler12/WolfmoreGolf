//
//  ImportRemoteRoundViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 4/13/26.
//

import UIKit

final class ImportRemoteRoundViewController: UIViewController {

    var onImport: ((String) -> Void)?

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Import Remote Round"
        l.font = .boldSystemFont(ofSize: 24)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let textView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 16)
        tv.layer.cornerRadius = 12
        tv.layer.borderWidth = 1
        tv.layer.borderColor = UIColor.systemGray4.cgColor
        tv.autocorrectionType = .no
        tv.autocapitalizationType = .none
        tv.spellCheckingType = .no
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private lazy var pasteButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Paste", for: .normal)
        b.titleLabel?.font = .boldSystemFont(ofSize: 18)
        b.addTarget(self, action: #selector(pasteTapped), for: .touchUpInside)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private lazy var importButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Import", for: .normal)
        b.titleLabel?.font = .boldSystemFont(ofSize: 18)
        b.addTarget(self, action: #selector(importTapped), for: .touchUpInside)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private lazy var cancelButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Cancel", for: .normal)
        b.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }

    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(textView)
        view.addSubview(pasteButton)
        view.addSubview(importButton)
        view.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            textView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.heightAnchor.constraint(equalToConstant: 220),

            pasteButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 20),
            pasteButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            pasteButton.heightAnchor.constraint(equalToConstant: 50),

            importButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 20),
            importButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            importButton.heightAnchor.constraint(equalToConstant: 50),

            cancelButton.topAnchor.constraint(equalTo: pasteButton.bottomAnchor, constant: 16),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc private func pasteTapped() {
        textView.paste(nil)
    }

    @objc private func importTapped() {
        let text = textView.text ?? ""
        onImport?(text)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}
