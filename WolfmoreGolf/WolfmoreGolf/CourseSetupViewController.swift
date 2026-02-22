import UIKit

final class CourseSetupViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet private weak var courseLabel: UILabel!
    @IBOutlet private var parFields: [UITextField]!   // tags 0...17
    @IBOutlet private var hcFields:  [UITextField]!   // tags 0...17
    @IBOutlet private weak var instructionLabel: UILabel!

    // MARK: - Inputs

    /// If set by CoursePicker (Edit), we load that course.
    var loadCourseID: UUID?

    // MARK: - State

    private var activeCourseID: UUID?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        hideKeyboardWhenTappedAround()
        wirePopupOnInstructionLabel()

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(saveCourseTapped)
        )

        CourseLibrary.shared.seedIfNeeded()
        loadInitialCourse()
        updateCourseLabel()
        startInstructionGlow()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        CourseLibrary.shared.seedIfNeeded()
        updateCourseLabel()
    }

    // MARK: - Initial Load

    private func loadInitialCourse() {
        // Priority:
        // 1) explicit loadCourseID (editing)
        // 2) selectedCourseID (from Home picker)
        // 3) match current game pars/hcs to a saved course
        // 4) WolfMore defaults

        if let id = loadCourseID, let c = CourseLibrary.shared.get(id: id) {
            setActiveCourse(c)
            return
        }

        if let id = CourseLibrary.shared.selectedCourseID,
           let c = CourseLibrary.shared.get(id: id) {
            setActiveCourse(c)
            return
        }

        if let match = matchCourseToCurrentGame() {
            setActiveCourse(match)
            return
        }

        // fallback
        applyToUIAndModel(pars: WOLFMORE_PARS, hcs: WOLFMORE_HCS)
        activeCourseID = CourseLibrary.shared.wolfMore()?.id
    }

    private func setActiveCourse(_ c: CourseProfile) {
        activeCourseID = c.id
        applyToUIAndModel(pars: c.pars, hcs: c.hcs)
        // Keep Home picker in sync with what you actually loaded
        CourseLibrary.shared.selectedCourseID = c.id
    }

    private func matchCourseToCurrentGame() -> CourseProfile? {
        guard let g = GameManager.shared.currentGame else { return nil }
        let curPars = Array(g.course.pars.prefix(18))
        let curHCs  = Array(g.course.holeHandicaps.prefix(18))

        return CourseLibrary.shared.courses.first(where: {
            Array($0.pars.prefix(18)) == curPars &&
            Array($0.hcs.prefix(18))  == curHCs
        })
    }

    // MARK: - Save

    @objc private func saveCourseTapped() {
        view.endEditing(true)
        promptSaveCurrentAsNew()
    }

    private func promptSaveCurrentAsNew() {
        let (pars, hcs) = readFields()

        let ac = UIAlertController(
            title: "Save Course",
            message: "Enter a course name",
            preferredStyle: .alert
        )
        ac.addTextField { tf in
            tf.placeholder = "e.g., Cedar Rapids CC (Championship)"
            tf.autocapitalizationType = .words
            tf.clearButtonMode = .whileEditing
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self else { return }

            let raw = ac.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            let name = (raw?.isEmpty == false) ? raw! : "Unnamed Course"

            let newCourse = CourseProfile(name: name, pars: pars, hcs: hcs)
            CourseLibrary.shared.upsert(newCourse)

            self.activeCourseID = newCourse.id
            CourseLibrary.shared.selectedCourseID = newCourse.id

            self.applyToUIAndModel(pars: newCourse.pars, hcs: newCourse.hcs)
            self.updateCourseLabel()

            UINotificationFeedbackGenerator().notificationOccurred(.success)
        })
        present(ac, animated: true)
    }

    // MARK: - Label

    private func updateCourseLabel() {
        CourseLibrary.shared.seedIfNeeded()

        // prefer the active course id
        if let id = activeCourseID, let c = CourseLibrary.shared.get(id: id) {
            let isHome = (ProfileStore.homeCourseID == id.uuidString)
            courseLabel.text = isHome ? "Course: ⭐ \(c.name)" : "Course: \(c.name)"
            return
        }

        // otherwise infer from current game
        if let inferred = matchCourseToCurrentGame() {
            let isHome = (ProfileStore.homeCourseID == inferred.id.uuidString)
            courseLabel.text = isHome ? "Course: ⭐ \(inferred.name)" : "Course: \(inferred.name)"
            return
        }

        courseLabel.text = "Course: Custom"
    }

    // MARK: - Read / Write UI <-> Model

    private func applyToUIAndModel(pars: [Int], hcs: [Int]) {
        let p = Array(pars.prefix(18))
        let h = Array(hcs.prefix(18))

        let parSorted = parFields.sorted { $0.tag < $1.tag }
        let hcSorted  = hcFields.sorted  { $0.tag < $1.tag }

        for i in 0..<min(18, parSorted.count) { parSorted[i].text = "\(p[i])" }
        for i in 0..<min(18, hcSorted.count)  { hcSorted[i].text  = "\(h[i])" }

        GameManager.shared.update { g in
            g.course.pars = p
            g.course.holeHandicaps = h
            g.hole = min(max(g.hole, 0), 17)
        }
    }

    private func readFields() -> (pars: [Int], hcs: [Int]) {
        let parSorted = parFields.sorted { $0.tag < $1.tag }.prefix(18)
        let hcSorted  = hcFields.sorted  { $0.tag < $1.tag }.prefix(18)

        let pars = parSorted.map { max(3, min(6, Int($0.text ?? "") ?? 4)) }
        let hcs  = hcSorted.map  { max(1, min(18, Int($0.text ?? "") ?? 1)) }

        return (pars, hcs)
    }

    // MARK: - Home button

    @IBAction func homeButtonTapped(_ sender: UIButton) {
        view.endEditing(true)

        // Ensure model is updated from fields before leaving
        let (pars, hcs) = readFields()
        applyToUIAndModel(pars: pars, hcs: hcs)

        navigationController?.popToRootViewController(animated: true)
    }

    // MARK: - Instruction popup + glow

    private func wirePopupOnInstructionLabel() {
        instructionLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(instructionLabelTapped))
        instructionLabel.addGestureRecognizer(tap)
    }

    @objc private func instructionLabelTapped() {
        let ac = UIAlertController(
            title: "How to Edit Pars & HC",
            message: """
            • Tap any PAR box to edit
            • Tap any HC box to edit
            • Tap Save to save as a new course
            """,
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    private var isGlowing = false

    private func startInstructionGlow() {
        guard !isGlowing else { return }
        isGlowing = true

        instructionLabel.superview?.clipsToBounds = false
        instructionLabel.clipsToBounds = false

        instructionLabel.layer.masksToBounds = false
        instructionLabel.layer.shadowOffset = .zero
        instructionLabel.layer.shadowRadius = 6
        instructionLabel.layer.shadowOpacity = 0.0
        instructionLabel.layer.shadowColor = instructionLabel.textColor.cgColor

        let pulse = CABasicAnimation(keyPath: "shadowOpacity")
        pulse.fromValue = 0.0
        pulse.toValue = 0.85
        pulse.duration = 0.9
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        instructionLabel.layer.add(pulse, forKey: "glowPulse")
    }

    // MARK: - Keyboard helpers

    private func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditingNow))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func endEditingNow() { view.endEditing(true) }
}
