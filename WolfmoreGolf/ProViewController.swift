//
//  ProViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 1/29/26.
//
import UIKit
import StoreKit

final class ProViewController: UITableViewController {

    private enum Section: Int, CaseIterable { case unlock, plan, restore, legal }

    private let store = ProStore.shared

    private var priceText: String = "Loading…"
    private var isBusy = false
    private var didInitialLoad = false

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "WolfMore Pro"
        tableView = UITableView(frame: .zero, style: .insetGrouped)

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )

        // Kick off load once
        Task { await initialLoadIfNeeded() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // On re-appear: refresh entitlement only (fast)
        Task {
            await store.refreshEntitlement()
            updatePrice()
            tableView.reloadData()

            #if DEBUG
            // Optional debug logging (not an alert)
            print("Pro Debug:",
                  "yearlyProduct:", store.yearlyProduct?.id ?? "nil",
                  "priceText:", priceText,
                  "isLoaded:", store.isLoaded,
                  "bundle:", Bundle.main.bundleIdentifier ?? "nil")
            #endif
        }
    }

    @objc private func closeTapped() { dismiss(animated: true) }

    // MARK: - Loading

    private func initialLoadIfNeeded() async {
        guard !didInitialLoad else { return }
        didInitialLoad = true

        isBusy = true
        tableView.reloadData()

        await store.loadProducts()
        await store.refreshEntitlement()
        updatePrice()

        isBusy = false
        tableView.reloadData()
    }

    private func updatePrice() {
        if let p = store.yearlyProduct {
            priceText = "\(p.displayPrice) / year"
        } else {
            priceText = "Unavailable"
        }
    }

    // MARK: - Table

    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .unlock:  return 3
        case .plan:    return 1
        case .restore: return 1
        case .legal:   return 1
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .unlock:  return "Unlock with Pro"
        case .plan:    return nil
        case .restore: return nil
        case .legal:   return nil
        }
    }

    override func tableView(_ tableView: UITableView,
                            titleForFooterInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .legal:
            return "Payment will be charged to your Apple ID. Subscription automatically renews unless canceled at least 24 hours before the end of the current period. Manage or cancel in Settings."
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.textLabel?.numberOfLines = 2

        switch Section(rawValue: indexPath.section)! {

        case .unlock:
            cell.selectionStyle = .none
            cell.textLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
            cell.textLabel?.text = [
                "Unlimited round history",
                "Year-long summaries",
                "Advanced player & course stats"
            ][indexPath.row]

        case .plan:
            cell.textLabel?.font = .systemFont(ofSize: 18, weight: .semibold)

            if store.isPro {
                cell.textLabel?.text = "You’re Pro ✅"
                cell.detailTextLabel?.text = ""
                cell.selectionStyle = .none
                cell.accessoryType = .none
            } else {
                // CTA-like row
                cell.textLabel?.text = "Start Pro"
                cell.detailTextLabel?.text = priceText
                cell.accessoryType = .none

                // Make it look tappable + premium
                cell.textLabel?.textColor = view.tintColor
                cell.detailTextLabel?.textColor = .secondaryLabel

                // Disable if loading or missing product
                let enabled = (!isBusy && store.yearlyProduct != nil)
                cell.selectionStyle = enabled ? .default : .none

                // Optional subtle spinner while loading
                if isBusy && store.yearlyProduct == nil {
                    let spinner = UIActivityIndicatorView(style: .medium)
                    spinner.startAnimating()
                    cell.accessoryView = spinner
                } else {
                    cell.accessoryView = nil
                }
            }

        case .restore:
            cell.textLabel?.text = "Restore Purchases"
            cell.textLabel?.font = .systemFont(ofSize: 17, weight: .regular)
            cell.textLabel?.textColor = isBusy ? .secondaryLabel : .label
            cell.selectionStyle = isBusy ? .none : .default

        case .legal:
            cell.textLabel?.text = "Terms & subscription info"
            cell.textLabel?.font = .systemFont(ofSize: 15, weight: .regular)
            cell.textLabel?.textColor = .secondaryLabel
            cell.selectionStyle = .none
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch Section(rawValue: indexPath.section)! {

        case .unlock, .legal:
            return

        case .plan:
            guard !store.isPro, !isBusy else { return }

            // If product missing, try one reload then stop
            guard store.yearlyProduct != nil else {
                isBusy = true
                tableView.reloadData()

                Task {
                    await store.loadProducts()
                    updatePrice()
                    isBusy = false
                    tableView.reloadData()

                    if store.yearlyProduct == nil {
                        showAlert(title: "Unavailable", message: "Couldn’t load the Pro plan. Please try again.")
                    }
                }
                return
            }

            isBusy = true
            tableView.reloadData()

            Task {
                do {
                    try await store.purchaseYearly()
                    await store.refreshEntitlement()
                    updatePrice()
                } catch is CancellationError {
                    // user canceled
                } catch {
                    showAlert(title: "Purchase Failed", message: "Please try again.")
                }

                isBusy = false
                tableView.reloadData()
            }

        case .restore:
            guard !isBusy else { return }

            isBusy = true
            tableView.reloadData()

            Task {
                do {
                    try await store.restore()
                    await store.refreshEntitlement()
                    updatePrice()

                    // Keep message but less “noisy”
                    if !store.isPro {
                        showAlert(title: "Not Found", message: "No active subscription found for this Apple ID.")
                    }
                } catch {
                    showAlert(title: "Restore Failed", message: "Please try again.")
                }

                isBusy = false
                tableView.reloadData()
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}

