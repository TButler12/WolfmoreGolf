import UIKit

final class WolfScorecardPreviewViewController: UIViewController {

    private let image: UIImage

    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    private let scrollView  = UIScrollView()
    private let imageView   = UIImageView()
    private let shareBtn    = UIButton(type: .system)
    private weak var rotateBtn: UIButton?

    private var imageHeightConstraint: NSLayoutConstraint?
    private var isLandscape = false

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        isLandscape ? .landscape : .portrait
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isLandscape { requestOrientation(.portrait) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        buildLayout()
    }

    // MARK: - Layout

    private func buildLayout() {

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Scorecard"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // Close button
        let closeBtn = UIButton(type: .system)
        let closeImg = UIImage(systemName: "xmark.circle.fill",
                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 24))
        closeBtn.setImage(closeImg, for: .normal)
        closeBtn.tintColor = .secondaryLabel
        closeBtn.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeBtn)

        // Scroll view + image
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.bouncesZoom = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)
        view.addSubview(scrollView)

        // Share button
        shareBtn.setTitle("Share", for: .normal)
        shareBtn.setTitleColor(.white, for: .normal)
        shareBtn.backgroundColor = UIColor(red: 0.08, green: 0.24, blue: 0.50, alpha: 1)
        shareBtn.layer.cornerRadius = 14
        shareBtn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        shareBtn.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        shareBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shareBtn)

        let guide = view.safeAreaLayoutGuide

        // Image height — placeholder updated in viewDidLayoutSubviews
        let hc = imageView.heightAnchor.constraint(equalToConstant: 200)
        hc.isActive = true
        imageHeightConstraint = hc

        // Rotate pill
        var rotCfg = UIButton.Configuration.filled()
        rotCfg.title = "Landscape"
        rotCfg.image = UIImage(systemName: "rotate.right")
        rotCfg.imagePadding = 6
        rotCfg.baseBackgroundColor = UIColor.secondarySystemGroupedBackground
        rotCfg.baseForegroundColor = .label
        rotCfg.cornerStyle = .capsule
        rotCfg.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 14, bottom: 7, trailing: 14)
        let rotBtn = UIButton(configuration: rotCfg)
        rotBtn.addTarget(self, action: #selector(rotateTapped), for: .touchUpInside)
        rotBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rotBtn)
        rotateBtn = rotBtn

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: guide.topAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            closeBtn.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeBtn.widthAnchor.constraint(equalToConstant: 32),
            closeBtn.heightAnchor.constraint(equalToConstant: 32),

            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: shareBtn.topAnchor, constant: -12),

            // imageView fills scroll view width; height set from aspect ratio
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            shareBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            shareBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            shareBtn.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -14),
            shareBtn.heightAnchor.constraint(equalToConstant: 52),

            rotBtn.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),
            rotBtn.bottomAnchor.constraint(equalTo: shareBtn.topAnchor, constant: -12),
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let w = scrollView.bounds.width
        guard w > 0, image.size.width > 0 else { return }
        imageHeightConstraint?.constant = w * (image.size.height / image.size.width)
    }

    // MARK: - Actions

    @objc private func rotateTapped() {
        isLandscape.toggle()
        var config = UIButton.Configuration.filled()
        config.title = isLandscape ? "Portrait" : "Landscape"
        config.image = UIImage(systemName: isLandscape ? "arrow.counterclockwise" : "rotate.right")
        config.imagePadding = 6
        config.baseBackgroundColor = UIColor.secondarySystemGroupedBackground
        config.baseForegroundColor = .label
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 14, bottom: 7, trailing: 14)
        rotateBtn?.configuration = config
        setNeedsUpdateOfSupportedInterfaceOrientations()
        requestOrientation(isLandscape ? .landscape : .portrait)
    }

    private func requestOrientation(_ mask: UIInterfaceOrientationMask) {
        guard let scene = view.window?.windowScene else { return }
        let prefs = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: mask)
        scene.requestGeometryUpdate(prefs) { _ in }
    }

    @objc private func doneTapped() { dismiss(animated: true) }

    @objc private func shareTapped() {
        let ac = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let pop = ac.popoverPresentationController {
            pop.sourceView = shareBtn
            pop.sourceRect = shareBtn.bounds
        }
        present(ac, animated: true)
    }
}

// MARK: - UIScrollViewDelegate

extension WolfScorecardPreviewViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // Keep the image centered when zoomed smaller than the scroll view
        let offsetX = max((scrollView.bounds.width  - scrollView.contentSize.width)  / 2, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) / 2, 0)
        imageView.center = CGPoint(
            x: scrollView.contentSize.width  / 2 + offsetX,
            y: scrollView.contentSize.height / 2 + offsetY
        )
    }
}
