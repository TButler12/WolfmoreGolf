import UIKit
import StoreKit

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

    private let scrollView  = UIScrollView()
    private let stack       = UIStackView()
    private var monthlyBtn  = UIButton(type: .system)
    private var yearlyBtn   = UIButton(type: .system)
    private let spinner     = UIActivityIndicatorView(style: .medium)

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

        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 14
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
        crownLabel.text = "👑"
        crownLabel.font = .systemFont(ofSize: 60)
        crownLabel.textAlignment = .center

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "WolfMore Premium"
        titleLabel.font = .systemFont(ofSize: 26, weight: .bold)
        titleLabel.textAlignment = .center

        // Limit message
        let limitLabel = UILabel()
        limitLabel.text = "You've used your \(feature.freeLimit) free \(feature.displayName) sessions."
        limitLabel.font = .systemFont(ofSize: 16, weight: .medium)
        limitLabel.textColor = .secondaryLabel
        limitLabel.textAlignment = .center
        limitLabel.numberOfLines = 0

        // Description
        let descLabel = UILabel()
        descLabel.text = "Upgrade to WolfMore Premium for unlimited access to AI Summary, Remote Nassau, and Live Wolf."
        descLabel.font = .systemFont(ofSize: 15)
        descLabel.textColor = .secondaryLabel
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0

        // Divider
        let divider = UIView()
        divider.backgroundColor = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false

        // Features
        let featuresLabel = UILabel()
        featuresLabel.text = "✓  Unlimited AI Summaries\n✓  Unlimited Remote Nassau\n✓  Unlimited Live Wolf\n✓  All future premium features"
        featuresLabel.font = .systemFont(ofSize: 15)
        featuresLabel.textAlignment = .center
        featuresLabel.numberOfLines = 0

        let spacer = UIView()

        // Yearly button (primary)
        yearlyBtn = makeButton(title: "Upgrade — $41.99/year · Save 30%", primary: true)
        yearlyBtn.addTarget(self, action: #selector(yearlyTapped), for: .touchUpInside)

        // Monthly button
        monthlyBtn = makeButton(title: "Upgrade — $4.99/month", primary: false)
        monthlyBtn.addTarget(self, action: #selector(monthlyTapped), for: .touchUpInside)

        // Restore
        let restoreBtn = UIButton(type: .system)
        restoreBtn.setTitle("Restore Purchases", for: .normal)
        restoreBtn.titleLabel?.font = .systemFont(ofSize: 14)
        restoreBtn.setTitleColor(.secondaryLabel, for: .normal)
        restoreBtn.addTarget(self, action: #selector(restoreTapped), for: .touchUpInside)

        // Spinner
        spinner.hidesWhenStopped = true

        // Maybe Later
        let laterBtn = UIButton(type: .system)
        laterBtn.setTitle("Maybe Later", for: .normal)
        laterBtn.titleLabel?.font = .systemFont(ofSize: 16)
        laterBtn.setTitleColor(green, for: .normal)
        laterBtn.addTarget(self, action: #selector(laterTapped), for: .touchUpInside)

        // Add all views to the stack FIRST, then activate cross-view constraints
        [crownLabel, titleLabel, limitLabel, descLabel, divider, featuresLabel,
         spacer, yearlyBtn, monthlyBtn, restoreBtn, spinner, laterBtn]
            .forEach { stack.addArrangedSubview($0) }

        NSLayoutConstraint.activate([
            divider.heightAnchor.constraint(equalToConstant: 1),
            divider.widthAnchor.constraint(equalTo: stack.widthAnchor),
            spacer.heightAnchor.constraint(equalToConstant: 4),
            yearlyBtn.widthAnchor.constraint(equalTo: stack.widthAnchor),
            monthlyBtn.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])
    }

    private func makeButton(title: String, primary: Bool) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        btn.titleLabel?.numberOfLines = 0
        btn.titleLabel?.textAlignment = .center
        btn.layer.cornerRadius = 12
        btn.heightAnchor.constraint(equalToConstant: 54).isActive = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        if primary {
            btn.backgroundColor = green
            btn.setTitleColor(.white, for: .normal)
        } else {
            btn.backgroundColor = .secondarySystemBackground
            btn.setTitleColor(green, for: .normal)
            btn.layer.borderWidth = 1.5
            btn.layer.borderColor = green.cgColor
        }
        return btn
    }

    private func refreshProductTitles() {
        for product in PremiumManager.shared.products {
            if product.id == PremiumManager.monthlyProductID {
                monthlyBtn.setTitle("Upgrade — \(product.displayPrice)/month", for: .normal)
            } else if product.id == PremiumManager.yearlyProductID {
                yearlyBtn.setTitle("Upgrade — \(product.displayPrice)/year · Save 30%", for: .normal)
            }
        }
    }

    // MARK: - Actions

    @objc private func yearlyTapped()  { purchase(id: PremiumManager.yearlyProductID) }
    @objc private func monthlyTapped() { purchase(id: PremiumManager.monthlyProductID) }

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
            await PremiumManager.shared.restorePurchases()
            await MainActor.run {
                self.setLoading(false)
                if PremiumManager.shared.isPremium {
                    self.dismiss(animated: true)
                } else {
                    self.alert("No Purchases Found",
                               "No active WolfMore Premium subscription or previous Pro purchase was found for this Apple ID.")
                }
            }
        }
    }

    @objc private func laterTapped() { dismiss(animated: true) }

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
