import UIKit

final class LocationPromptViewController: UIViewController {

    private static let legacyShownKey      = "hasShownLocationPrompt_v1"
    private static let shownCountKey        = "locationPrompt_shownCount"
    private static let roundsAtDismissalKey = "locationPrompt_roundsAtLastDismissal"
    private static let lastVersionKey       = "locationPrompt_lastDismissedVersion"
    private static let cleanupDoneKey       = "locationPrompt_cleanupV2Done"

    private static func distinctRoundsCount() -> Int {
        Set(RoundStore.shared.rounds.map(\.gameID)).count
    }

    private static func appVersion() -> String {
        let v = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
        #if DEBUG
        let b = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? ""
        return "\(v)(\(b))"
        #else
        return v
        #endif
    }

    // Migrate existing users who have the old boolean flag set.
    private static func migrateIfNeeded() {
        let ud = UserDefaults.standard
        guard ud.bool(forKey: legacyShownKey) else { return }
        guard ud.integer(forKey: shownCountKey) == 0 else { return }
        ud.set(1, forKey: shownCountKey)
        ud.set(distinctRoundsCount(), forKey: roundsAtDismissalKey)
        ud.removeObject(forKey: legacyShownKey)
        // DEBUG only: leave lastVersionKey unset so version-change trigger fires immediately.
        // Release: lastVersionKey stays unset too, but the version check is compiled out,
        // so existing users only see the prompt again after 25 more rounds.
    }

    // One-time cleanup: an earlier migration incorrectly wrote lastVersionKey = currentVersion,
    // which blocked the DEBUG version-change trigger. Wipe it once so debug testing works.
    // In Release this key is never read, so this cleanup is a no-op in production.
    private static func cleanupV2IfNeeded() {
        let ud = UserDefaults.standard
        guard !ud.bool(forKey: cleanupDoneKey) else { return }
        #if DEBUG
        ud.removeObject(forKey: lastVersionKey)
        #endif
        ud.set(true, forKey: cleanupDoneKey)
    }

    private static func shouldShow(shownCount: Int) -> Bool {
        guard shownCount > 0 else { return true }   // first time ever
        #if DEBUG
        // Version-change trigger: debug only, for fast manual testing.
        if appVersion() != (UserDefaults.standard.string(forKey: lastVersionKey) ?? "") {
            return true
        }
        #endif
        // Production trigger: 25+ rounds since last dismissal.
        let roundsAtDismissal = UserDefaults.standard.integer(forKey: roundsAtDismissalKey)
        return distinctRoundsCount() - roundsAtDismissal >= 25
    }

    static func showIfNeeded(from presenter: UIViewController) {
        migrateIfNeeded()
        cleanupV2IfNeeded()
        guard shouldShow(shownCount: UserDefaults.standard.integer(forKey: shownCountKey)) else { return }
        let vc = LocationPromptViewController()
        vc.modalPresentationStyle = .pageSheet
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        presenter.present(vc, animated: true)
    }

    private static func recordDismissal() {
        let ud = UserDefaults.standard
        ud.set(ud.integer(forKey: shownCountKey) + 1, forKey: shownCountKey)
        ud.set(distinctRoundsCount(), forKey: roundsAtDismissalKey)
        #if DEBUG
        ud.set(appVersion(), forKey: lastVersionKey)
        #endif
    }

    private let stack         = UIStackView()
    private let countryField  = UITextField()
    private let regionField   = UITextField()
    private let stateField    = UITextField()
    private let zipField      = UITextField()
    private let regionRow     = UIView()
    private let stateRow      = UIView()
    private let zipRow        = UIView()
    private let submitBtn     = UIButton(type: .system)
    private let spinner       = UIActivityIndicatorView(style: .medium)

    private let countries: [String] = {
        var list = Locale.isoRegionCodes
            .compactMap { Locale.current.localizedString(forRegionCode: $0) }
            .sorted()
        list.removeAll { $0 == "United States" }
        list.insert("United States", at: 0)
        return list
    }()

    private let regions = [
        "Northeast",
        "Southeast",
        "Midwest",
        "South Central (Texas, Oklahoma, Louisiana, Arkansas)",
        "Mountain West",
        "West Coast",
    ]

