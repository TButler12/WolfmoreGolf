import UIKit

extension UIViewController {
    /// Present a UIAlertController with `.actionSheet` style safely on iPad.
    /// On iPhone this is identical to `present(_:animated:)`.
    /// On iPad, if no `sourceView` is given, the sheet anchors to the center of the view.
    func presentActionSheet(_ ac: UIAlertController, from sourceView: UIView? = nil, sourceRect: CGRect? = nil) {
        if let pop = ac.popoverPresentationController {
            let sv = sourceView ?? view!
            pop.sourceView = sv
            pop.sourceRect = sourceRect ?? sv.bounds
            if sourceView == nil {
                pop.permittedArrowDirections = []
            }
        }
        present(ac, animated: true)
    }

    func presentActionSheet(_ ac: UIAlertController, from barButton: UIBarButtonItem) {
        ac.popoverPresentationController?.barButtonItem = barButton
        present(ac, animated: true)
    }
}
