import UIKit
import StoreKit
import SafariServices

final class PaywallViewController: UIViewController {

    private let feature: PremiumManager.Feature

    init(feature: PremiumManager.Feature) {
        self.feature = feature
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    private let scrollView        = UIScrollView()
    private let stack             = UIStackView()
    private var monthlyBtn        = UIButton(type: .system)
    private var yearlyBtn         = UIButton(type: .system)
    private let spinner           = UIActivityIndicatorView(style: .medium)

    // Disclosure labels — updated by refreshProductTitles()
    private let monthlyInfoLabel  = makeDisclosureLabel()
    private let yearlyInfoLabel   = makeDisclosureLabel()
    private let autoRenewsLabel   = makeDisclosureLabel()

    private let green = UIColor(red: 0.106, green: 0.227, blue: 0.165, alpha: 1)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        buildLayout()
        refreshProductTitles()
    }

    // MARK: - Layout

    private func buildLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        stack.axis      = .vertical
        stack.alignment = .center
        stack.spacing   = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 36),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -36),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48),
        ])

        // Crown
        let crownLabel = UILabel()
        crownLabel.text          = "👑"
        crownLabel.font          = .systemFont(ofSize: 60)
        crownLabel.textAlignment = .center

        // Title
        let titleLabel = UILabel()
        titleLabel.text          = "WolfMore Premium"
        titleLabel.font          = .systemFont(ofSize: 26, weight: .bold)
        titleLabel.textAlignment = .center

        // Limit message
        let limitLabel = UILabel()
        limitLabel.text          = feature.limitMessage
        limitLabel.font          = .systemFont(ofSize: 16, weight: .medium)
        limitLabel.textColor     = .secondaryLabel
        limitLabel.textAlignment = .center
        limitLabel.numberOfLines = 0

        // Description
        let descLabel = UILabel()
        descLabel.text          = "Upgrade to WolfMore Premium for unlimited access to AI Summary, Remote Nassau, and Live Wolf."
        descLabel.font          = .systemFont(ofSize: 15)
        descLabel.textColor     = .secondaryLabel
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0

        // Divider
        let divider = UIView()
        divider.backgroundColor = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false

        // Features
        let featuresLabel = UILabel()
        featuresLabel.text          = "✓  Unlimited AI Summaries\n✓  Unlimited Remote Nassau\n✓  Unlimited Live Wolf\n✓  All future premium features"
        featuresLabel.font          = .systemFont(ofSize: 15)
        featuresLabel.textAlignment = .center
        featuresLabel.numberOfLines = 0

        let spacer = UIView()

        // Subscribe buttons
        monthlyBtn = makeButton(title: "Upgrade — $4.99/month", primary: true)
        monthlyBtn.addTarget(self, action: #selector(monthlyTapped), for: .touchUpInside)

        yearlyBtn = makeButton(title: "Upgrade Yearly", primary: false)
        yearlyBtn.addTarget(self, action: #selector(yearlyTapped), for: .touchUpInside)
        yearlyBtn.isHidden = true   // shown only when product loads

        // ── Disclosure section ─────────────────────────────────────────────

        // Per-product info labels
        monthlyInfoLabel.text    = ""
        yearlyInfoLabel.text     = ""
        yearlyInfoLabel.isHidden = true

        // Auto-renews notice (always visible)
        autoRenewsLabel.text = "Auto-renews until canceled. Cancel anytime in\nSettings → Apple ID → Subscriptions."

        // Terms / Privacy links
        let termsBtn = makeLinkButton(title: "Terms of Use")
        termsBtn.addTarget(self, action: #selector(termsTapped), for: .touchUpInside)

        let privacyBtn = makeLinkButton(title: "Privacy Policy")
        privacyBtn.addTarget(self, action: #selector(privacyTapped), for: .touchUpInside)

        let pipe = UILabel()
        pipe.text      = "|"
        pipe.font      = .systemFont(ofSize: 13)
        pipe.textColor = .separator

        let linksRow = UIStackView(arrangedSubviews: [termsBtn, pipe, privacyBtn])
        linksRow.axis      = .horizontal
        linksRow.spacing   = 4
        linksRow.alignment = .center

        // ── Restore / dismiss ──────────────────────────────────────────────

        let restoreBtn = UIButton(type: .system)
        restoreBtn.setTitle("Restore Purchases", for: .normal)
        restoreBtn.titleLabel?.font = .systemFont(ofSize: 14)
        restoreBtn.setTitleColor(.secondaryLabel, for: .normal)
        restoreBtn.addTarget(self, action: #selector(restoreTapped), for: .touchUpInside)

        spinner.hidesWhenStopped = true

        let laterBtn = UIButton(type: .system)
        laterBtn.setTitle("Maybe Later", for: .normal)
        laterBtn.titleLabel?.font = .systemFont(ofSize: 16)
        laterBtn.setTitleColor(green, for: .normal)
        laterBtn.addTarget(self, action: #selector(laterTapped), for: .touchUpInside)

        // ── Assemble stack ─────────────────────────────────────────────────

        [crownLabel, titleLabel, limitLabel, descLabel, divider, featuresLabel,
         spacer,
         monthlyBtn, yearlyBtn,
         monthlyInfoLabel, yearlyInfoLabel,
         autoRenewsLabel, linksRow,
         restoreBtn, spinner, laterBtn]
            .forEach { stack.addArrangedSubview($0) }

        NSLayoutConstraint.activate([
            divider.heightAnchor.constraint(equalToConstant: 1),
            divider.widthAnchor.constraint(equalTo: stack.widthAnchor),
            spacer.heightAnchor.constraint(equalToConstant: 4),
            monthlyBtn.widthAnchor.constraint(equalTo: stack.widthAnchor),
            yearlyBtn.widthAnchor.constraint(equalTo: stack.widthAnchor),
            monthlyInfoLabel.widthAnchor.constraint(equalTo: stack.widthAnchor),
            yearlyInfoLabel.widthAnchor.constraint(equalTo: stack.widthAnchor),
            autoRenewsLabel.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])
    }

    private func makeButton(title: String, primary: Bool) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font          = .systemFont(ofSize: 16, weight: .semibold)
        btn.titleLabel?.numberOfLines = 0
        btn.titleLabel?.textAlignment = .center
        btn.layer.cornerRadius        = 12
        btn.heightAnchor.constraint(equalToConstant: 54).isActive = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        if primary {
            btn.backgroundColor = green
            btn.setTitleColor(.white, for: .normal)
        } else {
            btn.backgroundColor  = .secondarySystemBackground
            btn.setTitleColor(green, for: .normal)
            btn.layer.borderWidth = 1.5
            btn.layer.borderColor = green.cgColor
        }
        return btn
    }

    private func makeLinkButton(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 13)
        btn.setTitleColor(.link, for: .normal)
        return btn
    }

    private static func makeDisclosureLabel() -> UILabel {
        let l = UILabel()
        l.font          = .systemFont(ofSize: 12)
        l.textColor     = .secondaryLabel
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }

    // MARK: - Product refresh

    private func refreshProductTitles() {
        let products = PremiumManager.shared.products
        let monthly  = products.first(where: { $0.id == PremiumManager.monthlyProductID })
        let yearly   = products.first(where: { $0.id == PremiumManager.yearlyProductID  })

        // Monthly button + info
        if let m = monthly {
            monthlyBtn.setTitle("Upgrade Monthly — \(m.displayPrice)/month", for: .normal)
            monthlyInfoLabel.text = "\(m.displayName) · Monthly · \(m.displayPrice)/month"
            print("[Paywall] monthly loaded — \(m.id) \(m.displayPrice)")
        } else {
            print("[Paywall] monthly NOT loaded — products: \(products.map(\.id))")
        }

        // Yearly button + info (shown only when product available)
        if let y = yearly {
            let perMonth  = y.price / 12
            let perMonthF = perMonth.formatted(y.priceFormatStyle)
            yearlyBtn.setTitle("Upgrade Yearly — \(y.displayPrice)/year", for: .normal)
            yearlyInfoLabel.text = "\(y.displayName) · Yearly · \(y.displayPrice)/year (\(perMonthF)/month)"
            yearlyBtn.isHidden        = false
            yearlyInfoLabel.isHidden  = false
            print("[Paywall] yearly loaded — \(y.id) \(y.displayPrice)")
        } else {
            yearlyBtn.isHidden       = true
            yearlyInfoLabel.isHidden = true
            print("[Paywall] yearly not available")
        }
    }

    // MARK: - Actions

    @objc private func monthlyTapped() { purchase(id: PremiumManager.monthlyProductID) }
    @objc private func yearlyTapped()  { purchase(id: PremiumManager.yearlyProductID)  }

    private func purchase(id: String) {
        guard let product = PremiumManager.shared.products.first(where: { $0.id == id }) else {
            alert("Unavailable", "Product could not be loaded. Please try again.")
            return
        }
        setLoading(true)
        Task {
            do {
                let success = try await PremiumManager.shared.purchase(product)
                await MainActor.run {
                    self.setLoading(false)
                    if success { self.dismiss(animated: true) }
                }
            } catch {
                await MainActor.run {
                    self.setLoading(false)
                    self.alert("Purchase Failed", error.localizedDescription)
                }
            }
        }
    }

    @objc private func restoreTapped() {
        setLoading(true)
        Task {
            do {
                try await PremiumManager.shared.restorePurchases()
                await MainActor.run {
                    self.setLoading(false)
                    let pm = PremiumManager.shared
                    if pm.isPremium {
                        self.dismiss(animated: true)
                    } else {
                        let entitlementIDs = pm.lastSeenEntitlementIDs
                        let detail: String
                        if let diagnostic = pm.lastRestoreDiagnostic {
                            detail = diagnostic
                        } else if entitlementIDs.isEmpty {
                            detail = "No entitlements were returned by the App Store for this Apple ID."
                        } else {
                            detail = "Entitlements found but none matched a known product ID:\n\(entitlementIDs.joined(separator: "\n"))"
                        }
                        self.alert("No Active Subscription Found", detail)
                    }
                }
            } catch {
                await MainActor.run {
                    self.setLoading(false)
                    self.alert("Couldn't Connect to App Store",
                               "A network error prevented us from verifying your purchases. Please check your connection and try again.")
                }
            }
        }
    }

    @objc private func laterTapped() { dismiss(animated: true) }

    @objc private func termsTapped() {
        openURL("https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")
    }

    @objc private func privacyTapped() {
        openURL("https://www.wolfmore.com/privacy-policy")
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        let vc = SFSafariViewController(url: url)
        present(vc, animated: true)
    }

    private func setLoading(_ on: Bool) {
        on ? spinner.startAnimating() : spinner.stopAnimating()
        monthlyBtn.isEnabled = !on
        yearlyBtn.isEnabled  = !on
    }

    private func alert(_ title: String, _ message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}
