//
//  ViewController.swift
//  Wolfmore
//
//  Created by Tom BUTLER on 9/24/25.
//
import UIKit
import MessageUI

final class ViewController: UIViewController, MFMailComposeViewControllerDelegate {

    // MARK: - Layout references (programmatic)
    private weak var headerCourseButton: UIButton?
    private weak var headerArchitectLabel: UILabel?
    private weak var headerStatsLabel: UILabel?
    private weak var headerNameLabel: UILabel?
    private weak var inProgressCard: UIView?
    private weak var inProgressCaptionLabel: UILabel?
    private weak var inProgressTitleLabel: UILabel?
    private weak var inProgressDetailLabel: UILabel?
    private weak var inProgressChipsRow: UIStackView?
    private weak var resetBannerCard: UIView?
    private weak var resetBannerLabel: UILabel?
    private var resetBannerDismissedThisVisit = false
    private weak var tournamentInfoCard: UIView?
    private weak var tournamentInfoNameLabel: UILabel?
    private weak var tournamentInfoSubtitleLabel: UILabel?
    private weak var editCourseButton: UIButton?
    private weak var tournamentButton: UIButton?
    private weak var liveConnectedButton: UIButton?
    private weak var quickStartButton: UIButton?
    private weak var premiumBadgeItem: UIBarButtonItem?

    // MARK: - State
    private var shouldPromptForName = false

    // MARK: - Keys
    private let didPromptHomeCourseKey = "profile.didPromptHomeCourse_v1"
    private let suppressWelcomeTipsKey = "onboarding.suppressWelcomeTips_v1"

    private var didPromptHomeCourse: Bool {
        get { UserDefaults.standard.bool(forKey: didPromptHomeCourseKey) }
        set { UserDefaults.standard.set(newValue, forKey: didPromptHomeCourseKey) }
    }

