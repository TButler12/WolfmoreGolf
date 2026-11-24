import XCTest
import UIKit
@testable import WolfmoreGolf

/// Presents each Club Event screen on the live simulator display, then captures
/// UIScreen.main.snapshotView — reads the actual framebuffer, no cold-start blanks.
final class ClubEventSnapshotTests: XCTestCase {

    private let mockEvent = ClubEventRecord(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        code: "TEST01",
        name: "Summer Club Championship",
        organizerDeviceId: "device-abc",
        courseName: "Wolfmore Golf Club",
        numDays: 1,
        status: "active"
    )

    private func topVC() -> UIViewController? {
        var vc = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController
        while let p = vc?.presentedViewController { vc = p }
        return vc
    }

    private func captureView(_ view: UIView, to path: String) throws {
        let size = view.bounds.size
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { _ in
            view.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
        }
        guard let png = img.pngData() else { throw NSError(domain: "Snapshot", code: 1) }
        try png.write(to: URL(fileURLWithPath: path))
        NSLog("Screenshot saved: \(path), size: \(size), scale: \(UIScreen.main.scale)")
    }

    // MARK: - Screen 1: Join (with event card)

    func testScreen1_JoinWithEventCard() throws {
        let vc  = ClubEventJoinViewController()
        let nav = UINavigationController(rootViewController: vc)
        let exp = expectation(description: "presented")
        topVC()?.present(nav, animated: false) { exp.fulfill() }
        wait(for: [exp], timeout: 3)

        vc.showEventCard(mockEvent)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))

        try captureView(nav.view, to: "/tmp/club_event_1_join.png")

        let dim = expectation(description: "dismissed")
        nav.dismiss(animated: false) { dim.fulfill() }
        wait(for: [dim], timeout: 3)
    }

    // MARK: - Screen 2: Group Setup

    func testScreen2_GroupSetup() throws {
        let vc  = ClubEventGroupSetupViewController(event: mockEvent)
        vc.skipNetworkLoad = true
        let tid = mockEvent.id
        vc.allRoster = [
            ClubEventPlayer(id: UUID(), tournamentId: tid, playerName: "Smith, John",    handicap: 14, groupCode: nil),
            ClubEventPlayer(id: UUID(), tournamentId: tid, playerName: "Jones, Robert",  handicap: 7,  groupCode: nil),
            ClubEventPlayer(id: UUID(), tournamentId: tid, playerName: "Williams, Mark", handicap: 22, groupCode: nil),
            ClubEventPlayer(id: UUID(), tournamentId: tid, playerName: "Brown, David",   handicap: 0,  groupCode: nil),
            ClubEventPlayer(id: UUID(), tournamentId: tid, playerName: "Taylor, Chris",  handicap: 18, groupCode: "ABC123"),
            ClubEventPlayer(id: UUID(), tournamentId: tid, playerName: "Anderson, Paul", handicap: 11, groupCode: "ABC123"),
        ]
        vc.selected = [
            (.roster(vc.allRoster[0]), ["A"]),
            (.roster(vc.allRoster[1]), ["B"]),
        ]
        let nav = UINavigationController(rootViewController: vc)
        let exp = expectation(description: "presented")
        topVC()?.present(nav, animated: false) { exp.fulfill() }
        wait(for: [exp], timeout: 3)

        vc.tableView.reloadData()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))

        try captureView(nav.view, to: "/tmp/club_event_2_group_setup.png")

        let dim = expectation(description: "dismissed")
        nav.dismiss(animated: false) { dim.fulfill() }
        wait(for: [dim], timeout: 3)
    }

    // MARK: - Screen 3: Group Code + QR

    func testScreen3_GroupCode() throws {
        let tid = mockEvent.id
        let vc  = ClubEventGroupCodeViewController(
            groupCode:    "GX7K4P",
            eventCode:    mockEvent.code,
            eventName:    "Summer Club Championship",
            players: [
                ClubEventGroupPlayer(id: UUID(), name: "Smith, John",    handicap: 14, teams: ["A"]),
                ClubEventGroupPlayer(id: UUID(), name: "Jones, Robert",  handicap: 7,  teams: ["B"]),
                ClubEventGroupPlayer(id: UUID(), name: "Williams, Mark", handicap: 22, teams: ["A"]),
                ClubEventGroupPlayer(id: UUID(), name: "Brown, David",   handicap: 0,  teams: ["B"]),
            ],
            tournamentId: tid,
            startingHole: 1
        )
        let nav = UINavigationController(rootViewController: vc)
        let exp = expectation(description: "presented")
        topVC()?.present(nav, animated: false) { exp.fulfill() }
        wait(for: [exp], timeout: 3)

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))

        try captureView(nav.view, to: "/tmp/club_event_3_code.png")

        let dim = expectation(description: "dismissed")
        nav.dismiss(animated: false) { dim.fulfill() }
        wait(for: [dim], timeout: 3)
    }
}
