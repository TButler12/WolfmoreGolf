//
//  ProViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 1/29/26.
//
import UIKit
import StoreKit

@available(iOS 15.0, *)

final class ProViewController: UIViewController {

    // MARK: - UI

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "WolfMore Pro"
        l.font = .systemFont(ofSize: 28, weight: .bold)
        l.numberOfLines = 0
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Unlock custom text groups, advanced stats, and more."
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        return l
    }()

    private let featuresLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.numberOfLines = 0
        l.text = """
        ✅ Custom text groups
        ✅ Favorites & tracked friend blasts
        ✅ Year-long stats + summaries
        """
        return l
    }()

    private let priceLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .secondaryLabel
        l.text = "Loading price…"
        return l
    }()

    private let unlockButton: UIButton = {
        var cfg = UIButton.Configuration.filled()
        cfg.title = "Unlock Pro"
        cfg.cornerStyle = .large
        cfg.baseBackgroundColor = .systemGreen
        let b = UIButton(configuration: cfg)
        return b
    }()

    private let restoreButton: UIButton = {
        var cfg = UIButton.Configuration.plain()
        cfg.title = "Restore Purchases"
        let b = UIButton(configuration: cfg)
        return b
    }()

    private let closeButton: UIBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .close, target: nil, action: nil)
    }()

    private let spinner = UIActivityIndicatorView(style: .medium)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Pro"

        closeButton.target = self
        closeButton.action = #selector(closeTapped)
        navigationItem.leftBarButtonItem = closeButton

        layout()
        wireActions()

        // ✅ Start StoreKit listener + load product + refresh entitlement
        Task { @MainActor in
            ProStore.shared.start()
            await ProStore.shared.refreshEntitlement()
            await loadPrice()
            updateForEntitlement()
        }
    }

    // MARK: - Layout

    private func layout() {
        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            subtitleLabel,
            featuresLabel,
            priceLabel,
            unlockButton,
            restoreButton
        ])
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 18)
        ])
    }

    private func wireActions() {
        unlockButton.addTarget(self, action: #selector(unlockTapped), for: .touchUpInside)
        restoreButton.addTarget(self, action: #selector(restoreTapped), for: .touchUpInside)
    }

    // MARK: - StoreKit

    private func loadPrice() async {
        await ProStore.shared.loadProducts()

        if let p = ProStore.shared.yearlyProduct {
            // StoreKit provides localized price formatting
            priceLabel.text = "\(p.displayName) — \(p.displayPrice)"
        } else {
            priceLabel.text = "Price unavailable (try again)."
        }
    }

    private func updateForEntitlement() {
        if ProStore.shared.isPro {
            priceLabel.text = "✅ Pro Active"
            unlockButton.configuration?.title = "Pro Active"
            unlockButton.isEnabled = false
        } else {
            unlockButton.configuration?.title = "Unlock Pro"
            unlockButton.isEnabled = true
        }
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func unlockTapped() {
        Task { @MainActor in
            setLoading(true)
            defer { setLoading(false) }

            do {
                // ✅ Ensure products are loaded
                await ProStore.shared.loadProducts()

                // ✅ Purchase (no try!, catch errors)
                try await ProStore.shared.purchaseYearly()

                // ✅ Refresh + update UI
                await ProStore.shared.refreshEntitlement()
                updateForEntitlement()

                if ProStore.shared.isPro {
                    dismiss(animated: true)
                }

            } catch is CancellationError {
                // user cancelled; no alert needed
            } catch {
                showAlert("Purchase Failed", error.localizedDescription)
            }
        }
    }

    @objc private func restoreTapped() {
        Task { @MainActor in
            setLoading(true)
            defer { setLoading(false) }

            do {
                try await ProStore.shared.restore()
                updateForEntitlement()

                if ProStore.shared.isPro {
                    dismiss(animated: true)
                } else {
                    showAlert("Nothing to Restore", "No active Pro subscription was found for this Apple ID.")
                }
            } catch {
                showAlert("Restore Failed", error.localizedDescription)
            }
        }
    }

    // MARK: - Helpers

    private func setLoading(_ loading: Bool) {
        if loading {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
        unlockButton.isEnabled = !loading && !ProStore.shared.isPro
        restoreButton.isEnabled = !loading
    }

    private func showAlert(_ title: String, _ message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}
