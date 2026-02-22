//
//
//  CoursePickerViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 2/19/26.
//

import UIKit

final class CoursePickerViewController: UITableViewController, UISearchResultsUpdating {

    // Callbacks
    var onPickCourse: ((UUID) -> Void)?
    var onTapAddCourse: (() -> Void)?

    // Data
    private var all: [CourseProfile] = []
    private var filtered: [CourseProfile] = []

    private var isSearching: Bool {
        !(navigationItem.searchController?.searchBar.text?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty ?? true)
    }

    private var homeCourseUUID: UUID? {
        UUID(uuidString: ProfileStore.homeCourseID.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    private let searchController = UISearchController(searchResultsController: nil)
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Choose Course"
        tableView = UITableView(frame: .zero, style: .insetGrouped)

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addTapped)
        )

        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search courses"
        navigationItem.searchController = search
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search courses"
        navigationItem.searchController = searchController
        definesPresentationContext = true

        reload()
    }

    // MARK: - Data

    private func reload() {
        CourseLibrary.shared.seedIfNeeded()
        all = CourseLibrary.shared.allSorted()
        filtered = all
        tableView.reloadData()
    }

    private func setHomeCourse(_ id: UUID) {
        ProfileStore.homeCourseID = id.uuidString
    }

    // MARK: - Actions

    @objc private func cancelTapped() { dismiss(animated: true) }
    @objc private func addTapped() { onTapAddCourse?() }

    // MARK: - Table

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        (isSearching ? filtered : all).count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)

        let list = isSearching ? filtered : all
        let c = list[indexPath.row]

        cell.textLabel?.text = c.name

        // ✓ Loaded/selected course
        cell.accessoryType = (c.id == CourseLibrary.shared.selectedCourseID) ? .checkmark : .none

        // ⭐ Home/Tracking course
        if c.id == homeCourseUUID {
            cell.imageView?.image = UIImage(systemName: "star.fill")
            cell.imageView?.tintColor = .systemYellow
        } else {
            cell.imageView?.image = nil
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let list = isSearching ? filtered : all
        let c = list[indexPath.row]
        onPickCourse?(c.id)
    }

    // Swipe: Set Home ⭐
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {

        let list = isSearching ? filtered : all
        let c = list[indexPath.row]

        // ⭐ Home
        let home = UIContextualAction(style: .normal, title: "Home") { [weak self] _, _, done in
            self?.setHomeCourse(c.id)
            tableView.reloadData()
            done(true)
        }
        home.backgroundColor = .systemYellow
        home.image = UIImage(systemName: "star.fill")

        // ✏️ Edit
        let edit = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, done in
            self?.editCourse(c)   // implement below
            done(true)
        }
        edit.backgroundColor = .systemBlue
        edit.image = UIImage(systemName: "pencil")

     
        // 🗑️ Delete
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            guard let self else { done(false); return }

            if CourseLibrary.shared.isBuiltIn(id: c.id) {
                let ac = UIAlertController(
                    title: "Can’t Delete",
                    message: "\(c.name) is a built-in course.",
                    preferredStyle: .alert
                )
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(ac, animated: true)
                done(false)
                return
            }

            self.confirmDeleteCourse(c, indexPath: indexPath)
            done(true)
        }
        delete.image = UIImage(systemName: "trash")

        // Order matters: the first action is closest to the edge.
        let config = UISwipeActionsConfiguration(actions: [delete, edit, home])

        // Prevent “full swipe” from auto-triggering delete.
        config.performsFirstActionWithFullSwipe = false
        return config
    }
    private func editCourse(_ c: CourseProfile) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "CourseSetupVC") as! CourseSetupViewController

        vc.loadCourseID = c.id   // add `var loadCourseID: UUID?` to CourseSetupVC
        navigationController?.pushViewController(vc, animated: true)
    }
    private func confirmDeleteCourse(_ c: CourseProfile, indexPath: IndexPath) {

        // Protect your default
        if c.name.caseInsensitiveCompare("WolfMore") == .orderedSame {
            let ac = UIAlertController(title: "Can’t Delete", message: "WolfMore is the built-in default.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            return
        }

        let ac = UIAlertController(
            title: "Delete \(c.name)?",
            message: "This removes the course from your device.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        ac.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }

            // If deleting home course, clear it
            if ProfileStore.homeCourseID == c.id.uuidString {
                ProfileStore.homeCourseID = ""
            }

            CourseLibrary.shared.delete(id: c.id)

            // Refresh arrays (use whatever your existing refresh method is)
            self.reloadCourses()          // <-- you likely already have something like this
            self.tableView.reloadData()
        })

        present(ac, animated: true)
    }
    private func reloadCourses() {
        CourseLibrary.shared.seedIfNeeded()
        all = CourseLibrary.shared.allSorted()

        // keep your WolfMore CC pin-to-top if you want
        if let idx = all.firstIndex(where: { $0.name.caseInsensitiveCompare("WolfMore") == .orderedSame }) {
            let b = all.remove(at: idx)
            all.insert(b, at: 0)
        }

        // Rebuild filtered from the current search text
        let q = (searchController.searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        if q.isEmpty {
            filtered.removeAll()
            // DON'T touch isSearching (it's computed)
        } else {
            filtered = all.filter { $0.name.localizedCaseInsensitiveContains(q) }
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        let q = (searchController.searchBar.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if q.isEmpty {
            filtered = all
        } else {
            filtered = all.filter { $0.name.lowercased().contains(q) }
        }
        tableView.reloadData()
    }
}
