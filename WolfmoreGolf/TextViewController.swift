
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

    // ✅ Computed (avoids “self not available” initializer issues)
    private var proShopPhone: String { ServiceContactStore.shared.contacts.proShop }
    private var drinkCartPhone: String { ServiceContactStore.shared.contacts.drinkCart }

    @IBOutlet private weak var numberField: UITextField!
    @IBOutlet private weak var messageView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

       
       
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshServiceButtonTitles()
    }

    private func refreshServiceButtonTitles() {
        let c = ServiceContactStore.shared.contacts
        proShopButton.setTitle(c.proShopName, for: .normal)
        drinkCartButton.setTitle(c.drinkCartName, for: .normal)
    }

    // MARK: - Actions

    @IBAction private func sendTapped(_ sender: UIButton) {
        let raw = numberField.text ?? ""
        let p = normalizePhone(raw)

        guard !p.isEmpty else {
            showAlert("Missing Number", "Enter a phone number first.")
            return
        }

        pickTemplateAndSend(to: [p], target: .manual)
    }
    @IBOutlet private weak var proShopButton: UIButton!
    @IBOutlet private weak var drinkCartButton: UIButton!

    @IBAction private func favoritesTapped(_ sender: UIButton) {
        let phones = FriendStore.shared.friends
            .filter { $0.isFavorite }
            .map { normalizePhone($0.phone) }
            .filter { !$0.isEmpty }

        guard !phones.isEmpty else {
            showAlert("No Favorites", "Star a few contacts (and add mobile numbers) in Contacts.")
            return
        }

        pickTemplateAndSend(to: phones, target: .favorites)
    }

    @IBAction private func todaysGroupTapped(_ sender: UIButton) {
        // “Today’s Group” = Activate switches (preselectForRound)
        let phones = FriendStore.shared.friends
            .filter { $0.preselectForRound }
            .map { normalizePhone($0.phone) }
            .filter { !$0.isEmpty }

        guard !phones.isEmpty else {
            showAlert("No Numbers Found", "Activate players and add mobile numbers in Manage Players.")
            return
        }

        pickTemplateAndSend(to: phones, target: .todaysGroup)
    }

    @IBAction private func allFriendsTapped(_ sender: UIButton) {
        let phones = FriendStore.shared.friends
            .map { normalizePhone($0.phone) }
            .filter { !$0.isEmpty }

        guard !phones.isEmpty else {
            showAlert("No Numbers Found", "Add mobile numbers in Manage Players.")
            return
        }

        pickTemplateAndSend(to: phones, target: .allFriends)
    }

    @IBAction private func proShopTapped(_ sender: UIButton) {
        let c = ServiceContactStore.shared.contacts
        let number = c.proShop
        if number.filter(\.isNumber).isEmpty {
            showAlert("No Pro Shop Number", "Tap “Edit Course Numbers” to add it.")
            return
        }

        // If you still want templates, keep them for Text.
        // For Call/Text chooser:
        presentCallOrTextSheet(
            name: c.proShopName,
            rawNumber: number,
            textBody: "Hey — quick question:"
        )
    }

    @IBAction private func drinkCartTapped(_ sender: UIButton) {
        let c = ServiceContactStore.shared.contacts
        let number = c.drinkCart
        if number.filter(\.isNumber).isEmpty {
            showAlert("No Drink Cart Number", "Tap “Edit Course Numbers” to add it.")
            return
        }

        presentCallOrTextSheet(
            name: c.drinkCartName,
            rawNumber: number,
            textBody: "Beer cart — can we get: "
        )
    }


    @IBAction private func editServiceNumbersTapped(_ sender: UIButton) {
        let current = ServiceContactStore.shared.contacts

        let ac = UIAlertController(
            title: "Course Contacts",
            message: "Set names + numbers for your service buttons.",
            preferredStyle: .alert
        )

        // Pro Shop Name
        ac.addTextField { tf in
            tf.placeholder = "Pro Shop Button Name"
            tf.text = current.proShopName
            tf.clearButtonMode = .whileEditing
            tf.autocapitalizationType = .words
        }

        // Pro Shop Number
        ac.addTextField { tf in
            tf.placeholder = "Pro Shop Number"
            tf.keyboardType = .phonePad
            tf.text = current.proShop
            tf.clearButtonMode = .whileEditing
        }

        // Drink Cart Name
        ac.addTextField { tf in
            tf.placeholder = "Drink Cart Button Name"
            tf.text = current.drinkCartName
            tf.clearButtonMode = .whileEditing
            tf.autocapitalizationType = .words
        }

        // Drink Cart Number
        ac.addTextField { tf in
            tf.placeholder = "Drink Cart Number"
            tf.keyboardType = .phonePad
            tf.text = current.drinkCart
            tf.clearButtonMode = .whileEditing
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        ac.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self else { return }

            let namePro  = (ac.textFields?[0].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let rawPro   = (ac.textFields?[1].text ?? "")
            let nameCart = (ac.textFields?[2].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let rawCart  = (ac.textFields?[3].text ?? "")

            let proNumber  = rawPro.filter(\.isNumber)
            let cartNumber = rawCart.filter(\.isNumber)

            ServiceContactStore.shared.setProShopName(namePro.isEmpty ? "Pro Shop" : namePro)
            ServiceContactStore.shared.setProShop(proNumber)

            ServiceContactStore.shared.setDrinkCartName(nameCart.isEmpty ? "Drink Cart" : nameCart)
            ServiceContactStore.shared.setDrinkCart(cartNumber)

            self.refreshServiceButtonTitles()
        })

        present(ac, animated: true)
    }


    // MARK: - Targets + Templates

    private enum TextTarget {
        case manual
        case todaysGroup
        case allFriends
        case favorites
        case proShop
        case drinkCart

        var title: String {
            switch self {
            case .manual:      return "Manual Number"
            case .todaysGroup: return "Today’s Group"
            case .favorites:   return "Favorites"
            case .allFriends:  return "All Friends"
            case .proShop:     return "Pro Shop"
            case .drinkCart:   return "Drink Cart"
            }
        }
    }

    private enum MessageTemplate: CaseIterable, Equatable {
        case eta
        case onTee
        case beerOrder
        case scoreUpdate
        case rulesQuestion
        case custom

        static func templates(for target: TextTarget) -> [MessageTemplate] {
            switch target {
            case .manual:
                return [.eta, .onTee, .scoreUpdate, .custom]
            case .todaysGroup:
                return [.eta, .onTee, .scoreUpdate, .custom]
            case .allFriends:
                return [.eta, .scoreUpdate, .custom]
            case .favorites:
                return [.eta, .onTee, .scoreUpdate, .custom]

            case .proShop:
                return [.rulesQuestion, .custom]
            case .drinkCart:
                return [.beerOrder, .eta, .custom]
            }
        }

        func title(for target: TextTarget) -> String {
            switch self {
            case .eta:           return "Arrival / ETA"
            case .onTee:         return "On Tee"
            case .beerOrder:     return "Beer Order 🍺"
            case .scoreUpdate:   return "Score Update"
            case .rulesQuestion: return "Quick Question"
            case .custom:        return "Custom…"
            }
        }

        func defaultBody(for target: TextTarget) -> String {
            switch (target, self) {

            // TODAY / MANUAL
            case (.todaysGroup, .eta), (.manual, .eta):
                return "WolfMore: pulling in now ⛳️"
            case (.todaysGroup, .onTee), (.manual, .onTee):
                return "WolfMore: on the tee in 10."
            case (.todaysGroup, .scoreUpdate), (.manual, .scoreUpdate):
                return "WolfMore update: "

            // ALL FRIENDS
            case (.allFriends, .eta):
                return "WolfMore: anyone getting out today?"
            case (.allFriends, .scoreUpdate):
                return "WolfMore: tee time / group update — "

            // PRO SHOP
            case (.proShop, .rulesQuestion):
                return "Hey — quick question:"

            // DRINK CART
            case (.drinkCart, .beerOrder):
                return "Beer cart — can we get: "
            case (.drinkCart, .eta):
                return "Beer cart — where are you at right now?"

            default:
                return ""
            }
        }
    }

    private func pickTemplateAndSend(to recipients: [String], target: TextTarget) {
        let clean = recipients
            .map { normalizePhone($0) }
            .filter { !$0.isEmpty }

        guard !clean.isEmpty else {
            showAlert("No Numbers", "No phone numbers found for this selection.")
            return
        }

        guard MFMessageComposeViewController.canSendText() else {
            showAlert("Messages Unavailable", "This device can’t send text messages.")
            return
        }

        let templates = MessageTemplate.templates(for: target)

        let ac = UIAlertController(
            title: target.title,
            message: "Choose a message",
            preferredStyle: .actionSheet
        )

        templates.forEach { template in
            ac.addAction(UIAlertAction(title: template.title(for: target), style: .default) { [weak self] _ in
                guard let self else { return }

                if template == .custom {
                    self.promptCustomMessage(to: clean)
                } else {
                    let body = template.defaultBody(for: target)
                    self.presentComposer(to: clean, body: body)
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

        ac.addTextField { tf in
            tf.placeholder = "Type your message…"
            tf.autocapitalizationType = .sentences
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        ac.addAction(UIAlertAction(title: "Send", style: .default) { [weak self] _ in
            guard let self else { return }
            let text = (ac.textFields?.first?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return }
            self.presentComposer(to: recipients, body: text)
        })

        present(ac, animated: true)
    }

    // MARK: - Helpers

    private func normalizePhone(_ s: String) -> String {
        s.filter(\.isNumber)
    }

    private func showAlert(_ title: String, _ msg: String) {
        let a = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    private func presentComposer(to phones: [String], body: String) {
        let clean = phones
            .map { normalizePhone($0) }
            .filter { !$0.isEmpty }

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

    // MARK: - MFMessageComposeViewControllerDelegate

    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                     didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
    }
    private func presentCallOrTextSheet(name: String, rawNumber: String, textBody: String? = nil) {
        let digits = rawNumber.filter(\.isNumber)
        guard !digits.isEmpty else {
            showAlert("No Number", "Add a phone number first.")
            return
        }

        let ac = UIAlertController(title: name, message: digits, preferredStyle: .actionSheet)

        // CALL
        if let callURL = URL(string: "tel://\(digits)"),
           UIApplication.shared.canOpenURL(callURL) {
            ac.addAction(UIAlertAction(title: "Call", style: .default) { _ in
                UIApplication.shared.open(callURL)
            })
        }

        // TEXT
        if MFMessageComposeViewController.canSendText() {
            ac.addAction(UIAlertAction(title: "Text", style: .default) { [weak self] _ in
                guard let self else { return }
                self.presentComposer(to: [digits], body: textBody ?? "")
            })
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // iPad safety
        if let pop = ac.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        }

        present(ac, animated: true)
    }

}
