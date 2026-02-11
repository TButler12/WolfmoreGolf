import UIKit

final class CourseSetupViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet private weak var courseLabel: UILabel!

    @IBOutlet private var parFields: [UITextField]!   // tags 0...17
    @IBOutlet private var hcFields:  [UITextField]!   // tags 0...17
    @IBOutlet private weak var instructionLabel: UILabel!

    // MARK: - State
    private var activeCourseID: UUID?   // the saved course currently loaded (if any)

    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()

        wirePopupOnInstructionLabel()   // ✅ ADD THIS

        // ✅ ONE button only
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Course Review",
            style: .plain,
            target: self,
            action: #selector(courseButtonTapped(_:))
        )

        CourseLibrary.shared.seedIfNeeded()
        loadFromGameOrDefault()
        syncActiveCourseIDFromCurrentModel()
        updateCourseLabel()
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        CourseLibrary.shared.seedIfNeeded()
        syncActiveCourseIDFromCurrentModel()
        updateCourseLabel()
        startInstructionGlow()
        
    }
    
    private func presentNewGameFlow_showManagePlayersFirst() {
        let sb = UIStoryboard(name: "Main", bundle: nil)

        let setup = sb.instantiateViewController(withIdentifier: "PlayerSetupVC") as! PlayerSetupViewController
        let manage = sb.instantiateViewController(withIdentifier: "ManagePlayersVC") as! ManagePlayersViewController

        let nav = UINavigationController()
        nav.modalPresentationStyle = .fullScreen

        // ✅ No flash: ManagePlayers is top, PlayerSetup is root
        nav.setViewControllers([setup, manage], animated: false)

        present(nav, animated: true)
    }

    @IBAction private func playNewGameTapped(_ sender: UIButton) {
        GameManager.shared.startNewGame()
        presentNewGameFlow_showManagePlayersFirst()
    }

    
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
            • Tap any HC box to edit.
            • When finished, tap Course Review to save course,   load a saved course and make a course your Home Tracking Course
            """,
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    // MARK: - Glow hint

    private var isGlowing = false

    private func startInstructionGlow() {
        guard !isGlowing else { return }
        isGlowing = true

        // If any parent view clips, the glow will be cut off.
        instructionLabel.superview?.clipsToBounds = false
        instructionLabel.clipsToBounds = false

        instructionLabel.layer.masksToBounds = false
        instructionLabel.layer.shadowOffset = .zero
        instructionLabel.layer.shadowRadius = 6
        instructionLabel.layer.shadowOpacity = 0.0

        // Use the label's current text color for the glow color (works in dark mode)
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

    private func stopInstructionGlow() {
        isGlowing = false
        instructionLabel.layer.removeAnimation(forKey: "glowPulse")
        instructionLabel.layer.shadowOpacity = 0.0
    }

    // MARK: - One Course button action
    @objc private func courseButtonTapped(_ sender: UIBarButtonItem) {
        view.endEditing(true)
        presentCourseMenu(anchor: sender)
    }

    // If you want to use a single on-screen pill button instead of nav bar:
    // connect it to this IBAction and REMOVE the rightBarButtonItem above.
    @IBAction private func courseButtonTappedOnScreen(_ sender: UIButton) {
        view.endEditing(true)
        presentCourseMenu(anchorView: sender)
    }

    private func presentCourseMenu(anchor: UIBarButtonItem? = nil, anchorView: UIView? = nil) {

        let titleName: String = {
            if let id = activeCourseID, let c = CourseLibrary.shared.get(id: id) { return c.name }
            return "Current (Custom)"
        }()

        let ac = UIAlertController(
            title: "Course",
            message: "Loaded: \(titleName)",
            preferredStyle: .actionSheet
        )

        // ---------------------------------------------------
        // LOAD COURSES
        // ---------------------------------------------------
        ac.addAction(UIAlertAction(title: "Load Course…", style: .default) { [weak self] _ in
            self?.presentLoadList(anchor: anchor, anchorView: anchorView)
        })

        // ---------------------------------------------------
        // SAVE / MANAGE
        // ---------------------------------------------------
        ac.addAction(UIAlertAction(title: "Save Current As…", style: .default) { [weak self] _ in
            self?.promptSaveCurrentAsNew()
        })

       // ac/////.addAction(UIAlertAction(title: "Save Edits (Overwrite Loaded)", style: //.default) { [weak self] _ in
         //   self?.saveEditsOverActiveOrSaveAs()
        //})

       // ac.addAction(UIAlertAction(title: "Reset Unsaved Changes", style: .default) { [weak self] _ in
        //    self?.resetUnsavedToActive()
      //  })

        ac.addAction(UIAlertAction(title: "Set as Home / Tracking Course", style: .default) { [weak self] _ in
            self?.setActiveAsHomeCourse()
        })

        ac.addAction(UIAlertAction(title: "Set to WolMore Defaults", style: .default) { [weak self] _ in
            self?.setToWolfMoreDefaults()
        })

        // Delete (protect Biltmore)
        if let id = activeCourseID,
           let c = CourseLibrary.shared.get(id: id),
           c.name.caseInsensitiveCompare("WolfMore CC") != .orderedSame {
            ac.addAction(UIAlertAction(title: "Delete Course", style: .destructive) { [weak self] _ in
                self?.confirmDeleteActiveCourse()
            })
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // iPad anchor
        if let pop = ac.popoverPresentationController {
            if let bar = anchor {
                pop.barButtonItem = bar
            } else if let v = anchorView {
                pop.sourceView = v
                pop.sourceRect = v.bounds
            } else {
                pop.sourceView = view
                pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY - 1, width: 1, height: 1)
            }
        }

        present(ac, animated: true)
    }

    private func presentLoadList(anchor: UIBarButtonItem?, anchorView: UIView?) {

        CourseLibrary.shared.seedIfNeeded()

        // Put Biltmore first
        var courses = CourseLibrary.shared.allSorted()
        if let idx = courses.firstIndex(where: { $0.name.caseInsensitiveCompare("WolfMore CC") == .orderedSame }) {
            let b = courses.remove(at: idx)
            courses.insert(b, at: 0)
        }

        let ac = UIAlertController(
            title: "Load Course",
            message: "Choose the course to play",
            preferredStyle: .actionSheet
        )

        for course in courses {
            let isHome = (course.id.uuidString == ProfileStore.homeCourseID)
            let title = isHome ? "⭐ \(course.name)" : course.name

            ac.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.applyToUIAndModel(pars: course.pars, hcs: course.hcs)
                self?.activeCourseID = course.id
                self?.updateCourseLabel()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            })
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = ac.popoverPresentationController {
            if let bar = anchor {
                pop.barButtonItem = bar
            } else if let v = anchorView {
                pop.sourceView = v
                pop.sourceRect = v.bounds
            } else {
                pop.sourceView = view
                pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY - 1, width: 1, height: 1)
            }
        }

        present(ac, animated: true)
    }

    // MARK: - Initial load
    private func loadFromGameOrDefault() {
        if let g = GameManager.shared.currentGame,
           g.course.pars.count >= 18,
           g.course.holeHandicaps.count >= 18 {

            applyToUIAndModel(
                pars: Array(g.course.pars.prefix(18)),
                hcs:  Array(g.course.holeHandicaps.prefix(18))
            )
        } else {
            applyToUIAndModel(pars: WOLFMORE_PARS, hcs: WOLFMORE_HCS)
        }
    }

    private func syncActiveCourseIDFromCurrentModel() {
        guard let g = GameManager.shared.currentGame else {
            activeCourseID = nil
            return
        }

        let curPars = Array(g.course.pars.prefix(18))
        let curHCs  = Array(g.course.holeHandicaps.prefix(18))

        if let match = CourseLibrary.shared.courses.first(where: {
            Array($0.pars.prefix(18)) == curPars && Array($0.hcs.prefix(18)) == curHCs
        }) {
            activeCourseID = match.id
        } else {
            activeCourseID = nil
        }
    }

    // MARK: - Label
    private func updateCourseLabel() {
        CourseLibrary.shared.seedIfNeeded()

        guard let g = GameManager.shared.currentGame else {
            courseLabel.text = "Course: (none)"
            return
        }

        let curPars = Array(g.course.pars.prefix(18))
        let curHCs  = Array(g.course.holeHandicaps.prefix(18))

        let match = CourseLibrary.shared.courses.first { c in
            Array(c.pars.prefix(18)) == curPars &&
            Array(c.hcs.prefix(18))  == curHCs
        }

        if let course = match {
            let isHome = (course.id.uuidString == ProfileStore.homeCourseID)
            courseLabel.text = isHome ? "Course: ⭐ \(course.name)" : "Course: \(course.name)"
        } else {
            courseLabel.text = "Course: Custom"
        }
    }

    // MARK: - Manage actions
    private func setActiveAsHomeCourse() {
        guard let id = activeCourseID else {
            showAlert(title: "Save First", message: "Load a saved course (or Save Current As…) before setting Home.")
            return
        }
        ProfileStore.homeCourseID = id.uuidString
        updateCourseLabel()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func saveEditsOverActiveOrSaveAs() {
        let (pars, hcs) = readFields()

        if let id = activeCourseID,
           let existing = CourseLibrary.shared.get(id: id) {

            let updated = CourseProfile(id: existing.id, name: existing.name, pars: pars, hcs: hcs)
            CourseLibrary.shared.upsert(updated)
            applyToUIAndModel(pars: updated.pars, hcs: updated.hcs)
            updateCourseLabel()
            UINotificationFeedbackGenerator().notificationOccurred(.success)

        } else {
            promptSaveCurrentAsNew()
        }
    }

    private func resetUnsavedToActive() {
        guard let id = activeCourseID,
              let c  = CourseLibrary.shared.get(id: id) else {
            showAlert(title: "Nothing to Reset", message: "Load a saved course first.")
            return
        }

        applyToUIAndModel(pars: c.pars, hcs: c.hcs)
        updateCourseLabel()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func setToWolfMoreDefaults() {
        CourseLibrary.shared.seedIfNeeded()
        if let b = CourseLibrary.shared.WolfMore() {
            applyToUIAndModel(pars: b.pars, hcs: b.hcs)
            activeCourseID = b.id
        } else {
            applyToUIAndModel(pars: WOLFMORE_PARS, hcs: WOLFMORE_HCS)
            activeCourseID = nil
        }
        updateCourseLabel()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func confirmDeleteActiveCourse() {
        guard let id = activeCourseID,
              let current = CourseLibrary.shared.get(id: id) else { return }

        let warn = UIAlertController(
            title: "Delete \(current.name)?",
            message: "This removes the course from your library. You can’t undo this.",
            preferredStyle: .alert
        )
        warn.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        warn.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            CourseLibrary.shared.delete(id: id)
            self.setToWolfMoreDefaults()
        })
        present(warn, animated: true)
    }

    // MARK: - Save As
    private func promptSaveCurrentAsNew() {
        let (pars, hcs) = readFields()

        let ac = UIAlertController(
            title: "Save Course",
            message: "Enter a course name",
            preferredStyle: .alert
        )
        ac.addTextField { tf in
            tf.placeholder = "e.g., Red Run – Blue Tees"
            tf.autocapitalizationType = .words
            tf.clearButtonMode = .whileEditing
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self else { return }

            let raw = ac.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            let name = (raw?.isEmpty == false) ? raw! : "Unnamed Course"

            let newCourse = CourseProfile(name: name, pars: pars, hcs: hcs)
            CourseLibrary.shared.upsert(newCourse)

            self.activeCourseID = newCourse.id
            self.applyToUIAndModel(pars: newCourse.pars, hcs: newCourse.hcs)
            self.updateCourseLabel()

            UINotificationFeedbackGenerator().notificationOccurred(.success)
        })
        present(ac, animated: true)
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

    // MARK: - Existing Home button behavior (kept)
    @IBAction func homeButtonTapped(_ sender: UIButton) {
        view.endEditing(true)

        // Ensure model is updated from fields before leaving
        let (pars, hcs) = readFields()
        applyToUIAndModel(pars: pars, hcs: hcs)

        if let nav = navigationController {
            nav.popToRootViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    // MARK: - Keyboard helpers
    private func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditingNow))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func endEditingNow() { view.endEditing(true) }

    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}
