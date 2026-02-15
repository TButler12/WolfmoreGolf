
//
//  TextViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 2/5/26.
//
import UIKit
import MessageUI

final class TextViewController: UIViewController, MFMessageComposeViewControllerDelegate {

    // MARK: - Outlets (must be connected in storyboard)

   
    @IBOutlet private weak var proShopButton: UIButton!
    @IBOutlet private weak var drinkCartButton: UIButton!
    @IBOutlet private weak var coordinatorButton: UIButton!
    

    
    

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // ✅ Helps catch storyboard wiring issues instantly
      
        assert(proShopButton != nil, "❌ proShopButton outlet not connected")
        assert(drinkCartButton != nil, "❌ drinkCartButton outlet not connected")

        title = "Text Hub"
        view.backgroundColor = .systemBackground

        applyServiceButtonStyle()

          refreshServiceButtonTitles()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshServiceButtonTitles()
    }

    // MARK: - Service button titles
    private func applyServiceButtonStyle() {
        let buttons = [coordinatorButton, proShopButton, drinkCartButton]

        // Pick ONE source of truth:
        // Option 1: use Pro Shop’s current font as the standard
        let font = proShopButton.titleLabel?.font ?? .systemFont(ofSize: 22, weight: .semibold)

        buttons.forEach { b in
            b?.titleLabel?.font = font
            b?.titleLabel?.adjustsFontForContentSizeCategory = true
            b?.titleLabel?.minimumScaleFactor = 0.8
            b?.titleLabel?.adjustsFontSizeToFitWidth = true
        }
    }
    private func refreshServiceButtonTitles() {
        let c = ServiceContactStore.shared.contacts
        coordinatorButton.setTitle(c.coordinatorName, for: .normal)
        proShopButton.setTitle(c.proShopName, for: .normal)
        drinkCartButton.setTitle(c.drinkCartName, for: .normal)
    }
    



    @IBAction private func favoritesTapped(_ sender: UIButton) {
        let phones = FriendStore.shared.friends
            .filter { $0.isFavorite }
            .map { normalizePhone($0.phone) }
            .filter { !$0.isEmpty }
            .uniquePreserveOrder()

        guard !phones.isEmpty else {
            showAlert("No Favorites", "Star a few contacts (and add mobile numbers) in Contacts.")
            return
        }

        pickTemplateAndSend(to: phones, target: .favorites)
    }

    @IBAction private func todaysGroupTapped(_ sender: UIButton) {
        let phones = FriendStore.shared.friends
            .filter { $0.preselectForRound }
            .map { normalizePhone($0.phone) }
            .filter { !$0.isEmpty }
            .uniquePreserveOrder()

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
            .uniquePreserveOrder()

        guard !phones.isEmpty else {
            showAlert("No Numbers Found", "Add mobile numbers in Manage Players.")
            return
        }

        pickTemplateAndSend(to: phones, target: .allFriends)
    }

    // ✅ Tracked Friends: EXACTLY like Favorites, but uses FriendTrackStore for current home course
    @IBAction private func trackedFriendsTapped(_ sender: UIButton) {
        let courseID = trackingCourseID()

        let phones = FriendStore.shared.friends
            .filter { FriendTrackStore.shared.isTracked(friendID: $0.id, courseID: courseID) }
            .map { normalizePhone($0.phone) }
            .filter { !$0.isEmpty }
            .uniquePreserveOrder()

        guard !phones.isEmpty else {
            showAlert("No Tracked Friends", "Track friends (and add mobile numbers) first.")
            return
        }

        pickTemplateAndSend(to: phones, target: .trackedFriendsGroup)
    }

    @IBAction private func proShopTapped(_ sender: UIButton) {
        let c = ServiceContactStore.shared.contacts
        let digits = normalizePhone(c.proShop)
        guard !digits.isEmpty else {
            showAlert("No Pro Shop Number", "Tap “Edit Course Numbers” to add it.")
            return
        }

        presentCallOrTextSheet(
            name: c.proShopName,
            rawNumber: digits,
            textBody: "Hey — quick question:"
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

        // Coordinator Name
        ac.addTextField { tf in
            tf.placeholder = "Coordinator Button Name"
            tf.text = current.coordinatorName
            tf.clearButtonMode = .whileEditing
            tf.autocapitalizationType = .words
        }

        // Coordinator Number
        ac.addTextField { tf in
            tf.placeholder = "Coordinator Number"
            tf.keyboardType = .phonePad
            tf.text = current.coordinator
            tf.clearButtonMode = .whileEditing
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        ac.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self else { return }

            let namePro  = (ac.textFields?[0].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let rawPro   = (ac.textFields?[1].text ?? "")
            let nameCart = (ac.textFields?[2].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let rawCart  = (ac.textFields?[3].text ?? "")
            let nameCoord = (ac.textFields?[4].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let rawCoord  = (ac.textFields?[5].text ?? "")

            ServiceContactStore.shared.setProShopName(namePro.isEmpty ? "Pro Shop" : namePro)
            ServiceContactStore.shared.setProShop(self.normalizePhone(rawPro))

            ServiceContactStore.shared.setDrinkCartName(nameCart.isEmpty ? "Drink Cart" : nameCart)
            ServiceContactStore.shared.setDrinkCart(self.normalizePhone(rawCart))

            ServiceContactStore.shared.setCoordinatorName(nameCoord.isEmpty ? "Coordinator" : nameCoord)
            ServiceContactStore.shared.setCoordinator(self.normalizePhone(rawCoord))

            self.refreshServiceButtonTitles()
        })

        present(ac, animated: true)
    }

    @IBAction private func drinkCartTapped(_ sender: UIButton) {
        let c = ServiceContactStore.shared.contacts
        let digits = normalizePhone(c.drinkCart)
        guard !digits.isEmpty else {
            showAlert("No Drink Cart Number", "Tap “Edit Course Numbers” to add it.")
            return
        }
        presentCallOrTextSheet(
            name: c.drinkCartName,
            rawNumber: digits,
            textBody: "Beer cart — can we get: "        )
        
    }
    
    
    
    @IBAction private func coordinatorTapped(_ sender: UIButton) {
        let c = ServiceContactStore.shared.contacts
        let digits = normalizePhone(c.coordinator)

        guard !digits.isEmpty else {
            showAlert("No Coordinator Number", "Tap “Edit Service Numbers” to add it.")
            return
        }

        presentCallOrTextSheet(
            name: c.coordinatorName,
            rawNumber: digits,
            textBody: "Hey — quick question:"
        )
    }

    // MARK: - Course ID used for tracking

    private func trackingCourseID() -> String {
        let stored = ProfileStore.homeCourseID.trimmingCharacters(in: .whitespacesAndNewlines)
        if !stored.isEmpty { return stored }

        if let c = CourseLibrary.shared.WolfMore() {
            return c.id.uuidString
        }
        return "HOME-COURSE"
    }

    // MARK: - Targets + Templates

    private enum TextTarget {
        case manual
        case todaysGroup
        case allFriends
        case favorites
        case trackedFriendsGroup
        case proShop
        case drinkCart

        var title: String {
            switch self {
            case .manual:             return "Manual Number"
            case .todaysGroup:        return "Today’s Group"
            case .favorites:          return "Favorites"
            case .allFriends:         return "All Friends"
            case .trackedFriendsGroup:return "Tracked Friends"
            case .proShop:            return "Pro Shop"
            case .drinkCart:          return "Drink Cart"
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
            case .manual, .todaysGroup, .favorites, .trackedFriendsGroup:
                return [.eta, .onTee, .scoreUpdate, .custom]
            case .allFriends:
                return [.eta, .scoreUpdate, .custom]
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

            case (.todaysGroup, .eta), (.manual, .eta), (.favorites, .eta), (.trackedFriendsGroup, .eta):
                return "WolfMore: pulling in now ⛳️"

            case (.todaysGroup, .onTee), (.manual, .onTee), (.favorites, .onTee), (.trackedFriendsGroup, .onTee):
                return "WolfMore: on the tee in 10."

            case (.todaysGroup, .scoreUpdate), (.manual, .scoreUpdate),
                 (.favorites, .scoreUpdate), (.trackedFriendsGroup, .scoreUpdate):
                return "WolfMore update: "

            case (.allFriends, .eta):
                return "WolfMore: anyone getting out today?"
            case (.allFriends, .scoreUpdate):
                return "WolfMore: tee time / group update — "

            case (.proShop, .rulesQuestion):
                return "Hey — quick question:"

            case (.drinkCart, .beerOrder):
                return "Beer cart — can we get: "
            case (.drinkCart, .eta):
                return "Beer cart — where are you at right now?"

            default:
                return ""
            }
        }
    }

    // MARK: - Template Picker + Composer

    private func pickTemplateAndSend(to recipients: [String], target: TextTarget) {
        let clean = recipients
            .map { normalizePhone($0) }
            .filter { !$0.isEmpty }
            .uniquePreserveOrder()

        guard !clean.isEmpty else {
            showAlert("No Numbers", "No phone numbers found for this selection.")
            return
        }

        guard MFMessageComposeViewController.canSendText() else {
            showAlert("Messages Unavailable", "This device can’t send text messages.")
            return
        }

        let templates = MessageTemplate.templates(for: target)

        let ac = UIAlertController(title: target.title, message: "Choose a message", preferredStyle: .actionSheet)

        templates.forEach { template in
            ac.addAction(UIAlertAction(title: template.title(for: target), style: .default) { [weak self] _ in
                guard let self else { return }

                if template == .custom {
                    self.promptCustomMessage(to: clean)
                } else {
                    self.presentComposer(to: clean, body: template.defaultBody(for: target))
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

    private func presentComposer(to phones: [String], body: String) {
        let clean = phones
            .map { normalizePhone($0) }
            .filter { !$0.isEmpty }
            .uniquePreserveOrder()

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

    // MARK: - Call/Text chooser (service contacts)

    private func presentCallOrTextSheet(name: String, rawNumber: String, textBody: String? = nil) {
        let digits = normalizePhone(rawNumber)
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

    // MARK: - Helpers

    private func normalizePhone(_ s: String) -> String {
        s.filter(\.isNumber)
    }

    private func showAlert(_ title: String, _ msg: String) {
        let a = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    // MARK: - MFMessageComposeViewControllerDelegate

    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                     didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
    }
}

// MARK: - Small helper

private extension Array where Element == String {
    func uniquePreserveOrder() -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for s in self where !seen.contains(s) {
            seen.insert(s)
            out.append(s)
        }
        return out
    }
}
