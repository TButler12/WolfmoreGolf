import Foundation
import UIKit

// =======================================================
// MARK: - Built-in default: Biltmore CC (18 pars + 18 HCs)
// =======================================================

private let BILTMORE_PARS: [Int] = [
    4,4,4,4,3,5,3,4,4,
    4,4,3,4,4,5,3,4,5
]

private let BILTMORE_HCS: [Int] = [
    4,8,14,10,16,2,18,6,12,
    11,3,15,1,13,7,17,9,5
]

// ===============================================
// MARK: - Course model + tiny persistent library
// ===============================================

struct CourseProfile: Codable, Equatable {
    var id: UUID
    var name: String
    var pars: [Int]   // 18
    var hcs:  [Int]   // 18

    init(id: UUID = UUID(), name: String, pars: [Int], hcs: [Int]) {
        self.id = id
        self.name = name
        self.pars = Array(pars.prefix(18))
        self.hcs  = Array(hcs.prefix(18))
    }
}

final class CourseLibrary {
    static let shared = CourseLibrary()

    private let keyLibrary = "course.library.v1"
    private let keySeed    = "course.library.seeded.v1"

    private(set) var courses: [CourseProfile] = []

    private init() { load() }

    /// Seed Biltmore CC once on first launch
    func seedIfNeeded() {
        let u = UserDefaults.standard
        guard !u.bool(forKey: keySeed) else { return }

        if !courses.contains(where: { $0.name.caseInsensitiveCompare("Biltmore CC") == .orderedSame }) {
            courses.append(
                CourseProfile(
                    name: "Biltmore CC",
                    pars: BILTMORE_PARS,
                    hcs:  BILTMORE_HCS
                )
            )
            save()
        }
        u.set(true, forKey: keySeed)
    }

    func allSorted() -> [CourseProfile] {
        courses.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    func upsert(_ c: CourseProfile) {
        if let i = courses.firstIndex(where: { $0.id == c.id }) {
            courses[i] = c
        } else if let j = courses.firstIndex(
            where: { $0.name.caseInsensitiveCompare(c.name) == .orderedSame }
        ) {
            // preserve stable id if saving over existing name
            courses[j] = CourseProfile(
                id:   courses[j].id,
                name: c.name,
                pars: c.pars,
                hcs:  c.hcs
            )
        } else {
            courses.append(c)
        }
        save()
    }

    // MARK: - Persistence

    private func load() {
        let u = UserDefaults.standard
        guard let data = u.data(forKey: keyLibrary) else { return }
        courses = (try? JSONDecoder().decode([CourseProfile].self, from: data)) ?? []
    }

    private func save() {
        let u = UserDefaults.standard
        let data = (try? JSONEncoder().encode(courses)) ?? Data()
        u.set(data, forKey: keyLibrary)
    }
}

// Convenience helpers
extension CourseLibrary {
    func get(id: UUID) -> CourseProfile? {
        courses.first { $0.id == id }
    }

    func delete(id: UUID) {
        courses.removeAll { $0.id == id }

        // persist after delete
        let u = UserDefaults.standard
        let data = (try? JSONEncoder().encode(courses)) ?? Data()
        u.set(data, forKey: "course.library.v1")
    }

    func biltmore() -> CourseProfile? {
        courses.first {
            $0.name.caseInsensitiveCompare("Biltmore CC") == .orderedSame
        }
    }
}

// ===================================================
// MARK: - CourseSetupViewController
// ===================================================

final class CourseSetupViewController: UIViewController {

    
    @IBOutlet private weak var courseLabel: UILabel!   // 👈 NEW

    @IBOutlet private var parFields: [UITextField]!   // tags 0…17
    @IBOutlet private var hcFields:  [UITextField]!   // tags 0…17 (stroke index 1…18)

    /// Which library course is currently “active” in this editor.
    private var activeCourseID: UUID?

    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()