    private var suppressWelcomeTips: Bool {
        get { UserDefaults.standard.bool(forKey: suppressWelcomeTipsKey) }
        set { UserDefaults.standard.set(newValue, forKey: suppressWelcomeTipsKey) }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "WolfMore"
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = false

        CourseLibrary.shared.seedIfNeeded()
        migrateHomeCourseIfNeeded()
        seedProfileNameIfNeeded()

        styleNavigationBar()
        buildLayout()

        setupPremiumBadge()
        #if DEBUG
        setupDebugButton()
        #endif
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshPremiumBadge),
            name: .premiumStatusChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(noop),
            name: .roundSaveBlockedNeedsPro,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSnapshotSaved),
            name: .snapshotSaved,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resetBannerDismissedThisVisit = false
        refreshHomeUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        runFirstLaunchPromptsIfNeeded()
        refreshHomeUI()
        UpdateChecker.shared.check(from: self)
        animateResetBannerIfNeeded()
        // Slight delay so other first-launch prompts settle first
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self, self.presentedViewController == nil else { return }
            LocationPromptViewController.showIfNeeded(from: self)
        }
    }

    private func animateResetBannerIfNeeded() {
        guard ResetSnapshotStore.shared.needsAttentionOnNextAppearance,
              let banner = resetBannerCard,
              !resetBannerDismissedThisVisit,
              ResetSnapshotStore.shared.load() != nil else { return }
        ResetSnapshotStore.shared.needsAttentionOnNextAppearance = false
        banner.alpha = 0
        banner.isHidden = false
        UIView.animate(
            withDuration: 0.45, delay: 0.15,
            usingSpringWithDamping: 0.78, initialSpringVelocity: 0.4,
            options: .curveEaseOut
        ) {
            banner.alpha = 1
        }
    }

    // MARK: - Navigation Bar

    private func styleNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = forestGreen
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = goldColor
    }

    // MARK: - Layout

    private func buildLayout() {
        view.backgroundColor = UIColor.systemGroupedBackground

        let scroll = UIScrollView()
        scroll.alwaysBounceVertical = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            content.topAnchor.constraint(equalTo: scroll.topAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor)
        ])

        let header = buildHeaderView()
        let card = buildInProgressCard()
        inProgressCard = card
        let resetBanner = buildResetBannerView()
        resetBannerCard = resetBanner
        let tCard = buildTournamentInfoCard()
        tournamentInfoCard = tCard
        let newRound = buildNewRoundSection()
        let utils = buildUtilityRow()

        // Stack collapses hidden views to zero height automatically
        let mainStack = UIStackView(arrangedSubviews: [card, resetBanner, tCard, newRound])
        mainStack.axis = .vertical
        mainStack.spacing = 16
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        content.addSubview(header)
        content.addSubview(mainStack)
        content.addSubview(utils)

        let m: CGFloat = 16
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: content.topAnchor),
            header.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: content.trailingAnchor),

            mainStack.topAnchor.constraint(equalTo: header.bottomAnchor, constant: m),
            mainStack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: m),
            mainStack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -m),

            utils.topAnchor.constraint(equalTo: mainStack.bottomAnchor, constant: 28),
            utils.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            utils.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -40)
        ])
    }

    private func buildHeaderView() -> UIView {
        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        header.backgroundColor = forestGreen

        // Wolf head logo — centered at top of header
        let logoView = UIImageView(image: UIImage(named: "Home"))
        logoView.contentMode = .scaleAspectFit
        logoView.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(logoView)

        // Edit course button (pencil, top-right)
        let editBtn = UIButton(type: .system)
        editBtn.setImage(UIImage(systemName: "pencil.circle"), for: .normal)
        editBtn.tintColor = goldColor.withAlphaComponent(0.8)
        editBtn.addTarget(self, action: #selector(editCourseTapped(_:)), for: .touchUpInside)
        editBtn.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(editBtn)
        editCourseButton = editBtn

        // Course name button (tappable to pick course)
        let courseBtn = UIButton(type: .system)
        courseBtn.contentHorizontalAlignment = .leading
        courseBtn.addTarget(self, action: #selector(courseHeaderTapped), for: .touchUpInside)
        courseBtn.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(courseBtn)
        headerCourseButton = courseBtn

        // Architect label
        let architectLbl = UILabel()
        architectLbl.font = .systemFont(ofSize: 13, weight: .regular)
        architectLbl.textColor = sageColor
        architectLbl.numberOfLines = 1
        architectLbl.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(architectLbl)
        headerArchitectLabel = architectLbl

        // Stats label: "47 rounds · +$214 lifetime"
        let statsLbl = UILabel()
        statsLbl.font = .systemFont(ofSize: 13, weight: .regular)
        statsLbl.textColor = sageColor
        statsLbl.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(statsLbl)
        headerStatsLabel = statsLbl

        // Name label (tappable to edit name)
        let nameLbl = UILabel()
        nameLbl.font = .systemFont(ofSize: 12, weight: .regular)
        nameLbl.textColor = sageColor.withAlphaComponent(0.65)
        nameLbl.isUserInteractionEnabled = true
        nameLbl.translatesAutoresizingMaskIntoConstraints = false
        nameLbl.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(welcomeLabelTapped)))
        header.addSubview(nameLbl)
        headerNameLabel = nameLbl

        let pad: CGFloat = 20
        NSLayoutConstraint.activate([
            // Logo: centered, sits at top with small padding
            logoView.topAnchor.constraint(equalTo: header.topAnchor, constant: 12),
            logoView.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            logoView.heightAnchor.constraint(equalToConstant: 68),
            logoView.widthAnchor.constraint(equalToConstant: 68),

            // Edit pencil: vertically centered with course button row, pinned right
            editBtn.topAnchor.constraint(equalTo: courseBtn.topAnchor),
            editBtn.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -pad),
            editBtn.widthAnchor.constraint(equalToConstant: 32),
            editBtn.heightAnchor.constraint(equalToConstant: 32),

            // Course name: below logo
            courseBtn.topAnchor.constraint(equalTo: logoView.bottomAnchor, constant: 10),
            courseBtn.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: pad),
            courseBtn.trailingAnchor.constraint(equalTo: editBtn.leadingAnchor, constant: -8),

            architectLbl.topAnchor.constraint(equalTo: courseBtn.bottomAnchor, constant: 4),
            architectLbl.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: pad),
            architectLbl.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -pad),

            statsLbl.topAnchor.constraint(equalTo: architectLbl.bottomAnchor, constant: 2),
            statsLbl.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: pad),
            statsLbl.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -pad),

            nameLbl.topAnchor.constraint(equalTo: statsLbl.bottomAnchor, constant: 2),
            nameLbl.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: pad),
            nameLbl.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -pad),
            nameLbl.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -pad)
        ])

        return header
    }

    private func buildInProgressCard() -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = goldColor
        card.layer.cornerRadius = 16
        card.layer.masksToBounds = true
        card.isHidden = true
        card.isUserInteractionEnabled = true
        card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(inProgressCardTapped)))

        let pad: CGFloat = 16

        let caption = UILabel()
        caption.text = "ROUND IN PROGRESS"
        caption.font = .systemFont(ofSize: 10, weight: .semibold)
        caption.textColor = forestGreen.withAlphaComponent(0.65)
        caption.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(caption)
        inProgressCaptionLabel = caption

        let titleLbl = UILabel()
        titleLbl.font = .systemFont(ofSize: 20, weight: .bold)
        titleLbl.textColor = forestGreen
        titleLbl.adjustsFontSizeToFitWidth = true
        titleLbl.minimumScaleFactor = 0.8
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLbl)
        inProgressTitleLabel = titleLbl

        let detailLbl = UILabel()
        detailLbl.font = .systemFont(ofSize: 14, weight: .regular)
        detailLbl.textColor = forestGreen.withAlphaComponent(0.75)
        detailLbl.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(detailLbl)
        inProgressDetailLabel = detailLbl

        let chipsRow = UIStackView()
        chipsRow.axis = .horizontal
        chipsRow.spacing = 6
        chipsRow.alignment = .center
        chipsRow.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(chipsRow)
        inProgressChipsRow = chipsRow

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right.circle.fill"))
        chevron.tintColor = forestGreen
        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(chevron)

        NSLayoutConstraint.activate([
            caption.topAnchor.constraint(equalTo: card.topAnchor, constant: pad),
            caption.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: pad),
            caption.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),

            titleLbl.topAnchor.constraint(equalTo: caption.bottomAnchor, constant: 4),
            titleLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: pad),
            titleLbl.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),

            detailLbl.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 4),
            detailLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: pad),
            detailLbl.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),

            chipsRow.topAnchor.constraint(equalTo: detailLbl.bottomAnchor, constant: 10),
            chipsRow.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: pad),
            chipsRow.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -pad),

            chevron.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -pad),
            chevron.widthAnchor.constraint(equalToConstant: 28),
            chevron.heightAnchor.constraint(equalToConstant: 28)
        ])

        return card
    }

    private func buildResetBannerView() -> UIView {
        let amber = UIColor(red: 1.0, green: 0.78, blue: 0.25, alpha: 1.0)
        let ink   = UIColor(red: 0.45, green: 0.24, blue: 0.0, alpha: 1.0)

        let banner = UIView()
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.backgroundColor = amber
        banner.layer.cornerRadius = 12
        banner.layer.masksToBounds = true
        banner.isHidden = true

        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 14, weight: .semibold)
        lbl.textColor = ink
        lbl.numberOfLines = 1
        lbl.adjustsFontSizeToFitWidth = true
        lbl.minimumScaleFactor = 0.8
        lbl.translatesAutoresizingMaskIntoConstraints = false
        banner.addSubview(lbl)
        resetBannerLabel = lbl

        let restoreBtn = UIButton(type: .system)
        restoreBtn.setTitle("Restore", for: .normal)
        restoreBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        restoreBtn.tintColor = ink
        restoreBtn.addTarget(self, action: #selector(restoreSnapshotTapped), for: .touchUpInside)
        restoreBtn.translatesAutoresizingMaskIntoConstraints = false
        restoreBtn.setContentHuggingPriority(.required, for: .horizontal)
        restoreBtn.setContentCompressionResistancePriority(.required, for: .horizontal)
        banner.addSubview(restoreBtn)

        let dismissBtn = UIButton(type: .system)
        dismissBtn.setImage(UIImage(systemName: "xmark"), for: .normal)
        dismissBtn.tintColor = ink.withAlphaComponent(0.55)
        dismissBtn.addTarget(self, action: #selector(dismissResetBannerTapped), for: .touchUpInside)
        dismissBtn.translatesAutoresizingMaskIntoConstraints = false
        dismissBtn.setContentHuggingPriority(.required, for: .horizontal)
        dismissBtn.setContentCompressionResistancePriority(.required, for: .horizontal)
        banner.addSubview(dismissBtn)

        NSLayoutConstraint.activate([
            banner.heightAnchor.constraint(equalToConstant: 52),

            lbl.leadingAnchor.constraint(equalTo: banner.leadingAnchor, constant: 14),
            lbl.centerYAnchor.constraint(equalTo: banner.centerYAnchor),
            lbl.trailingAnchor.constraint(lessThanOrEqualTo: restoreBtn.leadingAnchor, constant: -8),

            restoreBtn.trailingAnchor.constraint(equalTo: dismissBtn.leadingAnchor, constant: -6),
            restoreBtn.centerYAnchor.constraint(equalTo: banner.centerYAnchor),

            dismissBtn.trailingAnchor.constraint(equalTo: banner.trailingAnchor, constant: -12),
            dismissBtn.centerYAnchor.constraint(equalTo: banner.centerYAnchor),
            dismissBtn.widthAnchor.constraint(equalToConstant: 30),
            dismissBtn.heightAnchor.constraint(equalToConstant: 44),
        ])

        return banner
    }

    private func buildTournamentInfoCard() -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = forestGreen
        card.layer.cornerRadius = 16
        card.layer.masksToBounds = true
        card.isHidden = true

        let pad: CGFloat = 16

        let badge = UILabel()
        badge.text = "🏆  ACTIVE TOURNAMENT"
        badge.font = .systemFont(ofSize: 10, weight: .semibold)
        badge.textColor = goldColor
        badge.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(badge)

        let nameLbl = UILabel()
        nameLbl.font = .systemFont(ofSize: 20, weight: .bold)
        nameLbl.textColor = .white
        nameLbl.adjustsFontSizeToFitWidth = true
        nameLbl.minimumScaleFactor = 0.8
        nameLbl.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(nameLbl)
        tournamentInfoNameLabel = nameLbl

        let subtitleLbl = UILabel()
        subtitleLbl.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLbl.textColor = UIColor.white.withAlphaComponent(0.75)
        subtitleLbl.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(subtitleLbl)
        tournamentInfoSubtitleLabel = subtitleLbl

        let lbBtn = UIButton(type: .system)
        lbBtn.setTitle("Leaderboard", for: .normal)
        lbBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        lbBtn.tintColor = goldColor
        lbBtn.addTarget(self, action: #selector(tournamentCardLeaderboardTapped), for: .touchUpInside)
        lbBtn.translatesAutoresizingMaskIntoConstraints = false

        let groupBtn = UIButton(type: .system)
        groupBtn.setTitle("Set Up Group", for: .normal)
        groupBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        groupBtn.tintColor = UIColor.white.withAlphaComponent(0.85)
        groupBtn.addTarget(self, action: #selector(tournamentCardGroupTapped), for: .touchUpInside)
        groupBtn.translatesAutoresizingMaskIntoConstraints = false

        let btnRow = UIStackView(arrangedSubviews: [lbBtn, groupBtn])
        btnRow.axis = .horizontal
        btnRow.spacing = 20
        btnRow.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(btnRow)

        NSLayoutConstraint.activate([
            badge.topAnchor.constraint(equalTo: card.topAnchor, constant: pad),
            badge.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: pad),
            badge.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -pad),

            nameLbl.topAnchor.constraint(equalTo: badge.bottomAnchor, constant: 4),
            nameLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: pad),
            nameLbl.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -pad),

            subtitleLbl.topAnchor.constraint(equalTo: nameLbl.bottomAnchor, constant: 2),
            subtitleLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: pad),
            subtitleLbl.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -pad),

            btnRow.topAnchor.constraint(equalTo: subtitleLbl.bottomAnchor, constant: 14),
            btnRow.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: pad),
            btnRow.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -pad),
        ])

        return card
    }

    @objc private func tournamentCardLeaderboardTapped() {
        guard let code = GameManager.shared.currentGame?.tournamentCode else { return }
        let gameType  = GameManager.shared.currentGame?.tournamentGameType
        let sfEnabled = GameManager.shared.currentGame?.tournamentStablefordEnabled ?? false
        let vc = TournamentLeaderboardViewController(code: code, gameType: gameType, stablefordEnabled: sfEnabled)
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func tournamentCardGroupTapped() {
        guard let g = GameManager.shared.currentGame,
              let code = g.tournamentCode else { return }

        let spinner = UIAlertController(title: nil, message: "Setting up…", preferredStyle: .alert)
        present(spinner, animated: true)

        Task { [weak self] in
            guard let self else { return }

            let record: TournamentRecord
            do {
                record = try await SupabaseService.shared.fetchTournament(code: code)
            } catch {
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        let alert = UIAlertController(
                            title: "Connection Error",
                            message: "Couldn't reach the server. Check your connection and try again.",
                            preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    }
                }
                return
            }

            let liveDay = record.currentDay ?? (g.tournamentDay ?? 1)
            let savedDay = g.tournamentDay ?? 1
            let isNewDay = liveDay > savedDay

            // New day → new matchId so scores don't collide with previous day
            let newMatchId = isNewDay ? UUID().uuidString : (g.tournamentMatchId ?? UUID().uuidString)

            // Organizer clears all roster claims so everyone is available on the new day
            if isNewDay {
                let isOrg = (record.createdBy == DeviceID.id)
                    || (record.coOrganizerDevices?.contains(DeviceID.id) == true)
                if isOrg { try? await SupabaseService.shared.clearRosterClaims(code: record.code) }
            }

            GameManager.shared.update { g in
                g.tournamentDay         = liveDay
                g.tournamentMatchId     = newMatchId
                g.tournamentScoringType = record.scoring
                g.tournamentPotAmount   = record.potAmount
                g.tournamentCarryTies   = record.carryTies
                g.tournamentGameType    = record.gameType
                g.stablefordBaseline          = StablefordBaseline(rawValue: record.stablefordBaseline ?? "par") ?? .par
                g.stablefordCountingPlayers   = record.stablefordTeamCount ?? 3
                g.tournamentStablefordEnabled = record.stablefordEnabled
            }
            UserDefaults.standard.set(liveDay, forKey: "lastTournamentDay_\(code)")
            GameManager.shared.saveCurrent()

            await MainActor.run {
                spinner.dismiss(animated: false) {
                    let sb = UIStoryboard(name: "Main", bundle: nil)
                    guard let manageVC = sb.instantiateViewController(withIdentifier: "ManagePlayersVC")
                            as? ManagePlayersViewController else { return }
                    manageVC.autoOpenRosterPicker = true
                    let nav = UINavigationController(rootViewController: manageVC)
                    nav.modalPresentationStyle = .pageSheet
                    if let sheet = nav.sheetPresentationController {
                        sheet.detents = [.large()]
                        sheet.prefersGrabberVisible = true
                    }
                    self.present(nav, animated: true)
                }
            }
        }
    }

    private func buildNewRoundSection() -> UIView {
        let section = UIView()
        section.translatesAutoresizingMaskIntoConstraints = false

        let sectionHeader = makeSectionHeader("START NEW ROUND")
        section.addSubview(sectionHeader)

        let quickBtn = buildActionCard(
            title: "Quick Start",
            subtitle: "Type names on next screen",
            systemImage: "bolt.fill",
            accentColor: .systemOrange
        )
        quickBtn.addTarget(self, action: #selector(quickStartHomeTapped), for: .touchUpInside)
        quickStartButton = quickBtn

        let contactsBtn = buildActionCard(
            title: "Play from Loaded Contacts",
            subtitle: "Load saved players",
            systemImage: "person.2.fill",
            accentColor: wolfPrimaryGreen
        )
        contactsBtn.addTarget(self, action: #selector(fromContactsTapped), for: .touchUpInside)

        let hStack = UIStackView(arrangedSubviews: [quickBtn, contactsBtn])
        hStack.axis = .horizontal
        hStack.spacing = 12
        hStack.distribution = .fillEqually
        hStack.translatesAutoresizingMaskIntoConstraints = false
        section.addSubview(hStack)

        // Tagline
        let tagline = UILabel()
        tagline.text = "Every round automatically tracks Wolf · Skins · Nassau — no extra setup"
        tagline.font = .systemFont(ofSize: 14, weight: .regular)
        tagline.textColor = sageColor
        tagline.textAlignment = .center
        tagline.numberOfLines = 0
        tagline.translatesAutoresizingMaskIntoConstraints = false
        section.addSubview(tagline)

        let liveBtn = buildSecondaryButton(
            title: "Live & Tournaments",
            systemImage: "antenna.radiowaves.left.and.right",
            tintColor: UIColor(red: 0.20, green: 0.47, blue: 0.78, alpha: 1.0)
        )
        liveBtn.addTarget(self, action: #selector(liveConnectedTapped), for: .touchUpInside)
        liveConnectedButton = liveBtn

        let secondaryStack = UIStackView(arrangedSubviews: [liveBtn])
        secondaryStack.axis = .vertical
        secondaryStack.spacing = 8
        secondaryStack.translatesAutoresizingMaskIntoConstraints = false
        section.addSubview(secondaryStack)

        NSLayoutConstraint.activate([
            sectionHeader.topAnchor.constraint(equalTo: section.topAnchor),
            sectionHeader.leadingAnchor.constraint(equalTo: section.leadingAnchor),
            sectionHeader.trailingAnchor.constraint(equalTo: section.trailingAnchor),

            hStack.topAnchor.constraint(equalTo: sectionHeader.bottomAnchor, constant: 10),
            hStack.leadingAnchor.constraint(equalTo: section.leadingAnchor),
            hStack.trailingAnchor.constraint(equalTo: section.trailingAnchor),

            tagline.topAnchor.constraint(equalTo: hStack.bottomAnchor, constant: 10),
            tagline.leadingAnchor.constraint(equalTo: section.leadingAnchor, constant: 4),
            tagline.trailingAnchor.constraint(equalTo: section.trailingAnchor, constant: -4),

            secondaryStack.topAnchor.constraint(equalTo: tagline.bottomAnchor, constant: 12),
            secondaryStack.leadingAnchor.constraint(equalTo: section.leadingAnchor),
            secondaryStack.trailingAnchor.constraint(equalTo: section.trailingAnchor),
            secondaryStack.bottomAnchor.constraint(equalTo: section.bottomAnchor),
        ])

        return section
    }

    private func buildUtilityRow() -> UIStackView {
        let statsBtn = makeChip(title: "Stats", systemImage: "chart.bar.fill")
        statsBtn.addTarget(self, action: #selector(statsTapped(_:)), for: .touchUpInside)

        let moreBtn = makeChip(title: "More", systemImage: "ellipsis.circle.fill")
        moreBtn.addTarget(self, action: #selector(moreTapped(_:)), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [statsBtn, moreBtn])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    // MARK: - Layout Helpers

    private func makeSectionHeader(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.text = text
        lbl.font = .systemFont(ofSize: 11, weight: .semibold)
        lbl.textColor = .secondaryLabel
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }

    private func buildActionCard(
        title: String,
        subtitle: String,
        systemImage: String,
        accentColor: UIColor
    ) -> UIButton {
        var cfg = UIButton.Configuration.filled()
        cfg.baseBackgroundColor = UIColor.secondarySystemGroupedBackground
        cfg.baseForegroundColor = .label
        cfg.cornerStyle = .large
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 14, bottom: 16, trailing: 14)
        cfg.imagePlacement = .top
        cfg.imagePadding = 8
        cfg.image = UIImage(systemName: systemImage)?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 22, weight: .medium))
        cfg.imageColorTransformer = UIConfigurationColorTransformer { _ in accentColor }
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs
            a.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
            a.foregroundColor = UIColor.label
            return a
        }
        cfg.subtitleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs
            a.font = UIFont.systemFont(ofSize: 11, weight: .regular)
            a.foregroundColor = UIColor.secondaryLabel
            return a
        }
        cfg.attributedTitle = AttributedString(title)
        cfg.attributedSubtitle = AttributedString(subtitle)
        cfg.titleAlignment = .center
        let btn = UIButton(configuration: cfg)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }

    private func buildSecondaryButton(title: String, systemImage: String, tintColor: UIColor) -> UIButton {
        var cfg = UIButton.Configuration.tinted()
        cfg.title = title
        cfg.image = UIImage(systemName: systemImage)
        cfg.imagePadding = 8
        cfg.cornerStyle = .large
        cfg.baseBackgroundColor = tintColor
        cfg.baseForegroundColor = tintColor
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs; a.font = UIFont.systemFont(ofSize: 15, weight: .medium); return a
        }
        let btn = UIButton(configuration: cfg)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }

    private func makeChip(title: String, systemImage: String? = nil) -> UIButton {
        var cfg = UIButton.Configuration.filled()
        cfg.baseBackgroundColor = .systemGray5
        cfg.baseForegroundColor = .label
        cfg.cornerStyle = .capsule
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs; a.font = UIFont.systemFont(ofSize: 14, weight: .medium); return a
        }
        cfg.attributedTitle = AttributedString(title)
        if let name = systemImage {
            cfg.image = UIImage(systemName: name)?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: 13, weight: .medium))
            cfg.imagePlacement = .leading
            cfg.imagePadding = 6
        }
        let btn = UIButton(configuration: cfg)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }

    // MARK: - Refresh

    private func refreshHomeUI() {
        refreshHeaderDisplay()
        refreshInProgressCard()
        refreshResetBanner()
        refreshTournamentInfoCard()
    }

    private func refreshTournamentInfoCard() {
        guard let card = tournamentInfoCard else { return }
        if GameManager.shared.currentGame == nil {
            _ = GameManager.shared.loadLastOpened(notify: false)
        }
        guard let g = GameManager.shared.currentGame,
              let code = g.tournamentCode, !code.isEmpty else {
            card.isHidden = true
            return
        }
        tournamentInfoNameLabel?.text = g.tournamentName ?? "Tournament"
        let day = g.tournamentDay ?? 1
        tournamentInfoSubtitleLabel?.text = "Day \(day) · Code: \(code)"
        card.isHidden = false

        // Background fetch to catch stale day (e.g. day advanced while app was idle)
        Task { [weak self] in
            guard let liveDay = try? await SupabaseService.shared.fetchTournament(code: code).currentDay,
                  liveDay != day else { return }
            GameManager.shared.update { g in g.tournamentDay = liveDay }
            UserDefaults.standard.set(liveDay, forKey: "lastTournamentDay_\(code)")
            await MainActor.run {
                self?.tournamentInfoSubtitleLabel?.text = "Day \(liveDay) · Code: \(code)"
            }
        }
    }

    private func refreshResetBanner() {
        guard let banner = resetBannerCard else { return }
        guard !resetBannerDismissedThisVisit,
              let entry = ResetSnapshotStore.shared.load() else {
            banner.isHidden = true
            return
        }
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        resetBannerLabel?.text = "Game reset at \(fmt.string(from: entry.savedAt)) — Restore?"
        // If a fresh reset just happened, leave the banner hidden so viewDidAppear can animate it in
        if !ResetSnapshotStore.shared.needsAttentionOnNextAppearance {
            banner.isHidden = false
        }
    }

    private func refreshHeaderDisplay() {
        // Course name
        let courseName: String
        if let g = GameManager.shared.currentGame {
            let stored = g.course.name.trimmingCharacters(in: .whitespacesAndNewlines)
            courseName = stored.isEmpty ? (CourseLibrary.shared.selectedCourseName ?? "Choose Course") : stored
        } else {
            courseName = CourseLibrary.shared.selectedCourseName ?? "Choose Course"
        }

        var cfg = UIButton.Configuration.plain()
        let titleAttrs = AttributeContainer([
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: UIColor.white
        ])
        cfg.attributedTitle = AttributedString(courseName, attributes: titleAttrs)
        cfg.image = UIImage(systemName: "chevron.down")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 13, weight: .medium))
        cfg.imagePlacement = .trailing
        cfg.imagePadding = 6
        cfg.baseForegroundColor = .white
        cfg.contentInsets = .zero
        headerCourseButton?.configuration = cfg

        // Architect
        let profile: CourseProfile? = CourseLibrary.shared.selectedCourseID.flatMap { CourseLibrary.shared.get(id: $0) }
        if let arch = profile?.architect, !arch.isEmpty {
            headerArchitectLabel?.text = "Designed by \(arch)"
            headerArchitectLabel?.isHidden = false
        } else {
            headerArchitectLabel?.text = nil
            headerArchitectLabel?.isHidden = true
        }

        // P&L stats
        let name = (ProfileStore.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty, let stats = RoundStore.shared.stats(forPlayerNamed: name), stats.rounds > 0 {
            let sign = stats.totalMoney >= 0 ? "+" : ""
            headerStatsLabel?.text = "\(stats.rounds) rounds · \(sign)$\(stats.totalMoney) lifetime"
            headerStatsLabel?.isHidden = false
        } else {
            headerStatsLabel?.text = nil
            headerStatsLabel?.isHidden = true
        }

        // Name label
        if name.isEmpty || name == "Player 1" {
            headerNameLabel?.text = "Tap to set your scoring name"
        } else {
            headerNameLabel?.text = "Playing as \(name)"
        }
    }

    private func refreshInProgressCard() {
        guard let card = inProgressCard else { return }

        if !GameManager.shared.hasSavedGame {
            card.isHidden = true
            return
        }

        if GameManager.shared.currentGame == nil {
            _ = GameManager.shared.loadLastOpened(notify: false)
        }
        guard let g = GameManager.shared.currentGame else {
            card.isHidden = true
            return
        }

        card.isHidden = false

        let played = g.holeCommitted.filter { $0 }.count
        let isComplete = played >= 18

        if isComplete {
            inProgressCaptionLabel?.text = "ROUND COMPLETE"
            inProgressTitleLabel?.text = "Round complete — view results"
            inProgressDetailLabel?.isHidden = true
            // A completed new game means the reset recovery window is over
            ResetSnapshotStore.shared.discard()
            resetBannerCard?.isHidden = true
        } else {
            inProgressCaptionLabel?.text = "ROUND IN PROGRESS"
            inProgressTitleLabel?.text = "Continue \(inProgressDayLabel())"
            inProgressDetailLabel?.text = played > 0 ? "Through hole \(played) of 18" : "Hole 1 of 18 — not yet started"
            inProgressDetailLabel?.isHidden = false
        }

        rebuildGameChips(for: g)
    }

    private func inProgressDayLabel() -> String {
        guard let date = RoundStore.shared.rounds.first?.date else { return "your round" }
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 999
        guard days <= 7 else { return "your round" }
        if days == 0 { return "today's round" }
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE"
        return "\(fmt.string(from: date))'s round"
    }

    private func rebuildGameChips(for game: GameData) {
        guard let row = inProgressChipsRow else { return }
        row.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let gameLabel: String
        switch game.resolvedGameType {
        case .wolf:           gameLabel = "Wolf"
        case .wolfLowBall:    gameLabel = "Wolf LowBall"
        case .sixPointScotch: gameLabel = "6-Point Scotch"
        case .hammer:         gameLabel = "Hammer"
        case .tournament:     gameLabel = "Stableford"
        default:              gameLabel = "Wolf"
        }
        row.addArrangedSubview(makeGameChip(gameLabel))

        if game.skinsState?.settings.isEnabled == true {
            row.addArrangedSubview(makeGameChip("Skins"))
        }
        if game.nassauState?.isEnabled == true {
            row.addArrangedSubview(makeGameChip("Nassau"))
        }
    }

    private func makeGameChip(_ text: String) -> UIView {
        let lbl = UILabel()
        lbl.text = text
        lbl.font = .systemFont(ofSize: 11, weight: .semibold)
        lbl.textColor = forestGreen
        lbl.translatesAutoresizingMaskIntoConstraints = false

        let bg = UIView()
        bg.backgroundColor = forestGreen.withAlphaComponent(0.15)
        bg.layer.cornerRadius = 8
        bg.translatesAutoresizingMaskIntoConstraints = false
        bg.addSubview(lbl)

        NSLayoutConstraint.activate([
            lbl.topAnchor.constraint(equalTo: bg.topAnchor, constant: 4),
            lbl.bottomAnchor.constraint(equalTo: bg.bottomAnchor, constant: -4),
            lbl.leadingAnchor.constraint(equalTo: bg.leadingAnchor, constant: 8),
            lbl.trailingAnchor.constraint(equalTo: bg.trailingAnchor, constant: -8)
        ])

        return bg
    }

    // MARK: - Migration

    private func migrateHomeCourseIfNeeded() {
        let raw = ProfileStore.homeCourseID.trimmingCharacters(in: .whitespacesAndNewlines)
        if !raw.isEmpty, UUID(uuidString: raw) == nil {
            ProfileStore.homeCourseID = ""
            UserDefaults.standard.removeObject(forKey: didPromptHomeCourseKey)
        }
    }

    // MARK: - Welcome / Name

    private func seedProfileNameIfNeeded() {
        if ProfileStore.name == nil {
            shouldPromptForName = true
        }
    }

    private func updateWelcome() {
        refreshHeaderDisplay()
    }

    // MARK: - First Launch / Onboarding

    private func runFirstLaunchPromptsIfNeeded() {
        guard presentedViewController == nil else { return }

        let storedName = (ProfileStore.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if shouldPromptForName || storedName.isEmpty || storedName == "Player 1" {
            shouldPromptForName = false
            promptForName { [weak self] in
                self?.runPostNamePrompts()
            }
            return
        }

        runPostNamePrompts()
    }

    private func runPostNamePrompts() {
        guard presentedViewController == nil else { return }
        if !didPromptHomeCourse && !hasHomeCourseSet() {
            runHomeCoursePromptIfNeeded()
            return
        }
        runOnboardingIfNeeded()
    }

    private func runOnboardingIfNeeded() {
        guard presentedViewController == nil else { return }
        guard !suppressWelcomeTips else { return }
        showOnboardingAlert()
    }

    private func showOnboardingAlert() {
        let ac = UIAlertController(
            title: "Getting Started",
            message: "Load players from Contacts to start games faster.\n\nYou can also explore Rules to learn Wolf, Nassau, and scoring.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "Load Contacts", style: .default) { [weak self] _ in
            self?.openContactsManager()
        })
        ac.addAction(UIAlertAction(title: "View Rules", style: .default) { [weak self] _ in
            self?.openRules()
        })
        ac.addAction(UIAlertAction(title: "Don't Show Again", style: .destructive) { [weak self] _ in
            self?.suppressWelcomeTips = true
        })
        ac.addAction(UIAlertAction(title: "Later", style: .cancel))
        present(ac, animated: true)
    }

    private func promptForName(completion: @escaping () -> Void) {
        let ac = UIAlertController(
            title: "Choose Your Scoring Name",
            message: "This name appears on every scorecard you play and in your friends' matches. Use the nickname your golf group already knows you by — not your full legal name.",
            preferredStyle: .alert
        )
        ac.addTextField { tf in
            tf.placeholder = "e.g. McTommy, Bucky, Hollandaise"
            let stored = ProfileStore.name ?? ""
            tf.text = (stored == "Player 1" || stored.isEmpty) ? "" : stored
            tf.autocapitalizationType = .words
            tf.clearButtonMode = .whileEditing
            tf.returnKeyType = .done
        }
        ac.addAction(UIAlertAction(title: "Skip for now", style: .cancel) { _ in
            completion()
        })
        ac.addAction(UIAlertAction(title: "Use This Name", style: .default) { [weak self] _ in
            guard let self = self else { completion(); return }
            let raw = (ac.textFields?.first?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if raw.contains(" ") && raw.split(separator: " ").count >= 2 {
                self.confirmFullNameUsage(typedName: raw, completion: completion)
                return
            }
            if !raw.isEmpty {
                ProfileStore.name = raw
                self.updateWelcome()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            completion()
        })
        present(ac, animated: true)
    }

    private func confirmFullNameUsage(typedName: String, completion: @escaping () -> Void) {
        let ac = UIAlertController(
            title: "Use \"\(typedName)\" on every scorecard?",
            message: "Most golfers prefer a shorter nickname here so it fits cleanly in the scorecard row.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "Pick a Nickname Instead", style: .cancel) { [weak self] _ in
            self?.promptForName(completion: completion)
        })
        ac.addAction(UIAlertAction(title: "Use \"\(typedName)\"", style: .default) { [weak self] _ in
            ProfileStore.name = typedName
            self?.updateWelcome()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            completion()
        })
        present(ac, animated: true)
    }

    // MARK: - Home Course Prompt

    private func hasHomeCourseSet() -> Bool {
        let id = ProfileStore.homeCourseID.trimmingCharacters(in: .whitespacesAndNewlines)
        return UUID(uuidString: id) != nil
    }

    private func runHomeCoursePromptIfNeeded() {
        guard presentedViewController == nil else { return }
        guard !didPromptHomeCourse else { return }

        guard !hasHomeCourseSet() else {
            didPromptHomeCourse = true
            runOnboardingIfNeeded()
            return
        }

        setEditCourseGlow(true)

        let ac = UIAlertController(
            title: "Set your Home Course?",
            message: "Home Course is used for tracking Hole Stats and Friend Stats. Want to set it now?",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "Not now", style: .cancel) { [weak self] _ in
            self?.didPromptHomeCourse = true
            self?.setEditCourseGlow(false)
            self?.runOnboardingIfNeeded()
        })
        ac.addAction(UIAlertAction(title: "Yes", style: .default) { [weak self] _ in
            self?.didPromptHomeCourse = true
            self?.setEditCourseGlow(false)
            self?.openCourseSetup(nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self?.runOnboardingIfNeeded()
            }
        })
        present(ac, animated: true)
    }

    private func setEditCourseGlow(_ on: Bool) {
        guard let btn = editCourseButton else { return }
        if on {
            btn.layer.shadowColor = UIColor.systemYellow.cgColor
            btn.layer.shadowRadius = 12
            btn.layer.shadowOpacity = 0.9
            btn.layer.shadowOffset = .zero
            let pulse = CABasicAnimation(keyPath: "shadowOpacity")
            pulse.fromValue = 0.2
            pulse.toValue = 0.95
            pulse.duration = 0.7
            pulse.autoreverses = true
            pulse.repeatCount = .infinity
            btn.layer.add(pulse, forKey: "homeCourseGlowPulse")
        } else {
            btn.layer.removeAnimation(forKey: "homeCourseGlowPulse")
            btn.layer.shadowOpacity = 0
            btn.layer.shadowRadius = 0
        }
    }

    // MARK: - Course Actions

    private func openAddCourse() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "CourseSetupVC") as? CourseSetupViewController else { return }
        vc.prefillTemplate = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func courseHeaderTapped() {
        courseButtonTapped(headerCourseButton ?? UIButton())
    }

    @objc private func courseButtonTapped(_ sender: UIButton) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let picker = sb.instantiateViewController(withIdentifier: "CoursePickerVC") as? CoursePickerViewController else {
            assertionFailure("CoursePickerVC storyboard id / class mismatch")
            return
        }

        picker.onPickCourse = { [weak self] id in
            guard let self else { return }
            guard let newCourse = CourseLibrary.shared.get(id: id) else {
                CourseLibrary.shared.selectedCourseID = id
                self.refreshHomeUI()
                self.dismiss(animated: true)
                return
            }

            guard let currentGame = GameManager.shared.currentGame else {
                CourseLibrary.shared.selectedCourseID = id
                GameManager.shared.update { g in
                    g.course.pars          = Array(newCourse.pars.prefix(STANDARD_HOLES))
                    g.course.holeHandicaps = Array(newCourse.hcs.prefix(STANDARD_HOLES))
                    g.course.name          = newCourse.name
                    g.course.id            = newCourse.id
                }
                self.refreshHomeUI()
                self.dismiss(animated: true)
                return
            }

            let curName = currentGame.course.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if curName == newCourse.name {
                CourseLibrary.shared.selectedCourseID = id
                self.refreshHomeUI()
                self.dismiss(animated: true)
                return
            }

            let alert = UIAlertController(
                title: "Change Course?",
                message: "Switch from \(curName) to \(newCourse.name)?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Switch", style: .default) { _ in
                CourseLibrary.shared.selectedCourseID = id
                GameManager.shared.update { g in
                    g.course.pars          = Array(newCourse.pars.prefix(STANDARD_HOLES))
                    g.course.holeHandicaps = Array(newCourse.hcs.prefix(STANDARD_HOLES))
                    g.course.name          = newCourse.name
                    g.course.id            = newCourse.id
                }
                GameManager.shared.saveCurrent()
                self.refreshHomeUI()
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.dismiss(animated: true) {
                self.present(alert, animated: true)
            }
        }

        picker.onTapAddCourse = { [weak self] in
            self?.dismiss(animated: true) {
                self?.openAddCourse()
            }
        }

        let nav = UINavigationController(rootViewController: picker)
        nav.modalPresentationStyle = .fullScreen
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    @objc private func openCourseSetup(_ sender: Any? = nil) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "CourseSetupVC") as? CourseSetupViewController else {
            assertionFailure("CourseSetupVC storyboard id / class mismatch")
            return
        }
        vc.loadCourseID = CourseLibrary.shared.selectedCourseID
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            let wrap = UINavigationController(rootViewController: vc)
            wrap.modalPresentationStyle = .fullScreen
            present(wrap, animated: true)
        }
    }

    @objc private func editCourseTapped(_ sender: UIButton) {
        openCourseSetup(sender)
    }

    // MARK: - Reset Snapshot Banner

    @objc private func handleSnapshotSaved() {
        resetBannerDismissedThisVisit = false
        guard let banner = resetBannerCard,
              let entry = ResetSnapshotStore.shared.load() else { return }
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        resetBannerLabel?.text = "Game reset at \(fmt.string(from: entry.savedAt)) — Restore?"
        guard banner.isHidden else { return }
        ResetSnapshotStore.shared.needsAttentionOnNextAppearance = false
        banner.alpha = 0
        banner.isHidden = false
        UIView.animate(
            withDuration: 0.45, delay: 0,
            usingSpringWithDamping: 0.78, initialSpringVelocity: 0.4,
            options: .curveEaseOut
        ) {
            banner.alpha = 1
        }
    }

    @objc private func restoreSnapshotTapped() {
        guard let entry = ResetSnapshotStore.shared.load() else { return }
        let g = entry.gameData
        let course = g.course.name
        let df = DateFormatter()
        df.dateStyle = .medium; df.timeStyle = .none
        let date = df.string(from: entry.savedAt)
        let players = (0..<min(MAX_PLAYERS, g.playerActivated.count)).compactMap { i -> String? in
            guard g.playerActivated[i] else { return nil }
            let name = (g.playerNames[safe: i] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return name.isEmpty ? nil : name
        }.joined(separator: ", ")
        let detail = [course, date, players].filter { !$0.isEmpty }.joined(separator: "\n")
        let ac = UIAlertController(
            title: "Swap to Previous Round?",
            message: "\(detail)\n\nYour current round will be saved — you can swap back anytime from More.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Swap Rounds", style: .default) { [weak self] _ in
            guard let self else { return }
            // Circular swap: save current first so it becomes available to restore next time
            ResetSnapshotStore.shared.saveFromCurrentGame()
            ResetSnapshotStore.shared.restore(entry: entry)
            self.refreshResetBanner()
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "showPlayerSetup", sender: self)
            }
        })
        present(ac, animated: true)
    }

    @objc private func dismissResetBannerTapped() {
        resetBannerDismissedThisVisit = true
        UIView.animate(withDuration: 0.2) { self.resetBannerCard?.isHidden = true }
    }

    // MARK: - Play Game

    @objc private func inProgressCardTapped() {
        performSegue(withIdentifier: "showPlayerSetup", sender: self)
    }

    @objc private func fromContactsTapped() {
        guard GameManager.shared.hasSavedGame else {
            presentManagePlayers()
            return
        }
        var message = "This will delete your previous game data."
        if GameManager.shared.currentGame?.liveSessionId != nil {
            message += "\n\nYou have an active Live Wolf broadcast — starting a new game will end it for anyone watching."
        }
        let ac = UIAlertController(title: "Start New Game?", message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Start New Game", style: .destructive) { [weak self] _ in
            let ids = GameManager.shared.currentGame?.remoteMatchIds ?? []
            Task { for id in ids { try? await SupabaseService.shared.archiveMatch(id: id) } }
            ResetSnapshotStore.shared.saveFromCurrentGame()
            GameManager.shared.resetForNewRoundPreservingCourseAndRoster()
            self?.presentManagePlayers()
        })
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }

    private func confirmStartNewGame() {
        let isTournamentActive = (GameManager.shared.currentGame?.resolvedGameType == .tournament)
            && (GameManager.shared.currentGame?.holeCommitted.contains(true) ?? false)
        var message = isTournamentActive
            ? "This will delete your current Stableford round."
            : "This will delete your previous game data."
        if GameManager.shared.currentGame?.liveSessionId != nil {
            message += "\n\nYou have an active Live Wolf broadcast — starting a new game will end it for anyone watching."
        }
        let ac = UIAlertController(title: "Start New Game?", message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Start New Game", style: .destructive) { [weak self] _ in
            let idsToArchive = GameManager.shared.currentGame?.remoteMatchIds ?? []
            Task { for id in idsToArchive { try? await SupabaseService.shared.archiveMatch(id: id) } }
            ResetSnapshotStore.shared.saveFromCurrentGame()
            GameManager.shared.resetForNewRoundPreservingCourseAndRoster()
            self?.presentManagePlayers()
        })
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }

    func makeSharedRound(for playerIndex: Int) -> SharedRound? {
        guard let g = GameManager.shared.currentGame else { return nil }
        guard playerIndex < g.playerNames.count else { return nil }
        guard playerIndex < g.scorePerHole.count else { return nil }
        guard playerIndex < g.fairwayHit.count else { return nil }
        guard playerIndex < g.girHit.count else { return nil }
        guard playerIndex < g.puttsPerHole.count else { return nil }

        return SharedRound(
            playerName: g.playerNames[playerIndex],
            courseName: g.course.name,
            pars: Array(g.course.pars.prefix(STANDARD_HOLES)),
            hcs: Array(g.course.holeHandicaps.prefix(STANDARD_HOLES)),
            scores: Array(g.scores[playerIndex].prefix(STANDARD_HOLES)).map { $0 ?? 0 },
            fairways: Array(g.fairwayHit[playerIndex].prefix(STANDARD_HOLES)),
            girs: Array(g.girHit[playerIndex].prefix(STANDARD_HOLES)),
            putts: Array(g.puttsPerHole[playerIndex].prefix(STANDARD_HOLES)),
            courseHandicap: playerIndex < g.hcPlayers.count ? g.hcPlayers[playerIndex] : 0
        )
    }

    @objc private func welcomeLabelTapped() {
        promptForName(completion: {})
    }

    @objc private func noop() {}

    // MARK: - Contacts

    @objc private func contactsTapped(_ sender: UIButton) {
        let ac = UIAlertController(title: "Contacts", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Text Contacts", style: .default) { [weak self] _ in
            self?.openTextHub()
        })
        ac.addAction(UIAlertAction(title: "Manage Contacts", style: .default) { [weak self] _ in
            self?.openContactsManager()
        })
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let pop = ac.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
            pop.permittedArrowDirections = [.up, .down]
        }
        present(ac, animated: true)
    }

    private func openTextHub() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "TextVC")
        navigationController?.pushViewController(vc, animated: true)
    }

    private func openContactsManager() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "ContactsViewController")
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Stats

    @objc private func statsTapped(_ sender: UIButton) {
        let ac = UIAlertController(title: "Stats", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Player Stats", style: .default) { [weak self] _ in
            self?.openFriendStatsScreen()
        })
        ac.addAction(UIAlertAction(title: "Home Course Summary", style: .default) { [weak self] _ in
            self?.openCourseSummaryScreen()
        })
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let pop = ac.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
            pop.permittedArrowDirections = [.up, .down]
        }
        present(ac, animated: true)
    }

    private func openCourseSummaryScreen() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "CourseSummaryViewController")
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
        }
    }

    private func openFriendStatsScreen() {
        let vc = MyStatsViewController()
        vc.mode = .friends
        pushOrPresent(vc)
    }

    // MARK: - More

    @objc private func moreTapped(_ sender: UIButton) {
        let ac = UIAlertController(title: "More", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Calcutta Pools",    style: .default) { [weak self] _ in self?.openCalcutta() })
        ac.addAction(UIAlertAction(title: "Manage Players",    style: .default) { [weak self] _ in self?.presentManagePlayers() })
        ac.addAction(UIAlertAction(title: "Past Games",        style: .default) { [weak self] _ in self?.openPastGames() })
        ac.addAction(UIAlertAction(title: "Explore the Rules", style: .default) { [weak self] _ in self?.openRules() })
        ac.addAction(UIAlertAction(title: "Delete History",    style: .destructive) { [weak self] _ in
            guard let self else { return }
            self.deleteHistoryTapped(sender)
        })
        ac.addAction(UIAlertAction(title: "Check for Updates", style: .default) { [weak self] _ in
            guard let self else { return }
            UpdateChecker.shared.checkManually(from: self)
        })
        ac.addAction(UIAlertAction(title: "Rate WolfMore ★",   style: .default) { _ in
            if let url = URL(string: "itms-apps://itunes.apple.com/app/id6755116882?action=write-review") {
                UIApplication.shared.open(url)
            }
        })
        ac.addAction(UIAlertAction(title: "Send Feedback",     style: .default) { [weak self] _ in self?.sendFeedbackEmail() })
        if ResetSnapshotStore.shared.hasSnapshots {
            ac.addAction(UIAlertAction(title: "Swap to Previous Round", style: .default) { [weak self] _ in self?.openRestorePastRound() })
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let pop = ac.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
            pop.permittedArrowDirections = [.up, .down]
        }
        present(ac, animated: true)
    }

    private func openCalcutta() {
        let vc = CalcuttaListViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    private func openPastGames() {
        let vc = PastGamesViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    private func openRestorePastRound() {
        guard let entry = ResetSnapshotStore.shared.load() else { return }
        let g = entry.gameData
        let course = g.course.name
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        let date = df.string(from: entry.savedAt)
        let players = (0..<min(MAX_PLAYERS, g.playerActivated.count)).compactMap { i -> String? in
            guard g.playerActivated[i] else { return nil }
            let name = (g.playerNames[safe: i] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return name.isEmpty ? nil : name
        }.joined(separator: ", ")
        let detail = [course, date, players].filter { !$0.isEmpty }.joined(separator: "\n")
        let ac = UIAlertController(
            title: "Swap to Previous Round?",
            message: "\(detail)\n\nYour current round will be saved — you can swap back anytime from More.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Swap Rounds", style: .default) { [weak self] _ in
            guard let self else { return }
            // Circular swap: save current before restoring so neither round is lost
            ResetSnapshotStore.shared.saveFromCurrentGame()
            ResetSnapshotStore.shared.restore(entry: entry)
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "showPlayerSetup", sender: self)
            }
        })
        present(ac, animated: true)
    }

    private func openRules() {
        let rules = RulesViewController()
        if let nav = navigationController {
            nav.pushViewController(rules, animated: true)
        } else {
            let wrap = UINavigationController(rootViewController: rules)
            wrap.modalPresentationStyle = .fullScreen
            present(wrap, animated: true)
        }
    }

    // MARK: - Delete History

    @objc private func deleteHistoryTapped(_ sender: UIButton) {
        guard !RoundStore.shared.rounds.isEmpty else {
            let ac = UIAlertController(title: "No History", message: "No saved rounds yet.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            return
        }
        let ac = UIAlertController(
            title: "Delete History?",
            message: "This will permanently delete all saved rounds and stats on this device.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            RoundStore.shared.clearAll()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            let done = UIAlertController(title: "Deleted", message: "History cleared.", preferredStyle: .alert)
            done.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(done, animated: true)
        })
        present(ac, animated: true)
    }

    // MARK: - Tournament

    @objc private func tournamentTapped() {
        if GameManager.shared.currentGame == nil {
            _ = GameManager.shared.loadLastOpened(notify: false)
        }
        let current = GameManager.shared.currentGame

        if current?.resolvedGameType == .tournament {
            let hasHolesPlayed = current?.holeCommitted.contains(true) ?? false
            if hasHolesPlayed {
                let ac = UIAlertController(title: "Tournament in Progress", message: nil, preferredStyle: .actionSheet)
                ac.addAction(UIAlertAction(title: "Continue Tournament", style: .default) { [weak self] _ in
                    self?.performSegue(withIdentifier: "showPlayerSetup", sender: self)
                })
                ac.addAction(UIAlertAction(title: "New Tournament", style: .destructive) { [weak self] _ in
                    self?.confirmNewTournament()
                })
                ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                if let pop = ac.popoverPresentationController {
                    pop.sourceView = tournamentButton ?? view
                    pop.sourceRect = tournamentButton?.bounds ?? view.bounds
                }
                present(ac, animated: true)
            } else {
                launchTournament()
            }
        } else if GameManager.shared.hasSavedGame {
            let ac = UIAlertController(
                title: "Start Stableford?",
                message: "This will delete your previous game data.",
                preferredStyle: .alert
            )
            ac.addAction(UIAlertAction(title: "Start Stableford", style: .destructive) { [weak self] _ in
                self?.launchTournament()
            })
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(ac, animated: true)
        } else {
            launchTournament()
        }
    }

    private func confirmNewTournament() {
        let ac = UIAlertController(
            title: "Start New Tournament?",
            message: "This will delete your current tournament data.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "Start New", style: .destructive) { [weak self] _ in
            self?.launchTournament()
        })
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }

    private func launchTournament() {
        if GameManager.shared.currentGame == nil {
            GameManager.shared.startNewGame()
        } else {
            GameManager.shared.resetForNewRoundPreservingCourseAndRoster()
        }
        GameManager.shared.update { g in
            g.gameType = .tournament
            g.tournamentGameType = "stableford"
            // Clear any stale online-tournament state so ManagePlayersVC treats this
            // as a local game (no roster fetch, no tournament-code gating).
            g.tournamentCode        = nil
            g.groupCode             = nil
            g.tournamentMatchId     = nil
            g.tournamentIsOrganizer = false
            g.tournamentIsCreator   = false
        }
        let rulesVC = StablefordRulesSetupViewController()
        rulesVC.onStart = { [weak self] in self?.presentManagePlayers() }
        let nav = UINavigationController(rootViewController: rulesVC)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }

    // MARK: - Quick Start

    @objc private func quickStartHomeTapped() {
        guard GameManager.shared.hasSavedGame else {
            doQuickStart()
            return
        }
        var message = "Your current game data will be cleared. Continue?"
        if GameManager.shared.currentGame?.liveSessionId != nil {
            message += "\n\nYou have an active Live Wolf broadcast — starting a new game will end it for anyone watching."
        }
        let alert = UIAlertController(title: "Quick Start", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Clear & Start", style: .destructive) { [weak self] _ in
            ResetSnapshotStore.shared.saveFromCurrentGame()
            self?.doQuickStart()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func doQuickStart() {
        let rawName = (ProfileStore.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let name = (rawName.isEmpty || rawName == "Player 1") ? "Player 1" : rawName

        let idsToArchive = GameManager.shared.currentGame?.remoteMatchIds ?? []
        Task { for id in idsToArchive { try? await SupabaseService.shared.archiveMatch(id: id) } }

        GameManager.shared.startNewGame(name: "New Game")
        GameManager.shared.update { g in
            g.playerNames     = Array(repeating: "",    count: MAX_PLAYERS)
            g.hcPlayers       = Array(repeating: 0,     count: MAX_PLAYERS)
            g.playerActivated = Array(repeating: false, count: MAX_PLAYERS)

            g.playerNames[0]     = name
            g.hcPlayers[0]       = ProfileStore.myHC
            g.playerActivated[0] = true

            if let cid = CourseLibrary.shared.selectedCourseID,
               let course = CourseLibrary.shared.get(id: cid) {
                g.course.pars          = Array(course.pars.prefix(STANDARD_HOLES))
                g.course.holeHandicaps = Array(course.hcs.prefix(STANDARD_HOLES))
                g.course.name          = course.name
                g.course.id            = course.id
            }

            g.nassauState = NassauEngine.makeDefaultState(
                playerNames: g.playerNames,
                activeFlags: g.playerActivated
            )
            if var ns = g.nassauState {
                NassauEngine.recalculate(state: &ns, gameData: g)
                g.nassauState = ns
            }
            g.hole = 0
        }

        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let roundNav = sb.instantiateViewController(withIdentifier: "RoundNav") as? UINavigationController else { return }
        present(roundNav, animated: true)
    }

    // MARK: - Live & Connected

    @objc private func liveConnectedTapped() {
        let vc = LiveConnectedViewController(style: .insetGrouped)
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    // MARK: - Feedback

    private func sendFeedbackEmail() {
        guard MFMailComposeViewController.canSendMail() else {
            if let url = URL(string: "mailto:coursemanagement@wolfmore.com?subject=WolfMore%20Feedback") {
                UIApplication.shared.open(url)
            }
            return
        }
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self
        composer.setToRecipients(["coursemanagement@wolfmore.com"])
        composer.setSubject("WolfMore Feedback")
        present(composer, animated: true)
    }

    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        controller.dismiss(animated: true)
    }

    // MARK: - Helpers

    private func presentManagePlayers() {
        // Local-game path — clear any stale live-tournament state so ManagePlayersVC
        // shows the normal contacts roster (not the tournament roster picker).
        // Live Wolf tournament sessions go through LiveConnectedViewController instead.
        GameManager.shared.update { g in
            g.tournamentCode        = nil
            g.groupCode             = nil
            g.tournamentMatchId     = nil
            g.tournamentIsOrganizer = false
            g.tournamentIsCreator   = false
        }
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let manage = sb.instantiateViewController(withIdentifier: "ManagePlayersVC") as! ManagePlayersViewController
        let nav = UINavigationController(rootViewController: manage)
        nav.modalPresentationStyle = .fullScreen
        nav.isModalInPresentation = true
        present(nav, animated: true)
    }

    private func pushOrPresent(_ vc: UIViewController) {
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            let wrap = UINavigationController(rootViewController: vc)
            wrap.modalPresentationStyle = .fullScreen
            present(wrap, animated: true)
        }
    }

    // MARK: - Premium Badge

    private func setupPremiumBadge() {
        var cfg = UIButton.Configuration.filled()
        cfg.cornerStyle = .capsule
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
        cfg.baseBackgroundColor = UIColor.white.withAlphaComponent(0.18)
        let btn = UIButton(configuration: cfg)
        btn.addTarget(self, action: #selector(premiumBadgeTapped), for: .touchUpInside)
        let item = UIBarButtonItem(customView: btn)
        navigationItem.leftBarButtonItem = item
        premiumBadgeItem = item
        refreshPremiumBadge()
    }

    @objc private func refreshPremiumBadge() {
        guard let item = premiumBadgeItem,
              let btn = item.customView as? UIButton else { return }
        let pm = PremiumManager.shared
        var cfg = btn.configuration ?? UIButton.Configuration.filled()
        if pm.isPremium {
            cfg.attributedTitle = AttributedString("👑 Premium", attributes: AttributeContainer([
                .font: UIFont.systemFont(ofSize: 15, weight: .bold),
                .foregroundColor: goldColor
            ]))
        } else {
            let minRemaining = [
                pm.remainingFreeUses(for: .aiSummary),
                pm.remainingFreeUses(for: .remoteNassau),
                pm.remainingFreeUses(for: .liveWolf)
            ].min() ?? 0
            cfg.attributedTitle = AttributedString("👑 \(minRemaining) free", attributes: AttributeContainer([
                .font: UIFont.systemFont(ofSize: 15, weight: .bold),
                .foregroundColor: goldColor.withAlphaComponent(0.85)
            ]))
        }
        btn.configuration = cfg
    }

    @objc private func premiumBadgeTapped() {
        let pm = PremiumManager.shared
        if pm.isPremium {
            let ac = UIAlertController(title: "👑 WolfMore Premium",
                                       message: "Premium is active. Enjoy unlimited AI Summaries, Remote Nassau, and Live Wolf.",
                                       preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let lowestFeature: PremiumManager.Feature = [.aiSummary, .remoteNassau, .liveWolf]
                .min(by: { pm.remainingFreeUses(for: $0) < pm.remainingFreeUses(for: $1) }) ?? .aiSummary
            present(PaywallViewController(feature: lowestFeature), animated: true)
        }
    }

    // MARK: - Debug

    #if DEBUG
    private func setupDebugButton() {
        let btn = UIBarButtonItem(title: "🧪", style: .plain, target: self, action: #selector(debugTapped))
        navigationItem.rightBarButtonItem = btn
    }

    @objc private func debugTapped() {
        let ac = UIAlertController(title: "🧪 Debug", message: nil, preferredStyle: .actionSheet)

        ac.addAction(UIAlertAction(title: "Trigger location prompt (25-round rule)", style: .default) { _ in
            let currentRounds = Set(RoundStore.shared.rounds.map(\.gameID)).count
            let fakeRoundsAtDismissal = max(0, currentRounds - 25)
            UserDefaults.standard.set(fakeRoundsAtDismissal, forKey: "locationPrompt_roundsAtLastDismissal")
            // Ensure shownCount > 0 so the first-time trigger doesn't fire (we're testing the 25-round path)
            if UserDefaults.standard.integer(forKey: "locationPrompt_shownCount") == 0 {
                UserDefaults.standard.set(1, forKey: "locationPrompt_shownCount")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                LocationPromptViewController.showIfNeeded(from: self)
            }
        })

        ac.addAction(UIAlertAction(title: "Reset location prompt (show as first-time)", style: .destructive) { _ in
            UserDefaults.standard.removeObject(forKey: "locationPrompt_shownCount")
            UserDefaults.standard.removeObject(forKey: "locationPrompt_roundsAtLastDismissal")
            UserDefaults.standard.removeObject(forKey: "locationPrompt_lastDismissedVersion")
            UserDefaults.standard.removeObject(forKey: "locationPrompt_cleanupV2Done")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                LocationPromptViewController.showIfNeeded(from: self)
            }
        })

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.barButtonItem = navigationItem.rightBarButtonItem
        }
        present(ac, animated: true)
    }
    #endif

    // MARK: - Colors

    private var forestGreen: UIColor {
        UIColor(red: 0.106, green: 0.227, blue: 0.165, alpha: 1) // #1B3A2A
    }

    private var goldColor: UIColor {
        UIColor(red: 0.910, green: 0.851, blue: 0.541, alpha: 1) // #E8D98A
    }

    private var sageColor: UIColor {
        UIColor(red: 0.624, green: 0.784, blue: 0.659, alpha: 1) // #9FC8A8
    }

    private var wolfPrimaryGreen: UIColor {
        UIColor(red: 0.10, green: 0.33, blue: 0.18, alpha: 1.0)
    }
}

// MARK: - Stats Helpers
extension ViewController {

    func showMyStatsAlert(anchor: UIView) {
        let ac = UIAlertController(title: "My Stats", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Open My Stats", style: .default) { [weak self] _ in
            self?.openMyStatsScreen()
        })
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presentActionSheet(ac, anchor: anchor)
    }

    private func presentActionSheet(_ ac: UIAlertController, anchor: UIView) {
        if let pop = ac.popoverPresentationController {
            pop.sourceView = anchor
            pop.sourceRect = anchor.bounds
            pop.permittedArrowDirections = [.up, .down]
        }
        present(ac, animated: true)
    }

    private func openMyStatsScreen() {
        let vc = MyStatsViewController()
        vc.mode = .me
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            let wrap = UINavigationController(rootViewController: vc)
            wrap.modalPresentationStyle = .fullScreen
            present(wrap, animated: true)
        }
    }
}
