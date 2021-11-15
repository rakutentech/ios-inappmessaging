import UIKit

/// Extension to `UIColor` class to provide addtional initializers required by InAppMessaging.
internal extension UIColor {

    static var statusBarOverlayColor: UIColor {
        if UIApplication.shared.getCurrentStatusBarStyle() == .lightContent {
            return black.withAlphaComponent(0.4)
        } else {
            return white.withAlphaComponent(0.4)
        }
    }
}
