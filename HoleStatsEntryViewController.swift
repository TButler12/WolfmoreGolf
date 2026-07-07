//
//  HoleStatsEntryViewController..swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 4/3/26.
//
import UIKit

final class HoleStatsEntryViewController: UIViewController, UITextFieldDelegate {
    var hasExistingStats = false
    private var keyboardObservers: [NSObjectProtocol] = []
    var onSave: ((Bool?, Bool?, Int?, Int?) -> Void)?
    var existingFairway: Bool?
    var existingWasSaved = false
    var existingGIR: Bool?
    var existingPutts: Int?
    var existingScore: Int?
    var par: Int = 4
    private let scoreLabel = UILabel()
    private let scoreField = UITextField()
    private var selectedFairway: Bool? = nil
    private var selectedGIR: Bool? = nil

    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let fairwayLabel = UILabel()
    private let fairwayHitButton = UIButton(type: .system)
    private let fairwayMissButton = UIButton(type: .system)
    private let fairwayNAButton = UIButton(type: .system)

    private let girLabel = UILabel()
    private let girHitButton = UIButton(type: .system)
    private let girMissButton = UIButton(type: .system)
    private let girNAButton = UIButton(type: .system)
    private var cardCenterYConstraint: NSLayoutConstraint!
    private let puttsLabel = UILabel()
    private let puttsField = UITextField()

    private let cancelButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    private weak var activeField: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()

