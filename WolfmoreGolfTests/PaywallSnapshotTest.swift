import XCTest
@testable import WolfmoreGolf

final class PaywallSnapshotTest: XCTestCase {
    func testRenderPaywallToFile() throws {
        let vc  = PaywallViewController(feature: .remoteNassau)
        let nav = UINavigationController(rootViewController: vc)
        let size = CGSize(width: 390, height: 844)
        let win = UIWindow(frame: CGRect(origin: .zero, size: size))
        win.rootViewController = nav
        win.makeKeyAndVisible()

        vc.loadViewIfNeeded()
        nav.view.frame = CGRect(origin: .zero, size: size)
        nav.view.setNeedsLayout()
        nav.view.layoutIfNeeded()
        vc.view.setNeedsLayout()
        vc.view.layoutIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))

        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            nav.view.layer.render(in: ctx.cgContext)
        }
        let url = URL(fileURLWithPath: "/tmp/paywall_screenshot.png")
        try img.pngData()!.write(to: url)
        NSLog("Paywall screenshot saved to: \(url.path)")
    }
}
