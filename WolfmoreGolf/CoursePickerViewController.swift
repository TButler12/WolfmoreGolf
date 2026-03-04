//
//
//  //
//  //
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
    
    // Sections (e.g., "IL", "WI", "FL", "Ireland", "Northern Ireland")
    private var sections: [(title: String, items: [CourseProfile])] = []
    
    // Search
    private let searchController = UISearchController(searchResultsController: nil)
    private var searchText: String {
        (searchController.searchBar.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
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
        
        // Keep WolfMore at top of its section later
        applyFilter()
    }
    
    private func applyFilter() {
        if searchText.isEmpty {
            filtered = all
        } else {
            let q = searchText.lowercased()
            filtered = all.filter { $0.name.lowercased().contains(q) }
        }
        
        buildSections()
        tableView.reloadData()
    }
    
    // MARK: - Grouping
    
    private func isUSA(_ country: String?) -> Bool {
        let t = (country ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return true } // treat nil as USA default in your app
        return t.caseInsensitiveCompare("USA") == .orderedSame
        || t.caseInsensitiveCompare("United States") == .orderedSame
        || t.caseInsensitiveCompare("United States of America") == .orderedSame
    }
    
    private func sectionTitle(for c: CourseProfile) -> String {
        if isUSA(c.country) {
            let st = (c.state ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return st.isEmpty ? "USA (No State)" : st
        } else {
            let ct = (c.country ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return ct.isEmpty ? "International" : ct
        }
    }
    
    
    private func buildSections() {
        
        let grouped = Dictionary(grouping: filtered, by: sectionTitle(for:))
        
        var built: [(title: String, items: [CourseProfile])] = grouped.map { title, items in
            let sortedItems = items.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            return (title: title, items: sortedItems)
        }
        
        // Pin WolfMore to top of its section
        for i in built.indices {
            if let idx = built[i].items.firstIndex(where: {
                $0.name.caseInsensitiveCompare("WolfMore") == .orderedSame
            }) {
                let w = built[i].items.remove(at: idx)
                built[i].items.insert(w, at: 0)
            }
        }
        
        // 🔥 THIS is the important part:
        built.sort { a, b in
            
            let aIsUSAState = isUSAStateTitle(a.title)
            let bIsUSAState = isUSAStateTitle(b.title)
            
            // USA states always first
            if aIsUSAState != bIsUSAState {
                return aIsUSAState && !bIsUSAState
            }
            
            // Alphabetical inside their group
            return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
        }
        
        sections = built
    }
    private func isUSAStateTitle(_ title: String) -> Bool {
        // If it's 2 letters and not "USA (No State)", treat as state
        return title.count == 2 && title != "USA (No State)"
    }
    private func course(at indexPath: IndexPath) -> CourseProfile {
        sections[indexPath.section].items[indexPath.row]
    }
    
    private func setHomeCourse(_ id: UUID) {
        ProfileStore.homeCourseID = id.uuidString
    }
    
    // MARK: - Actions
    
    @objc private func cancelTapped() { dismiss(animated: true) }
    @objc private func addTapped() { onTapAddCourse?() }
    
    // MARK: - UITableView
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let reuseID = "CourseCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseID)
        ?? UITableViewCell(style: .default, reuseIdentifier: reuseID)
        
        let c = course(at: indexPath)
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
        let c = course(at: indexPath)
        onPickCourse?(c.id)
    }
    
    // Swipe actions: Home ⭐, Edit ✏️, Delete 🗑️
    // Swipe actions: Home ⭐, Edit ✏️, Delete 🗑️
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        
        let c = course(at: indexPath)
        
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
                ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    done(false)
                })
                self.present(ac, animated: true)
                return
            }
            
            self.confirmDeleteCourse(c) { didDelete in
                done(didDelete) // ✅ only completes swipe after user decides
            }
        }
        delete.image = UIImage(systemName: "trash")
        
        let config = UISwipeActionsConfiguration(actions: [delete, edit, home])
        config.performsFirstActionWithFullSwipe = false
        return config
    }  // ✅ YOU WERE MISSING THIS BRACE
    
    
    // MARK: - Edit / Delete helpers
    
    private func editCourse(_ c: CourseProfile) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "CourseSetupVC") as! CourseSetupViewController
        vc.loadCourseID = c.id
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func confirmDeleteCourse(_ c: CourseProfile, completion: @escaping (Bool) -> Void) {
        
        if c.name.caseInsensitiveCompare("WolfMore") == .orderedSame {
            let ac = UIAlertController(
                title: "Can’t Delete",
                message: "WolfMore is the built-in default.",
                preferredStyle: .alert
            )
            ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completion(false)
            })
            present(ac, animated: true)
            return
        }
        
        let ac = UIAlertController(
            title: "Delete \(c.name)?",
            message: "This removes the course from your device.",
            preferredStyle: .alert
        )
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(false)
        })
        
        ac.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self else { completion(false); return }
            
            if ProfileStore.homeCourseID == c.id.uuidString {
                ProfileStore.homeCourseID = ""
            }
            
            CourseLibrary.shared.delete(id: c.id)
            self.reloadCourses()
            completion(true)
        })
        
        present(ac, animated: true)
    }
    
    
    // MARK: - UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        applyFilter()
    }
}
