import UIKit

protocol CourseSearchDelegate: AnyObject {
    func courseSearchDidImport(_ course: CourseProfile)
}

/// Search OpenGolfAPI for a course to import into the local library.
final class CourseSearchViewController: UITableViewController {

    weak var delegate: CourseSearchDelegate?

    private let searchController = UISearchController(searchResultsController: nil)
    private var results: [OpenGolfSearchResult] = []
    private var searchTask: Task<Void, Never>?
    private var isLoading = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Search Courses"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.estimatedRowHeight = 60

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search by name or location"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))

        tableView.tableFooterView = attributionFooter()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchController.isActive = true
        DispatchQueue.main.async { self.searchController.searchBar.becomeFirstResponder() }
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    // MARK: - Attribution

    private func attributionFooter() -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "Golf course data © OpenStreetMap contributors"
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
        let tap = UITapGestureRecognizer(target: self, action: #selector(attributionTapped))
        container.addGestureRecognizer(tap)
        return container
    }

    @objc private func attributionTapped() {
        UIApplication.shared.open(URL(string: "https://www.openstreetmap.org/copyright")!)
    }

    // MARK: - Search

    private func runSearch(_ query: String) {
        searchTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            tableView.reloadData()
            return
        }
        isLoading = true
        tableView.reloadData()

        searchTask = Task {
            do {
                let items = try await OpenGolfAPIService.shared.search(query: query)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.isLoading = false
                    self.results = items
                    self.tableView.reloadData()
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.isLoading = false
                    self.results = []
                    self.tableView.reloadData()
                }
            }
        }
    }

    // MARK: - Table

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        isLoading ? 1 : results.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if isLoading {
            var cfg = cell.defaultContentConfiguration()
            cfg.text = "Searching…"
            cfg.textProperties.color = .secondaryLabel
            cell.contentConfiguration = cfg
            cell.selectionStyle = .none
            return cell
        }
        let r = results[indexPath.row]
        var cfg = cell.defaultContentConfiguration()
        cfg.text = r.name
        let loc = r.locationLabel
        if !loc.isEmpty {
            cfg.secondaryText = loc
        }
        cell.contentConfiguration = cfg
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !isLoading else { return }
        let result = results[indexPath.row]
        let vc = CourseImportViewController(searchResult: result)
        vc.delegate = delegate
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension CourseSearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let q = searchController.searchBar.text ?? ""
        searchTask?.cancel()
        guard !q.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            isLoading = false
            tableView.reloadData()
            return
        }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run { self.runSearch(q) }
        }
    }
}