        // Nav buttons
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                title: "Load",
                style: .plain,
                target: self,
                action: #selector(loadButtonTapped(_:))
            ),
            UIBarButtonItem(
                title: "Manage",
                style: .plain,
                target: self,
                action: #selector(manageTapped(_:))
            )
            
        ]

        // Seed once
        CourseLibrary.shared.seedIfNeeded()

        // Prefer the course already in the model; otherwise default to Biltmore
        if let g = GameManager.shared.currentGame,
           g.courseParToPass.count == 18,
           g.courseHCToPass.count == 18 {

            // If your GameData has a courseName property, swap "Current Course" for g.courseName
            applyToUIAndModel(
                name: "Current Course",
                pars: g.courseParToPass,
                hcs:  g.courseHCToPass
            )

        } else {
            applyToUIAndModel(
                name: "Biltmore CC",
                pars: BILTMORE_PARS,
                hcs:  BILTMORE_HCS
            )
        }
        updateCourseLabel()
     
        
    }

    // MARK: - Keyboard helpers
    private func updateCourseLabel() {
        // Make sure our library is loaded
        CourseLibrary.shared.seedIfNeeded()

        guard let g = GameManager.shared.currentGame else {
            courseLabel.text = "Course: (none)"
            return
        }

        let currentPars = Array(g.course.pars.prefix(18))
        let currentHCs  = Array(g.course.holeHandicaps.prefix(18))

        // Try to match current layout to a saved course
        let match = CourseLibrary.shared.courses.first { c in
            Array(c.pars.prefix(18)) == currentPars &&
            Array(c.hcs.prefix(18))  == currentHCs
        }

        if let course = match {
            let isHome = (course.id.uuidString == ProfileStore.homeCourseID)
            if isHome {
                courseLabel.text = "Course: ⭐ \(course.name)"
            } else {
                courseLabel.text = "Course: \(course.name)"
            }
        } else {
            courseLabel.text = "Course: Custom"
        }
    }

    private func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(endEditingNow)
        )
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func endEditingNow() { view.endEditing(true) }

    // ===================================================
    // MARK: - Manage sheet
    // ===================================================

    @objc private func manageTapped(_ sender: Any) {
        view.endEditing(true)

        let titleName: String = {
            if let id = activeCourseID,
               let c  = CourseLibrary.shared.get(id: id) {
                return c.name
            }
            return "Current Course"
        }()

        let ac = UIAlertController(
            title: "Manage \(titleName)",
            message: nil,
            preferredStyle: .actionSheet
        )

        // ⭐ Set as Home / Tracking Course
        if let id = activeCourseID {
            ac.addAction(UIAlertAction(
                title: "Set as Home / Tracking Course",
                style: .default
            ) { _ in
                ProfileStore.homeCourseID = id.uuidString
                UINotificationFeedbackGenerator()
                    .notificationOccurred(.success)
                
                self.updateCourseLabel()
            })
        }

        // Save Edits → overwrite loaded course (or Save As… if none)
        ac.addAction(UIAlertAction(
            title: "Save Edits",
            style: .default
        ) { [weak self] _ in
            self?.saveEditsOverActiveOrSaveAs()
        })

        // Reset Unsaved Changes → reload from library snapshot for the active course
        ac.addAction(UIAlertAction(
            title: "Reset Unsaved Changes",
            style: .default
        ) { [weak self] _ in
            self?.resetUnsavedToActive()
        })

        // Set to Biltmore Defaults → make Biltmore active
        ac.addAction(UIAlertAction(
            title: "Set to Biltmore Defaults",
            style: .default
        ) { [weak self] _ in
            guard let self = self else { return }
            CourseLibrary.shared.seedIfNeeded()
            if let b = CourseLibrary.shared.biltmore() {
                self.applyToUIAndModel(
                    name: b.name,
                    pars: b.pars,
                    hcs:  b.hcs
                )
                self.activeCourseID = b.id
                NotificationCenter.default.post(name: .reloadUI, object: nil)
            }
        })

        // Delete Course (protect Biltmore)
        if let id = activeCourseID,
           let current = CourseLibrary.shared.get(id: id),
           current.name.caseInsensitiveCompare("Biltmore CC") != .orderedSame {

            ac.addAction(UIAlertAction(
                title: "Delete Course",
                style: .destructive
            ) { [weak self] _ in
                self?.confirmDeleteActiveCourse()
            })
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // iPad / large iPhone anchor
        if let pop = ac.popoverPresentationController {
            if let btn = sender as? UIView {
                pop.sourceView = btn
                pop.sourceRect = btn.bounds
            } else {
                pop.sourceView = view
                pop.sourceRect = CGRect(
                    x: view.bounds.midX,
                    y: view.bounds.maxY - 1,
                    width: 1,
                    height: 1
                )
            }
        }

        present(ac, animated: true)
    }

    // Overwrite the active course; if none, fallback to Save As…
    private func saveEditsOverActiveOrSaveAs() {
        let (pars, hcs) = readFields()

        if let id = activeCourseID,
           let existing = CourseLibrary.shared.get(id: id) {

            let updated = CourseProfile(
                id:   existing.id,
                name: existing.name,
                pars: pars,
                hcs:  hcs
            )
            CourseLibrary.shared.upsert(updated)
            applyToUIAndModel(
                name: updated.name,
                pars: updated.pars,
                hcs:  updated.hcs
            )
            UINotificationFeedbackGenerator()
                .notificationOccurred(.success)

        } else {
            // No active (e.g., pasted values) → Save As…
            promptSaveCurrentAsNew()
        }
    }

    // Revert fields to the saved values of the active course (discard unsaved edits)
    private func resetUnsavedToActive() {
        guard let id = activeCourseID,
              let c  = CourseLibrary.shared.get(id: id) else { return }

        applyToUIAndModel(
            name: c.name,
            pars: c.pars,
            hcs:  c.hcs
        )
        UINotificationFeedbackGenerator()
            .notificationOccurred(.success)
    }

    // Confirm + delete the active course; then fall back to Biltmore
    private func confirmDeleteActiveCourse() {
        guard let id = activeCourseID,
              let current = CourseLibrary.shared.get(id: id) else { return }

        let warn = UIAlertController(
            title: "Delete \(current.name)?",
            message: "This removes the course from your library. You can’t undo this.",
            preferredStyle: .alert
        )

        warn.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        warn.addAction(UIAlertAction(
            title: "Delete",
            style: .destructive
        ) { [weak self] _ in
            guard let self = self else { return }

            CourseLibrary.shared.delete(id: id)

            // Fall back to Biltmore as the active course
            CourseLibrary.shared.seedIfNeeded()
            if let b = CourseLibrary.shared.biltmore() {
                self.activeCourseID = b.id
                self.applyToUIAndModel(
                    name: b.name,
                    pars: b.pars,
                    hcs:  b.hcs
                )
            } else {
                self.activeCourseID = nil
            }

            NotificationCenter.default.post(name: .reloadUI, object: nil)
            UINotificationFeedbackGenerator()
                .notificationOccurred(.success)
        })

        present(warn, animated: true)
    }

    // ===================================================
    // MARK: - Load / Save buttons
    // ===================================================

    @IBAction func homeButtonTapped(_ sender: UIButton) {
        view.endEditing(true)
        saveCourseData()

        if let nav = navigationController {
            nav.popToRootViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    /// Show a course picker (Biltmore + saved courses)
    @IBAction private func loadButtonTapped(_ sender: Any) {
        view.endEditing(true)

        // Ensure default course exists
        CourseLibrary.shared.seedIfNeeded()

        // Fetch and reorder so Biltmore is always first
        var courses = CourseLibrary.shared.allSorted()
        if let idx = courses.firstIndex(
            where: { $0.name.caseInsensitiveCompare("Biltmore CC") == .orderedSame }
        ) {
            let b = courses.remove(at: idx)
            courses.insert(b, at: 0)
        }

        guard !courses.isEmpty else {
            applyToUIAndModel(
                name: "Biltmore CC",
                pars: BILTMORE_PARS,
                hcs:  BILTMORE_HCS
            )
            activeCourseID = nil
            NotificationCenter.default.post(name: .reloadUI, object: nil)
            return
        }

        let ac = UIAlertController(
            title: "Load Course",
            message: "Choose the course to play",
            preferredStyle: .actionSheet
        )

        for course in courses {
            // ⭐ Mark the currently tracked home course
            let isHome = (course.id.uuidString == ProfileStore.homeCourseID)
            let title  = isHome ? "⭐ \(course.name)" : course.name

            ac.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                guard let self = self else { return }

                self.applyToUIAndModel(
                    name: course.name,
                    pars: course.pars,
                    hcs:  course.hcs
                )
                self.activeCourseID = course.id

                NotificationCenter.default.post(name: .reloadUI, object: nil)
                UINotificationFeedbackGenerator()
                    .notificationOccurred(.success)
                
                self.updateCourseLabel()
            })
        }

        ac.addAction(UIAlertAction(
            title: "Save Current As…",
            style: .default
        ) { [weak self] _ in
            self?.promptSaveCurrentAsNew()
        })

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // iPhone/iPad popover anchor
        if let pop = ac.popoverPresentationController {
            if let viewSender = sender as? UIView {
                pop.sourceView = viewSender
                pop.sourceRect = viewSender.bounds
            } else {
                pop.sourceView = view
                pop.sourceRect = CGRect(
                    x: view.bounds.midX,
                    y: view.bounds.maxY - 1,
                    width: 1,
                    height: 1
                )
            }
        }

        present(ac, animated: true)
    }

    @IBAction private func editButtonTapped(_ sender: UIButton) {
        manageTapped(sender)   // shows Manage sheet
    }

    @IBAction func saveAsButtonTapped(_ sender: UIButton) {
        promptSaveCurrentAsNew()
    }

    // ===================================================
    // MARK: - Read/Write helpers
    // ===================================================

    private func applyToUIAndModel(name: String, pars: [Int], hcs: [Int]) {
        // Paint fields
        for (i, field) in parFields
            .sorted(by: { $0.tag < $1.tag })
            .enumerated()
        where i < 18 {
            field.text = "\(pars[i])"
        }

        for (i, field) in hcFields
            .sorted(by: { $0.tag < $1.tag })
            .enumerated()
        where i < 18 {
            field.text = "\(hcs[i])"
        }

        // Push to the game model so scoring uses it
        GameManager.shared.update { g in
            g.course.pars = Array(pars.prefix(18))
            g.course.holeHandicaps = Array(hcs.prefix(18))
            g.hole = min(g.hole, max(0, g.course.pars.count - 1))
        }
    }

    private func readFields() -> (pars: [Int], hcs: [Int]) {
        let pars = parFields
            .sorted { $0.tag < $1.tag }
            .prefix(18)
            .map { max(3, min(6, Int($0.text ?? "") ?? 4)) }

        let hcs = hcFields
            .sorted { $0.tag < $1.tag }
            .prefix(18)
            .map { max(1, min(18, Int($0.text ?? "") ?? 1)) }

        return (pars, hcs)
    }

    private func promptSaveCurrentAsNew() {
        let (pars, hcs) = readFields()

        let nameAC = UIAlertController(
            title: "Save Course",
            message: "Enter a course name",
            preferredStyle: .alert
        )

        nameAC.addTextField { tf in
            tf.placeholder = "e.g., Red Run – Blue Tees"
            tf.autocapitalizationType = .words
            tf.clearButtonMode = .whileEditing
        }

        nameAC.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        nameAC.addAction(UIAlertAction(
            title: "Save",
            style: .default
        ) { [weak self] _ in
            guard let self = self else { return }

            let rawName = nameAC.textFields?.first?.text?
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let finalName = (rawName?.isEmpty == false)
                ? rawName!
                : "Unnamed Course"

            let newCourse = CourseProfile(
                name: finalName,
                pars: pars,
                hcs:  hcs
            )

            CourseLibrary.shared.upsert(newCourse)
            self.activeCourseID = newCourse.id

            self.applyToUIAndModel(
                name: newCourse.name,
                pars: newCourse.pars,
                hcs:  newCourse.hcs
            )

            NotificationCenter.default.post(name: .reloadUI, object: nil)
            UINotificationFeedbackGenerator()
                .notificationOccurred(.success)
        })

        present(nameAC, animated: true)
    }

    // ===================================================
    // MARK: - Your existing save/load (kept)
// ===================================================

    func saveCourseData() {
        view.endEditing(true)

        let pars18 = parFields
            .sorted { $0.tag < $1.tag }
            .map { Int($0.text ?? "") ?? 4 }

        let hcs18 = hcFields
            .sorted { $0.tag < $1.tag }
            .map { min(18, max(1, Int($0.text ?? "") ?? 1)) }

        func pad<T>(_ a: [T], to n: Int, fill: T) -> [T] {
            a.count >= n
                ? Array(a.prefix(n))
                : a + Array(repeating: fill, count: n - a.count)
        }

        GameManager.shared.update { g in
            g.course.pars = pad(pars18, to: 18, fill: 4)
            g.course.holeHandicaps = pad(hcs18, to: 18, fill: 1)
            g.hole = min(g.hole, max(0, g.course.pars.count - 1))
        }
    }

    private func loadCourseData() {
        guard let g = GameManager.shared.currentGame else { return }

        let pars = g.course.pars
        let hcps = g.course.holeHandicaps

        for (i, field) in parFields
            .sorted(by: { $0.tag < $1.tag })
            .enumerated() {
            field.text = i < pars.count ? "\(pars[i])" : ""
        }

        for (i, field) in hcFields
            .sorted(by: { $0.tag < $1.tag })
            .enumerated() {
            field.text = i < hcps.count ? "\(hcps[i])" : ""
        }
    }
}
