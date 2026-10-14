import XCTest
@testable import WolfmoreGolf

final class ScorecardSnapshotTest: XCTestCase {

    func testRenderScorecardToFile() throws {
        func p(net: Int, yG: Int = 4, oG: Int = 4, yS: Int = 0, oS: Int = 0,
               yH: Int = 1, oH: Int = 1, par: Int = 4) -> PairedHole {
            PairedHole(hcRank: 1, hostPhysicalHole: yH,
                       hostScore: yG, hostNetScore: yG - yS, hostStrokes: yS, hostPar: par,
                       opponentPhysicalHole: oH,
                       opponentScore: oG, opponentNetScore: oG - oS, opponentStrokes: oS, opponentPar: par,
                       netResult: net)
        }
        let waiting = PairedHole(hcRank: 1, hostPhysicalHole: 7,
                                  hostScore: 5, hostNetScore: 5, hostStrokes: 0, hostPar: 4,
                                  opponentPhysicalHole: 7,
                                  opponentScore: nil, opponentNetScore: nil, opponentStrokes: 0, opponentPar: 4,
                                  netResult: 0)
        let pairs: [PairedHole] = [
            p(net: -1, yG: 5, oG: 4, yH: 1,  oH:  3, par: 4),
            p(net: -1, yG: 6, oG: 5, yS: 1, yH: 2,  oH:  7, par: 5),
            p(net:  0, yG: 4, oG: 4, yH: 3,  oH:  1, par: 4),
            p(net:  1, yG: 3, oG: 4, yH: 4,  oH:  5, par: 4),
            p(net:  1, yG: 4, oG: 5, yH: 5,  oH:  9, par: 4),
            p(net:  0, yG: 4, oG: 4, yH: 6,  oH:  2, par: 4),
            waiting,
            p(net:  0, yG: 3, oG: 3, yH: 8,  oH:  6, par: 3),
            p(net: -1, yG: 5, oG: 4, yH: 9,  oH:  4, par: 4),
            p(net:  0, yG: 4, oG: 4, yH: 10, oH: 12, par: 4),
            p(net:  1, yG: 3, oG: 4, yH: 11, oH: 14, par: 4),
            p(net:  1, yG: 4, oG: 5, yS: 1, yH: 12, oH: 11, par: 5),
            p(net: -1, yG: 5, oG: 4, yH: 13, oH: 16, par: 4),
            p(net: -1, yG: 5, oG: 4, yH: 14, oH: 10, par: 4),
            p(net:  0, yG: 4, oG: 4, yH: 15, oH: 13, par: 4),
            p(net:  1, yG: 3, oG: 4, yH: 16, oH: 17, par: 3),
            p(net:  0, yG: 4, oG: 4, yH: 17, oH: 15, par: 4),
            p(net: -1, yG: 5, oG: 4, yH: 18, oH: 18, par: 4),
        ]
        let config = ScorecardConfig(
            ownerName: "McTommy", opponentName: "Wolfmore",
            ownerCourse: "Sunridge CC", opponentCourse: "Pineview GC",
            pairs: pairs, stake: 5, trigger: 2, pressMode: .auto, isV2: true,
            isSameCourse: false, posLabel: "#", title: "Scorecard")

        let vc  = NassauScorecardViewController(config: config)
        let nav = UINavigationController(rootViewController: vc)
        let size = CGSize(width: 390, height: 844)
        let win = UIWindow(frame: CGRect(origin: .zero, size: size))
        win.rootViewController = nav
        win.makeKeyAndVisible()

        // Force complete layout before capture
        vc.loadViewIfNeeded()
        nav.view.frame = CGRect(origin: .zero, size: size)
        nav.view.setNeedsLayout()
        nav.view.layoutIfNeeded()
        vc.view.setNeedsLayout()
        vc.view.layoutIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            nav.view.layer.render(in: ctx.cgContext)
        }
        let png = img.pngData()!
        let url = URL(fileURLWithPath: "/tmp/nassau_scorecard.png")
        try png.write(to: url)
        NSLog("Scorecard screenshot saved to: \(url.path)")

