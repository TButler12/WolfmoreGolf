import UIKit

final class TeeSetEditorViewController: UIViewController {

    // MARK: - Inputs

    var existingTeeSet: TeeSet?
    var defaultPars: [Int] = []
    var defaultHCs: [Int] = []
    var onSave: ((TeeSet) -> Void)?

    // MARK: - Private

    private let scrollView = UIScrollView()
    private let nameField  = UITextField()
    private var parFields:        [UITextField] = []
    private var hcFields:         [UITextField] = []
    private var defaultParLabels: [UILabel]     = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = existingTeeSet == nil ? "Add Tee Set" : "Edit Tee Set"
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save", style: .done, target: self, action: #selector(saveTapped)
        )

        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        buildUI()
        populateFields()
    }

    // MARK: - UI Construction

    private func buildUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 28
        content.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            content.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32),
            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),
        ])

        // Tee name field
        nameField.placeholder = "Tee name  (e.g., Red)"
        nameField.borderStyle = .roundedRect
        nameField.font = .systemFont(ofSize: 17)
        nameField.autocapitalizationType = .words
        nameField.clearButtonMode = .whileEditing
        nameField.returnKeyType = .done
        nameField.delegate = self
        content.addArrangedSubview(nameField)

        // Legend explaining the colour coding
        let legend = UILabel()
        legend.text = "Orange = same as course  ·  Green = changed"
        legend.font = .systemFont(ofSize: 12)
        legend.textColor = .secondaryLabel
        legend.textAlignment = .center
        content.addArrangedSubview(legend)

        // Grid: 3 sections of 6 holes each
        for section in 0..<3 {
            content.addArrangedSubview(makeSection(startHole: section * 6))
        }
    }

    private func makeSection(startHole: Int) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 4

        let holeRow = UIStackView()
        let parRow  = UIStackView()
        let defRow  = UIStackView()   // course-default comparison row
        let hcRow   = UIStackView()
        for row in [holeRow, parRow, defRow, hcRow] {
            row.axis = .horizontal
            row.spacing = 4
            row.alignment = .center
        }

        // Left-side labels
        holeRow.addArrangedSubview(sideLabel(""))
        parRow.addArrangedSubview(sideLabel("Par"))
        defRow.addArrangedSubview(sideLabel("Crs"))
        hcRow.addArrangedSubview(sideLabel("HC"))

        for i in 0..<6 {
            let holeIndex = startHole + i
            let holeNumber = holeIndex + 1

            let numView = holeNumberTile("\(holeNumber)")
            let parTF   = parField()
            let defL    = courseDefaultLabel()
            let hcTF    = hcField()

            parFields.append(parTF)
            defaultParLabels.append(defL)
            hcFields.append(hcTF)

            holeRow.addArrangedSubview(numView)
            parRow.addArrangedSubview(parTF)
            defRow.addArrangedSubview(defL)
            hcRow.addArrangedSubview(hcTF)

            // Visual gap between groups of 3
            if i == 2 {
                holeRow.setCustomSpacing(10, after: numView)
                parRow.setCustomSpacing(10, after: parTF)
                defRow.setCustomSpacing(10, after: defL)
                hcRow.setCustomSpacing(10, after: hcTF)
            }
        }

        container.addArrangedSubview(holeRow)
        container.addArrangedSubview(parRow)
        container.addArrangedSubview(defRow)
        container.addArrangedSubview(hcRow)
        return container
    }

    // MARK: - Cell Factories

    private func sideLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = .secondaryLabel
        l.textAlignment = .right
        l.setContentHuggingPriority(.required, for: .horizontal)
        NSLayoutConstraint.activate([l.widthAnchor.constraint(equalToConstant: 28)])
        return l
    }

    private func holeNumberTile(_ text: String) -> UIView {
        let v = UIView()
        v.backgroundColor = .black
        v.layer.cornerRadius = 6

        let l = UILabel()
        l.text = text
        l.font = .boldSystemFont(ofSize: 14)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(l)

        NSLayoutConstraint.activate([
            v.widthAnchor.constraint(equalToConstant: 42),
            v.heightAnchor.constraint(equalToConstant: 34),
            l.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            l.centerYAnchor.constraint(equalTo: v.centerYAnchor),
        ])
        return v
    }

    private func parField() -> UITextField {
        let tf = UITextField()
        tf.backgroundColor = UIColor(red: 0.97, green: 0.72, blue: 0.18, alpha: 1.0)
        tf.textAlignment = .center
        tf.font = .boldSystemFont(ofSize: 16)
        tf.keyboardType = .numberPad
        tf.layer.cornerRadius = 6
        tf.delegate = self
        NSLayoutConstraint.activate([
            tf.widthAnchor.constraint(equalToConstant: 42),
            tf.heightAnchor.constraint(equalToConstant: 34),
        ])
        return tf
    }

    private func courseDefaultLabel() -> UILabel {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = .tertiaryLabel
        l.textAlignment = .center
        l.layer.cornerRadius = 4
        l.layer.masksToBounds = true
        l.backgroundColor = UIColor.systemGray6
        NSLayoutConstraint.activate([
            l.widthAnchor.constraint(equalToConstant: 42),
            l.heightAnchor.constraint(equalToConstant: 24),
        ])
        return l
    }

    private func hcField() -> UITextField {
        let tf = UITextField()
        tf.backgroundColor = .secondarySystemBackground
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.systemGray4.cgColor
        tf.textAlignment = .center
        tf.font = .systemFont(ofSize: 15)
        tf.keyboardType = .numberPad
        tf.layer.cornerRadius = 6
        tf.delegate = self
        NSLayoutConstraint.activate([
            tf.widthAnchor.constraint(equalToConstant: 42),
            tf.heightAnchor.constraint(equalToConstant: 34),
        ])
        return tf
    }

    // MARK: - Data

    private func populateFields() {
        let pars = existingTeeSet?.pars ?? defaultPars
        let hcs  = existingTeeSet?.hcs  ?? defaultHCs
        nameField.text = existingTeeSet?.name ?? ""

        for (i, tf) in parFields.enumerated() {
            tf.text = i < pars.count ? "\(pars[i])" : ""
            applyParColor(to: tf, value: i < pars.count ? pars[i] : nil, index: i)
        }
        for (i, l) in defaultParLabels.enumerated() {
            l.text = i < defaultPars.count ? "\(defaultPars[i])" : ""
        }
        for (i, tf) in hcFields.enumerated() {
            tf.text = i < hcs.count ? "\(hcs[i])" : ""
        }
    }

    private func applyParColor(to tf: UITextField, value: Int?, index: Int) {
        let v = value ?? (index < defaultPars.count ? defaultPars[index] : 4)
        let isCustom = index < defaultPars.count && v != defaultPars[index]
        tf.backgroundColor = isCustom
            ? UIColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1.0)
            : UIColor(red: 0.97, green: 0.72, blue: 0.18, alpha: 1.0)
    }

    private func recolorParFields() {
        for (i, tf) in parFields.enumerated() {
            applyParColor(to: tf, value: Int(tf.text ?? ""), index: i)
        }
    }

    @objc private func endEditing() { view.endEditing(true) }

    // MARK: - Save

    @objc private func saveTapped() {
        view.endEditing(true)

        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else {
            let ac = UIAlertController(title: "Name Required",
                                       message: "Enter a name for this tee set (e.g., Red).",
                                       preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            return
        }

        let pars = parFields.enumerated().map { i, tf in
            max(3, min(6, Int(tf.text ?? "") ?? (i < defaultPars.count ? defaultPars[i] : 4)))
        }
        let hcs = hcFields.enumerated().map { i, tf in
            max(1, min(STANDARD_HOLES, Int(tf.text ?? "") ?? (i < defaultHCs.count ? defaultHCs[i] : i + 1)))
        }

        var ts = existingTeeSet ?? TeeSet(name: name, pars: pars, hcs: hcs)
        ts.name = name
        ts.pars = pars
        ts.hcs  = hcs

        onSave?(ts)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension TeeSetEditorViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if parFields.contains(textField) { recolorParFields() }
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        guard textField !== nameField else { return true }
        // Number-pad fields: max 2 digits
        let current = (textField.text ?? "") as NSString
        let new = current.replacingCharacters(in: range, with: string)
        return new.count <= 2
    }
}