    private let regionStates: [String: [String]] = [
        "Northeast": [
            "Connecticut", "Delaware", "Maine", "Maryland", "Massachusetts",
            "New Hampshire", "New Jersey", "New York", "Pennsylvania",
            "Rhode Island", "Vermont",
        ],
        "Southeast": [
            "Alabama", "Florida", "Georgia", "Kentucky", "Mississippi",
            "North Carolina", "South Carolina", "Tennessee", "Virginia", "West Virginia",
        ],
        "Midwest": [
            "Illinois", "Indiana", "Iowa", "Kansas", "Michigan", "Minnesota",
            "Missouri", "Nebraska", "North Dakota", "Ohio", "South Dakota", "Wisconsin",
        ],
        "South Central (Texas, Oklahoma, Louisiana, Arkansas)": [
            "Arkansas", "Louisiana", "Oklahoma", "Texas",
        ],
        "Mountain West": [
            "Arizona", "Colorado", "Idaho", "Montana", "Nevada",
            "New Mexico", "Utah", "Wyoming",
        ],
        "West Coast": [
            "Alaska", "California", "Hawaii", "Oregon", "Washington",
        ],
    ]

    private var currentStates: [String] { regionStates[selectedRegion] ?? [] }

    private var selectedCountry = "United States"
    private var selectedRegion  = "Northeast"
    private var selectedState   = "Connecticut"

    private let countryPicker = UIPickerView()
    private let regionPicker  = UIPickerView()
    private let statePicker   = UIPickerView()

