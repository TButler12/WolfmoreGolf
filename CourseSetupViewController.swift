import UIKit
import MessageUI

final class CourseSetupViewController: UIViewController, MFMailComposeViewControllerDelegate {

    // MARK: - Outlets

    @IBOutlet private weak var courseLabel: UILabel!
    @IBOutlet private var parFields: [UITextField]!   // tags 0...(STANDARD_HOLES-1)
    @IBOutlet private var hcFields:  [UITextField]!   // tags 0...(STANDARD_HOLES-1)
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
        if let id = loadCourseID, let c = CourseLibrary.shared.get(id: id) {
            setActiveCourse(c)
            return
        }

        if let id = CourseLibrary.shared.selectedCourseID,
           let c = CourseLibrary.shared.get(id: id) {
            setActiveCourse(c)
            return
        }

        // No prior pick — default to WolfMore
        if let wm = CourseLibrary.shared.wolfMore() {
            setActiveCourse(wm)
        } else {
            applyToUIAndModel(pars: WOLFMORE_PARS, hcs: WOLFMORE_HCS)
            activeCourseID = nil
        }
    }

    private func setActiveCourse(_ c: CourseProfile) {
        activeCourseID = c.id
        applyToUIAndModel(pars: c.pars, hcs: c.hcs)
        // Keep Home picker in sync with what you actually loaded
        CourseLibrary.shared.selectedCourseID = c.id
    }

    private func matchCourseToCurrentGame() -> CourseProfile? {
        guard let g = GameManager.shared.currentGame else { return nil }
        let curPars = Array(g.course.pars.prefix(STANDARD_HOLES))
        let curHCs  = Array(g.course.holeHandicaps.prefix(STANDARD_HOLES))

        return CourseLibrary.shared.courses.first(where: {
            Array($0.pars.prefix(STANDARD_HOLES)) == curPars &&
            Array($0.hcs.prefix(STANDARD_HOLES))  == curHCs
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
            message: "Enter course details",
            preferredStyle: .alert
        )

        // 1) Name
        ac.addTextField { tf in
            tf.placeholder = "Course name (e.g., Sea Island — Seaside)"
            tf.autocapitalizationType = .words
            tf.clearButtonMode = .whileEditing
        }

        // 2) Country
        ac.addTextField { tf in
            tf.placeholder = "Country (default: USA)"
            tf.autocapitalizationType = .words
            tf.clearButtonMode = .whileEditing
            tf.text = "USA"
        }

        // 3) State / Region
        ac.addTextField { tf in
            tf.placeholder = "State / Region (e.g., IL, GA, County Down)"
            tf.autocapitalizationType = .words
            tf.clearButtonMode = .whileEditing
        }

        // 4) Type
        ac.addTextField { tf in
            tf.placeholder = "Type (Private / Resort / Daily-Fee / Municipal)"
            tf.autocapitalizationType = .words
            tf.clearButtonMode = .whileEditing
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        ac.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self else { return }

            let tfs = ac.textFields ?? []

            let nameRaw = tfs[safe: 0]?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            let countryRaw = tfs[safe: 1]?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            let stateRaw = tfs[safe: 2]?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            let typeRaw = tfs[safe: 3]?.text?.trimmingCharacters(in: .whitespacesAndNewlines)

            let name = (nameRaw?.isEmpty == false) ? nameRaw! : "Unnamed Course"
            let country = (countryRaw?.isEmpty == false) ? countryRaw! : "USA"
            let state = (stateRaw?.isEmpty == false) ? stateRaw : nil
            let type = (typeRaw?.isEmpty == false) ? typeRaw : nil

            // IMPORTANT: use memberwise init so it always compiles
            let newCourse = CourseProfile(
                id: UUID(),
                name: name,
                pars: pars,
                hcs: hcs,
                tees: nil,
                country: country,
                state: state,
                architect: nil,
                type: type
            )

            CourseLibrary.shared.upsert(newCourse)

            self.activeCourseID = newCourse.id
            CourseLibrary.shared.selectedCourseID = newCourse.id

            self.applyToUIAndModel(pars: newCourse.pars, hcs: newCourse.hcs)
            self.updateCourseLabel()

            UINotificationFeedbackGenerator().notificationOccurred(.success)

            self.promptShareCourse(newCourse)
        })

        present(ac, animated: true)
    }

    // MARK: - Course sharing

    private func promptShareCourse(_ course: CourseProfile) {
        let ac = UIAlertController(
            title: "Join the WolfMore Community! 🏌️",
            message: "Help fellow golfers by sharing \(course.name) with the WolfMore community. We'll add it to the app so everyone can play it!",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "Maybe later", style: .cancel))
        ac.addAction(UIAlertAction(title: "Yes, I want to help!", style: .default) { [weak self] _ in
            self?.promptShareDetails(course)
        })
        present(ac, animated: true)
    }

    private func promptShareDetails(_ course: CourseProfile) {
        let form = UIAlertController(
            title: "You're a WolfMore Legend! 🏆",
            message: "We'll notify you when \(course.name) goes live for all users.",
            preferredStyle: .alert
        )
        form.addTextField { tf in
            tf.placeholder = "Name (optional)"
            tf.autocapitalizationType = .words
        }
        form.addTextField { tf in
            tf.placeholder = "Email — so we can notify you when your course goes live"
            tf.keyboardType = .emailAddress
            tf.autocapitalizationType = .none
        }
        form.addTextField { tf in
            tf.placeholder = "Notes — private club? recent changes? let us know"
        }
        form.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        form.addAction(UIAlertAction(title: "Submit to WolfMore", style: .default) { [weak self] _ in
            guard let self else { return }
            let tfs = form.textFields ?? []
            let submitterName  = tfs[safe: 0]?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let submitterEmail = tfs[safe: 1]?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let notes          = tfs[safe: 2]?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            self.sendCourseEmail(course, submitterName: submitterName,
                                 submitterEmail: submitterEmail, notes: notes)
        })
        present(form, animated: true)
    }

    private func sendCourseEmail(_ course: CourseProfile,
                                 submitterName: String,
                                 submitterEmail: String,
                                 notes: String) {
        guard MFMailComposeViewController.canSendMail() else {
            let ac = UIAlertController(
                title: "Mail Unavailable",
                message: "Please email course details to coursemanagement@wolfmore.com",
                preferredStyle: .alert
            )
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            return
        }

        let pars = course.pars.prefix(18).enumerated()
            .map { "H\($0.offset + 1): \($0.element)" }.joined(separator: "  ")
        let hcs = course.hcs.prefix(18).enumerated()
            .map { "H\($0.offset + 1): \($0.element)" }.joined(separator: "  ")

        var body = """
        Course Name: \(course.name)
        Country: \(course.country ?? "USA")
        State / Region: \(course.state ?? "")
        Type: \(course.type ?? "")
        Address: \(course.address ?? "")

        Pars (holes 1–18):
        \(pars)

        Handicap Ratings (holes 1–18):
        \(hcs)
        """

        if !submitterName.isEmpty   { body += "\n\nSubmitted by: \(submitterName)" }
        if !submitterEmail.isEmpty  { body += "\nEmail: \(submitterEmail)" }
        if !notes.isEmpty           { body += "\n\nNotes: \(notes)" }

        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self
        composer.setToRecipients(["coursemanagement@wolfmore.com"])
        composer.setSubject("New Course Submission: \(course.name)")
        composer.setMessageBody(body, isHTML: false)
        present(composer, animated: true)
    }

    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
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
        let p = Array(pars.prefix(STANDARD_HOLES))
        let h = Array(hcs.prefix(STANDARD_HOLES))

        let parSorted = parFields.sorted { $0.tag < $1.tag }
        let hcSorted  = hcFields.sorted  { $0.tag < $1.tag }

        for i in 0..<min(STANDARD_HOLES, parSorted.count) { parSorted[i].text = "\(p[i])" }
        for i in 0..<min(STANDARD_HOLES, hcSorted.count)  { hcSorted[i].text  = "\(h[i])" }

        GameManager.shared.update { g in
            g.course.pars = p
            g.course.holeHandicaps = h
            g.hole = min(max(g.hole, 0), 17)
        }
    }

    private func readFields() -> (pars: [Int], hcs: [Int]) {
        let parSorted = parFields.sorted { $0.tag < $1.tag }.prefix(STANDARD_HOLES)
        let hcSorted  = hcFields.sorted  { $0.tag < $1.tag }.prefix(STANDARD_HOLES)

        let pars = parSorted.map { max(3, min(6, Int($0.text ?? "") ?? 4)) }
        let hcs  = hcSorted.map  { max(1, min(STANDARD_HOLES, Int($0.text ?? "") ?? 1)) }

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
private extension Array {
    subscript(safe i: Int) -> Element? {
        indices.contains(i) ? self[i] : nil
    }
}
