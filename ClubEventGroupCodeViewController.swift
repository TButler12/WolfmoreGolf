import UIKit
import CoreImage

/// Shows the generated 6-character group code and QR after a scorer finishes group setup.
/// Push onto the navigation stack; "Done" pops to root (dismisses the whole join flow).
final class ClubEventGroupCodeViewController: UIViewController {

    private let groupCode:    String
    private let eventCode:    String
    private let eventName:    String
    private var players:      [ClubEventGroupPlayer]
    private let tournamentId: UUID
    private let startingHole: Int
    private let courseName:   String?

    private var releaseRowStack: UIStackView?

    init(groupCode:    String,
         eventCode:    String,
         eventName:    String,
         players:      [ClubEventGroupPlayer],
         tournamentId: UUID,
         startingHole: Int,
         courseName:   String? = nil) {
        self.groupCode    = groupCode
        self.eventCode    = eventCode
        self.eventName    = eventName
        self.players      = players
        self.tournamentId = tournamentId
        self.startingHole = startingHole
        self.courseName   = courseName
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Group Code"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done", style: .done, target: self, action: #selector(doneTapped))
        buildUI()
    }

    // MARK: - Layout

    private func buildUI() {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
        ])

        // ── Instruction label ──────────────────────────────────────────────────
        let instrLabel = UILabel()
        instrLabel.text = "Show this code to your scoring partner. They can enter it on their device to take over at any time."
        instrLabel.font = .preferredFont(forTextStyle: .subheadline)
        instrLabel.adjustsFontForContentSizeCategory = true
        instrLabel.textColor = .secondaryLabel
        instrLabel.textAlignment = .center
        instrLabel.numberOfLines = 0
        instrLabel.translatesAutoresizingMaskIntoConstraints = false

        // ── Code card ──────────────────────────────────────────────────────────
        let card = UIView()
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 16
        card.layer.shadowColor  = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.08
        card.layer.shadowRadius  = 8
        card.layer.shadowOffset  = CGSize(width: 0, height: 2)
        card.translatesAutoresizingMaskIntoConstraints = false

        let codeLabel = UILabel()
        codeLabel.text          = groupCode
        codeLabel.font          = UIFont.monospacedSystemFont(ofSize: 52, weight: .bold)
        codeLabel.textColor     = .label
        codeLabel.textAlignment = .center
        codeLabel.adjustsFontSizeToFitWidth = true
        codeLabel.minimumScaleFactor = 0.6
        codeLabel.translatesAutoresizingMaskIntoConstraints = false

        // ── QR code ────────────────────────────────────────────────────────────
        let qrView = UIImageView(image: makeQRImage(for: groupCode, size: 220))
        qrView.contentMode                    = .scaleAspectFit
        qrView.layer.cornerRadius             = 8
        qrView.layer.masksToBounds            = true
        qrView.backgroundColor                = .white
        qrView.translatesAutoresizingMaskIntoConstraints = false
        qrView.accessibilityLabel             = "QR code for group \(groupCode)"

        // ── Players summary ────────────────────────────────────────────────────
        let playerText = players.isEmpty ? "" : players.map { $0.name }.joined(separator: "  ·  ")
        let playersLabel = UILabel()
        playersLabel.text          = playerText
        playersLabel.font          = .preferredFont(forTextStyle: .footnote)
        playersLabel.adjustsFontForContentSizeCategory = true
        playersLabel.textColor     = .secondaryLabel
        playersLabel.textAlignment = .center
        playersLabel.numberOfLines = 0
        playersLabel.translatesAutoresizingMaskIntoConstraints = false

        // ── Share button ───────────────────────────────────────────────────────
        var shareCfg = UIButton.Configuration.filled()
        shareCfg.baseBackgroundColor = UIColor(red: 0.10, green: 0.42, blue: 0.42, alpha: 1.0)
        shareCfg.baseForegroundColor = .white
        shareCfg.cornerStyle         = .large
        shareCfg.contentInsets       = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        shareCfg.title               = "Share Code"
        shareCfg.image               = UIImage(systemName: "square.and.arrow.up")
        shareCfg.imagePadding        = 8
        let shareBtn = UIButton(configuration: shareCfg)
        shareBtn.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        shareBtn.translatesAutoresizingMaskIntoConstraints = false
        shareBtn.heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true

        // ── Start Scoring button ───────────────────────────────────────────────
        var scoringCfg = UIButton.Configuration.filled()
        scoringCfg.baseBackgroundColor = UIColor(red: 0.18, green: 0.55, blue: 0.34, alpha: 1.0)
        scoringCfg.baseForegroundColor = .white
        scoringCfg.cornerStyle         = .large
        scoringCfg.contentInsets       = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        scoringCfg.title               = "Start Scoring"
        scoringCfg.image               = UIImage(systemName: "flag.fill")
        scoringCfg.imagePadding        = 8
        let scoringBtn = UIButton(configuration: scoringCfg)
        scoringBtn.addTarget(self, action: #selector(startScoringTapped), for: .touchUpInside)
        scoringBtn.translatesAutoresizingMaskIntoConstraints = false
        scoringBtn.heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true

        // ── Players section ────────────────────────────────────────────────────
        let playersSectionLabel = UILabel()
        playersSectionLabel.text      = "PLAYERS"
        playersSectionLabel.font      = .preferredFont(forTextStyle: .footnote)
        playersSectionLabel.textColor = .secondaryLabel
        playersSectionLabel.translatesAutoresizingMaskIntoConstraints = false

        let playerRowsStack = UIStackView()
        playerRowsStack.axis    = .vertical
        playerRowsStack.spacing = 0
        playerRowsStack.translatesAutoresizingMaskIntoConstraints = false
        playerRowsStack.layer.cornerRadius = 12
        playerRowsStack.layer.masksToBounds = true
        self.releaseRowStack = playerRowsStack
        rebuildPlayerRows(in: playerRowsStack)

        // ── Assemble card ──────────────────────────────────────────────────────
        [codeLabel, qrView, playersLabel].forEach { card.addSubview($0) }
        [instrLabel, card, shareBtn, scoringBtn, playersSectionLabel, playerRowsStack]
            .forEach { content.addSubview($0) }

        NSLayoutConstraint.activate([
            instrLabel.topAnchor.constraint(equalTo: content.topAnchor, constant: 24),
            instrLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
            instrLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),

            card.topAnchor.constraint(equalTo: instrLabel.bottomAnchor, constant: 24),
            card.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            card.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),

            codeLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 28),
            codeLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            codeLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),

            qrView.topAnchor.constraint(equalTo: codeLabel.bottomAnchor, constant: 20),
            qrView.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            qrView.widthAnchor.constraint(equalToConstant: 220),
            qrView.heightAnchor.constraint(equalToConstant: 220),

            playersLabel.topAnchor.constraint(equalTo: qrView.bottomAnchor, constant: 16),
            playersLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            playersLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            playersLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24),

            shareBtn.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 24),
            shareBtn.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            shareBtn.widthAnchor.constraint(lessThanOrEqualTo: content.widthAnchor, constant: -40),

            scoringBtn.topAnchor.constraint(equalTo: shareBtn.bottomAnchor, constant: 12),
            scoringBtn.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            scoringBtn.widthAnchor.constraint(lessThanOrEqualTo: content.widthAnchor, constant: -40),

            playersSectionLabel.topAnchor.constraint(equalTo: scoringBtn.bottomAnchor, constant: 32),
            playersSectionLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),

            playerRowsStack.topAnchor.constraint(equalTo: playersSectionLabel.bottomAnchor, constant: 8),
            playerRowsStack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            playerRowsStack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            playerRowsStack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -32),
        ])
    }

    private func rebuildPlayerRows(in stack: UIStackView) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (i, player) in players.enumerated() {
            let row = makePlayerRow(player: player, isLast: i == players.count - 1)
            stack.addArrangedSubview(row)
        }
    }

    private func makePlayerRow(player: ClubEventGroupPlayer, isLast: Bool) -> UIView {
        let container = UIView()
        container.backgroundColor = .systemBackground

        let nameLabel = UILabel()
        nameLabel.text = player.name
        nameLabel.font = .preferredFont(forTextStyle: .body)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let teamLabel = UILabel()
        teamLabel.text = "Team \(player.teams.sorted().joined(separator: " & "))"
        teamLabel.font = .preferredFont(forTextStyle: .footnote)
        teamLabel.textColor = .secondaryLabel
        teamLabel.translatesAutoresizingMaskIntoConstraints = false

        let releaseBtn = UIButton(type: .system)
        releaseBtn.setTitle("Release", for: .normal)
        releaseBtn.setTitleColor(.systemRed, for: .normal)
        releaseBtn.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        releaseBtn.translatesAutoresizingMaskIntoConstraints = false

        releaseBtn.addAction(UIAction { [weak self] _ in
            self?.confirmRelease(player: player)
        }, for: .touchUpInside)

        let nameStack = UIStackView(arrangedSubviews: [nameLabel, teamLabel])
        nameStack.axis    = .vertical
        nameStack.spacing = 2
        nameStack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(nameStack)
        container.addSubview(releaseBtn)

        if !isLast {
            let sep = UIView()
            sep.backgroundColor = .separator
            sep.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(sep)
            NSLayoutConstraint.activate([
                sep.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
                sep.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                sep.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                sep.heightAnchor.constraint(equalToConstant: 0.5),
            ])
        }

        NSLayoutConstraint.activate([
            nameStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            nameStack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            nameStack.trailingAnchor.constraint(lessThanOrEqualTo: releaseBtn.leadingAnchor, constant: -8),

            releaseBtn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            releaseBtn.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 52),
        ])
        return container
    }

    // MARK: - Actions

    @objc private func doneTapped() {
        navigationController?.popToRootViewController(animated: true)
    }

    @objc private func shareTapped() {
        let text = "My group code for \(eventName): \(groupCode)"
        let vc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        vc.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(vc, animated: true)
    }

    @objc private func startScoringTapped() {
        ClubEventSessionStore.shared.save(ClubEventSession(
            eventId:      tournamentId,
            eventCode:    eventCode,
            eventName:    eventName,
            courseName:   courseName,
            groupCode:    groupCode,
            startingHole: startingHole,
            playerIds:    players.map { $0.id }
        ))
        let vc = ClubEventScoringViewController(
            tournamentId: tournamentId,
            groupCode:    groupCode,
            startingHole: startingHole,
            eventName:    eventName,
            courseName:   courseName,
            players:      players
        )
        navigationController?.pushViewController(vc, animated: true)
    }

    private func confirmRelease(player: ClubEventGroupPlayer) {
        let ac = UIAlertController(
            title: "Release \(player.name)?",
            message: "They will return to the available roster. This cannot be undone if scores exist.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Release", style: .destructive) { [weak self] _ in
            self?.releasePlayer(player)
        })
        present(ac, animated: true)
    }

    private func releasePlayer(_ player: ClubEventGroupPlayer) {
        let loading = UIAlertController(title: nil, message: "Releasing…", preferredStyle: .alert)
        present(loading, animated: true)
        Task {
            do {
                try await SupabaseService.shared.releaseClubEventPlayer(
                    playerId: player.id, groupCode: groupCode)
                await MainActor.run {
                    loading.dismiss(animated: false) {
                        // Pop back to group setup so the scorer can re-select
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    loading.dismiss(animated: false) {
                        let err = UIAlertController(
                            title: "Could Not Release",
                            message: error.localizedDescription,
                            preferredStyle: .alert)
                        err.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(err, animated: true)
                    }
                }
            }
        }
    }

    // MARK: - QR generation

    private func makeQRImage(for string: String, size: CGFloat) -> UIImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(Data(string.utf8), forKey: "inputMessage")
        filter.setValue("M",              forKey: "inputCorrectionLevel")
        guard let raw = filter.outputImage else { return nil }
        let scale  = size / raw.extent.width
        let scaled = raw.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let ctx    = CIContext()
        guard let cg = ctx.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}
