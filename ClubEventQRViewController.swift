import UIKit
import CoreImage

final class ClubEventQRViewController: UIViewController {

    private let code: String
    private let joinURL: String
    private var previousBrightness: CGFloat = UIScreen.main.brightness

    init(code: String) {
        self.code    = code.uppercased()
        self.joinURL = ShareLinks.joinClubEvent(code: code)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle   = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        let qrImage = makeQRImage(from: joinURL, size: 320)
        let iv = UIImageView(image: qrImage)
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false

        let codeLabel = UILabel()
        codeLabel.text = code
        codeLabel.font = .monospacedSystemFont(ofSize: 36, weight: .bold)
        codeLabel.textColor = .label
        codeLabel.textAlignment = .center
        codeLabel.isUserInteractionEnabled = true
        codeLabel.translatesAutoresizingMaskIntoConstraints = false

        let tapGR = UITapGestureRecognizer(target: self, action: #selector(codeTapped))
        codeLabel.addGestureRecognizer(tapGR)

        let hintLabel = UILabel()
        hintLabel.text = "Tap code to copy"
        hintLabel.font = .preferredFont(forTextStyle: .caption1)
        hintLabel.textColor = .secondaryLabel
        hintLabel.textAlignment = .center
        hintLabel.translatesAutoresizingMaskIntoConstraints = false

        let closeBtn = UIButton(type: .system)
        closeBtn.setTitle("Close", for: .normal)
        closeBtn.titleLabel?.font = .preferredFont(forTextStyle: .body)
        closeBtn.addTarget(self, action: #selector(close), for: .touchUpInside)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(iv)
        view.addSubview(codeLabel)
        view.addSubview(hintLabel)
        view.addSubview(closeBtn)

        NSLayoutConstraint.activate([
            iv.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iv.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            iv.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.80),
            iv.heightAnchor.constraint(equalTo: iv.widthAnchor),

            codeLabel.topAnchor.constraint(equalTo: iv.bottomAnchor, constant: 20),
            codeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            codeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            hintLabel.topAnchor.constraint(equalTo: codeLabel.bottomAnchor, constant: 4),
            hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            closeBtn.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 24),
            closeBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previousBrightness = UIScreen.main.brightness
        UIScreen.main.brightness = 1.0
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIScreen.main.brightness = previousBrightness
    }

    // MARK: - Actions

    @objc private func codeTapped() {
        UIPasteboard.general.string = code
        let alert = UIAlertController(title: nil, message: "Code copied", preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { alert.dismiss(animated: true) }
    }

    @objc private func close() { dismiss(animated: true) }

    // MARK: - QR generation

    private func makeQRImage(from string: String, size: CGFloat) -> UIImage? {
        guard let data = string.data(using: .ascii),
              let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let raw = filter.outputImage else { return nil }
        let scale = size / raw.extent.width
        let scaled = raw.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let bg = CIImage(color: CIColor.white).cropped(to: scaled.extent)
        let composed = scaled.composited(over: bg)
        guard let cgImage = CIContext().createCGImage(composed, from: composed.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
