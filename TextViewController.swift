
//
//  TextViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 2/5/26.
//
import UIKit
import MessageUI

final class TextViewController: UIViewController, MFMessageComposeViewControllerDelegate {

    // Optional: manual test number
    var phone: String?

    // MARK: - Outlets

    @IBOutlet private weak var numberField: UITextField!
    @IBOutlet private weak var messageView: UITextView!

    @IBOutlet private weak var proShopButton: UIButton!
    @IBOutlet private weak var drinkCartButton: UIButton!
    @IBOutlet private weak var coordinatorButton: UIButton!
    @IBOutlet private weak var todaysGroupButton: UIButton!
    @IBOutlet private weak var favoritesButton: UIButton!
    @IBOutlet private weak var customGroupsButton: UIButton!
    @IBOutlet private weak var allFriendsButton: UIButton?
    @IBOutlet private weak var editServiceNumbersButton: UIButton!
    @IBOutlet private weak var groupsSectionLabel: UILabel?
    @IBOutlet private weak var servicesSectionLabel: UILabel?
    @IBOutlet private weak var trackedFriendsButton: UIButton!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(closeTapped)
        )
        refreshServiceButtonTitles()
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshServiceButtonTitles()
    }

    private func refreshServiceButtonTitles() {
        let c = ServiceContactStore.shared.contacts
        proShopButton.setTitle(c.proShopName, for: .normal)
        drinkCartButton.setTitle(c.drinkCartName, for: .normal)
        coordinatorButton.setTitle(c.coordinatorName, for: .normal)
    }

    // MARK: - Actions

    @IBAction private func sendTapped(_ sender: UIButton) {
        let p = normalizePhone(numberField.text ?? "")
        guard !p.isEmpty else {
            showAlert("Missing Number", "Enter a phone number first.")
            return
        }
        pickQuickTextAndSend(to: [p], target: .manual)
    }

    @IBAction private func favoritesTapped(_ sender: UIButton) {
        let phones = FriendStore.shared.friends
            .filter { $0.isFavorite }
            .map { normalizePhone($0.phone) }
            .filter { !$0.isEmpty }

        guard !phones.isEmpty else {
            showAlert("No Favorites", "Star a few contacts (and add mobile numbers) in Contacts.")
            return
        }

        pickQuickTextAndSend(to: phones, target: .favorites)
    }


    @IBAction private func todaysGroupTapped(_ sender: UIButton) {
        let phones = FriendStore.shared.friends
            .filter { $0.preselectForRound }
            .map { normalizePhone($0.phone) }
            .filter { !$0.isEmpty }

        guard !phones.isEmpty else {
            showAlert("No Numbers Found", "Activate players (Today’s Group) and add mobile numbers.")
            return
        }

        pickQuickTextAndSend(to: phones, target: .todaysGroup)
    }

    @IBAction private func trackedFriendsTapped(_ sender: UIButton) {
        let courseID = ProfileStore.homeCourseID.isEmpty ? "HOME-COURSE" : ProfileStore.homeCourseID

        let phones = FriendStore.shared.friends
            .filter { FriendTrackStore.shared.isTracked($0.id, on: courseID) }
            .map { normalizePhone($0.phone) }
            .filter { !$0.isEmpty }

        guard !phones.isEmpty else {
            showAlert("No Tracked Friends", "Track players on Players & Tracking, and make sure they have mobile numbers.")
            return
        }

        pickQuickTextAndSend(to: phones, target: .trackedFriends)
    }


    @IBAction private func allFriendsTapped(_ sender: UIButton) {
        let phones = FriendStore.shared.friends
            .map { normalizePhone($0.phone) }
            .filter { !$0.isEmpty }

        guard !phones.isEmpty else {
            showAlert("No Numbers Found", "Add mobile numbers in Contacts.")
            return
        }

        pickQuickTextAndSend(to: phones, target: .allFriends)
    }


    @IBAction private func proShopTapped(_ sender: UIButton) {
        let c = ServiceContactStore.shared.contacts
        guard !c.proShop.filter(\.isNumber).isEmpty else {
            showAlert("No Pro Shop Number", "Tap “Edit Course Numbers” to add it.")
            return
        }

        presentCallOrTextSheet(
            name: c.proShopName,
            rawNumber: c.proShop,
            textBody: "Quick question:"
        )
    }

    @IBAction private func drinkCartTapped(_ sender: UIButton) {
        let c = ServiceContactStore.shared.contacts
        guard !c.drinkCart.filter(\.isNumber).isEmpty else {
            showAlert("No Drink Cart Number", "Tap “Edit Course Numbers” to add it.")
            return
        }

        presentCallOrTextSheet(
            name: c.drinkCartName,
            rawNumber: c.drinkCart,
            textBody: "Drink/Food Orders — can we get: "
        )
    }

    @IBAction private func coordinatorTapped(_ sender: UIButton) {
        let c = ServiceContactStore.shared.contacts
        let digits = c.coordinator.filter(\.isNumber)

        guard !digits.isEmpty else {
            showAlert("No Coordinator", "Tap “Edit Course Numbers” to add it.")
            return
        }

        presentCallOrTextSheet(
            name: c.coordinatorName,
            rawNumber: digits,
            textBody: "WolfMore — quick question:"
        )
    }

    @IBAction private func editServiceNumbersTapped(_ sender: UIButton) {
        let current = ServiceContactStore.shared.contacts

        let ac = UIAlertController(
            title: "Course Contacts",
            message: "Set names + numbers for your service buttons.",
            preferredStyle: .alert
        )

        ac.addTextField {
            $0.placeholder = "Pro Shop Button Name"
            $0.text = current.proShopName
            $0.clearButtonMode = .whileEditing
            $0.autocapitalizationType = .words
        }

        ac.addTextField {
            $0.placeholder = "Pro Shop Number"
            $0.keyboardType = .phonePad
            $0.text = current.proShop
            $0.clearButtonMode = .whileEditing
        }

        ac.addTextField {
            $0.placeholder = "Drink Cart Button Name"
            $0.text = current.drinkCartName
            $0.clearButtonMode = .whileEditing
            $0.autocapitalizationType = .words
        }

        ac.addTextField {
            $0.placeholder = "Drink Cart Number"
            $0.keyboardType = .phonePad
            $0.text = current.drinkCart
            $0.clearButtonMode = .whileEditing
        }

        ac.addTextField {
            $0.placeholder = "Coordinator Button Name"
            $0.text = current.coordinatorName
            $0.clearButtonMode = .whileEditing
            $0.autocapitalizationType = .words
        }

        ac.addTextField {
            $0.placeholder = "Coordinator Number"
            $0.keyboardType = .phonePad
            $0.text = current.coordinator
            $0.clearButtonMode = .whileEditing
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        ac.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self else { return }

            let namePro   = (ac.textFields?[0].text ?? "").trimmed
            let rawPro    = (ac.textFields?[1].text ?? "")
            let nameCart  = (ac.textFields?[2].text ?? "").trimmed
            let rawCart   = (ac.textFields?[3].text ?? "")
            let nameCoord = (ac.textFields?[4].text ?? "").trimmed
            let rawCoord  = (ac.textFields?[5].text ?? "")

            ServiceContactStore.shared.setProShopName(namePro.isEmpty ? "Pro Shop" : namePro)
            ServiceContactStore.shared.setProShop(rawPro.digitsOnly)

            ServiceContactStore.shared.setDrinkCartName(nameCart.isEmpty ? "Drink Cart" : nameCart)
            ServiceContactStore.shared.setDrinkCart(rawCart.digitsOnly)

            ServiceContactStore.shared.setCoordinatorName(nameCoord.isEmpty ? "Coordinator" : nameCoord)
            ServiceContactStore.shared.setCoordinator(rawCoord.digitsOnly)

            self.refreshServiceButtonTitles()
        })

        present(ac, animated: true)
    }
    @IBAction private func customGroupsTapped(_ sender: UIButton) {
        let groups = TextGroupStore.shared.allSorted()
        guard !groups.isEmpty else {
            showAlert("No Custom Groups", "Create a custom group first in Contacts.")
            return
        }

        let vc = CustomGroupsViewController(style: .insetGrouped)

        vc.onPick = { [weak self] (group: TextGroup) in
            guard let self else { return }

            let members = FriendStore.shared.friends
                .filter { group.memberIDs.contains($0.id) }

            let phones = members
                .map { self.normalizePhone($0.phone) }
                .filter { !$0.isEmpty }

            guard !phones.isEmpty else {
                self.showAlert("No Numbers", "This custom group has no valid phone numbers.")
                return
            }

            let names = members
                .map { $0.name }
                .sorted()

            let message = names.isEmpty
                ? "No names found."
                : names.joined(separator: "\n")

            let ac = UIAlertController(
                title: group.name,
                message: "Texting:\n\n\(message)",
                preferredStyle: .actionSheet
            )

            ac.addAction(UIAlertAction(title: "Continue", style: .default) { _ in
                self.pickQuickTextAndSend(to: phones, target: .allFriends)
            })

            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            if let pop = ac.popoverPresentationController {
                pop.sourceView = self.view
                pop.sourceRect = CGRect(x: self.view.bounds.midX,
                                        y: self.view.bounds.midY,
                                        width: 1,
                                        height: 1)
            }

            self.present(ac, animated: true)
        }

        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    // MARK: - Targets + Quick Text

    private enum TextTarget {
        case manual, todaysGroup, trackedFriends, favorites, allFriends

        var title: String {
            switch self {
            case .manual:         return "Manual Number"
            case .todaysGroup:    return "Today’s Group"
            case .trackedFriends: return "Tracked Friends"
            case .favorites:      return "Favorites"
            case .allFriends:     return "All Friends"
            }
        }
    }

    private enum QuickText: CaseIterable {
        case arrived, onTee, runningLate, custom

        var title: String {
            switch self {
            case .arrived:     return "Arrived"
            case .onTee:       return "On Tee"
            case .runningLate: return "Running Late"
            case .custom:      return "Custom…"
            }
        }

        var body: String {
            switch self {
            case .arrived:     return "WolfMore: I'm here ⛳️"
            case .onTee:       return "WolfMore: We're on the tee"
            case .runningLate: return "WolfMore: running a few minutes late."
            case .custom:      return ""
            }
        }
    }

    private func pickQuickTextAndSend(to recipients: [String], target: TextTarget) {
        let clean = recipients.map(normalizePhone).filter { !$0.isEmpty }

        guard !clean.isEmpty else {
            showAlert("No Numbers", "No phone numbers found for this selection.")
            return
        }

        guard MFMessageComposeViewController.canSendText() else {
            showAlert("Messages Unavailable", "This device can’t send text messages.")
            return
        }

        let ac = UIAlertController(title: target.title, message: "Quick Text", preferredStyle: .actionSheet)

        QuickText.allCases.forEach { item in
            ac.addAction(UIAlertAction(title: item.title, style: .default) { [weak self] _ in
                guard let self else { return }
                if item == .custom {
                    self.promptCustomMessage(to: clean)
                } else {
                    self.presentComposer(to: clean, body: item.body)
                }
            })
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY - 40, width: 1, height: 1)
        }

        present(ac, animated: true)
    }

    private func promptCustomMessage(to recipients: [String]) {
        let ac = UIAlertController(title: "Custom Message", message: nil, preferredStyle: .alert)
        ac.addTextField {
            $0.placeholder = "Type your message…"
            $0.autocapitalizationType = .sentences
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Send", style: .default) { [weak self] _ in
            guard let self else { return }
            let text = (ac.textFields?.first?.text ?? "").trimmed
            guard !text.isEmpty else { return }
            self.presentComposer(to: recipients, body: text)
        })

        present(ac, animated: true)
    }

    // MARK: - Helpers

    private func normalizePhone(_ s: String) -> String { s.digitsOnly }

    private func showAlert(_ title: String, _ msg: String) {
        let a = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    private func presentComposer(to phones: [String], body: String) {
        let clean = phones.map(normalizePhone).filter { !$0.isEmpty }

        guard !clean.isEmpty else {
            showAlert("No Numbers", "No phone numbers found for this group.")
            return
        }

        guard MFMessageComposeViewController.canSendText() else {
            showAlert("Messages Unavailable", "This device can’t send text messages.")
            return
        }

        let composer = MFMessageComposeViewController()
        composer.messageComposeDelegate = self
        composer.recipients = clean
        composer.body = body
        present(composer, animated: true)
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                     didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
    }

    // MARK: - Call / Text Sheet

    private func presentCallOrTextSheet(name: String, rawNumber: String, textBody: String? = nil) {
        let digits = rawNumber.digitsOnly
        guard !digits.isEmpty else {
            showAlert("No Number", "Add a phone number first.")
            return
        }

        let ac = UIAlertController(title: name, message: digits, preferredStyle: .actionSheet)

        if let callURL = URL(string: "tel://\(digits)"),
           UIApplication.shared.canOpenURL(callURL) {
            ac.addAction(UIAlertAction(title: "Call", style: .default) { _ in
                UIApplication.shared.open(callURL)
            })
        }

        if MFMessageComposeViewController.canSendText() {
            ac.addAction(UIAlertAction(title: "Text", style: .default) { [weak self] _ in
                self?.presentComposer(to: [digits], body: textBody ?? "")
            })
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        }

        present(ac, animated: true)
    }
    
    private func requirePro(orUpsellFrom source: UIView? = nil, _ action: () -> Void) {
        action()
    }
    private func showProUpsell(source: UIView? = nil) {}
    private func presentProPaywall() {}

}

// MARK: - Small helpers

private extension String {
    var digitsOnly: String { filter(\.isNumber) }
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
