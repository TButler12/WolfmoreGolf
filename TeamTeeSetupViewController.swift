import UIKit

final class TeamTeeSetupViewController: UIViewController {

    var settings: TeamTeeSettings
    var onSave: ((TeamTeeSettings) -> Void)?
    // Cap steppers at actual player count so N can never exceed the field size.
    var maxCount: Int = 4

    init(settings: TeamTeeSettings, maxCount: Int = 4) {
        self.settings = settings
        self.maxCount = max(1, maxCount)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    private weak var modeSeg: UISegmentedControl?
    private weak var fixedSection: UIStackView?
    private weak var byParSection: UIStackView?
    private weak var fixedLabel: UILabel?
    private weak var fixedStepper: UIStepper?
    private weak var par3Label: UILabel?
    private weak var par3Stepper: UIStepper?
    private weak var par4Label: UILabel?
    private weak var par4Stepper: UIStepper?
    private weak var par5Label: UILabel?
    private weak var par5Stepper: UIStepper?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "Team Tee Game"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        buildLayout()
        refresh()
    }

    // MARK: - Layout

    private func buildLayout() {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -32),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -40)
        ])

        // Mode
        stack.addArrangedSubview(sectionHeader("Count Mode"))
        let seg = UISegmentedControl(items: ["Fixed", "4-3-2"])
        seg.addTarget(self, action: #selector(modeChanged(_:)), for: .valueChanged)
        modeSeg = seg
        stack.addArrangedSubview(seg)

        let modeNote = noteLabel(
            "Fixed: same number of scores counted on every hole.\n" +
            "By Par: different count per par tier (e.g. 4 of 4 on par-3, 3 of 4 on par-4, 2 of 4 on par-5).")
        stack.addArrangedSubview(modeNote)

        // Fixed section
        let fixedCard = makeCard()
        let (fixedRow, fs, fl) = makeStepperRow(label: "Scores to count")
        fs.minimumValue = 1; fs.maximumValue = Double(maxCount); fs.stepValue = 1
        fs.addTarget(self, action: #selector(fixedChanged(_:)), for: .valueChanged)
        fixedStepper = fs; fixedLabel = fl
        fixedCard.addArrangedSubview(fixedRow)
        fixedSection = fixedCard
        stack.addArrangedSubview(fixedCard)

        // By Par section
        let byParCard = makeCard()
        let (p3Row, p3s, p3l) = makeStepperRow(label: "Par 3s — count")
        p3s.minimumValue = 1; p3s.maximumValue = Double(maxCount); p3s.stepValue = 1
        p3s.addTarget(self, action: #selector(par3Changed(_:)), for: .valueChanged)
        par3Stepper = p3s; par3Label = p3l

        let sep1 = makeSep()
        let (p4Row, p4s, p4l) = makeStepperRow(label: "Par 4s — count")
        p4s.minimumValue = 1; p4s.maximumValue = Double(maxCount); p4s.stepValue = 1
        p4s.addTarget(self, action: #selector(par4Changed(_:)), for: .valueChanged)
        par4Stepper = p4s; par4Label = p4l

        let sep2 = makeSep()
        let (p5Row, p5s, p5l) = makeStepperRow(label: "Par 5s — count")
        p5s.minimumValue = 1; p5s.maximumValue = Double(maxCount); p5s.stepValue = 1
        p5s.addTarget(self, action: #selector(par5Changed(_:)), for: .valueChanged)
        par5Stepper = p5s; par5Label = p5l

        byParCard.addArrangedSubview(p3Row)
        byParCard.addArrangedSubview(sep1)
        byParCard.addArrangedSubview(p4Row)
        byParCard.addArrangedSubview(sep2)
        byParCard.addArrangedSubview(p5Row)
        byParSection = byParCard
        stack.addArrangedSubview(byParCard)

        stack.addArrangedSubview(noteLabel(
            "Net score = gross minus handicap strokes, using the same stroke index and relative HC already used for individual net scoring."))
    }

    private func makeCard() -> UIStackView {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 0
        s.backgroundColor = .secondarySystemGroupedBackground
        s.layer.cornerRadius = 10
        s.clipsToBounds = true
        return s
    }

    private func makeSep() -> UIView {
        let v = UIView()
        v.backgroundColor = .separator
        v.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return v
    }

    private func makeStepperRow(label: String) -> (UIView, UIStepper, UILabel) {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 12)
        row.isLayoutMarginsRelativeArrangement = true
        row.spacing = 8

        let lbl = UILabel()
        lbl.text = label
        lbl.font = .systemFont(ofSize: 16)
        lbl.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let valLbl = UILabel()
        valLbl.font = .monospacedDigitSystemFont(ofSize: 16, weight: .semibold)
        valLbl.textAlignment = .right
        valLbl.widthAnchor.constraint(greaterThanOrEqualToConstant: 22).isActive = true

        let stepper = UIStepper()
        row.addArrangedSubview(lbl)
        row.addArrangedSubview(valLbl)
        row.addArrangedSubview(stepper)
        return (row, stepper, valLbl)
    }

    private func sectionHeader(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text.uppercased()
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = .secondaryLabel
        return l
    }

    private func noteLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .preferredFont(forTextStyle: .footnote)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        return l
    }

    // MARK: - Refresh

    private func refresh() {
        modeSeg?.selectedSegmentIndex = settings.countMode == .fixed ? 0 : 1
        fixedStepper?.value = Double(settings.fixedCount)
        fixedLabel?.text    = "\(settings.fixedCount)"
        par3Stepper?.value  = Double(settings.par3Count)
        par3Label?.text     = "\(settings.par3Count)"
        par4Stepper?.value  = Double(settings.par4Count)
        par4Label?.text     = "\(settings.par4Count)"
        par5Stepper?.value  = Double(settings.par5Count)
        par5Label?.text     = "\(settings.par5Count)"
        fixedSection?.isHidden = settings.countMode != .fixed
        byParSection?.isHidden = settings.countMode != .byPar
    }

    // MARK: - Actions

    @objc private func modeChanged(_ seg: UISegmentedControl) {
        settings.countMode = seg.selectedSegmentIndex == 0 ? .fixed : .byPar
        refresh()
    }

    @objc private func fixedChanged(_ s: UIStepper) {
        settings.fixedCount = Int(s.value)
        fixedLabel?.text = "\(settings.fixedCount)"
    }

    @objc private func par3Changed(_ s: UIStepper) {
        settings.par3Count = Int(s.value)
        par3Label?.text = "\(settings.par3Count)"
    }

    @objc private func par4Changed(_ s: UIStepper) {
        settings.par4Count = Int(s.value)
        par4Label?.text = "\(settings.par4Count)"
    }

    @objc private func par5Changed(_ s: UIStepper) {
        settings.par5Count = Int(s.value)
        par5Label?.text = "\(settings.par5Count)"
    }

    @objc private func doneTapped() {
        onSave?(settings)
        navigationController?.popViewController(animated: true)
    }
}
