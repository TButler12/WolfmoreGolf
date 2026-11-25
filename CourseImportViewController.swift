import UIKit

/// Shows holes for a selected OpenGolfAPI course, validates the data, and lets the user add it.
final class CourseImportViewController: UITableViewController {

    weak var delegate: CourseSearchDelegate?

    private let searchResult: OpenGolfSearchResult
    private var holes: [OpenGolfHoleData] = []
    private var validationError: CourseValidationError?
    private var isLoading = true

    private enum Section: Int, CaseIterable {
        case status, holes
    }

    init(searchResult: OpenGolfSearchResult) {
        self.searchResult = searchResult
        super.init(style: .insetGrouped)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = searchResult.name
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.estimatedRowHeight = 44
        navigationItem.largeTitleDisplayMode = .never

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Add", style: .done, target: self, action: #selector(addTapped))
        navigationItem.rightBarButtonItem?.isEnabled = false

        tableView.tableFooterView = attributionFooter()

        fetchHoles()
    }

    // MARK: - Fetch

    private func fetchHoles() {
        Task {
            do {
                let raw = try await OpenGolfAPIService.shared.holes(courseId: searchResult.id)
                await MainActor.run { self.applyHoles(raw) }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.validationError = nil
                    self.tableView.reloadData()
                    self.showAlert("Could not load hole data.\n\n\(error.localizedDescription)")
                }
            }
        }
    }

    private func applyHoles(_ raw: [OpenGolfHoleData]) {
        isLoading = false
        holes = raw.sorted { $0.holeNumber < $1.holeNumber }

        switch CourseValidator.buildArrays(from: holes, expectedCount: holes.count) {
        case .success:
            validationError = nil
            navigationItem.rightBarButtonItem?.isEnabled = true
        case .failure(let err):
            validationError = err
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
        tableView.reloadData()
    }

    // MARK: - Add

    @objc private func addTapped() {
        guard validationError == nil, !holes.isEmpty else { return }
        let pars = holes.map { $0.par }
        let hcs  = holes.map { $0.handicapIndex! }

        let profile = CourseLibrary.shared.importOpenGolfCourse(
            apiId:   searchResult.id,
            name:    searchResult.name,
            city:    searchResult.city,
            state:   searchResult.state,
            country: searchResult.country,
            pars:    pars,
            handicaps: hcs
        )

        delegate?.courseSearchDidImport(profile)

        let ac = UIAlertController(
            title: "Course Added",
            message: "\(searchResult.name) is now in My Courses.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popToRootViewController(animated: true)
        })
        present(ac, animated: true)
    }

    // MARK: - Attribution

    private func attributionFooter() -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
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

    private func showAlert(_ message: String) {
        let ac = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    // MARK: - Table

    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .status: return 1
        case .holes:  return isLoading ? 0 : holes.count
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard Section(rawValue: section) == .holes, !holes.isEmpty else { return nil }
        return "Holes"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.selectionStyle = .none

        switch Section(rawValue: indexPath.section)! {
        case .status:
            var cfg = cell.defaultContentConfiguration()
            if isLoading {
                cfg.text = "Loading holes…"
                cfg.textProperties.color = .secondaryLabel
            } else if let err = validationError {
                cfg.text = "Cannot import"
                cfg.secondaryText = err.localizedDescription
                cfg.textProperties.color = .systemRed
            } else {
                cfg.text = "\(holes.count) holes — ready to add"
                cfg.textProperties.color = .systemGreen
            }
            cell.contentConfiguration = cfg

        case .holes:
            let hole = holes[indexPath.row]
            var cfg = cell.defaultContentConfiguration()
            cfg.text = "Hole \(hole.holeNumber)"
            var parts = ["Par \(hole.par)"]
            if let hc = hole.handicapIndex { parts.append("HC \(hc)") }
            cfg.secondaryText = parts.joined(separator: "  ·  ")
            cell.contentConfiguration = cfg
        }
        return cell
    }
}
