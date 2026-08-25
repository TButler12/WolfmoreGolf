import UIKit

// MARK: - TournamentScorecardViewController

final class TournamentScorecardViewController: UIViewController {

    private let game: GameData

    private let scrollView = UIScrollView()
    private let imageView  = UIImageView()
    private weak var rotateBtn: UIButton?
    private var imageHeightConstraint: NSLayoutConstraint?
    private var isLandscape = false

    init(game: GameData) {
        self.game = game
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        isLandscape ? .landscape : .portrait
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isLandscape { requestOrientation(.portrait) }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Scorecard"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(doneTapped)
        )
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action, target: self, action: #selector(shareTapped)
        )
        buildUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let img = imageView.image, img.size.width > 0 else { return }
        let w = scrollView.bounds.width
        guard w > 0 else { return }
        imageHeightConstraint?.constant = w * (img.size.height / img.size.width)
    }

    // MARK: - Actions

    @objc private func doneTapped() { dismiss(animated: true) }

    @objc private func shareTapped() {
        let image = TournamentScorecardRenderer(game: game, filledHoles: computeFilledHoles()).render()
        let av = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let pop = av.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        present(av, animated: true)
    }

    @objc private func rotateTapped() {
        isLandscape.toggle()
        updateRotateButton()
        setNeedsUpdateOfSupportedInterfaceOrientations()
        requestOrientation(isLandscape ? .landscape : .portrait)
    }

    // MARK: - Helpers

    private func requestOrientation(_ mask: UIInterfaceOrientationMask) {
        guard let scene = view.window?.windowScene else { return }
        let prefs = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: mask)
        scene.requestGeometryUpdate(prefs) { _ in }
    }

    private func updateRotateButton() {
        var config = UIButton.Configuration.filled()
        config.title = isLandscape ? "Portrait" : "Landscape"
        config.image = UIImage(systemName: isLandscape ? "arrow.counterclockwise" : "rotate.right")
        config.imagePadding = 6
        config.baseBackgroundColor = UIColor.secondarySystemGroupedBackground
        config.baseForegroundColor = .label
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 14, bottom: 7, trailing: 14)
        rotateBtn?.configuration = config
    }

    private func computeFilledHoles() -> Range<Int> {
        let committed = game.holeCommitted
        if !committed.isEmpty {
            var maxCommitted = -1
            for h in 0..<min(committed.count, STANDARD_HOLES) {
                if committed[h] { maxCommitted = h }
            }
            if maxCommitted >= 0 { return 0..<(maxCommitted + 1) }
        }
        let cap = min(game.playerNames.count, game.playerActivated.count)
        var maxFilled = -1
        for seat in 0..<cap {
            guard game.playerActivated[seat], seat < game.scores.count else { continue }
            for h in 0..<STANDARD_HOLES where h < game.scores[seat].count {
                if game.scores[seat][h] != nil { maxFilled = max(maxFilled, h) }
            }
        }
        return maxFilled >= 0 ? 0..<(maxFilled + 1) : 0..<0
    }

    // MARK: - UI

    private func buildUI() {
        let image = TournamentScorecardRenderer(game: game, filledHoles: computeFilledHoles()).render()

        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.bouncesZoom = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)
        view.addSubview(scrollView)

        // Rotate pill
        var config = UIButton.Configuration.filled()
        config.title = "Landscape"
        config.image = UIImage(systemName: "rotate.right")
        config.imagePadding = 6
        config.baseBackgroundColor = UIColor.secondarySystemGroupedBackground
        config.baseForegroundColor = .label
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 14, bottom: 7, trailing: 14)
        let btn = UIButton(configuration: config)
        btn.addTarget(self, action: #selector(rotateTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(btn)
        rotateBtn = btn

        let hc = imageView.heightAnchor.constraint(equalToConstant: 400)
        hc.isActive = true
        imageHeightConstraint = hc

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: guide.topAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),

            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            btn.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),
            btn.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -16),
        ])
    }
}

// MARK: - UIScrollViewDelegate

extension TournamentScorecardViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = max((scrollView.bounds.width  - scrollView.contentSize.width)  / 2, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) / 2, 0)
        imageView.center = CGPoint(
            x: scrollView.contentSize.width  / 2 + offsetX,
            y: scrollView.contentSize.height / 2 + offsetY
        )
    }
}