        applyExistingValuesIfNeeded()   // 👈 ADD
        updateSelectionUI()
        let tap = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    @objc private func backgroundTapped() {
        view.endEditing(true)
    }
    private func applyExistingValuesIfNeeded() {
        subtitleLabel.text = hasExistingStats
            ? "Previously saved stats shown below"
            : "Enter stats for this hole"

        saveButton.setTitle(hasExistingStats ? "Update" : "Save", for: .normal)

        selectedFairway = existingFairway
        selectedGIR = existingGIR

        if let existingPutts {
            puttsField.text = "\(existingPutts)"
        }

        if let existingScore {
            scoreField.text = "\(existingScore)"
        } else {
            scoreField.text = "\(par)"
        }
    }
    private func makeNumberPadToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))

        toolbar.items = [flex, done]
        return toolbar
    }

    @objc private func doneTapped() {
        view.endEditing(true)
    }
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.35)

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = 22
        view.addSubview(cardView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Hole Stats"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Enter stats for this hole"
        subtitleLabel.font = .systemFont(ofSize: 18, weight: .medium)
        subtitleLabel.textColor = .secondaryLabel

        fairwayLabel.translatesAutoresizingMaskIntoConstraints = false
        fairwayLabel.text = "Fairway"
        fairwayLabel.font = .systemFont(ofSize: 20, weight: .semibold)

        girLabel.translatesAutoresizingMaskIntoConstraints = false
        girLabel.text = "GIR"
        girLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreLabel.text = "Score"
        scoreLabel.font = .systemFont(ofSize: 20, weight: .semibold)

        scoreField.translatesAutoresizingMaskIntoConstraints = false
        scoreField.borderStyle = .roundedRect
        scoreField.placeholder = "Score"
        scoreField.keyboardType = .numberPad
        scoreField.font = .systemFont(ofSize: 22, weight: .medium)
        scoreField.delegate = self
        puttsLabel.translatesAutoresizingMaskIntoConstraints = false
        puttsLabel.text = "Putts"
        puttsLabel.font = .systemFont(ofSize: 20, weight: .semibold)

        configureChoiceButton(fairwayHitButton, title: "● Hit", action: #selector(fairwayHitTapped))
        configureChoiceButton(fairwayMissButton, title: "○ Miss", action: #selector(fairwayMissTapped))
        configureChoiceButton(fairwayNAButton, title: "– N/A", action: #selector(fairwayNATapped))

        configureChoiceButton(girHitButton, title: "● Hit", action: #selector(girHitTapped))
        configureChoiceButton(girMissButton, title: "○ Miss", action: #selector(girMissTapped))
        configureChoiceButton(girNAButton, title: "– N/A", action: #selector(girNATapped))
        let toolbar = makeNumberPadToolbar()
        scoreField.inputAccessoryView = toolbar
        puttsField.inputAccessoryView = toolbar
        puttsField.translatesAutoresizingMaskIntoConstraints = false
        puttsField.borderStyle = .roundedRect
        puttsField.placeholder = "Putts"
        puttsField.keyboardType = .numberPad
        puttsField.font = .systemFont(ofSize: 22, weight: .medium)
        puttsField.delegate = self

        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 22, weight: .semibold)
        cancelButton.backgroundColor = .systemGray5
        cancelButton.layer.cornerRadius = 16
        cancelButton.setTitleColor(.label, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.setTitle("Save", for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 22, weight: .bold)
        saveButton.backgroundColor = .systemBlue
        saveButton.layer.cornerRadius = 16
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        let fairwayStack = UIStackView(arrangedSubviews: [fairwayHitButton, fairwayMissButton, fairwayNAButton])
        fairwayStack.translatesAutoresizingMaskIntoConstraints = false
        fairwayStack.axis = .horizontal
        fairwayStack.spacing = 10
        fairwayStack.distribution = .fillEqually

        let girStack = UIStackView(arrangedSubviews: [girHitButton, girMissButton, girNAButton])
        girStack.translatesAutoresizingMaskIntoConstraints = false
        girStack.axis = .horizontal
        girStack.spacing = 10
        girStack.distribution = .fillEqually

        let buttonStack = UIStackView(arrangedSubviews: [cancelButton, saveButton])
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually

        cardView.addSubview(titleLabel)
        cardView.addSubview(subtitleLabel)
        cardView.addSubview(fairwayLabel)
        cardView.addSubview(fairwayStack)
        cardView.addSubview(girLabel)
        cardView.addSubview(girStack)
        cardView.addSubview(scoreLabel)
        cardView.addSubview(scoreField)
        cardView.addSubview(puttsLabel)
        cardView.addSubview(puttsField)
        cardView.addSubview(buttonStack)

        cardCenterYConstraint = cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor)

        NSLayoutConstraint.activate([
            cardCenterYConstraint,
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),
            cardView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            cardView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            cardView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.82),
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            fairwayLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            fairwayLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            fairwayLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            fairwayStack.topAnchor.constraint(equalTo: fairwayLabel.bottomAnchor, constant: 10),
            fairwayStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            fairwayStack.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            fairwayStack.heightAnchor.constraint(equalToConstant: 56),
            girLabel.topAnchor.constraint(equalTo: fairwayStack.bottomAnchor, constant: 22),
            girLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            girLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            girStack.topAnchor.constraint(equalTo: girLabel.bottomAnchor, constant: 10),
            girStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            girStack.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            girStack.heightAnchor.constraint(equalToConstant: 56),
            // GIR stack (already correct above)

            // SCORE
            scoreLabel.topAnchor.constraint(equalTo: girStack.bottomAnchor, constant: 22),
            scoreLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            scoreLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            scoreField.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 10),
            scoreField.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            scoreField.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            scoreField.heightAnchor.constraint(equalToConstant: 56),

            // PUTTS
            puttsLabel.topAnchor.constraint(equalTo: scoreField.bottomAnchor, constant: 22),
            puttsLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            puttsLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            puttsField.topAnchor.constraint(equalTo: puttsLabel.bottomAnchor, constant: 10),
            puttsField.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            puttsField.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            puttsField.heightAnchor.constraint(equalToConstant: 56),
            buttonStack.topAnchor.constraint(equalTo: puttsField.bottomAnchor, constant: 28),
            buttonStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            buttonStack.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            buttonStack.heightAnchor.constraint(equalToConstant: 56),
            buttonStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -24)
        ])
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
    private func configureChoiceButton(_ button: UIButton, title: String, action: Selector) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        button.backgroundColor = .secondarySystemBackground
        button.setTitleColor(.label, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    private func styleChoiceButton(_ button: UIButton, selected: Bool, tint: UIColor) {
        button.backgroundColor = selected ? tint.withAlphaComponent(0.15) : .secondarySystemBackground
        button.layer.borderColor = selected ? tint.cgColor : UIColor.systemGray4.cgColor
        button.layer.borderWidth = selected ? 2 : 1
        button.setTitleColor(selected ? tint : .label, for: .normal)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ note: Notification) {
        guard let kbFrame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        let keyboardTop = view.bounds.height - kbFrame.height
        let puttsBottom = puttsField.convert(puttsField.bounds, to: view).maxY
        let overlap = puttsBottom - keyboardTop
        if overlap > 0 {
            cardCenterYConstraint.constant = -(overlap + 16)
        }
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }

    @objc private func keyboardWillHide(_ note: Notification) {
        guard let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        cardCenterYConstraint.constant = 0
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }
    private func updateSelectionUI() {
        styleChoiceButton(fairwayHitButton, selected: selectedFairway == true, tint: .systemGreen)
        styleChoiceButton(fairwayMissButton, selected: selectedFairway == false, tint: .systemOrange)
        styleChoiceButton(fairwayNAButton, selected: selectedFairway == nil, tint: .systemGray)

        styleChoiceButton(girHitButton, selected: selectedGIR == true, tint: .systemGreen)
        styleChoiceButton(girMissButton, selected: selectedGIR == false, tint: .systemOrange)
        styleChoiceButton(girNAButton, selected: selectedGIR == nil, tint: .systemGray)
    }

    @objc private func fairwayHitTapped() {
        selectedFairway = true
        updateSelectionUI()
    }

    @objc private func fairwayMissTapped() {
        selectedFairway = false
        updateSelectionUI()
    }

    @objc private func fairwayNATapped() {
        selectedFairway = nil
        updateSelectionUI()
    }

    @objc private func girHitTapped() {
        selectedGIR = true
        updateSelectionUI()
    }

    @objc private func girMissTapped() {
        selectedGIR = false
        updateSelectionUI()
    }

    @objc private func girNATapped() {
        selectedGIR = nil
        updateSelectionUI()
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        let putts = Int(puttsField.text ?? "")
        let score = Int(scoreField.text ?? "")
        onSave?(selectedFairway, selectedGIR, putts, score)
        dismiss(animated: true)
    }
}