        // Also render via ScorecardRenderer (share image)
        let shareImg = ScorecardRenderer.render(config: config)
        let sharePng = shareImg.pngData()!
        let shareUrl = URL(fileURLWithPath: "/tmp/nassau_scorecard_share.png")
        try sharePng.write(to: shareUrl)
        NSLog("Share image saved to: \(shareUrl.path)")
    }
}

// MARK: - LiveConnectedViewController match boards snapshot

final class LiveConnectedSnapshotTest: XCTestCase {

    func testRenderMyMatchBoardsSection() throws {
        // Seed two recent boards and one older board
        UserDefaults.standard.removeObject(forKey: MatchBoardStore.key)
        let now = Date().timeIntervalSince1970
        let boards: [[String: Any]] = [
            ["code": "ESATMTC",  "name": "Saturday Match Play", "createdAt": now - 86400,      "organizerToken": "fake-tok"],
            ["code": "ERYDRCUP", "name": "Ryder Cup",            "createdAt": now - 5*86400],
            ["code": "EOLDONE",  "name": "Old Board Oct",         "createdAt": now - 35*86400],
        ]
        if let data = try? JSONSerialization.data(withJSONObject: boards) {
            UserDefaults.standard.set(data, forKey: MatchBoardStore.key)
        }

        let vc  = LiveConnectedViewController()
        let nav = UINavigationController(rootViewController: vc)
        let size = CGSize(width: 390, height: 844)
        let win = UIWindow(frame: CGRect(origin: .zero, size: size))
        win.rootViewController = nav
        win.makeKeyAndVisible()

        vc.loadViewIfNeeded()
        nav.view.frame = CGRect(origin: .zero, size: size)
        nav.view.layoutIfNeeded()
        vc.view.layoutIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in nav.view.layer.render(in: ctx.cgContext) }
        let url = URL(fileURLWithPath: "/tmp/live_connected_boards.png")
        try img.pngData()!.write(to: url)
        NSLog("Live Connected screenshot saved to: \(url.path)")

        UserDefaults.standard.removeObject(forKey: MatchBoardStore.key)
    }
}

final class LiveConnectedBoardsSectionTest: XCTestCase {

    func testRenderMyMatchBoardsSectionFull() throws {
        UserDefaults.standard.removeObject(forKey: MatchBoardStore.key)
        let now = Date().timeIntervalSince1970
        let boards: [[String: Any]] = [
            ["code": "ESATMTC",  "name": "Saturday Match Play", "createdAt": now - 86400,    "organizerToken": "fake-tok"],
            ["code": "ERYDRCUP", "name": "Ryder Cup",           "createdAt": now - 5*86400],
            ["code": "EOLDONE",  "name": "Old Board Oct",        "createdAt": now - 35*86400],
        ]
        if let data = try? JSONSerialization.data(withJSONObject: boards) {
            UserDefaults.standard.set(data, forKey: MatchBoardStore.key)
        }

        let vc  = LiveConnectedViewController()
        let nav = UINavigationController(rootViewController: vc)
        let size = CGSize(width: 390, height: 1600)
        let win = UIWindow(frame: CGRect(origin: .zero, size: size))
        win.rootViewController = nav
        win.makeKeyAndVisible()

        vc.loadViewIfNeeded()
        nav.view.frame = CGRect(origin: .zero, size: size)
        nav.view.layoutIfNeeded()
        vc.view.layoutIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        // Scroll to bottom to show MY MATCH BOARDS section
        if let tv = vc.tableView as? UITableView {
            let sections = tv.numberOfSections
            if sections > 0 {
                let rows = tv.numberOfRows(inSection: sections - 1)
                if rows > 0 {
                    tv.scrollToRow(at: IndexPath(row: 0, section: sections - 1), at: .bottom, animated: false)
                }
            }
        }
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in nav.view.layer.render(in: ctx.cgContext) }
        let url = URL(fileURLWithPath: "/tmp/live_connected_boards_full.png")
        try img.pngData()!.write(to: url)
        NSLog("Full Live Connected screenshot saved to: \(url.path)")

        UserDefaults.standard.removeObject(forKey: MatchBoardStore.key)
    }
}
