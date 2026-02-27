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

    // Search
    private let searchController = UISearchController(searchResultsController: nil)
    private var searchText: String {
        (searchController.searchBar.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var isSearching: Bool { !searchText.isEmpty }

    // Home course star
    private var homeCourseUUID: UUID? {
        let s = ProfileStore.homeCourseID.trimmingCharacters(in: .whitespacesAndNewlines)
        return UUID(uuidString: s)
    }

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

        configureSearch()
        reloadCourses()
    }

    private func configureSearch() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search courses"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    // MARK: - Data

    private func reloadCourses() {
        all = CourseLibrary.shared.allSorted()

        // Optional: keep WolfMore pinned to top
        if let idx = all.firstIndex(where: { $0.name.caseInsensitiveCompare("WolfMore") == .orderedSame }) {
            let b = all.remove(at: idx)
            all.insert(b, at: 0)
        }

        applyFilter()
    }

    private func applyFilter() {
        if searchText.isEmpty {
            filtered = all
        } else {
            let q = searchText.lowercased()
            filtered = all.filter { $0.name.lowercased().contains(q) }
        }
        tableView.reloadData()
    }

    private func setHomeCourse(_ id: UUID) {
        ProfileStore.homeCourseID = id.uuidString
    }

    // MARK: - Actions

    @objc private func cancelTapped() { dismiss(animated: true) }
    @objc private func addTapped() { onTapAddCourse?() }

    // MARK: - UITableView

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filtered.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        let c = filtered[indexPath.row]

        cell.textLabel?.text = c.name

        // ✓ Selected course
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

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)
        let c = filtered[indexPath.row]
        onPickCourse?(c.id)
    }

    // Swipe actions: Home ⭐, Edit ✏️, Delete 🗑️
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {

        let c = filtered[indexPath.row]

        // ⭐ Home
        let home = UIContextualAction(style: .normal, title: "Home") { [weak self] _, _, done in
            self?.setHomeCourse(c.id)
            tableView.reloadData()
            done(true)
        }
        home.backgroundColor = .systemYellow
        home.image = UIImage(systemName: "star.fill")

        // ✏️ Edit
        let edit = UIContextualAction(style: .normal, title: "View/Edit") { [weak self] _, _, done in
            self?.editCourse(c)
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

            self.confirmDeleteCourse(c)
            done(true)
        }
        delete.image = UIImage(systemName: "trash")

        let config = UISwipeActionsConfiguration(actions: [delete, edit, home])
        config.performsFirstActionWithFullSwipe = false
        return config
    }

    // MARK: - Edit / Delete helpers

    private func editCourse(_ c: CourseProfile) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "CourseSetupVC") as! CourseSetupViewController
        vc.loadCourseID = c.id   // `var loadCourseID: UUID?` in CourseSetupVC
        navigationController?.pushViewController(vc, animated: true)
    }

    private func confirmDeleteCourse(_ c: CourseProfile) {
        if c.name.caseInsensitiveCompare("WolfMore") == .orderedSame {
            let ac = UIAlertController(
                title: "Can’t Delete",
                message: "WolfMore is the built-in default.",
                preferredStyle: .alert
            )
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
            guard let self else { return }

            if ProfileStore.homeCourseID == c.id.uuidString {
                ProfileStore.homeCourseID = ""
            }

            CourseLibrary.shared.delete(id: c.id)
            self.reloadCourses()
        })

        present(ac, animated: true)
    }

    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        applyFilter()
    }
}