    private let green = UIColor(red: 0.106, green: 0.227, blue: 0.165, alpha: 1)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        buildLayout()
    }

    // MARK: - Layout

    private func buildLayout() {
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 36),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])

        let globeLabel = UILabel()
        globeLabel.text = "🌍"
        globeLabel.font = .systemFont(ofSize: 48)
        globeLabel.textAlignment = .center

        let titleLabel = UILabel()
        titleLabel.text = "Help Us Improve WolfMore"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        let bodyLabel = UILabel()
        bodyLabel.text = "Tell us where you play so we can prioritize adding courses in your area."
        bodyLabel.font = .systemFont(ofSize: 15)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.textAlignment = .center
        bodyLabel.numberOfLines = 0

        // Country
        let countryLabel = makeFieldLabel("Country")
        countryPicker.dataSource = self
        countryPicker.delegate   = self
        countryPicker.tag        = 0
        countryField.inputView        = countryPicker
        countryField.inputAccessoryView = makeToolbar(#selector(countryPickerDone))
        countryField.text         = selectedCountry
        countryField.borderStyle  = .roundedRect
        countryField.font         = .systemFont(ofSize: 16)
        countryField.tintColor    = .clear

        let countryStack = UIStackView(arrangedSubviews: [countryLabel, countryField])
        countryStack.axis = .vertical
        countryStack.spacing = 6

        // Region (US only)
        let regionLabel = makeFieldLabel("Region")
        regionPicker.dataSource = self
        regionPicker.delegate   = self
        regionPicker.tag        = 1
        regionField.inputView        = regionPicker
        regionField.inputAccessoryView = makeToolbar(#selector(regionPickerDone))
        regionField.text         = selectedRegion
        regionField.borderStyle  = .roundedRect
        regionField.font         = .systemFont(ofSize: 16)
        regionField.tintColor    = .clear

        let regionStack = UIStackView(arrangedSubviews: [regionLabel, regionField])
        regionStack.axis = .vertical
        regionStack.spacing = 6
        regionRow.addSubview(regionStack)
        regionStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            regionStack.topAnchor.constraint(equalTo: regionRow.topAnchor),
            regionStack.bottomAnchor.constraint(equalTo: regionRow.bottomAnchor),
            regionStack.leadingAnchor.constraint(equalTo: regionRow.leadingAnchor),
            regionStack.trailingAnchor.constraint(equalTo: regionRow.trailingAnchor),
        ])

        // State (US only)
        let stateLabel = makeFieldLabel("State")
        statePicker.dataSource = self
        statePicker.delegate   = self
        statePicker.tag        = 2
        stateField.inputView        = statePicker
        stateField.inputAccessoryView = makeToolbar(#selector(statePickerDone))
        stateField.text         = selectedState
        stateField.borderStyle  = .roundedRect
        stateField.font         = .systemFont(ofSize: 16)
        stateField.tintColor    = .clear

        let stateStack = UIStackView(arrangedSubviews: [stateLabel, stateField])
        stateStack.axis = .vertical
        stateStack.spacing = 6
        stateRow.addSubview(stateStack)
        stateStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stateStack.topAnchor.constraint(equalTo: stateRow.topAnchor),
            stateStack.bottomAnchor.constraint(equalTo: stateRow.bottomAnchor),
            stateStack.leadingAnchor.constraint(equalTo: stateRow.leadingAnchor),
            stateStack.trailingAnchor.constraint(equalTo: stateRow.trailingAnchor),
        ])

        // Zip (US only)
        let zipLabel = makeFieldLabel("Zip Code (optional)")
        zipField.placeholder = "e.g. 90210"
        zipField.borderStyle = .roundedRect
        zipField.keyboardType = .numberPad
        zipField.font = .systemFont(ofSize: 16)
        zipField.returnKeyType = .done
        zipField.delegate = self

        let zipStack = UIStackView(arrangedSubviews: [zipLabel, zipField])
        zipStack.axis = .vertical
        zipStack.spacing = 6
        zipRow.addSubview(zipStack)
        zipStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            zipStack.topAnchor.constraint(equalTo: zipRow.topAnchor),
            zipStack.bottomAnchor.constraint(equalTo: zipRow.bottomAnchor),
            zipStack.leadingAnchor.constraint(equalTo: zipRow.leadingAnchor),
            zipStack.trailingAnchor.constraint(equalTo: zipRow.trailingAnchor),
        ])

        // Submit
        submitBtn.setTitle("Submit", for: .normal)
        submitBtn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        submitBtn.backgroundColor = green
        submitBtn.setTitleColor(.white, for: .normal)
        submitBtn.layer.cornerRadius = 12
        submitBtn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        submitBtn.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)

        let laterBtn = UIButton(type: .system)
        laterBtn.setTitle("Skip", for: .normal)
        laterBtn.titleLabel?.font = .systemFont(ofSize: 16)
        laterBtn.setTitleColor(.secondaryLabel, for: .normal)
        laterBtn.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)

        spinner.hidesWhenStopped = true

        [globeLabel, titleLabel, bodyLabel, countryStack, regionRow, stateRow, zipRow,
         submitBtn, spinner, laterBtn]
            .forEach { stack.addArrangedSubview($0) }

        updateUSFieldsVisibility()
    }

    private func makeFieldLabel(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.text = text
        lbl.font = .systemFont(ofSize: 13, weight: .medium)
        lbl.textColor = .secondaryLabel
        return lbl
    }

    private func makeToolbar(_ selector: Selector) -> UIToolbar {
        let tb = UIToolbar()
        tb.sizeToFit()
        let done = UIBarButtonItem(title: "Done", style: .done, target: self, action: selector)
        done.tintColor = green
        tb.setItems([UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), done],
                    animated: false)
        return tb
    }

    private func updateUSFieldsVisibility() {
        let isUS = selectedCountry == "United States"
        regionRow.isHidden = !isUS
        stateRow.isHidden  = !isUS
        zipRow.isHidden    = !isUS
    }

    // MARK: - Actions

    @objc private func countryPickerDone() { countryField.resignFirstResponder() }
    @objc private func regionPickerDone()  { regionField.resignFirstResponder() }
    @objc private func statePickerDone()   { stateField.resignFirstResponder() }

    @objc private func submitTapped() {
        countryField.resignFirstResponder()
        regionField.resignFirstResponder()
        stateField.resignFirstResponder()
        zipField.resignFirstResponder()

        let country = selectedCountry
        let isUS    = country == "United States"
        let region  = isUS ? selectedRegion : nil
        let state   = isUS ? selectedState  : nil
        let zip     = isUS ? zipField.text?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty : nil

        setLoading(true)
        Task {
            do {
                try await SupabaseService.shared.submitLocationTelemetry(
                    country: country, region: region, state: state, zipCode: zip)
            } catch {
                // Fire-and-forget: don't block dismissal on network failure
            }
            await MainActor.run {
                Self.recordDismissal()
                self.setLoading(false)
                self.dismiss(animated: true)
            }
        }
    }

    @objc private func skipTapped() {
        Self.recordDismissal()
        dismiss(animated: true)
    }

    private func setLoading(_ on: Bool) {
        on ? spinner.startAnimating() : spinner.stopAnimating()
        submitBtn.isEnabled = !on
    }
}

// MARK: - UIPickerViewDataSource / Delegate

extension LocationPromptViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
        case 0: return countries.count
        case 1: return regions.count
        default: return currentStates.count
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView.tag {
        case 0: return countries[row]
        case 1: return regions[row]
        default: return currentStates[row]
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView.tag {
        case 0:
            selectedCountry = countries[row]
            countryField.text = selectedCountry
            updateUSFieldsVisibility()
        case 1:
            selectedRegion = regions[row]
            regionField.text = selectedRegion
            statePicker.reloadAllComponents()
            statePicker.selectRow(0, inComponent: 0, animated: false)
            selectedState = currentStates.first ?? ""
            stateField.text = selectedState
        default:
            selectedState = currentStates[row]
            stateField.text = selectedState
        }
    }
}

// MARK: - UITextFieldDelegate

extension LocationPromptViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - String helper

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
