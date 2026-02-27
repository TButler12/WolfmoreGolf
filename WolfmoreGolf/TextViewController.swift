
//
//  TextViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 2/5/26.
//
import UIKit
import MessageUI

final class TextViewController: UIViewController, MFMessageComposeViewControllerDelegate {

    // MARK: - Types

    // ✅ Prefer moving this to its own file RecipientPreview.swift (shared by WMComposeVC + TextVC),
    // but keeping it here is fine as long as WMComposeViewController DOES NOT reference it.
    

    // MARK: - Outlets

    @IBOutlet private weak var proShopButton: UIButton!
    @IBOutlet private weak var drinkCartButton: UIButton!
    @IBOutlet private weak var coordinatorButton: UIButton!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(proShopButton != nil, "❌ proShopButton outlet not connected")
        assert(drinkCartButton != nil, "❌ drinkCartButton outlet not connected")
        assert(coordinatorButton != nil, "❌ coordinatorButton outlet not connected")

        title = "Text Hub"
        view.backgroundColor = .systemBackground

        applyServiceButtonStyle()
        refreshServiceButtonTitles()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshServiceButtonTitles()
    }

    // MARK: - Button styling / titles

    private func applyServiceButtonStyle() {
        let buttons = [coordinatorButton, proShopButton, drinkCartButton]
        let font = proShopButton.titleLabel?.font ?? .systemFont(ofSize: 22, weight: .semibold)

        buttons.forEach { b in
            b?.titleLabel?.font = font
            b?.titleLabel?.adjustsFontForContentSizeCategory = true
            b?.titleLabel?.minimumScaleFactor = 0.8
            b?.titleLabel?.adjustsFontSizeToFitWidth = true
        }
    }
    private func requireProForCustomGroups(_ onAllowed: () -> Void) {
        if ProStore.shared.isPro {
            onAllowed()
            return
        }

        let ac = UIAlertController(
            title: "Custom Groups are Pro",
            message: "Unlock Pro to create and use custom text groups for your regular games.",
            preferredStyle: .alert
        )

        ac.addAction(UIAlertAction(title: "Not Now", style: .cancel))

        ac.addAction(UIAlertAction(title: "Unlock Pro", style: .default) { [weak self] _ in
            self?.presentPro()
        })

        present(ac, animated: true)
    }

    private func presentPro() {
        // ✅ Option A: If you already have a ProViewController in storyboard
        let sb = UIStoryboard(name: "Main", bundle: nil)
        if let vc = sb.instantiateViewController(withIdentifier: "ProViewController") as? ProViewController {
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .pageSheet
            present(nav, animated: true)
            return
        }

        // ✅ Option B: fallback message if storyboard id isn’t set yet
        let ac = UIAlertController(title: "Pro", message: "Open your Pro screen here.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    private func refreshServiceButtonTitles() {
        let c = ServiceContactStore.shared.contacts
        coordinatorButton.setTitle(c.coordinatorName, for: .normal)
        proShopButton.setTitle(c.proShopName, for: .normal)
        drinkCartButton.setTitle(c.drinkCartName, for: .normal)
    }

    // MARK: - Groups (Custom)

    @IBAction private func customGroupsTapped(_ sender: UIButton) {
        requireProForCustomGroups { [weak self] in
            guard let self else { return }

            let vc = CustomGroupsViewController()
            vc.onPick = { [weak self] group in
                self?.sendCustomGroup(group)
            }

            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .pageSheet
            if let sheet = nav.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }
            self.present(nav, animated: true)
        }
    }
    private func requireProForCustomGroups(onAllowed: @escaping () -> Void) {
        // ✅ If Pro, proceed
        if ProStore.shared.isPro {
            onAllowed()
            return
        }

        // ✅ Not Pro: show paywall and STOP (do NOT run closure)
        presentProPaywall()
    }

    private func presentProPaywall() {
        // Prevent double-present crashes
        if presentedViewController != nil { return }

        let vc = ProGateViewController()   // <-- use the safe wrapper (or ProViewController if iOS15+ only)
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet

        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }

        present(nav, animated: true)
    }
    private func sendCustomGroup(_ group: TextGroup) {
        let phones: [String] = group.memberIDs.compactMap { id in
            FriendStore.shared.friends.first(where: { $0.id == id })?.phone
        }

        let clean = phones
            .map { normalizePhone($0) }
            .filter { !$0.isEmpty }
            .uniquePreserveOrder()

        guard !clean.isEmpty else {
            showAlert("No Numbers Found", "That group has no valid mobile numbers.")
            return
        }

        // ✅ Use templates + compose preview (names) before Apple Messages
        pickTemplateAndSend(to: clean, target: .customGroup(name: group.name))
    }

    // MARK: - Group buttons

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

    @IBAction private func trackedFriendsTapped(_ sender: UIButton) {

        let phones = FriendStore.shared.friends
            .filter { $0.isTracked }                      // ✅ use global tracked flag
            .map { normalizePhone($0.phone) }
            .filter { !$0.isEmpty }
            .uniquePreserveOrder()

        guard !phones.isEmpty else {
            showAlert("No Tracked Friends", "Track friends (and add mobile numbers) first.")
            return
        }

        pickTemplateAndSend(to: phones, target: .trackedFriendsGroup)
    }
    // MARK: - Service contacts (Pro Shop / Cart / Coordinator)

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
            textBody: "Beer cart — can we get: "
        )
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

    @IBAction private func editServiceNumbersTapped(_ sender: UIButton) {
        let current = ServiceContactStore.shared.contacts

        let ac = UIAlertController(
            title: "Course Contacts",
            message: "Set names + numbers for your service buttons.",
            preferredStyle: .alert
        )

        // 0 Pro Shop Name
        ac.addTextField {
            $0.placeholder = "Pro Shop Button Name"
            $0.text = current.proShopName
            $0.clearButtonMode = .whileEditing
            $0.autocapitalizationType = .words
        }

        // 1 Pro Shop Number
        ac.addTextField {
            $0.placeholder = "Pro Shop Number"
            $0.keyboardType = .phonePad
            $0.text = current.proShop
            $0.clearButtonMode = .whileEditing
        }

        // 2 Drink Cart Name
        ac.addTextField {
            $0.placeholder = "Drink Cart Button Name"
            $0.text = current.drinkCartName
            $0.clearButtonMode = .whileEditing
            $0.autocapitalizationType = .words
        }

        // 3 Drink Cart Number
        ac.addTextField {
            $0.placeholder = "Drink Cart Number"
            $0.keyboardType = .phonePad
            $0.text = current.drinkCart
            $0.clearButtonMode = .whileEditing
        }

        // 4 Coordinator Name
        ac.addTextField {
            $0.placeholder = "Coordinator Button Name"
            $0.text = current.coordinatorName
            $0.clearButtonMode = .whileEditing
            $0.autocapitalizationType = .words
        }

        // 5 Coordinator Number
        ac.addTextField {
            $0.placeholder = "Coordinator Number"
            $0.keyboardType = .phonePad
            $0.text = current.coordinator
            $0.clearButtonMode = .whileEditing
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        ac.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self else { return }

            let namePro   = (ac.textFields?[0].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let rawPro    = (ac.textFields?[1].text ?? "")
            let nameCart  = (ac.textFields?[2].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let rawCart   = (ac.textFields?[3].text ?? "")
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

    // MARK: - Course ID used for tracking

    private func trackingCourseID() -> String {
        let stored = ProfileStore.homeCourseID.trimmingCharacters(in: .whitespacesAndNewlines)
        if !stored.isEmpty { return stored }

        if let c = CourseLibrary.shared.wolfMore() {
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
        case customGroup(name: String)

        var title: String {
            switch self {
            case .manual:                 return "Manual Number"
            case .todaysGroup:            return "Today’s Group"
            case .favorites:              return "Favorites"
            case .allFriends:             return "All Friends"
            case .trackedFriendsGroup:    return "Tracked Friends"
            case .proShop:                return "Pro Shop"
            case .drinkCart:              return "Drink Cart"
            case .customGroup(let name):  return name
            }
        }
    }

    private enum MessageTemplate: CaseIterable, Equatable {
        case eta
        case onTee
        case beerOrder
        case rulesQuestion
        case custom

        static func templates(for target: TextTarget) -> [MessageTemplate] {
            switch target {
            case .manual, .todaysGroup, .favorites, .trackedFriendsGroup, .customGroup:
                return [.eta, .onTee, .custom]
            case .allFriends:
                return [.eta, .custom]
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
            case .rulesQuestion: return "Quick Question"
            case .custom:        return "Custom…"
            }
        }

        func defaultBody(for target: TextTarget) -> String {
            switch (target, self) {
            case (.todaysGroup, .eta), (.manual, .eta), (.favorites, .eta), (.trackedFriendsGroup, .eta), (.customGroup, .eta):
                return "WolfMore: pulling in now ⛳️"
            case (.todaysGroup, .onTee), (.manual, .onTee), (.favorites, .onTee), (.trackedFriendsGroup, .onTee), (.customGroup, .onTee):
                return "WolfMore: on the tee in 10."
            case (.allFriends, .eta):
                return "WolfMore: anyone getting out today?"
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

    // MARK: - Template Picker

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
                let body = (template == .custom) ? "" : template.defaultBody(for: target)
                self.presentComposeSheet(to: clean, defaultBody: body, title: target.title)
            })
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY - 40, width: 1, height: 1)
        }

        present(ac, animated: true)
    }

    // MARK: - Compose preview (names) -> Apple Messages

    private func resolveRecipientPreviews(from phones: [String]) -> [RecipientPreview] {
        let clean = phones
            .map { normalizePhone($0) }
            .filter { !$0.isEmpty }
            .uniquePreserveOrder()

        let friends = FriendStore.shared.friends

        return clean.map { p in
            let match = friends.first { normalizePhone($0.phone) == p }
            return RecipientPreview(name: match?.name ?? "Unknown", phone: p)
        }
    }

    private func presentComposeSheet(to recipients: [String], defaultBody: String, title: String) {
        let previews = resolveRecipientPreviews(from: recipients)
        guard !previews.isEmpty else {
            showAlert("No Numbers", "No phone numbers found for this group.")
            return
        }

        // ✅ IMPORTANT: use WMComposeViewController’s init(titleText:recipients:initialText:)
        let vc = WMComposeViewController(titleText: title, recipients: previews, initialText: defaultBody)
        vc.onSend = { [weak self] text in
            self?.presentComposer(to: previews.map { $0.phone }, body: text)
        }

        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet

        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }

        present(nav, animated: true)
    }

    // MARK: - Apple composer

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
