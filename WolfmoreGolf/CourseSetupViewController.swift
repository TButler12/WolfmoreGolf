import UIKit

final class CourseSetupViewController: UIViewController {

        @IBOutlet private var parFields: [UITextField]!   // tags 0…17
        @IBOutlet private var hcFields:  [UITextField]!   // tags 0…17 (stroke index 1…18)

    override func viewDidLoad() {
        super.viewDidLoad()
        loadCourseData()
        
        
    }

        @IBAction func homeButtonTapped(_ sender: UIButton) {
            view.endEditing(true)
            saveCourseData()
            if let nav = navigationController {
                nav.popToRootViewController(animated: true)
            } else {
                dismiss(animated: true)
            }
        }

        @IBAction func loadButtonTapped(_ sender: UIButton) {
            view.endEditing(true)
            if GameManager.shared.loadLastOpened() {
                loadCourseData()
                NotificationCenter.default.post(name: .reloadUI, object: nil)
            } else {
                let a = UIAlertController(title: "No Saved Game",
                                          message: "There isn’t a saved course yet.",
                                          preferredStyle: .alert)
                a.addAction(UIAlertAction(title: "OK", style: .default))
                present(a, animated: true)
            }
        }
    func saveCourseData() {
        view.endEditing(true)

        let pars18 = parFields
            .sorted { $0.tag < $1.tag }
            .map { Int($0.text ?? "") ?? 4 }

        let hcs18 = hcFields
            .sorted { $0.tag < $1.tag }
            .map { min(18, max(1, Int($0.text ?? "") ?? 1)) }

        func pad<T>(_ a: [T], to n: Int, fill: T) -> [T] {
            a.count >= n ? Array(a.prefix(n)) : a + Array(repeating: fill, count: n - a.count)
        }

        GameManager.shared.update { g in
            // ✅ Write to the same place the Game screen reads from
            g.course.pars = pad(pars18, to: 18, fill: 4)
            g.course.holeHandicaps = pad(hcs18, to: 18, fill: 1)

            // keep hole index in range
            g.hole = min(g.hole, max(0, g.course.pars.count - 1))
        }

        // If you persist separately, keep it in sync (optional)
        // CourseStore.save(pars: g.course.pars, hcs: g.course.holeHandicaps)
    }

        // MARK: - Save

       // @discardableResult
    private func loadCourseData() {
        guard let g = GameManager.shared.currentGame else { return }

        // ✅ Read from course.*
        let pars = g.course.pars
        let hcps = g.course.holeHandicaps

        for (i, field) in parFields.sorted(by: { $0.tag < $1.tag }).enumerated() {
            field.text = i < pars.count ? "\(pars[i])" : ""
        }
        for (i, field) in hcFields.sorted(by: { $0.tag < $1.tag }).enumerated() {
            field.text = i < hcps.count ? "\(hcps[i])" : ""
        }
    }

        // MARK: - Load

      
    }
